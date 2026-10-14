package de.aetheria.lebendiger_spielleiter

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.Closeable
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/** Transient SAF access; this bridge never requests storage or persistent URI permission. */
internal class JsonBackupBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val main = Handler(Looper.getMainLooper())
    // Only one operation runs. The second worker can close its stream during destruction.
    private val workers = Executors.newFixedThreadPool(2)
    private var pending: Operation? = null
    private var disposed = false

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "saveJson" && call.method != "openJson") {
            result.notImplemented()
            return
        }
        if (disposed) {
            result.error("interrupted", "Die Dateiauswahl wurde unterbrochen.", null)
            return
        }
        if (pending != null) {
            result.error("busy", "Eine Dateiauswahl ist bereits geöffnet.", null)
            return
        }

        val save = call.method == "saveJson"
        val arguments = call.arguments as? Map<*, *>
        val name = arguments?.get("name") as? String
        val bytes = arguments?.get("bytes") as? ByteArray
        if (save && (name == null || !JsonBackupIo.isSafeName(name) || bytes == null)) {
            result.error("invalid_argument", "Der Dateiname oder die Sicherung ist ungültig.", null)
            return
        }
        if (save && bytes!!.size > JsonBackupIo.MAX_BYTES) {
            result.error("too_large", "Die Sicherung darf höchstens 10 MiB groß sein.", null)
            return
        }
        if (save && !JsonBackupIo.isValidPayload(bytes!!)) {
            result.error("invalid_argument", "Die Sicherung darf nicht leer sein.", null)
            return
        }
        if (!save && call.arguments != null) {
            result.error("invalid_argument", "Die Dateiauswahl benötigt keine Argumente.", null)
            return
        }

        val operation = Operation(if (save) REQUEST_SAVE else REQUEST_OPEN, result, bytes)
        pending = operation
        val intent = if (save) {
            Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/json"
                putExtra(Intent.EXTRA_TITLE, name)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            }
        } else {
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                putExtra(
                    Intent.EXTRA_MIME_TYPES,
                    arrayOf("application/json", "text/*", "application/octet-stream"),
                )
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
        try {
            activity.startActivityForResult(intent, operation.requestCode)
        } catch (_: ActivityNotFoundException) {
            fail(operation, "unavailable", "Auf diesem Gerät ist keine Dateiauswahl verfügbar.")
        } catch (_: SecurityException) {
            fail(operation, "unavailable", "Die Dateiauswahl ist auf diesem Gerät nicht verfügbar.")
        } catch (_: Exception) {
            fail(operation, "unavailable", "Die Dateiauswahl konnte nicht geöffnet werden.")
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) return false
        val operation = pending ?: return true
        if (disposed || requestCode != operation.requestCode || !operation.awaitingPicker) return true
        operation.awaitingPicker = false
        if (resultCode == Activity.RESULT_CANCELED) {
            succeed(operation, if (requestCode == REQUEST_SAVE) false else null)
            return true
        }
        if (resultCode != Activity.RESULT_OK) {
            fail(operation, "io", "Die Dateiauswahl wurde nicht erfolgreich abgeschlossen.")
            return true
        }
        val uri = data?.data
        if (uri == null || uri.scheme != "content") {
            fail(operation, "io", "Die ausgewählte Datei konnte nicht geöffnet werden.")
            return true
        }
        val resolver = activity.contentResolver
        val context = activity.applicationContext
        try {
            workers.execute {
                try {
                    val value: Any = if (requestCode == REQUEST_SAVE) {
                        val output = resolver.openOutputStream(uri, "w")
                            ?: throw IOException("Missing output stream")
                        operation.stream.set(output)
                        try {
                            JsonBackupIo.write(output, operation.bytes!!) { operation.cancelled.get() }
                        } finally {
                            operation.stream.compareAndSet(output, null)
                        }
                        true
                    } else {
                        val input = resolver.openInputStream(uri)
                            ?: throw IOException("Missing input stream")
                        operation.stream.set(input)
                        try {
                            JsonBackupIo.read(input) { operation.cancelled.get() }
                        } finally {
                            operation.stream.compareAndSet(input, null)
                        }
                    }
                    if (operation.cancelled.get()) {
                        if (requestCode == REQUEST_SAVE) deleteCreatedDocument(resolver, context, uri)
                    } else {
                        main.post { succeed(operation, value) }
                    }
                } catch (_: BackupTooLargeException) {
                    main.post {
                        fail(operation, "too_large", "Die Datei darf höchstens 10 MiB groß sein.")
                    }
                } catch (_: Exception) {
                    // ACTION_CREATE_DOCUMENT creates a new file rather than overwriting one.
                    // Remove a partial new document when its provider permits deletion.
                    if (requestCode == REQUEST_SAVE) deleteCreatedDocument(resolver, context, uri)
                    if (!operation.cancelled.get()) {
                        main.post { fail(operation, "io", "Die Datei konnte nicht gelesen oder gespeichert werden.") }
                    }
                }
            }
        } catch (_: RejectedExecutionException) {
            fail(operation, "interrupted", "Der Dateivorgang wurde unterbrochen.")
        }
        return true
    }

    /** Called on the activity/main thread. A pending Dart result is completed exactly once. */
    fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        pending?.let { operation ->
            operation.cancelled.set(true)
            fail(operation, "interrupted", "Der Dateivorgang wurde unterbrochen.")
            operation.stream.getAndSet(null)?.let { stream ->
                // Closing a content-provider stream can block; do not perform it on the UI thread.
                workers.execute { try { stream.close() } catch (_: Exception) { } }
            }
        }
        workers.shutdown()
    }

    private fun succeed(operation: Operation, value: Any?) {
        if (pending !== operation) return
        pending = null
        val result = operation.result
        operation.result = null
        result?.success(value)
    }

    private fun fail(operation: Operation, code: String, message: String) {
        if (pending !== operation) return
        pending = null
        val result = operation.result
        operation.result = null
        result?.error(code, message, null)
    }

    private class Operation(
        val requestCode: Int,
        var result: MethodChannel.Result?,
        val bytes: ByteArray?,
    ) {
        var awaitingPicker = true
        val cancelled = AtomicBoolean(false)
        val stream = AtomicReference<Closeable?>(null)
    }

    companion object {
        private const val CHANNEL = "de.aetheria.lebendiger_spielleiter/backups"
        private const val REQUEST_SAVE = 61051
        private const val REQUEST_OPEN = 61052

        private fun deleteCreatedDocument(
            resolver: android.content.ContentResolver,
            context: android.content.Context,
            uri: Uri,
        ) {
            try {
                if (DocumentsContract.isDocumentUri(context, uri)) {
                    DocumentsContract.deleteDocument(resolver, uri)
                }
            } catch (_: Exception) {
                // Providers may refuse deletion. Neither the URI nor its contents enter logs.
            }
        }
    }
}

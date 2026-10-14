package de.aetheria.lebendiger_spielleiter

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.InterruptedIOException
import java.io.OutputStream

/** Byte limits apply to the actual stream, without trusting provider metadata. */
internal object JsonBackupIo {
    const val MAX_BYTES = 10 * 1024 * 1024
    private const val BUFFER_BYTES = 8192
    private val forbiddenNameCharacters = setOf('/', '\\', '<', '>', ':', '"', '|', '?', '*')

    fun isSafeName(name: String): Boolean =
        name.length in 6..128 &&
            name == name.trim() &&
            !name.startsWith('.') &&
            name.endsWith(".json") &&
            name.none { it in forbiddenNameCharacters || Character.isISOControl(it) }

    fun isValidPayload(bytes: ByteArray): Boolean = bytes.isNotEmpty() && bytes.size <= MAX_BYTES

    fun read(input: InputStream, cancelled: () -> Boolean = { false }): ByteArray =
        input.use { source ->
            val result = ByteArrayOutputStream(BUFFER_BYTES)
            val buffer = ByteArray(BUFFER_BYTES)
            while (true) {
                checkInterrupted(cancelled)
                val count = source.read(buffer)
                if (count < 0) break
                if (count == 0) {
                    // Some providers return zero unexpectedly. A scalar read makes progress.
                    val next = source.read()
                    if (next < 0) break
                    if (result.size() == MAX_BYTES) throw BackupTooLargeException()
                    result.write(next)
                } else {
                    if (count > MAX_BYTES - result.size()) throw BackupTooLargeException()
                    result.write(buffer, 0, count)
                }
            }
            checkInterrupted(cancelled)
            result.toByteArray()
        }

    fun write(output: OutputStream, bytes: ByteArray, cancelled: () -> Boolean = { false }) {
        output.use { target ->
            require(isValidPayload(bytes)) { "Invalid backup size" }
            var offset = 0
            while (offset < bytes.size) {
                checkInterrupted(cancelled)
                val count = minOf(BUFFER_BYTES, bytes.size - offset)
                target.write(bytes, offset, count)
                offset += count
            }
            checkInterrupted(cancelled)
            target.flush()
        }
    }

    private fun checkInterrupted(cancelled: () -> Boolean) {
        if (cancelled() || Thread.currentThread().isInterrupted) {
            throw InterruptedIOException("Backup interrupted")
        }
    }
}

internal class BackupTooLargeException : IOException("Backup exceeds limit")

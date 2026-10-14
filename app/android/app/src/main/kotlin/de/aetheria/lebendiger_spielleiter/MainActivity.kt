package de.aetheria.lebendiger_spielleiter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var backups: JsonBackupBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        backups?.dispose()
        backups = JsonBackupBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    @Deprecated("Android's activity result API is used for compatibility with FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (backups?.onActivityResult(requestCode, resultCode, data) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDestroy() {
        backups?.dispose()
        backups = null
        super.onDestroy()
    }
}

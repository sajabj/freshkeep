package com.freshkeep.freshkeep

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private var exportResult: MethodChannel.Result? = null
    private var exportContent: String? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "freshkeep/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "timezone" -> result.success(TimeZone.getDefault().id)
                    "exportJson" -> {
                        val content = call.argument<String>("content")
                        if (exportResult != null || content == null) {
                            result.error("export_busy", "Export unavailable", null)
                        } else {
                            exportResult = result
                            exportContent = content
                            try {
                                startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    type = "application/json"
                                    putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "FreshKeep.json")
                                }, 5105)
                            } catch (error: Exception) {
                                exportResult = null
                                exportContent = null
                                result.error("export_failed", "Cannot open document picker", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    @Deprecated("Activity result bridge used by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 5105) return
        val result = exportResult ?: return
        val content = exportContent ?: ""
        exportResult = null
        exportContent = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(false)
            return
        }
        // Only the URI explicitly granted by the system picker is writable.
        Thread {
            try {
                val output = contentResolver.openOutputStream(uri, "wt")
                    ?: throw java.io.IOException("No output stream")
                output.bufferedWriter(Charsets.UTF_8).use { it.write(content) }
                runOnUiThread { result.success(true) }
            } catch (error: Exception) {
                // A provider may leave a partial document; do not report success.
                runOnUiThread { result.error("export_failed", "Cannot write document", null) }
            }
        }.start()
    }
}

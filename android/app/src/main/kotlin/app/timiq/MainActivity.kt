package app.timiq

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PLATFORM_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncPlatform" -> {
                    @Suppress("UNCHECKED_CAST")
                    val payload = call.arguments as? Map<String, Any?>
                    if (payload == null) {
                        result.error("invalid_payload", "Chybí data pro Android.", null)
                        return@setMethodCallHandler
                    }
                    thread(name = "timiq-platform-sync") {
                        try {
                            PlatformSync.saveFlutterPayload(this, payload)
                            PlatformSync.updateFavoriteTotals(this)
                            PlatformSync.refreshSurfaces(this)
                            runOnUiThread { result.success(null) }
                        } catch (error: Exception) {
                            Log.e(
                                "TimIQ.MainActivity",
                                "Android surface synchronization failed",
                                error,
                            )
                            runOnUiThread {
                                result.error(
                                    "platform_sync_failed",
                                    "Android plochy se nepodařilo obnovit.",
                                    error.javaClass.simpleName,
                                )
                            }
                        }
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        requestPermissions(
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            NOTIFICATION_PERMISSION_REQUEST,
                        )
                    }
                    result.success(null)
                }
                "resetPlatform" -> {
                    thread(name = "timiq-platform-reset") {
                        try {
                            PlatformSync.resetSurfaces(this)
                            runOnUiThread { result.success(null) }
                        } catch (error: Exception) {
                            Log.e(
                                "TimIQ.MainActivity",
                                "Android surface reset failed",
                                error,
                            )
                            runOnUiThread {
                                result.error(
                                    "platform_reset_failed",
                                    "Android plochy se nepodařilo resetovat.",
                                    error.javaClass.simpleName,
                                )
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (
            requestCode == NOTIFICATION_PERMISSION_REQUEST &&
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        ) {
            PlatformSync.refreshSurfaces(this)
        }
    }

    companion object {
        private const val PLATFORM_CHANNEL = "app.timiq/platform"
        private const val NOTIFICATION_PERMISSION_REQUEST = 8101
    }
}

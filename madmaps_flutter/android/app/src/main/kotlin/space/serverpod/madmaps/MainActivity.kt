package space.serverpod.madmaps

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "madmaps/ar_config")
            .setMethodCallHandler { call, result ->
                if (call.method == "hasCloudAnchorKey") {
                    val info = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                    val key = info.metaData?.getString("com.google.android.ar.API_KEY")
                    result.success(!key.isNullOrBlank())
                } else {
                    result.notImplemented()
                }
            }
    }
}

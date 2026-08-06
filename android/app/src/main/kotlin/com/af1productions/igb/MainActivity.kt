package com.af1productions.igb

import com.google.ar.core.ArCoreApk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // i-GB installs on phones without ARCore (see AndroidManifest), so the
        // scanner has to ask what this device can do before opening an ARView.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "arCoreAvailability") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                // checkAvailability can answer "still checking" while Google Play
                // Services for AR is queried, so use the async form and let
                // ARCore call back once it knows for certain.
                ArCoreApk.getInstance().checkAvailabilityAsync(this) { availability ->
                    // Pass the enum name through and let Dart decide what to show.
                    // The distinction matters: a device can support ARCore while
                    // the Play Services for AR package is missing or too old,
                    // which is fixable by the player.
                    result.success(availability.name)
                }
            }
    }

    private companion object {
        const val CHANNEL = "com.af1productions.igb/arcore"
    }
}

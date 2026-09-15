//package com.example.vira_planter_app
//
//import io.flutter.embedding.android.FlutterActivity
//
//class MainActivity : FlutterActivity(){}


package com.example.vira_planter_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "vira/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "getNativeMessage") {
                result.success("Hello from Kotlin!")
            } else {
                result.notImplemented()
            }
        }
    }
}
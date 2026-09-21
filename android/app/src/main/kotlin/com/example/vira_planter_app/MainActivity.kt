package com.example.vira_planter_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.content.Context
import android.os.BatteryManager

class MainActivity : FlutterActivity() {

    private val channel = "vira/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->

            if (call.method == "getNativeMessage") {
                result.success("Hello from Kotlin!")
            }
            else if (call.method == "getBatteryInfo") {

                val batteryManager = getSystemService(
                    Context.BATTERY_SERVICE
                ) as BatteryManager

                val batteryLevel = batteryManager.getIntProperty(
                    BatteryManager.BATTERY_PROPERTY_CAPACITY
                )

                result.success(batteryLevel)
            }
            else {
                result.notImplemented()
            }
        }
    }
}
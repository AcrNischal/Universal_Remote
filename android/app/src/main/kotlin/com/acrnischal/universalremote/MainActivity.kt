package com.acrnischal.universalremote

import android.content.Context
import android.hardware.ConsumerIrManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.universalremote.ir/blaster"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasIrEmitter" -> {
                    val irManager = getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        result.success(irManager?.hasIrEmitter() ?: false)
                    } else {
                        result.success(false)
                    }
                }
                "transmit" -> {
                    val frequency = call.argument<Int>("frequency") ?: 38000
                    val patternList = call.argument<List<Int>>("pattern")
                    
                    if (patternList == null) {
                        result.error("INVALID_ARGUMENT", "Pattern cannot be null", null)
                        return@setMethodCallHandler
                    }

                    val pattern = patternList.toIntArray()
                    val irManager = getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT && irManager != null && irManager.hasIrEmitter()) {
                        try {
                            irManager.transmit(frequency, pattern)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("TRANSMIT_FAILED", e.message, null)
                        }
                    } else {
                        result.error("NO_IR_BLASTER", "Device has no IR emitter or Android version is below KitKat", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

package io.bearound.telemetry.bearound_telemetry_flutter_sdk

import android.Manifest
import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.bearound.telemetry.BearoundTelemetrySDK
import io.bearound.telemetry.interfaces.BearoundTelemetrySDKListener
import io.bearound.telemetry.models.Beacon
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bearound Telemetry — Flutter plugin (Android only).
 *
 * Thin bridge over the native Bearound Telemetry SDK: beacon-hardware telemetry
 * (battery, temperature, movement, firmware, signal) with NO location permission.
 *
 * Companion handoff is AUTOMATIC: when the Bearound tracking SDK is present in the
 * same app (e.g. via the bearound_flutter_sdk plugin) and already configured, this
 * plugin hands its instance to the telemetry SDK reflectively — business token and
 * device id come from tracking, so both SDKs report as the same device. Standalone
 * apps just pass the businessToken.
 */
class BearoundTelemetryFlutterSdkPlugin :
    FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var beaconsChannel: EventChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var beaconsSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val sdk: BearoundTelemetrySDK by lazy {
        BearoundTelemetrySDK.getInstance(context)
    }

    private val listener = object : BearoundTelemetrySDKListener {
        override fun onBeaconsUpdated(beacons: List<Beacon>) {
            val payload = beacons.map { b ->
                mapOf(
                    "uuid" to b.uuid.toString(),
                    "major" to b.major,
                    "minor" to b.minor,
                    "rssi" to b.rssi,
                    "lastSeen" to b.timestamp.time,
                    "battery" to b.metadata?.batteryLevel,
                    "temperature" to b.metadata?.temperature,
                    "movements" to b.metadata?.movements,
                    "firmware" to b.metadata?.firmwareVersion,
                )
            }
            mainHandler.post { beaconsSink?.success(payload) }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "bearound_telemetry_flutter_sdk")
        methodChannel.setMethodCallHandler(this)
        beaconsChannel = EventChannel(binding.binaryMessenger, "bearound_telemetry_flutter_sdk/beacons")
        beaconsChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                beaconsSink = events
            }

            override fun onCancel(arguments: Any?) {
                beaconsSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        beaconsChannel.setStreamHandler(null)
        beaconsSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> {
                val token = call.argument<String>("businessToken") ?: ""
                val precision = io.bearound.telemetry.models.ScanPrecision.fromName(
                    call.argument<String>("scanPrecision") ?: "medium"
                )
                sdk.listener = listener
                val tracking = trackingSdkInstanceOrNull()
                if (tracking != null) {
                    // Companion: credentials + deviceId handoff from the tracking instance.
                    sdk.configure(tracking, scanPrecision = precision, technology = "flutter-telemetry")
                } else {
                    sdk.configure(
                        businessToken = token,
                        scanPrecision = precision,
                        technology = "flutter-telemetry",
                    )
                }
                result.success(tracking != null)
            }

            "startScanning" -> {
                sdk.startScanning()
                result.success(null)
            }

            "stopScanning" -> {
                sdk.stopScanning()
                result.success(null)
            }

            "getDeviceId" -> result.success(sdk.deviceId)

            "requestPermissions" -> {
                val act = activity
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && act != null) {
                    ActivityCompat.requestPermissions(
                        act,
                        arrayOf(Manifest.permission.BLUETOOTH_SCAN),
                        7401
                    )
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Reflective lookup of a CONFIGURED io.bearound.sdk.BeAroundSDK instance — no
     * compile-time dependency on the tracking SDK (the two artifacts stay independent).
     * Returns null when the tracking SDK is absent or not configured yet.
     */
    private fun trackingSdkInstanceOrNull(): Any? = try {
        val cls = Class.forName("io.bearound.sdk.BeAroundSDK")
        val instance = cls.getMethod("getInstance", Context::class.java).invoke(null, context)
        val token = runCatching {
            cls.getMethod("getBusinessToken").invoke(instance) as? String
        }.getOrNull()
        if (token.isNullOrBlank()) null else instance
    } catch (_: Throwable) {
        null
    }

    // ActivityAware — needed only for the runtime-permission helper.
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}

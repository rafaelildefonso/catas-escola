package com.catas.catas

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.catas/native_context"
        private const val EVENT_CHANNEL = "com.catas/native_context_stream"
        private const val POLL_INTERVAL_MS = 2000L
    }

    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isPolling = false

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!isPolling) return
            val ctx = captureForegroundContext()
            eventSink?.success(ctx)
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCurrentContext" -> {
                        result.success(captureForegroundContext())
                    }
                    "startContextStream" -> {
                        startPolling()
                        result.success(null)
                    }
                    "stopContextStream" -> {
                        stopPolling()
                        result.success(null)
                    }
                    "hasUsageStatsPermission" -> {
                        result.success(hasUsageStatsPermission())
                    }
                    "requestUsageStatsPermission" -> {
                        requestUsageStatsPermission()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startPolling()
                }

                override fun onCancel(arguments: Any?) {
                    stopPolling()
                    eventSink = null
                }
            })
    }

    private fun startPolling() {
        if (isPolling) return
        isPolling = true
        handler.post(pollRunnable)
    }

    private fun stopPolling() {
        isPolling = false
        handler.removeCallbacks(pollRunnable)
    }

    /**
     * Captures the foreground app name using UsageStatsManager.
     * Returns a Map matching the Dart NativeContext.fromJson format.
     */
    private fun captureForegroundContext(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val iso = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        iso.timeZone = TimeZone.getTimeZone("UTC")
        map["capturedAt"] = iso.format(Date())

        if (!hasUsageStatsPermission()) {
            // Without permission we can only return the timestamp.
            return map
        }

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
        if (usm != null) {
            val end = System.currentTimeMillis()
            val begin = end - 5000 // last 5 seconds
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, begin, end)
            if (!stats.isNullOrEmpty()) {
                val recent = stats.maxByOrNull { it.lastTimeUsed }
                if (recent != null) {
                    map["foregroundAppId"] = recent.packageName
                    // Try to resolve a human-readable label
                    try {
                        val pm = packageManager
                        val appInfo = pm.getApplicationInfo(recent.packageName, 0)
                        map["foregroundAppName"] = pm.getApplicationLabel(appInfo).toString()
                    } catch (_: Exception) {
                        map["foregroundAppName"] = recent.packageName
                    }
                }
            }
        }

        // NOTE: Capturing the exact browser URL on Android requires an
        // AccessibilityService, which adds significant UX friction. For now we
        // only report the foreground app. Browser URL support can be added in a
        // future iteration with a dedicated AccessibilityService.

        return map
    }

    private fun hasUsageStatsPermission(): Boolean {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return false
        val end = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, end - 60000, end)
        return !stats.isNullOrEmpty()
    }

    private fun requestUsageStatsPermission() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    override fun onDestroy() {
        stopPolling()
        super.onDestroy()
    }
}

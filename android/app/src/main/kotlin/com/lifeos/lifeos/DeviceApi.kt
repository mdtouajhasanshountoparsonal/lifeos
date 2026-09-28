package com.lifeos.lifeos

import android.app.Activity
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.CallLog
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

object DeviceApi {

    const val CHANNEL = "lifeos/device"

    fun install(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val activity = currentActivity()
            try {
                when (call.method) {
                    "startMonitor" -> {
                        DeviceMonitorService.start(activity)
                        result.success(true)
                    }
                    "stopMonitor" -> {
                        DeviceMonitorService.stop(activity)
                        result.success(true)
                    }
                    "serviceRunning" -> result.success(isServiceRunning(activity))
                    "batteryNow" -> result.success(batteryNow(activity))
                    "deviceInfo" -> result.success(deviceInfo())
                    "events" -> {
                        val from = call.argument<Number>("from")?.toLong() ?: 0L
                        val to = call.argument<Number>("to")?.toLong() ?: System.currentTimeMillis()
                        result.success(EventStore.get(activity).query(from, to))
                    }
                    "callLog" -> {
                        val from = call.argument<Number>("from")?.toLong() ?: 0L
                        result.success(callLog(activity, from))
                    }
                    "usageStats" -> {
                        val from = call.argument<Number>("from")?.toLong() ?: 0L
                        result.success(usageStats(activity, from))
                    }
                    "installedApps" -> result.success(installedApps(activity))
                    "clearEvents" -> {
                        EventStore.get(activity).clearAllEvents()
                        result.success(true)
                    }
                    "lockConfig" -> {
                        val pkg = call.argument<String>("pkg") ?: ""
                        result.success(EventStore.get(activity).lockConfig(pkg))
                    }
                    "setLock" -> {
                        val pkg = call.argument<String>("pkg") ?: ""
                        val pin = call.argument<Int>("pin") ?: 0
                        val smart = call.argument<Int>("smartMinutes") ?: 0
                        val hash = sha256("lifeos::$pin")
                        EventStore.get(activity).setLock(pkg, hash, smart)
                        result.success(true)
                    }
                    "removeLock" -> {
                        val pkg = call.argument<String>("pkg") ?: ""
                        EventStore.get(activity).removeLock(pkg)
                        result.success(true)
                    }
                    "lockedApps" -> result.success(EventStore.get(activity).lockedPackages())
                    "lastUnlock" -> {
                        val pkg = call.argument<String>("pkg") ?: ""
                        result.success(EventStore.get(activity).lastUnlock(pkg))
                    }
                    "failedAttempts" -> {
                        val pkg = call.argument<String>("pkg") ?: ""
                        result.success(EventStore.get(activity).failedAttempts(pkg))
                    }
                    "usageAccessGranted" -> result.success(hasUsageAccess(activity))
                    "notifListenerEnabled" -> result.success(notifListenerEnabled(activity))
                    "accessibilityEnabled" -> result.success(accessibilityEnabled(activity))
                    "unlockNow" -> {
                        val pkg = call.argument<String>("pkg") ?: ""
                        val minutes = call.argument<Int>("minutes") ?: 1
                        val ts = System.currentTimeMillis()
                        EventStore.get(activity).markUnlock(pkg, ts)
                        LockStateHolder.unlockUntil[pkg] = ts + (minutes * 60000L)
                        result.success(true)
                    }
                    "openUsageSettings" -> {
                        activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    }
                    "openNotifSettings" -> {
                        activity.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(true)
                    }
                    "openAccessibilitySettings" -> {
                        activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(true)
                    }
                    "launchApp" -> {
                        val pkg = call.argument<String>("pkg") ?: ""
                        launchApp(activity, pkg)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("DEVICE_API", e.message, null)
            }
        }
    }

    private fun currentActivity(): Activity {
        return AppHolder.activity
    }

    private fun isServiceRunning(context: Context): Boolean {
        val sp = context.getSharedPreferences("lifeos_monitor", Context.MODE_PRIVATE)
        return sp.getBoolean("running", false)
    }

    private fun batteryNow(context: Context): Map<String, Any?> {
        val i = context.registerReceiver(null, android.content.IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = i?.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = i?.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, 100) ?: 100
        val tempC = (i?.getIntExtra(android.os.BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0) / 10.0
        val status = i?.getIntExtra(android.os.BatteryManager.EXTRA_STATUS, -1) ?: -1
        val plugged = i?.getIntExtra(android.os.BatteryManager.EXTRA_PLUGGED, 0) ?: 0
        val charging = status == android.os.BatteryManager.BATTERY_STATUS_CHARGING ||
            status == android.os.BatteryManager.BATTERY_STATUS_FULL
        return mapOf(
            "level" to level,
            "scale" to scale,
            "percent" to if (scale > 0) level * 100 / scale else -1,
            "tempC" to tempC,
            "charging" to charging,
            "plugged" to plugged
        )
    }

    private fun deviceInfo(): Map<String, Any?> {
        return mapOf(
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "sdk" to Build.VERSION.SDK_INT,
            "android" to Build.VERSION.RELEASE
        )
    }

    private fun callLog(context: Context, from: Long): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        if (checkCallLog(context)) {
            try {
                val cursor = context.contentResolver.query(
                    CallLog.Calls.CONTENT_URI,
                    arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.TYPE, CallLog.Calls.DURATION, CallLog.Calls.DATE),
                    "${CallLog.Calls.DATE} >= ?",
                    arrayOf(from.toString()),
                    "${CallLog.Calls.DATE} ASC"
                )
                cursor?.use {
                    while (it.moveToNext()) {
                        out.add(
                            mapOf(
                                "number" to it.getString(0),
                                "type" to it.getInt(1),
                                "duration" to it.getLong(2),
                                "date" to it.getLong(3)
                            )
                        )
                    }
                }
            } catch (_: Exception) {}
        }
        return out
    }

    private fun usageStats(context: Context, from: Long): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        if (hasUsageAccess(context)) {
            try {
                val now = System.currentTimeMillis()
                val um = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val stats: MutableMap<String, UsageStats> = HashMap()
                um.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, from, now).forEach { s ->
                    stats[s.packageName] = s
                }
                val events = um.queryEvents(from, now)
                val lastUsed = HashMap<String, Long>()
                val event = UsageEvents.Event()
                while (events.hasNextEvent()) {
                    events.getNextEvent(event)
                    if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                        lastUsed[event.packageName] = event.timeStamp
                    }
                }
                stats.forEach { (pkg, s) ->
                    out.add(
                        mapOf(
                            "pkg" to pkg,
                            "totalTime" to s.totalTimeInForeground,
                            "lastTime" to (lastUsed[pkg] ?: s.lastTimeUsed)
                        )
                    )
                }
            } catch (_: Exception) {}
        }
        return out
    }

    private fun installedApps(context: Context): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        try {
            val pm = context.packageManager
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            val list = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(intent, 0)
            }
            list.sortedBy { it.loadLabel(pm).toString() }.forEach { ri ->
                out.add(
                    mapOf(
                        "pkg" to ri.activityInfo.packageName,
                        "label" to ri.loadLabel(pm).toString()
                    )
                )
            }
        } catch (_: Exception) {}
        return out
    }

    private fun launchApp(context: Context, pkg: String) {
        try {
            val intent = context.packageManager.getLaunchIntentForPackage(pkg) ?: return
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        } catch (_: Exception) {}
    }

    private fun checkCallLog(context: Context): Boolean =
        context.checkSelfPermission(android.Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED

    private fun hasUsageAccess(context: Context): Boolean {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            }
            mode == android.app.AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) { false }
    }

    private fun notifListenerEnabled(context: Context): Boolean {
        return try {
            val flat = Settings.Secure.getString(
                context.contentResolver, "enabled_notification_listeners") ?: ""
            flat.split(":").any { it.contains(context.packageName) }
        } catch (_: Exception) { false }
    }

    private fun accessibilityEnabled(context: Context): Boolean {
        return try {
            val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
            val enabled = am.getEnabledAccessibilityServiceList(
                android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_GENERIC)
            enabled.any { it.resolveInfo.serviceInfo.packageName == context.packageName }
        } catch (_: Exception) { false }
    }

    private fun sha256(s: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(s.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }
}

object AppHolder {
    lateinit var activity: Activity
}
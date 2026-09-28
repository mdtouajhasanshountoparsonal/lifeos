package com.lifeos.lifeos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class DeviceMonitorService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var lastNetwork = ""
    private var screenReceiver: BroadcastReceiver? = null

    private val sampler = object : Runnable {
        override fun run() {
            sample()
            handler.postDelayed(this, 60000L)
        }
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundCompat()
        setRunning()
        // SCREEN_ON/OFF/USER_PRESENT cannot be registered in the manifest on
        // Android 8+, so register dynamically while the foreground service runs.
        val sf = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        val recv = LifeOSReceivers.Screen()
        try {
            registerReceiver(recv, sf)
            screenReceiver = recv
        } catch (_: Exception) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundCompat()
        setRunning()
        handler.removeCallbacks(sampler)
        handler.postDelayed(sampler, 1500L)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(sampler)
        screenReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        screenReceiver = null
        try {
            getSharedPreferences("lifeos_monitor", Context.MODE_PRIVATE)
                .edit().putBoolean("running", false).apply()
        } catch (_: Exception) {}
        super.onDestroy()
    }

    private fun setRunning() {
        try {
            getSharedPreferences("lifeos_monitor", Context.MODE_PRIVATE)
                .edit().putBoolean("running", true).apply()
        } catch (_: Exception) {}
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundCompat() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                var ch = nm.getNotificationChannel("lifeos_monitor")
                if (ch == null) {
                    ch = NotificationChannel(
                        "lifeos_monitor",
                        "LifeOS Monitor",
                        NotificationManager.IMPORTANCE_LOW
                    )
                    nm.createNotificationChannel(ch)
                }
            }
            val id = 1001
            val notif: Notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, "lifeos_monitor")
                    .setContentTitle("LifeOS Monitor")
                    .setContentText("Device intelligence is active")
                    .setSmallIcon(android.R.drawable.ic_menu_compass)
                    .setOngoing(true)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
                    .setContentTitle("LifeOS Monitor")
                    .setContentText("Device intelligence is active")
                    .setSmallIcon(android.R.drawable.ic_menu_compass)
                    .setOngoing(true)
                    .build()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(id, notif, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(id, notif)
            }
        } catch (_: Exception) {}
    }

    private fun sample() {
        try {
            val store = EventStore.get(this)
            val ts = System.currentTimeMillis()

            val b = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val level = b?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = b?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
            val tempC = (b?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0) / 10.0
            val status = b?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val charging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
            store.insert(ts, "battery", null, "$level:$scale:$tempC:${if (charging) 1 else 0}")

            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val net = cm.activeNetwork
            val caps = if (net != null) cm.getNetworkCapabilities(net) else null
            val type: String
            if (caps == null) {
                type = "none"
            } else if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                type = "wifi"
            } else if (caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                type = "mobile"
            } else {
                type = "other"
            }
            if (type != lastNetwork) {
                store.insert(ts, "network", null, type)
                lastNetwork = type
            }
        } catch (_: Exception) {}
    }

    companion object {
        fun start(context: Context) {
            try {
                val intent = Intent(context, DeviceMonitorService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Exception) {}
        }

        fun stop(context: Context) {
            try { context.stopService(Intent(context, DeviceMonitorService::class.java)) } catch (_: Exception) {}
        }
    }
}
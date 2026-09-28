package com.lifeos.lifeos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager

private fun batterySnapshot(c: Context): String? {
    return try {
        val i = c.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return null
        val level = i.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = i.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
        val tempC = (i.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0)
        val status = i.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        "$level:$scale:$tempC:${if (charging) 1 else 0}"
    } catch (_: Exception) { null }
}

class LifeOSReceivers {

    class Power : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val store = EventStore.get(context)
            val ts = System.currentTimeMillis()
            when (intent.action) {
                Intent.ACTION_POWER_CONNECTED -> {
                    store.insert(ts, "charge_on")
                    batterySnapshot(context)?.let { store.insert(ts, "battery", null, it) }
                }
                Intent.ACTION_POWER_DISCONNECTED -> {
                    batterySnapshot(context)?.let { store.insert(ts, "battery", null, it) }
                    store.insert(ts, "charge_off")
                }
            }
        }
    }

    class Screen : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val ts = System.currentTimeMillis()
            when (intent.action) {
                Intent.ACTION_SCREEN_ON -> EventStore.get(context).insert(ts, "screen_on")
                Intent.ACTION_SCREEN_OFF -> EventStore.get(context).insert(ts, "screen_off")
                Intent.ACTION_USER_PRESENT -> EventStore.get(context).insert(ts, "unlock")
            }
        }
    }

    class Boot : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
                EventStore.get(context).insert(System.currentTimeMillis(), "boot")
                DeviceMonitorService.start(context)
            }
        }
    }
}
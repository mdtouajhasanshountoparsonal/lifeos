package com.lifeos.lifeos

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotifListenerService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        EventStore.get(this).insert(System.currentTimeMillis(), "notif_connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val ticker = sbn.notification.tickerText?.toString() ?: ""
            EventStore.get(this).insert(
                sbn.postTime,
                "notif",
                sbn.packageName,
                ticker.take(120)
            )
        } catch (_: Exception) {}
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        try {
            EventStore.get(this).insert(sbn.postTime, "notif_removed", sbn.packageName, null)
        } catch (_: Exception) {}
    }
}
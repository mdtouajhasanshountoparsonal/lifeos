package com.lifeos.lifeos

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

object LockStateHolder {
    val unlockUntil = mutableMapOf<String, Long>()
}

class AppLockService : AccessibilityService() {

    private var lastPkg = ""

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == "com.lifeos.lifeos") return
        if (pkg == lastPkg) return
        lastPkg = pkg

        try {
            val cfg = EventStore.get(this).lockConfig(pkg) ?: return
            val now = System.currentTimeMillis()
            if (LockStateHolder.unlockUntil[pkg] ?: 0L > now) return
            val i = Intent(this, LockActivity::class.java)
            i.putExtra("pkg", pkg)
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            startActivity(i)
        } catch (_: Exception) {}
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        LockStateHolder.unlockUntil.clear()
    }
}
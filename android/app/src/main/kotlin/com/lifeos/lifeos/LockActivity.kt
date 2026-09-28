package com.lifeos.lifeos

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.security.MessageDigest

class LockActivity : Activity() {

    private var pkg: String = ""
    private val entered = StringBuilder()
    private var blocked = false
    private lateinit var dots: List<TextView>
    private lateinit var errorText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pkg = intent.getStringExtra("pkg") ?: ""
        if (pkg.isEmpty()) { finish(); return }
        val cfg = EventStore.get(this).lockConfig(pkg)
        if (cfg == null) { finish(); return }
        buildUi(cfg)
    }

    private fun buildUi(cfg: Map<String, Any?>) {
        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.argb(250, 7, 7, 14))
        }

        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(48), dp(24), dp(40))
        }
        root.addView(column, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
        ))

        try {
            val icon = ImageView(this).apply { setImageDrawable(packageManager.getApplicationIcon(pkg)) }
            column.addView(icon, dp(84), dp(84))
        } catch (_: Exception) {}

        column.addView(TextView(this).apply {
            text = appLabel(pkg)
            setTextColor(Color.WHITE)
            textSize = 20f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(14)
        })

        column.addView(TextView(this).apply {
            text = "Locked by LifeOS"
            setTextColor(Color.parseColor("#8A94A6"))
            textSize = 13f
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(4)
        })

        val dotRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        column.addView(dotRow, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(30)
        })
        dots = List(4) {
            TextView(this).apply { background = circle(Color.parseColor("#1E2733"), dp(14)) }
        }
        dots.forEach { d ->
            dotRow.addView(d, LinearLayout.LayoutParams(dp(14), dp(14)).apply {
                marginStart = dp(8); marginEnd = dp(8)
            })
        }

        errorText = TextView(this).apply {
            text = ""
            setTextColor(Color.parseColor("#FF6680"))
            textSize = 13f
            gravity = Gravity.CENTER
        }
        column.addView(errorText, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(14)
        })

        val grid = GridLayout(this).apply { columnCount = 3 }
        column.addView(grid, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(336)).apply {
            topMargin = dp(20)
        })

        val keys = listOf("1","2","3","4","5","6","7","8","9","","0","⌫")
        keys.forEachIndexed { idx, label ->
            val cell: View = if (label.isEmpty()) {
                View(this)
            } else {
                keyButton(label) { if (!blocked) onDigit(label) }
            }
            val params = GridLayout.LayoutParams().apply {
                rowSpec = GridLayout.spec(idx / 3)
                columnSpec = GridLayout.spec(idx % 3)
                width = dp(118)
                height = dp(70)
                marginStart = dp(4); marginEnd = dp(4); topMargin = dp(4); bottomMargin = dp(4)
            }
            grid.addView(cell, params)
            if (cell is TextView && label.isNotEmpty()) (cell as TextView).isEnabled = true
        }

        setContentView(root)

        val fails = EventStore.get(this).failedAttempts(pkg)
        if (fails >= 4) beginBlock()
    }

    private fun onDigit(n: String) {
        when (n) {
            "⌫" -> { if (entered.isNotEmpty()) entered.deleteCharAt(entered.length - 1) }
            "0","1","2","3","4","5","6","7","8","9" -> {
                if (entered.length < 4) entered.append(n)
            }
        }
        renderDots()
        if (entered.length == 4) verify()
    }

    private fun verify() {
        val store = EventStore.get(this)
        val hash = store.lockConfig(pkg)?.get("pin_hash") as? String
        if (hash == null) { finish(); return }
        if (sha256("lifeos::$entered") == hash) {
            store.addAttempt(pkg, System.currentTimeMillis(), true)
            val smart = (store.lockConfig(pkg)?.get("smart_minutes") as? Int) ?: 0
            val win = if (smart <= 0) 1 else smart
            LockStateHolder.unlockUntil[pkg] = System.currentTimeMillis() + (win * 60000L)
            store.markUnlock(pkg, System.currentTimeMillis())
            store.clearAttempts(pkg)
            finish()
        } else {
            store.addAttempt(pkg, System.currentTimeMillis(), false)
            entered.setLength(0)
            renderDots()
            errorText.text = "ভুল PIN — আবার চেষ্টা করুন"
            if (store.failedAttempts(pkg) >= 4) beginBlock()
        }
    }

    private fun beginBlock() {
        blocked = true
        errorText.text = "অনেকবার ভুল হয়েছে। ৩০ সেকেন্ড পরে চেষ্টা করুন।"
        Handler(Looper.getMainLooper()).postDelayed({
            blocked = false
            errorText.text = ""
            EventStore.get(this).clearAttempts(pkg)
        }, 30000L)
    }

    private fun renderDots() {
        dots.forEachIndexed { i, dot ->
            dot.background = circle(
                if (i < entered.length) Color.parseColor("#7C5CFF") else Color.parseColor("#1E2733"),
                dp(14)
            )
        }
    }

    private fun keyButton(label: String, onClick: () -> Unit): TextView =
        TextView(this).apply {
            text = label
            textSize = 24f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            background = rounded(Color.parseColor("#131B28"), dp(20))
            setOnClickListener { onClick() }
        }

    private fun circle(color: Int, sizePx: Int): GradientDrawable =
        GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(color); setSize(sizePx, sizePx) }

    private fun rounded(color: Int, radiusPx: Int): GradientDrawable =
        GradientDrawable().apply { setColor(color); cornerRadius = radiusPx.toFloat() }

    private fun appLabel(p: String): String {
        return try {
            val info = packageManager.getApplicationInfo(p, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (_: Exception) { p }
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun sha256(s: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(s.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }

    override fun onBackPressed() {
        // locked: back cannot escape
    }
}
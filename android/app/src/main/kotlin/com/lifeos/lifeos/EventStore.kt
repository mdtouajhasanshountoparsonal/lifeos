package com.lifeos.lifeos

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class EventStore private constructor(ctx: Context) :
    SQLiteOpenHelper(ctx.applicationContext, "device_events.db", null, 1) {

    companion object {
        @Volatile private var inst: EventStore? = null
        fun get(ctx: Context): EventStore = inst ?: synchronized(this) {
            inst ?: EventStore(ctx.applicationContext).also { inst = it }
        }
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS events(" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "ts INTEGER NOT NULL, " +
                "type TEXT NOT NULL, " +
                "pkg TEXT, " +
                "extra TEXT)"
        )
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts)")
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS app_lock(" +
                "pkg TEXT PRIMARY KEY, " +
                "pin_hash TEXT NOT NULL, " +
                "smart_minutes INTEGER NOT NULL DEFAULT 0)"
        )
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS unlocks(" +
                "pkg TEXT PRIMARY KEY, " +
                "last_ts INTEGER NOT NULL)"
        )
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS attempts(" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "pkg TEXT NOT NULL, " +
                "ts INTEGER NOT NULL, " +
                "ok INTEGER NOT NULL)"
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {}

    fun insert(ts: Long, type: String, pkg: String? = null, extra: String? = null) {
        try {
            val cv = ContentValues().apply {
                put("ts", ts)
                put("type", type)
                put("pkg", pkg)
                put("extra", extra)
            }
            writableDatabase.insert("events", null, cv)
        } catch (_: Exception) {}
    }

    fun query(from: Long, to: Long): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        try {
            val c = readableDatabase.rawQuery(
                "SELECT id, ts, type, pkg, extra FROM events WHERE ts >= ? AND ts <= ? ORDER BY ts",
                arrayOf(from.toString(), to.toString())
            )
            while (c.moveToNext()) {
                out.add(
                    mapOf(
                        "id" to c.getLong(0),
                        "ts" to c.getLong(1),
                        "type" to c.getString(2),
                        "pkg" to c.getString(3),
                        "extra" to c.getString(4)
                    )
                )
            }
            c.close()
        } catch (_: Exception) {}
        return out
    }

    fun clearBefore(ts: Long) {
        try { writableDatabase.delete("events", "ts < ?", arrayOf(ts.toString())) } catch (_: Exception) {}
    }

    fun clearAllEvents() {
        try { writableDatabase.delete("events", null, null) } catch (_: Exception) {}
    }

    fun setLock(pkg: String, pinHash: String, smartMinutes: Int) {
        try {
            val cv = ContentValues().apply {
                put("pkg", pkg)
                put("pin_hash", pinHash)
                put("smart_minutes", smartMinutes)
            }
            writableDatabase.insertWithOnConflict("app_lock", null, cv, SQLiteDatabase.CONFLICT_REPLACE)
        } catch (_: Exception) {}
    }

    fun removeLock(pkg: String) {
        try { writableDatabase.delete("app_lock", "pkg = ?", arrayOf(pkg)) } catch (_: Exception) {}
    }

    fun lockConfig(pkg: String): Map<String, Any?>? {
        try {
            val c = readableDatabase.rawQuery(
                "SELECT pin_hash, smart_minutes FROM app_lock WHERE pkg = ?",
                arrayOf(pkg)
            )
            if (c.moveToFirst()) {
                val m = mapOf("pin_hash" to c.getString(0), "smart_minutes" to c.getInt(1))
                c.close()
                return m
            }
            c.close()
        } catch (_: Exception) {}
        return null
    }

    fun lockedPackages(): List<String> {
        val out = mutableListOf<String>()
        try {
            val c = readableDatabase.rawQuery("SELECT pkg FROM app_lock", null)
            while (c.moveToNext()) out.add(c.getString(0))
            c.close()
        } catch (_: Exception) {}
        return out
    }

    fun markUnlock(pkg: String, ts: Long) {
        try {
            val cv = ContentValues().apply { put("pkg", pkg); put("last_ts", ts) }
            writableDatabase.insertWithOnConflict("unlocks", null, cv, SQLiteDatabase.CONFLICT_REPLACE)
        } catch (_: Exception) {}
    }

    fun lastUnlock(pkg: String): Long {
        try {
            val c = readableDatabase.rawQuery("SELECT last_ts FROM unlocks WHERE pkg = ?", arrayOf(pkg))
            if (c.moveToFirst()) {
                val v = c.getLong(0)
                c.close()
                return v
            }
            c.close()
        } catch (_: Exception) {}
        return 0L
    }

    fun addAttempt(pkg: String, ts: Long, ok: Boolean) {
        try {
            val cv = ContentValues().apply {
                put("pkg", pkg); put("ts", ts); put("ok", if (ok) 1 else 0)
            }
            writableDatabase.insert("attempts", null, cv)
        } catch (_: Exception) {}
    }

    fun failedAttempts(pkg: String): Int {
        try {
            val c = readableDatabase.rawQuery(
                "SELECT COUNT(*) FROM attempts WHERE pkg = ? AND ok = 0",
                arrayOf(pkg)
            )
            if (c.moveToFirst()) {
                val v = c.getInt(0)
                c.close()
                return v
            }
            c.close()
        } catch (_: Exception) {}
        return 0
    }

    fun clearAttempts(pkg: String) {
        try { writableDatabase.delete("attempts", "pkg = ?", arrayOf(pkg)) } catch (_: Exception) {}
    }
}
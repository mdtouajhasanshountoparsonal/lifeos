package com.lifeos.lifeos

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "lifeos/shared_inbox"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppHolder.activity = this
        DeviceApi.install(flutterEngine)
        NoteMedia.install(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pollSharedItem" -> {
                        result.success(pollSharedItem())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent)
    }

    private fun pollSharedItem(): Map<String, Any?>? {
        if (pendingText.isNotEmpty()) {
            val text = pendingText.removeAt(0)
            return mapOf("type" to "text", "text" to text)
        }
        if (pendingImagePaths.isNotEmpty()) {
            val path = pendingImagePaths.removeAt(0)
            return mapOf("type" to "image", "path" to path)
        }
        return null
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        DeviceMonitorService.start(this)
        handleShareIntent(intent)
    }

    private val pendingText = mutableListOf<String>()
    private val pendingImagePaths = mutableListOf<String>()

    private fun handleShareIntent(intent: Intent?) {
        if (intent == null) return
        when (intent.action) {
            Intent.ACTION_SEND -> {
                val type = intent.type
                if (type == "text/plain") {
                    intent.getStringExtra(Intent.EXTRA_TEXT)?.let { text ->
                        if (text.isNotBlank()) pendingText.add(text)
                    }
                } else {
                    getStreamUri(intent)?.let { uri ->
                        copyStreamToCache(uri)?.let { pendingImagePaths.add(it) }
                    }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val extras = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                extras?.forEach { uri ->
                    copyStreamToCache(uri)?.let { pendingImagePaths.add(it) }
                }
            }
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri -> copyStreamToCache(uri)?.let { pendingImagePaths.add(it) } }
            }
        }
    }

    private fun getStreamUri(intent: Intent): Uri? {
        return intent.getParcelableExtra(Intent.EXTRA_STREAM)
    }

    private fun copyStreamToCache(uri: Uri): String? {
        return try {
            val name = "shared_${System.currentTimeMillis()}.jpg"
            val outFile = File(cacheDir, name)
            contentResolver.openInputStream(uri)?.use { input ->
                outFile.outputStream().use { output -> input.copyTo(output) }
            }
            outFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
package com.lifeos.lifeos

import android.content.ActivityNotFoundException
import android.content.Intent
import android.media.MediaPlayer
import android.media.MediaRecorder
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

object NoteMedia {

    private var recorder: MediaRecorder? = null
    private var player: MediaPlayer? = null
    private var recordingPath: String? = null

    fun install(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "lifeos/notes")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startRecording" -> result.success(startRecording())
                    "stopRecording" -> result.success(stopRecording())
                    "playAudio" -> result.success(playAudio(call.arguments as? String))
                    "stopAudio" -> {
                        stopAudio()
                        result.success(true)
                    }
                    "openMedia" -> openMedia(call.arguments as? String, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun mediaDir(): File {
        return File(AppHolder.activity.filesDir, "lifeos_media").apply { mkdirs() }
    }

    private fun startRecording(): Boolean {
        if (recorder != null) return false
        val f = File(mediaDir(), "rec_${System.currentTimeMillis()}.m4a")
        val r = MediaRecorder()
        r.setAudioSource(MediaRecorder.AudioSource.MIC)
        r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        r.setAudioEncodingBitRate(96000)
        r.setAudioSamplingRate(44100)
        r.setOutputFile(f.absolutePath)
        return try {
            r.prepare()
            r.start()
            recordingPath = f.absolutePath
            recorder = r
            true
        } catch (e: Exception) {
            try { r.release() } catch (_: Exception) {}
            false
        }
    }

    private fun stopRecording(): String? {
        val r = recorder ?: return recordingPath
        val p = recordingPath
        return try {
            r.stop()
            r.release()
            recorder = null
            recordingPath = null
            p
        } catch (e: Exception) {
            try { r.release() } catch (_: Exception) {}
            recorder = null
            recordingPath = null
            p
        }
    }

    private fun playAudio(path: String?): Boolean {
        stopAudio()
        if (path == null || !File(path).exists()) return false
        val p = MediaPlayer()
        return try {
            p.setDataSource(path)
            p.setOnCompletionListener { mp ->
                mp.release()
                if (player === mp) player = null
            }
            p.prepare()
            p.start()
            player = p
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun stopAudio(): Boolean {
        player?.let { p ->
            try {
                if (p.isPlaying) p.stop()
            } catch (_: Exception) {}
            try {
                p.release()
            } catch (_: Exception) {}
        }
        player = null
        return true
    }

    private fun openMedia(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.success(false)
            return
        }
        val f = File(path)
        if (!f.exists()) {
            result.success(false)
            return
        }
        val mime = when {
            Regex("(?i).*\\.(mp4|mkv|3gp|mov|webm|avi)$").matches(path) -> "video/*"
            Regex("(?i).*\\.(m4a|mp3|aac|wav|amr|ogg)$").matches(path) -> "audio/*"
            else -> "image/*"
        }
        if (mime == "audio/*") {
            result.success(playAudio(path))
            return
        }
        val uri = FileProvider.getUriForFile(AppHolder.activity, "com.lifeos.lifeos.fileprovider", f)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        result.success(
            try {
                AppHolder.activity.startActivity(intent)
                true
            } catch (e: ActivityNotFoundException) {
                false
            }
        )
    }
}
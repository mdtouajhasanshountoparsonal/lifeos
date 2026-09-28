import 'package:flutter/services.dart';

/// Native helpers for note media: voice recording, audio playback and
/// opening attached files with the system viewer.
class NotesMedia {
  static const MethodChannel _channel = MethodChannel('lifeos/notes');

  static Future<bool> startRecording() async {
    try {
      return await _channel.invokeMethod<bool>('startRecording') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final v = await _channel.invokeMethod<dynamic>('stopRecording');
      return v as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> playAudio(String? path) async {
    try {
      return await _channel.invokeMethod<bool>('playAudio', path) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopAudio() async {
    try {
      return await _channel.invokeMethod<bool>('stopAudio') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openMedia(String path) async {
    try {
      return await _channel.invokeMethod<bool>('openMedia', path) ?? false;
    } catch (_) {
      return false;
    }
  }
}
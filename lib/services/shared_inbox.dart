import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inbox_item.dart';
import 'detect_text.dart';

/// Shared (Chrome/YouTube/নোট → Share → LifeOS) intake।
///
/// অ্যাপ শুরু থেকেই [startMonitoring] ডাকে — যাতে ইউজার "কপি/share" করলেই
/// স্ক্রিন খোলা না থাকলেও content জমা হয়:
///   - text → Smart Clipboard ('clipboard' box)
///   - image → Screenshot Inbox ('inbox' box)
class SharedInbox {
  SharedInbox._();

  static const MethodChannel _channel = MethodChannel('lifeos/shared_inbox');
  static Timer? _timer;
  static bool _busy = false;

  static void startMonitoring() {
    if (_timer != null) return;
    drain();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => drain());
  }

  /// Returns the next queued share (text or image file path) or null.
  static Future<Map<String, dynamic>?> poll() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('pollSharedItem');
      if (raw is! Map) return null;
      return {
        for (final e in raw.entries) '${e.key}': e.value,
      };
    } catch (_) {
      return null;
    }
  }

  /// সব pending শেয়ার টেনে যথাস্থানে জমা দেয়। concurrency-safe।
  static Future<void> drain() async {
    if (_busy) return;
    _busy = true;
    try {
      await _captureClipboard();
      while (true) {
        final share = await poll();
        if (share == null) break;
        final now = DateTime.now();
        if (share['type'] == 'text') {
          final text = (share['text'] as String? ?? '').trim();
          if (text.isEmpty) continue;
          Hive.box('clipboard').add({
            'id': now.millisecondsSinceEpoch.toString(),
            'text': text,
            'type': TextInsight.typeOf(text),
            'at': now.toIso8601String(),
            'sensitive': TextInsight.isSensitive(text),
            'starred': false,
          });
        } else if (share['type'] == 'image' && share['path'] != null) {
          if (Hive.isBoxOpen('inbox')) {
            Hive.box<InboxItem>('inbox').add(InboxItem(
              id: now.millisecondsSinceEpoch.toString(),
              path: share['path'] as String?,
              receivedAt: now,
            ));
          }
        }
      }
    } finally {
      _busy = false;
    }
  }

  /// সিস্টেম clipboard থেকে কপি করা লেখা auto-collect:
  /// অন্য অ্যাপে কপি → LifeOS (এই সেকেন্ডে) → Smart Clipboard-এ জমা।
  /// ডুপ্লিকেট / একই লেখা বারবার যোগ হওয়া থেকে বাঁচায় ('last_clipboard_text')।
  static Future<void> _captureClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final t = data?.text?.trim();
      if (t == null || t.isEmpty) return;
      final settings = Hive.box('settings');
      if (!Hive.isBoxOpen('clipboard')) return;
      if (settings.get('last_clipboard_text') == t) return;
      settings.put('last_clipboard_text', t);
      final clip = Hive.box('clipboard');
      final exists = clip.values.any((x) => x is Map && x['text'] == t);
      if (exists) return;
      final now = DateTime.now();
      clip.add({
        'id': now.millisecondsSinceEpoch.toString(),
        'text': t,
        'type': TextInsight.typeOf(t),
        'at': now.toIso8601String(),
        'sensitive': TextInsight.isSensitive(t),
        'starred': false,
      });
    } catch (_) {}
  }
}
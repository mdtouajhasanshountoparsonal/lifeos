import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// ইসলামিক কনটেন্ট রিপোতে ঢুকছে না — সব JSON অ্যাপের বাইরে।
/// GitHub raw থেকে manifest + ফাইল ডাউনলোড → strict-JSON validate → Hive-তে ক্যাশ।
/// প্রথম সিঙ্কের পর সম্পূর্ণ offline; update চাইলে `sync(force: true)`।
class ContentRepoState {
  final String phase; // 'idle' | 'downloading' | 'ready' | 'error'
  final int done;
  final int total;
  final String? error;

  const ContentRepoState({
    this.phase = 'idle',
    this.done = 0,
    this.total = 0,
    this.error,
  });

  bool get ready => phase == 'ready';
  bool get busy => phase == 'downloading';
}

class ContentFile {
  final String path;
  final String kind;
  final int version;
  final int count;
  final String source;

  const ContentFile({
    required this.path,
    required this.kind,
    required this.version,
    required this.count,
    required this.source,
  });

  factory ContentFile.fromMap(Map<String, dynamic> m) => ContentFile(
    path: (m['path'] as String? ?? '').trim(),
    kind: (m['kind'] as String? ?? '').trim(),
    version: ((m['version'] as num?) ?? 0).toInt(),
    count: ((m['count'] as num?) ?? 0).toInt(),
    source: (m['source'] as String? ?? '').trim(),
  );
}

class ContentRepository {
  ContentRepository._();

  /// কনটেন্ট রিপো — public GitHub, raw ডাউনলোড।
  static const repoBase =
      'https://raw.githubusercontent.com/mdtouajhasanshountoparsonal/islamic_data/main/';

  static const _metaBox = 'content_meta';
  static const _dataBox = 'content_data';

  /// হেড-লেস UI (ডাউনলোড-গেট) জন্য state।
  static final state = ValueNotifier<ContentRepoState>(
    const ContentRepoState(),
  );

  static List<ContentFile>? _manifest;
  static bool? _ready;

  /// কনটেন্ট নামানো হয়েছে কিনা (আগে sync সফল হয়েছে)।
  static bool get isReady => _ready == true;

  /// রিপো ফাইল তালিকা (manifest.json থেকে)।
  static Future<List<ContentFile>> manifest() async {
    if (_manifest != null) return _manifest!;
    final data = await loadMap('manifest.json');
    final list = <ContentFile>[];
    for (final f in (data?['files'] as List? ?? const [])) {
      list.add(ContentFile.fromMap(f as Map<String, dynamic>));
    }
    _manifest = list;
    return list;
  }

  /// একটি ফাইলের JSON → Map। না থাকলে null (ডাউনলোড হয়নি)।
  static Future<Map<String, dynamic>?> loadMap(String key) async {
    final box = Hive.isBoxOpen(_dataBox)
        ? Hive.box(_dataBox)
        : await Hive.openBox(_dataBox);
    final raw = box.get(key) as String?;
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// কনটেন্ট ready কিনা — না হলে প্রথমবার (বা force চাইলে) ডাউনলোড।
  /// নেট না থাকলে ContentNotReady খায় → UI রিট্রাই বোতাম দেখায়।
  static Future<void> ensureReady({bool force = false}) async {
    if (_ready == true && !force) return;
    final ok = await _sync(force: force);
    if (!ok) {
      throw const ContentNotReady();
    }
  }

  static Future<bool> _sync({required bool force}) async {
    final metaBox = Hive.isBoxOpen(_metaBox)
        ? Hive.box(_metaBox)
        : await Hive.openBox(_metaBox);
    final dataBox = Hive.isBoxOpen(_dataBox)
        ? Hive.box(_dataBox)
        : await Hive.openBox(_dataBox);

    // ইতিমধ্যে নামানো হয়েছে এবং force নয় → skip।
    if (!force && metaBox.get('ready') == true) {
      _ready = true;
      state.value = const ContentRepoState(phase: 'ready');
      return true;
    }

    state.value = const ContentRepoState(
      phase: 'downloading',
      done: 0,
      total: 0,
    );
    try {
      final manifestRaw = await _fetch('manifest.json');
      final manifestJson = _strictDecode(manifestRaw, 'manifest.json');
      final files = [
        for (final f in (manifestJson['files'] as List? ?? const []))
          ContentFile.fromMap(f as Map<String, dynamic>),
      ];

      if (files.isEmpty) {
        throw const FormatException('manifest.json-এ কোনো ফাইল নেই');
      }
      _manifest = files;

      state.value = ContentRepoState(
        phase: 'downloading',
        done: 0,
        total: files.length,
      );
      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        // meta-তে রাখা ভার্সন মিলে গেলে আবার নামাতে হয় না (force ছাড়া)।
        final cachedVersion = force
            ? 0
            : (metaBox.get('v:${f.path}') as num?)?.toInt() ?? 0;
        if (cachedVersion >= f.version && dataBox.get(f.path) != null) {
          state.value = ContentRepoState(
            phase: 'downloading',
            done: i + 1,
            total: files.length,
          );
          continue;
        }
        final raw = await _fetch(f.path);
        _strictDecode(raw, f.path); // validate — খারাপ হলে throw
        await dataBox.put(f.path, raw);
        await metaBox.put('v:${f.path}', f.version);
        state.value = ContentRepoState(
          phase: 'downloading',
          done: i + 1,
          total: files.length,
        );
      }
      await dataBox.put('manifest.json', manifestRaw);
      await metaBox.putAll({
        'ready': true,
        'downloadedAt': DateTime.now().toIso8601String(),
        'bundleVersion': manifestJson['bundleVersion'] ?? 1,
      });
      _ready = true;
      state.value = const ContentRepoState(phase: 'ready');
      return true;
    } on SocketException catch (e) {
      state.value = ContentRepoState(
        phase: 'error',
        error: 'ইন্টারনেট নেই — কনটেন্ট নামাতে সংযোগ লাগবে। (${e.message})',
      );
      return false;
    } on HttpException catch (e) {
      state.value = ContentRepoState(
        phase: 'error',
        error:
            'রিপো থেকে ফাইল পাওয়া যায়নি (${e.message})।\nরিপো public GitHub-এ তৈরি হয়েছে কিনা দেখুন।',
      );
      return false;
    } catch (e) {
      state.value = ContentRepoState(
        phase: 'error',
        error: 'কনটেন্ট নামা ব্যর্থ: $e',
      );
      return false;
    }
  }

  static Map<String, dynamic> _strictDecode(String raw, String path) {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw FormatException('$path: JSON top-level object নয়');
    }
    return data;
  }

  static Future<String> _fetch(String path) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final encoded = path.split('/').map(Uri.encodeComponent).join('/');
      final uri = Uri.parse('$repoBase$encoded');
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('$path → HTTP ${res.statusCode}');
      }
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}

class ContentNotReady implements Exception {
  const ContentNotReady();
  @override
  String toString() => 'ContentNotReady';
}

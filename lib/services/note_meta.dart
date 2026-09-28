import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/services/hash.dart';

/// Extended per-note metadata (tags, connections, private flag, versions,
/// vault PIN) kept outside the typed `Note` model so no Hive codegen is needed.
class NoteMeta {
  NoteMeta._();

  static Box<dynamic> get _meta => Hive.box('note_meta');
  static Box<dynamic> get _versions => Hive.box('notes_versions');

  static Map<String, dynamic> _read(String id) {
    final v = _meta.get(id);
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  static void _write(String id, Map<String, dynamic> m) => _meta.put(id, m);

  static List<String> getTags(String id) => List<String>.from(_read(id)['tags'] ?? const []);
  static void setTags(String id, List<String> tags) {
    final m = _read(id)..['tags'] = tags.toSet().toList();
    _write(id, m);
  }

  static List<String> getLinks(String id) => List<String>.from(_read(id)['links'] ?? const []);
  static void setLinks(String id, List<String> links) {
    final m = _read(id)..['links'] = links.toSet().toList();
    _write(id, m);
  }

  static void addLink(String id, String otherId) {
    final links = getLinks(id);
    if (!links.contains(otherId)) setLinks(id, [...links, otherId]);
  }

  /// Scans the content for `@Title` mentions and links/pings every matching
  /// note. Returns the resulting link ids (including any resolved mentions).
  static List<String> scanMentions(String id, String content) {
    final notes = Hive.box<Note>('notes');
    final mentions = RegExp(r'@([^\s@#]+)').allMatches(content);
    final resolved = <String>[];
    for (final m in mentions) {
      final title = m.group(1)!.trim();
      for (final n in notes.values) {
        if (n.id == id) continue;
        if (n.title.toLowerCase() == title.toLowerCase() && !resolved.contains(n.id)) {
          resolved.add(n.id);
        }
      }
    }
    if (resolved.isNotEmpty) {
      setLinks(id, {...getLinks(id), ...resolved}.toList());
      for (final r in resolved) {
        addLink(r, id); // backlink
      }
    }
    return resolved;
  }

  static bool isPrivate(String id) => _read(id)['private'] == true;
  static void setPrivate(String id, bool v) {
    final m = _read(id)..['private'] = v;
    _write(id, m);
  }

  static bool get hasPin => _read('_vault')['pin'] != null;
  static bool verifyPin(String input) => _read('_vault')['pin'] == Sha256.hashHex(input.trim());
  static void setPin(String pin) {
    final m = _read('_vault')..['pin'] = Sha256.hashHex(pin.trim());
    _write('_vault', m);
  }

  static List<Map<String, dynamic>> getVersions(String id) {
    final v = _versions.get(id);
    return v is List
        ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
  }

  /// Pushes the current note state onto its version stack (most recent first).
  static void pushVersion(Note note) {
    final list = getVersions(note.id);
    if (list.isNotEmpty && list.first['title'] == note.title && list.first['content'] == note.content) {
      return;
    }
    list.insert(
      0,
      {'title': note.title, 'content': note.content, 'at': DateTime.now().toIso8601String()},
    );
    _versions.put(note.id, list.take(30).toList());
  }

  /// Lists cross-note connections from the whole meta box.
  static List<Map<String, dynamic>> allConnections() {
    final out = <Map<String, dynamic>>[];
    _meta.toMap().forEach((id, v) {
      if (v is! Map) return;
      final links = (v['links'] as List?)?.cast<String>() ?? const [];
      for (final other in links) {
        out.add({'a': id, 'b': other});
      }
    });
    return out;
  }
}
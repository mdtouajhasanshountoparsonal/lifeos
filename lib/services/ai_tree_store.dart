import 'package:hive_flutter/hive_flutter.dart';
import 'tree_text_parser.dart';

/// সংরক্ষিত AI গাছ — মূল লেখা কখনো বদলানো হয় না, গাছটা আলাদা করে
/// 'ai_trees' box-এ জমা থাকে। Notes → 'n_<id>', Tasks → 't_<id>'.
///
/// এতে লিস্ট-ভিউতে emoji-সহ গাছ দেখানো যায়, আর পরে ব্যবহারকারী
/// নিজের আসল লেখা এডিট করে যেতে পারে।
class AiTreeStore {
  AiTreeStore._();

  static const _boxName = 'ai_trees';

  static Box _box() => Hive.box(_boxName);

  static String _key(String id, {required bool task}) =>
      '${task ? 't' : 'n'}_$id';

  static ({TreeBlueprint blueprint, String? source})? get(
    String id, {
    required bool task,
  }) {
    final v = _box().get(_key(id, task: task));
    if (v is! Map) return null;
    return (
      blueprint: TreeBlueprint.fromMap(v),
      source: v['source'] as String?,
    );
  }

  static void save(
    String id,
    TreeBlueprint b, {
    required bool task,
    String? source,
  }) {
    _box().put(
      _key(id, task: task),
      <String, dynamic>{...b.toMap(), if (source != null) 'source': source},
    );
  }

  static void remove(String id, {required bool task}) =>
      _box().delete(_key(id, task: task));

  // Clipboard আইটেমের গাছ — 'c_<id>'। Smart Clipboard-ও notes/tasks-এর মতো
  // নিজের AI গাছ মনে রাখে (স্ক্রিন ছেড়ে ফিরলেও থাকে)।
  static ({TreeBlueprint blueprint, String? source})? getClip(String id) {
    final v = _box().get('c_$id');
    if (v is! Map) return null;
    return (
      blueprint: TreeBlueprint.fromMap(v),
      source: v['source'] as String?,
    );
  }

  static void saveClip(String id, TreeBlueprint b, {String? source}) {
    _box().put(
      'c_$id',
      <String, dynamic>{...b.toMap(), if (source != null) 'source': source},
    );
  }

  static void removeClip(String id) => _box().delete('c_$id');
}
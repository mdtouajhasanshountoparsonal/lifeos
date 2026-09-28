import 'package:hive/hive.dart';

/// AiSettings — P5: online-AI চালু/বন্ধ + কোন provider (Gemini/GPT)।
/// Hive `settings` বক্সে সংরক্ষণ হয় (main-এ ইতিমধ্যে খোলা)।
class AiSettings {
  AiSettings._();

  static const _settingsBox = 'settings';
  static const _onlineKey = 'ai_online_enabled';
  static const _providerKey = 'ai_provider';

  static const gemini = 'gemini';
  static const openai = 'openai';

  static Box<dynamic>? _box;

  static Future<void> init() async {
    if (_box != null) return;
    try {
      _box = await Hive.openBox(_settingsBox);
    } catch (_) {
      _box = null;
    }
  }

  /// settings বক্স খোলা থাকলে পড়ে, না থাকলে null (টেস্ট/অস্বাভাবিক অবস্থায় নিরাপদ)।
  static Box<dynamic>? get _b {
    if (_box != null) return _box;
    try {
      _box = Hive.box(_settingsBox);
    } catch (_) {
      _box = null;
    }
    return _box;
  }

  /// online AI সদা চালু থাকুক কিনা (ডিফল্ট false — ব্যবহারকারীর সম্মতিতে)।
  static bool get onlineEnabled => _b?.get(_onlineKey) == true;

  static Future<void> setOnlineEnabled(bool v) async {
    final b = _b;
    if (b != null) await b.put(_onlineKey, v);
  }

  static String get provider => (_b?.get(_providerKey) as String?) ?? gemini;

  static Future<void> setProvider(String v) async {
    final b = _b;
    if (b != null) await b.put(_providerKey, v);
  }
}
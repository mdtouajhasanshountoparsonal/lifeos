import 'package:flutter_tts/flutter_tts.dart';

/// আরবি অক্ষরের জন্য Uthmani-স্টাইল ফন্ট (assets/fonts/Amiri-*.ttf)।
const kArabicFont = 'Amiri';

/// অক্ষর/শব্দের উচ্চারণ শোনানো (ডিভাইসে বাংলা TTS voice থাকলে)।
Future<void> speakPron(String text) async {
  try {
    final tts = FlutterTts();
    await tts.setLanguage('bn-BD');
    await tts.setSpeechRate(0.45);
    await tts.speak(text);
  } catch (_) {}
}

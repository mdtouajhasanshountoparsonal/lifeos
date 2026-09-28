import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OcrService {
  static Future<String> extractText(String imagePath) async {
    return FlutterTesseractOcr.extractText(
      imagePath,
      language: 'eng+ben',
      args: {
        'psm': '3',
        'preserve_interword_spaces': '1',
      },
    );
  }
}
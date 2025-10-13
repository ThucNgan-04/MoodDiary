import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  // Hàm dịch văn bản, có lưu cache để tiết kiệm API
  Future<String> translate(String text, String toLang) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'trans_${toLang}_$text';

    // Nếu có trong cache thì dùng luôn
    if (prefs.containsKey(cacheKey)) {
      return prefs.getString(cacheKey)!;
    }

    // Nếu chưa có thì dịch và lưu cache
    final translation = await _translator.translate(text, to: toLang);
    final translatedText = translation.text;

    await prefs.setString(cacheKey, translatedText);
    return translatedText;
  }
}



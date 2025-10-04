import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class TranslationProvider with ChangeNotifier {
  final _service = TranslationService();
  final Map<String, String> _cache = {};

  Future<void> preload(String text, String lang) async {
    final key = '$lang-$text';
    if (_cache.containsKey(key)) return;

    final translated = await _service.translate(text, lang);
    _cache[key] = translated;
    notifyListeners();
  }

  String getText(String text, String lang) {
    final key = '$lang-$text';
    return _cache[key] ?? text; //Nếu chưa d thì ->gốc
  }
}

import 'package:flutter/foundation.dart';
import '../l10n/translations.dart';

/// Service for managing the current language state
class LanguageService extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  List<String> get supportedLanguages => Translations.supportedLanguages;

  void setLanguage(String lang) {
    if (Translations.supportedLanguages.contains(lang) &&
        lang != _currentLanguage) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  /// Get a translation for the current language
  String translate(String key) {
    return Translations.get(key, _currentLanguage);
  }

  /// Get weekday name for current language
  String getWeekday(int day) {
    return Translations.getWeekday(day, _currentLanguage);
  }

  /// Get the flag asset path for a language
  String getFlagAsset(String lang) {
    return Translations.flagAssets[lang] ?? 'assets/images/flags/uk.png';
  }
}

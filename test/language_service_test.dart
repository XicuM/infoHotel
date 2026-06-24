import 'package:flutter_test/flutter_test.dart';
import 'package:info_hotel/services/language_service.dart';

void main() {
  group('LanguageService Tests', () {
    late LanguageService languageService;

    setUp(() {
      languageService = LanguageService();
    });

    test('Initial language should be English (en)', () {
      expect(languageService.currentLanguage, 'en');
    });

    test('Changing to supported language updates state', () {
      bool notified = false;
      languageService.addListener(() {
        notified = true;
      });

      languageService.setLanguage('es');
      
      expect(languageService.currentLanguage, 'es');
      expect(notified, isTrue);
    });

    test('Changing to unsupported language does nothing', () {
      bool notified = false;
      languageService.addListener(() {
        notified = true;
      });

      languageService.setLanguage('jp'); // Unsupported language
      
      expect(languageService.currentLanguage, 'en');
      expect(notified, isFalse);
    });

    test('Translations fallback gracefully', () {
      // Assuming 'home' is a key in Translations
      final translation = languageService.translate('home');
      expect(translation, isNotEmpty);
    });
  });
}

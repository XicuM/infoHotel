import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../l10n/translations.dart';
import '../widgets/app_image.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        final currentLang = langService.currentLanguage;
        final otherLanguages = Translations.supportedLanguages
            .where((lang) => lang != currentLang)
            .toList();

        return InkWell(
          onTap: () {
            showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                16,
                MediaQuery.of(context).size.height - 350,
                MediaQuery.of(context).size.width - 264,
                0,
              ),
              color: const Color(0xE0000000), // Semi-transparent black
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.white24),
              ),
              items: otherLanguages.map((lang) {
                return PopupMenuItem<String>(
                  value: lang,
                  child: Row(
                    children: [
                      AppImage(path: 
                        langService.getFlagAsset(lang),
                        width: 30,
                        height: 20,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Translations.languageNames[lang] ?? lang.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ).then((selectedLang) {
              if (selectedLang != null) {
                langService.setLanguage(selectedLang);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                AppImage(path: 
                  langService.getFlagAsset(currentLang),
                  width: 30,
                  height: 20,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Translations.languageNames[currentLang] ?? currentLang.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(
                  Icons.language,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

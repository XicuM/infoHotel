import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../l10n/translations.dart';
import '../widgets/app_image.dart';

/// Language selection bar with flag buttons
/// Ported from LanguageBar in Pygame prototype
class LanguageBar extends StatelessWidget {
  final Color? backgroundColor;
  final double height;

  const LanguageBar({
    super.key,
    this.backgroundColor,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return Container(
          height: height,
          color: backgroundColor ?? Colors.black.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: Translations.supportedLanguages.map((lang) {
              final isSelected = lang == langService.currentLanguage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () => langService.setLanguage(lang),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AppImage(path: 
                      langService.getFlagAsset(lang),
                      width: 48,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to text if flag image not found
                        return Container(
                          width: 48,
                          height: 32,
                          color: Colors.grey,
                          alignment: Alignment.center,
                          child: Text(
                            lang.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

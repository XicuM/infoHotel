import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../widgets/app_image.dart';
import '../config/app_config.dart';

/// Custom app bar — premium version with subtle gradient and polished styling
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleKey;
  final Color backgroundColor;
  final String? parentRoute;
  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color? titleColor;
  final String? logoPath;
  final bool isLogoLocal;

  const CustomAppBar({
    super.key,
    required this.titleKey,
    required this.backgroundColor,
    this.parentRoute,
    this.onHome,
    this.onBack,
    this.actions,
    this.titleColor,
    this.logoPath,
    this.isLogoLocal = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final lum = backgroundColor.computeLuminance();
    final isLight = lum > 0.5 || (titleColor != null && titleColor!.computeLuminance() < 0.5);
    final effectiveTitleColor = titleColor ?? (isLight ? Colors.black87 : Colors.white);
    final iconColor = isLight ? Colors.black54 : Colors.white70;

    // Derive a slightly darker shade for the gradient end
    final darkerBg = HSLColor.fromColor(backgroundColor)
        .withLightness((HSLColor.fromColor(backgroundColor).lightness * 0.78).clamp(0.0, 1.0))
        .toColor();

    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [backgroundColor, darkerBg],
            ),
            boxShadow: (backgroundColor.a > 0 && !AppConfig.lowPowerMode)
                ? [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SafeArea(
            child: Row(
              children: [
                // Back button — only show if there is a route to pop back to
                if ((parentRoute != null || onBack != null) && Navigator.of(context).canPop()) ...[
                  IconButton(
                    onPressed: onBack ?? () => Navigator.of(context).pop(),
                    iconSize: 32,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: AppImage(path: 
                      isLight ? 'assets/images/icons/back-dark.png' : 'assets/images/icons/back.png',
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.arrow_back, color: iconColor, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Company Logo
                if (logoPath != null) ...[
                  ClipOval(
                    child: Container(
                      color: Colors.white, // background for transparent logos
                      child: AppImage(
                        path: logoPath,
                        isLocal: isLogoLocal,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Title
                Expanded(
                  child: Text(
                    langService.translate(titleKey),
                    style: TextStyle(
                      color: effectiveTitleColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Actions
                if (actions != null) ...actions!,
              ],
            ),
          ),
        );
      },
    );
  }
}

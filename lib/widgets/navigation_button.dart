import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../config/app_config.dart';

/// Navigation button for the home screen — premium version with icon and hover effect
class NavigationButton extends StatefulWidget {
  final String titleKey;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  const NavigationButton({
    super.key,
    required this.titleKey,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  State<NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<NavigationButton> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        final isLight = widget.color.computeLuminance() > 0.5;
        final textColor = isLight ? Colors.black87 : Colors.white;
        final iconColor = isLight ? Colors.black54 : Colors.white70;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 420,
              height: 68,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppConfig.lowPowerMode
                    ? null
                    : [
                        BoxShadow(
                          color: widget.color.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: iconColor, size: 26),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    langService.translate(widget.titleKey),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'app_bar_widget.dart';

/// A generic layout for simple informational views, often used for transport
/// and services that display an icon, title, and body content within a centered card.
class GenericInfoModalView extends StatelessWidget {
  final String titleKey;
  final Color backgroundColor;
  final IconData headerIcon;
  final String headerTitle;
  final String? headerSubtitle;
  final Color? headerSubtitleColor;
  final Widget bodyContent;
  final BoxConstraints constraints;

  const GenericInfoModalView({
    super.key,
    required this.titleKey,
    required this.backgroundColor,
    required this.headerIcon,
    required this.headerTitle,
    this.headerSubtitle,
    this.headerSubtitleColor,
    required this.bodyContent,
    this.constraints = const BoxConstraints(maxWidth: 800, maxHeight: 700),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: titleKey,
        backgroundColor: backgroundColor,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: constraints,
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(headerIcon, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      headerTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (headerSubtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        headerSubtitle!,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: headerSubtitleColor ?? Colors.amberAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: bodyContent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

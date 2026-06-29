import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// A performance-optimized backdrop filter that bypasses expensive GPU blurs
/// on the Web platform (especially on low-spec kiosks like Pi 3B+) and uses
/// a solid overlay instead. Also bypasses blur when AppConfig.lowPowerMode is enabled.
class WebSafeBackdropFilter extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color overlayColor;

  const WebSafeBackdropFilter({
    super.key,
    required this.child,
    this.blur = 16.0,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || AppConfig.lowPowerMode) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: overlayColor,
        child: child,
      );
    }
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: overlayColor,
          child: child,
        ),
      ),
    );
  }
}

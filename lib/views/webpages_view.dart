import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../widgets/app_image.dart';

/// Modernized Webpages view showing QR codes for external websites
class WebpagesView extends StatelessWidget {
  const WebpagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'webpages',
        backgroundColor: AppColors.get('grey', 700),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.6),
            child: Column(
              children: [
                // Stylish Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      const Text(
                        'Scan to Visit',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // QR Content
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white, // Keep QR background white for scan readability
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: AppImage(
                          path: 'assets/images/webpages.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_2,
                                  size: 160,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'QR Codes Unavailable',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

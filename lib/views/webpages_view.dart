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
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stylish Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.get('grey', 800),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Scan to Visit',
                      style: TextStyle(
                        fontSize: 28,
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
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: AppImage(path: 
                    'assets/images/webpages.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
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
            ],
          ),
        ),
      ),
    );
  }
}

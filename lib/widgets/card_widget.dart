import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import 'app_image.dart';

/// Card widget — premium version with hover animations and glassmorphism label
class InfoCard extends StatefulWidget {
  final String? imagePath;
  final IconData? iconData;
  final String? titleKey;
  final String? title;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool isLocalImage;

  const InfoCard({
    super.key,
    this.imagePath,
    this.iconData,
    this.titleKey,
    this.title,
    this.onTap,
    this.width,
    this.height,
    this.isLocalImage = false,
  });

  @override
  State<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        final displayTitle =
            widget.titleKey != null ? langService.translate(widget.titleKey!) : widget.title ?? '';

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image / icon background
                      _buildBackground(),

                      // Gradient overlay
                      Opacity(
                        opacity: 0.85,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Color(0xCC000000),
                              ],
                              stops: [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Title at the bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Text(
                            displayTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildBackground() {
    if (widget.iconData != null) {
      return Container(
        color: const Color(0xFF2A2A2A),
        child: Center(
          child: Icon(
            widget.iconData,
            size: 56,
            color: Colors.white70,
          ),
        ),
      );
    }

    if (widget.imagePath != null) {
      return AppImage(
        path: widget.imagePath,
        isLocal: widget.isLocalImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF2A2A2A),
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 48, color: Colors.white38),
            ),
          );
        },
      );
    }

    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(child: Icon(Icons.image, size: 48, color: Colors.white38)),
    );
  }
}

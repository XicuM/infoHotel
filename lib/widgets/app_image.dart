import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/path_resolver.dart';
import '../config/app_config.dart';
import '../config/env.dart';

/// A unified widget for displaying asset or memory images with consistent error handling
/// and optional color filtering.
class AppImage extends StatelessWidget {
  final String? path;
  final Uint8List? bytes;
  final BoxFit fit;
  final ColorFilter? colorFilter;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final double? width;
  final double? height;
  final bool isLocal;
  final int? cacheWidth;
  final int? cacheHeight;

  const AppImage({
    super.key,
    this.path,
    this.bytes,
    this.fit = BoxFit.contain,
    this.colorFilter,
    this.errorBuilder,
    this.width,
    this.height,
    this.isLocal = false,
    this.cacheWidth,
    this.cacheHeight,
  }) : assert(path != null || bytes != null, 'Either path or bytes must be provided');

  @override
  Widget build(BuildContext context) {
    Widget image;

    int? finalCacheWidth = cacheWidth;
    int? finalCacheHeight = cacheHeight;

    if (AppConfig.lowPowerMode) {
      final mediaQuery = MediaQuery.maybeOf(context);
      final dpr = mediaQuery?.devicePixelRatio ?? 1.0;
      final screenWidth = mediaQuery?.size.width ?? 1280.0;
      final pathLower = path?.toLowerCase() ?? '';

      // Skip cache resizing for logos to preserve high quality
      if (!pathLower.contains('logo')) {
        if (finalCacheWidth == null && width != null && width! > 0 && width! != double.infinity) {
          finalCacheWidth = (width! * dpr).round();
        }
        if (finalCacheHeight == null && height != null && height! > 0 && height! != double.infinity) {
          finalCacheHeight = (height! * dpr).round();
        }

        // If we don't have explicit size constraints but we're in lowPowerMode, cap large images (like maps/backgrounds) to screen width
        if (finalCacheWidth == null && finalCacheHeight == null) {
          if (pathLower.contains('map') || 
              pathLower.contains('background') || 
              pathLower.contains('excursions') || 
              pathLower.contains('facilities') ||
              (bytes != null && bytes!.length > 100 * 1024)) {
            finalCacheWidth = (screenWidth * dpr).round().clamp(800, 1600);
          }
        }
      }
    }

    if (bytes != null) {
      image = Image.memory(
        bytes!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: finalCacheWidth,
        cacheHeight: finalCacheWidth == null ? finalCacheHeight : null,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) => _buildError(context),
      );
    } else if (path != null) {
      if (kIsWeb) {
        if (path!.startsWith('http')) {
          image = Image.network(
            path!,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: finalCacheWidth,
            cacheHeight: finalCacheWidth == null ? finalCacheHeight : null,
            errorBuilder: errorBuilder ?? (context, error, stackTrace) => _buildError(context),
          );
        } else if (path!.startsWith('hotel_assets/')) {
          // Dynamic assets must be loaded via network in Web because they aren't in the compiled AssetManifest
          final proxyUrl = Env.proxyBaseUrl;
          // Add a timestamp to bypass browser caching for newly uploaded images
          final cacheBuster = DateTime.now().millisecondsSinceEpoch;
          // IMPORTANT: encode the path so that strict webkit browsers do not reject URLs with spaces!
          final encodedPath = Uri.encodeFull(path!);
          final networkUrl = proxyUrl.isEmpty 
              ? '/$encodedPath?cb=$cacheBuster' 
              : '$proxyUrl/$encodedPath?cb=$cacheBuster';
          image = Image.network(
            networkUrl,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: finalCacheWidth,
            cacheHeight: finalCacheWidth == null ? finalCacheHeight : null,
            errorBuilder: errorBuilder ?? (context, error, stackTrace) => _buildError(context),
          );
        } else {
          image = Image.asset(
            path!,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: finalCacheWidth,
            cacheHeight: finalCacheWidth == null ? finalCacheHeight : null,
            errorBuilder: errorBuilder ?? (context, error, stackTrace) => _buildError(context),
          );
        }
      } else {
        // Force all path-based images to load from local file system
        final resolvedPath = PathResolver.resolve(path!);
        image = Image.file(
          File(resolvedPath),
          width: width,
          height: height,
          fit: fit,
          cacheWidth: finalCacheWidth,
          cacheHeight: finalCacheWidth == null ? finalCacheHeight : null,
          errorBuilder: errorBuilder ?? (context, error, stackTrace) => _buildError(context),
        );
      }
    } else {
      image = _buildError(context);
    }

    if (colorFilter != null) {
      image = ColorFiltered(
        colorFilter: colorFilter!,
        child: image,
      );
    }

    return image;
  }
  
  Widget _buildError(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../utils/path_resolver.dart';

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
  }) : assert(path != null || bytes != null, 'Either path or bytes must be provided');

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (bytes != null) {
      image = Image.memory(
        bytes!,
        width: width,
        height: height,
        fit: fit,
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
            errorBuilder: errorBuilder ?? (context, error, stackTrace) => _buildError(context),
          );
        } else {
          image = Image.asset(
            path!,
            width: width,
            height: height,
            fit: fit,
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

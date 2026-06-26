import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class PathResolver {
  static late String _basePath;
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    
    if (kIsWeb) {
      _basePath = '';
      _initialized = true;
      return;
    }

    // Check if we are running in debug from project root
    if (Directory(p.join(Directory.current.path, 'assets')).existsSync()) {
      _basePath = Directory.current.path;
    } else {
      // Fallback to executable directory
      _basePath = File(Platform.resolvedExecutable).parent.path;
    }
    _initialized = true;
  }

  static String resolve(String path) {
    if (!_initialized) init();
    if (kIsWeb) return path;
    if (path.startsWith('http')) return path;
    if (p.isAbsolute(path)) return path;
    
    // Check if it's already relative to our base path
    final absolutePath = p.join(_basePath, path);
    return absolutePath;
  }
}

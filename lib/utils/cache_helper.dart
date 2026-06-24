import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheHelper {
  static Future<File> _getCacheFile(String filename) async {
    final directory = await getApplicationCacheDirectory();
    final path = directory.path;
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('$path/$filename');
  }

  static Future<void> writeCache(String filename, String data) async {
    try {
      final file = await _getCacheFile(filename);
      await file.writeAsString(data);
    } catch (e) {
      print('Error writing cache to $filename: $e');
    }
  }

  static Future<String?> readCache(String filename) async {
    try {
      final file = await _getCacheFile(filename);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error reading cache from $filename: $e');
    }
    return null;
  }

  static Future<void> deleteCache(String filename) async {
    try {
      final file = await _getCacheFile(filename);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting cache $filename: $e');
    }
  }
}

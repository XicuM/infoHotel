import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/path_resolver.dart';

class StorageRepository {
  late Directory _dataDir;
  final bool _devMode = !kReleaseMode;

  Future<void> init() async {
    if (kIsWeb) return;

    if (AppConfig.skipHotelAssets) {
      _dataDir = Directory.systemTemp;
      return;
    }
    
    if (Platform.isWindows || Platform.isLinux) {
      try {
        final exeDir = File(Platform.resolvedExecutable).parent;
        final localDataDir = Directory(p.join(exeDir.path, 'hotel_assets', 'data'));
        
        if (await localDataDir.exists()) {
          _dataDir = localDataDir;
          debugPrint('Using local executable directory: ${_dataDir.path}');
          return;
        }
      } catch (e) {
        debugPrint('Error resolving executable path: $e');
      }
    }

    final docsDir = await getApplicationDocumentsDirectory();
    _dataDir = Directory(p.join(docsDir.path, 'hotel_assets', 'data'));
    
    if (!await _dataDir.exists()) {
      await _dataDir.create(recursive: true);
    }
    debugPrint('Using application documents directory: ${_dataDir.path}');
  }

  void initForTest(Directory tempDir) {
    _dataDir = tempDir;
  }

  dynamic _migrateAssetPaths(dynamic data) {
    if (data is String) {
      if (data.startsWith('assets/')) {
        if (!data.startsWith('assets/images/weather/') && 
            !data.startsWith('assets/images/flags/') && 
            !data.startsWith('assets/images/icons/')) {
          return data.replaceFirst('assets/', 'hotel_assets/');
        }
      }
      return data;
    } else if (data is List) {
      return data.map((e) => _migrateAssetPaths(e)).toList();
    } else if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, _migrateAssetPaths(value)));
    }
    return data;
  }

  Future<dynamic> readJson(String fileName) async {
    if (AppConfig.skipHotelAssets) return null;

    if (kIsWeb) {
      try {
        final proxyUrl = const String.fromEnvironment('PROXY_URL', defaultValue: 'http://localhost:8080');
        // Bypass browser cache to guarantee fresh data
        final cb = DateTime.now().millisecondsSinceEpoch;
        final response = await http.get(Uri.parse('$proxyUrl/hotel_assets/data/$fileName?cb=$cb'));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          return _migrateAssetPaths(decoded);
        }
      } catch (e) {
        debugPrint('Error reading JSON via API: $e');
      }
      return null;
    }
    
    final file = File(p.join(_dataDir.path, fileName));
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final decoded = json.decode(jsonString);
        return _migrateAssetPaths(decoded);
      } catch (e) {
        debugPrint('Error loading $fileName: $e');
      }
    }
    return null;
  }

  Future<void> writeJson(String fileName, dynamic data) async {
    if (AppConfig.skipHotelAssets) return;

    if (kIsWeb) {
      try {
        final proxyUrl = const String.fromEnvironment('PROXY_URL', defaultValue: 'http://localhost:8080');
        final request = http.Request('POST', Uri.parse('$proxyUrl/api/writeJson'));
        request.headers['Content-Type'] = 'application/json';
        request.body = json.encode({
          'fileName': fileName,
          'content': data,
        });
        await request.send();
      } catch (e) {
        debugPrint('Error writing JSON via API: $e');
      }
      return;
    }
    final file = File(p.join(_dataDir.path, fileName));
    final jsonString = data is Map ? const JsonEncoder.withIndent('  ').convert(data) : json.encode(data);
    await file.writeAsString(jsonString);
  }

  Future<void> writeJsonDevFallback(String fileName, dynamic data, String assetPath) async {
    await writeJson(fileName, data);
    
    if (_devMode && !kIsWeb) {
      try {
        final assetFile = File(assetPath);
        final parentDir = assetFile.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
        final jsonString = data is Map ? const JsonEncoder.withIndent('  ').convert(data) : json.encode(data);
        await assetFile.writeAsString(jsonString);
        debugPrint('Saved $fileName to assets submodule: ${assetFile.path}');
      } catch (e) {
        debugPrint('Error saving $fileName to assets submodule: $e');
      }
    }
  }

  Future<String> saveImageToAssets(String sourcePath, {String subFolder = 'markets', Uint8List? bytes, String? originalName}) async {
    if (kIsWeb) {
      if (bytes == null || originalName == null) return sourcePath;
      try {
        final proxyUrl = const String.fromEnvironment('PROXY_URL', defaultValue: 'http://localhost:8080');
        final request = http.Request('POST', Uri.parse('$proxyUrl/api/saveImage'));
        request.headers['Content-Type'] = 'application/json';
        request.body = json.encode({
          'subFolder': subFolder,
          'originalName': originalName,
          'imageBase64': base64Encode(bytes),
        });
        
        final response = await request.send();
        if (response.statusCode == 200) {
          final respData = await response.stream.bytesToString();
          final jsonResp = json.decode(respData);
          if (jsonResp['success'] == true) {
            return jsonResp['path'];
          }
        }
      } catch (e) {
        debugPrint('Error saving image via API: $e');
      }
      return sourcePath;
    }
    
    final extension = p.extension(sourcePath);
    final basename = p.basenameWithoutExtension(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${basename}_$timestamp$extension';
    
    // We MUST use PathResolver.resolve to get the absolute path based on the executable or project root.
    // Otherwise, it gets saved relative to the Current Working Directory, which might mismatch what AppImage loads.
    final relativeAssetFolder = 'hotel_assets/images/$subFolder';
    final absoluteAssetFolder = PathResolver.resolve(relativeAssetFolder);
    final dir = Directory(absoluteAssetFolder);
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    final destPath = '$absoluteAssetFolder/$fileName';
    final relativeDestPath = '$relativeAssetFolder/$fileName';
    
    try {
      final sourceFile = File(sourcePath);
      final destFile = File(destPath);
      
      // Foolproof copy: read bytes and write, works across file systems/mounts
      final bytes = await sourceFile.readAsBytes();
      await destFile.writeAsBytes(bytes);
      
      debugPrint('Successfully copied image to $destPath');
    } catch (e) {
      debugPrint('Error copying image: $e');
    }
    
    return relativeDestPath;
  }

  Future<void> deleteImage(String imagePath) async {
    if (imagePath.isEmpty || !imagePath.startsWith('hotel_assets/images/')) {
      return;
    }

    if (kIsWeb) {
      try {
        final proxyUrl = const String.fromEnvironment('PROXY_URL', defaultValue: 'http://localhost:8080');
        final request = http.Request('POST', Uri.parse('$proxyUrl/api/deleteImage'));
        request.headers['Content-Type'] = 'application/json';
        request.body = json.encode({
          'path': imagePath,
        });
        await request.send();
      } catch (e) {
        debugPrint('Error deleting image via API: $e');
      }
      return;
    }

    try {
      final absolutePath = PathResolver.resolve(imagePath);
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Successfully deleted image: $absolutePath');
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
}

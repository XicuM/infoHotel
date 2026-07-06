import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class PdfDiskCache {
  static Future<File> _getCacheFile(String pdfPath, int pageNumber) async {
    final tempDir = await getTemporaryDirectory();
    
    // Create a unique key that includes the file modification time if it's a local file
    // to automatically invalidate the cache if the PDF is replaced/updated.
    String modifier = '';
    if (!pdfPath.startsWith('hotel_assets/') && !kIsWeb) {
      try {
        final file = File(pdfPath);
        if (file.existsSync()) {
          modifier = file.lastModifiedSync().millisecondsSinceEpoch.toString();
        }
      } catch (_) {}
    }
    
    final bytes = utf8.encode('${pdfPath}_$modifier');
    final hash = md5.convert(bytes).toString();
    return File('${tempDir.path}/pdf_cache_${hash}_$pageNumber.jpg');
  }

  static Future<Uint8List?> get(String pdfPath, int pageNumber) async {
    if (kIsWeb) return null;
    try {
      final file = await _getCacheFile(pdfPath, pageNumber);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('PdfDiskCache read error: $e');
    }
    return null;
  }

  static Future<void> put(String pdfPath, int pageNumber, Uint8List bytes) async {
    if (kIsWeb) return;
    try {
      final file = await _getCacheFile(pdfPath, pageNumber);
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('PdfDiskCache write error: $e');
    }
  }
}

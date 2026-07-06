import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/market.dart';
import '../models/excursion.dart';
import '../models/hotel_config.dart';
import '../repositories/storage_repository.dart';

class ContentService extends ChangeNotifier {
  final StorageRepository _storage;

  ContentService({StorageRepository? storage}) 
    : _storage = storage ?? StorageRepository();

  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  Future<String> saveImage(String sourcePath, {String subFolder = 'markets', Uint8List? bytes, String? originalName}) async {
    return await _storage.saveImageToAssets(sourcePath, subFolder: subFolder, bytes: bytes, originalName: originalName);
  }

  Future<void> deleteImage(String imagePath) async {
    await _storage.deleteImage(imagePath);
  }
}



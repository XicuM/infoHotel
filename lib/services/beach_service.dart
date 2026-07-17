import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/beach.dart';
import '../repositories/storage_repository.dart';

class BeachService extends ChangeNotifier {
  final StorageRepository _storage;
  static const String _tagsFile = 'beaches.json';

  List<BeachModel> _beaches = [];
  List<BeachModel> get beaches => _beaches;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  BeachService({StorageRepository? storage})
    : _storage = storage ?? StorageRepository();

  Future<void> init() async {
    await _loadBeaches();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadBeaches() async {
    final dynamic data = await _storage.readJson(_tagsFile);
    if (data is List) {
      _beaches = data.map((j) => BeachModel.fromJson(j as Map<String, dynamic>)).toList();
      return;
    }
    _beaches = [];
  }

  Future<void> _saveBeaches() async {
    final jsonList = _beaches.map((b) => b.toJson()).toList();
    await _storage.writeJson(_tagsFile, jsonList);
  }

  Future<void> addBeach(BeachModel beach) async {
    _beaches.add(beach);
    await _saveBeaches();
    notifyListeners();
  }

  Future<void> deleteBeach(String id) async {
    final index = _beaches.indexWhere((b) => b.id == id);
    if (index != -1) {
      final b = _beaches[index];
      if (b.imagePath.isNotEmpty) await _storage.deleteImage(b.imagePath);

      _beaches.removeAt(index);
      await _saveBeaches();
      notifyListeners();
    }
  }

  Future<void> updateBeach(BeachModel beach) async {
    final index = _beaches.indexWhere((b) => b.id == beach.id);
    if (index != -1) {
      final oldBeach = _beaches[index];
      if (oldBeach.imagePath.isNotEmpty && oldBeach.imagePath != beach.imagePath) {
        await _storage.deleteImage(oldBeach.imagePath);
      }

      _beaches[index] = beach;
      await _saveBeaches();
      notifyListeners();
    }
  }
}

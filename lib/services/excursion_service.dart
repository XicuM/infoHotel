import 'package:flutter/foundation.dart';
import '../models/excursion.dart';
import '../repositories/storage_repository.dart';

class ExcursionService extends ChangeNotifier {
  final StorageRepository _storage;
  static const String _excursionsFile = 'excursions.json';

  List<ExcursionModel> _excursions = [];
  List<ExcursionModel> get excursions => _excursions;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ExcursionService({StorageRepository? storage}) 
    : _storage = storage ?? StorageRepository();

  Future<void> init() async {
    await _loadExcursions();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadExcursions() async {
    final dynamic data = await _storage.readJson(_excursionsFile);
    if (data is List) {
      _excursions = data.map((j) => ExcursionModel.fromJson(j as Map<String, dynamic>)).toList();
      return;
    }
    _excursions = [];
  }

  Future<void> _saveExcursions() async {
    final jsonList = _excursions.map((e) => e.toJson()).toList();
    await _storage.writeJson(_excursionsFile, jsonList);
  }

  Future<void> addExcursion(ExcursionModel excursion) async {
    _excursions.add(excursion);
    await _saveExcursions();
    notifyListeners();
  }

  Future<void> updateExcursion(ExcursionModel excursion) async {
    final index = _excursions.indexWhere((e) => e.id == excursion.id);
    if (index != -1) {
      final oldExcursion = _excursions[index];
      
      if (oldExcursion.imagePath.isNotEmpty && oldExcursion.imagePath != excursion.imagePath && oldExcursion.isLocalImage) {
        await _storage.deleteImage(oldExcursion.imagePath);
      }

      _excursions[index] = excursion;
      await _saveExcursions();
      notifyListeners();
    }
  }

  Future<void> deleteExcursion(String id) async {
    final index = _excursions.indexWhere((e) => e.id == id);
    if (index != -1) {
      final e = _excursions[index];
      if (e.imagePath.isNotEmpty && e.isLocalImage) await _storage.deleteImage(e.imagePath);
      
      _excursions.removeAt(index);
      await _saveExcursions();
      notifyListeners();
    }
  }
}

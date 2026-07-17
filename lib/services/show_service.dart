import 'package:flutter/foundation.dart';
import '../repositories/storage_repository.dart';

class ShowService extends ChangeNotifier {
  final StorageRepository _storage;
  static const String _showsFile = 'shows.json';

  Map<String, String> _showsImages = {};
  Map<String, String> get showsImages => _showsImages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ShowService({StorageRepository? storage}) 
    : _storage = storage ?? StorageRepository();

  Future<void> init() async {
    await _loadShows();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadShows() async {
    final dynamic data = await _storage.readJson(_showsFile);
    if (data is Map<String, dynamic>) {
      _showsImages = Map<String, String>.from(data);
      return;
    }
    _showsImages = {};
  }

  Future<void> _saveShows() async {
    await _storage.writeJson(_showsFile, _showsImages);
  }

  Future<void> updateShowImage(String key, String path) async {
    final oldPath = _showsImages[key];
    if (oldPath != null && oldPath.isNotEmpty && oldPath != path) {
      await _storage.deleteImage(oldPath);
    }
    _showsImages[key] = path;
    await _saveShows();
    notifyListeners();
  }

  String getShowImage(String key) {
    if (key == 'card_image') {
      return _showsImages[key] ?? 'hotel_assets/images/facilities/shows.jpg';
    }
    return _showsImages[key] ?? 'hotel_assets/images/shows/$key.jpg';
  }
}

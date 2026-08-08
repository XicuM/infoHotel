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

  Future<void> updateShowImage(String key, String path, {int week = 1}) async {
    final storageKey = _getKeyForWeek(key, week);
    final oldPath = _showsImages[storageKey];
    if (oldPath != null && oldPath.isNotEmpty && oldPath != path) {
      await _storage.deleteImage(oldPath);
    }
    _showsImages[storageKey] = path;
    await _saveShows();
    notifyListeners();
  }

  Future<void> removeShowImage(String key, {int week = 1}) async {
    await updateShowImage(key, '', week: week);
  }

  String getShowImage(String key, {int week = 1}) {
    if (key == 'card_image') {
      return _showsImages['card_image'] ?? 'hotel_assets/images/facilities/shows.jpg';
    }
    if (key == 'background') {
      return _showsImages['background'] ?? 'hotel_assets/images/shows/shows.png';
    }

    if (week == 2) {
      final week2Key = '${key}_2';
      if (_showsImages.containsKey(week2Key)) {
        return _showsImages[week2Key]!;
      }
    }

    if (_showsImages.containsKey(key)) {
      return _showsImages[key]!;
    }

    return 'hotel_assets/images/shows/$key.jpg';
  }

  int getStartHotelIndex(int week) {
    final key = 'start_hotel_week$week';
    if (_showsImages.containsKey(key)) {
      return int.tryParse(_showsImages[key]!) ?? (week == 1 ? 1 : 0);
    }
    return week == 1 ? 1 : 0;
  }

  Future<void> setStartHotelIndex(int week, int hotelIndex) async {
    _showsImages['start_hotel_week$week'] = hotelIndex.toString();
    await _saveShows();
    notifyListeners();
  }

  String _getKeyForWeek(String key, int week) {
    if (key == 'card_image' || key == 'background') return key;
    return week == 2 ? '${key}_2' : key;
  }
}

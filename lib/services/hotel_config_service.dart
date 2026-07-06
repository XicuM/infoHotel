import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/hotel_config.dart';
import '../repositories/storage_repository.dart';

class HotelConfigService extends ChangeNotifier {
  final StorageRepository _storage;
  static const String _hotelsFile = 'hotels.json';

  Map<String, dynamic> _hotels = {};
  Map<String, dynamic> get hotels => _hotels;

  Map<String, HotelConfig> _hotelConfigs = {};
  Map<String, HotelConfig> get hotelConfigs => _hotelConfigs;
  
  List<HotelConfig> get sortedHotelConfigs {
    final list = _hotelConfigs.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  HotelConfigService({StorageRepository? storage}) 
    : _storage = storage ?? StorageRepository();

  Future<void> init() async {
    await _loadHotels();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadHotels() async {
    final dynamic data = await _storage.readJson(_hotelsFile);
    if (data is Map<String, dynamic>) {
      _parseHotelsJson(data);
      return;
    }

    try {
      final jsonString = await rootBundle.loadString('hotel_assets/data/hotels.json');
      final parsed = json.decode(jsonString) as Map<String, dynamic>;
      _parseHotelsJson(parsed);
    } catch (e) {
      debugPrint('Error loading default hotels.json: $e');
      _hotels = {'Savines': [], 'Arenal': []};
      _hotelConfigs = _defaultHotelConfigs();
    }
  }

  void _parseHotelsJson(Map<String, dynamic> parsed) {
    _hotelConfigs = {};
    if (parsed.containsKey('_meta')) {
      final meta = parsed['_meta'] as Map<String, dynamic>;
      for (final entry in meta.entries) {
        _hotelConfigs[entry.key] = HotelConfig.fromJson(entry.key, entry.value as Map<String, dynamic>);
      }
      parsed.remove('_meta');
    } else {
      _hotelConfigs = _defaultHotelConfigs();
    }
    _hotels = parsed;
  }

  Map<String, HotelConfig> _defaultHotelConfigs() {
    return {
      'Savines': const HotelConfig(
        id: 'Savines',
        name: 'Hotel Ses Savines',
        background: 'hotel_assets/images/background/savines.jpg',
        logo: 'hotel_assets/images/logo/savines.png',
        cardImage: 'hotel_assets/images/facilities/savines.png',
        showsLogo: 'hotel_assets/images/shows/savines.png',
        showShows: true,
        sortOrder: 0,
      ),
      'Arenal': const HotelConfig(
        id: 'Arenal',
        name: 'Hotel Arenal',
        background: 'hotel_assets/images/background/arenal.jpg',
        logo: 'hotel_assets/images/logo/arenal.png',
        cardImage: 'hotel_assets/images/facilities/arenal.png',
        showsLogo: 'hotel_assets/images/shows/arenal.png',
        showShows: true,
        sortOrder: 1,
      ),
    };
  }

  Future<void> _saveHotels() async {
    final output = <String, dynamic>{
      '_meta': {for (final c in _hotelConfigs.values) c.id: c.toJson()},
      ..._hotels,
    };
    await _storage.writeJsonDevFallback(_hotelsFile, output, 'hotel_assets/data/hotels.json');
  }

  Future<void> updateHotels(Map<String, dynamic> hotelsData) async {
    _hotels = hotelsData;
    await _saveHotels();
    notifyListeners();
  }

  HotelConfig? getHotelConfig(String hotelId) {
    return _hotelConfigs[hotelId];
  }

  Future<void> saveHotelConfig(HotelConfig config) async {
    final oldConfig = _hotelConfigs[config.id];
    if (oldConfig != null) {
      if (oldConfig.background.isNotEmpty && oldConfig.background != config.background) await _storage.deleteImage(oldConfig.background);
      if (oldConfig.logo.isNotEmpty && oldConfig.logo != config.logo) await _storage.deleteImage(oldConfig.logo);
      if (oldConfig.cardImage.isNotEmpty && oldConfig.cardImage != config.cardImage) await _storage.deleteImage(oldConfig.cardImage);
      if (oldConfig.showsLogo.isNotEmpty && oldConfig.showsLogo != config.showsLogo) await _storage.deleteImage(oldConfig.showsLogo);
    }
    
    _hotelConfigs[config.id] = config;
    if (!_hotels.containsKey(config.id)) {
      _hotels[config.id] = [];
    }
    await _saveHotels();
    notifyListeners();
  }

  Future<void> deleteHotel(String hotelId) async {
    final oldConfig = _hotelConfigs[hotelId];
    if (oldConfig != null) {
      if (oldConfig.background.isNotEmpty) await _storage.deleteImage(oldConfig.background);
      if (oldConfig.logo.isNotEmpty) await _storage.deleteImage(oldConfig.logo);
      if (oldConfig.cardImage.isNotEmpty) await _storage.deleteImage(oldConfig.cardImage);
      if (oldConfig.showsLogo.isNotEmpty) await _storage.deleteImage(oldConfig.showsLogo);
    }
    
    _hotelConfigs.remove(hotelId);
    _hotels.remove(hotelId);
    await _saveHotels();
    notifyListeners();
  }
}

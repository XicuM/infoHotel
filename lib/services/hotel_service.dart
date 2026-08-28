import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hotel_config.dart';
import 'hotel_config_service.dart';

class HotelService extends ChangeNotifier {
  static const String _prefsKey = 'current_hotel_id';

  String _currentHotelId = '';
  HotelConfigService? _hotelConfigService;
  SharedPreferences? _prefs;

  String get currentHotelId => _currentHotelId;

  HotelConfig? get currentHotelConfig => _hotelConfigService?.getHotelConfig(_currentHotelId);

  List<HotelConfig> get hotelConfigs => _hotelConfigService?.sortedHotelConfigs ?? [];

  void init(HotelConfigService hotelConfigService) {
    if (_hotelConfigService == hotelConfigService) return;
    _hotelConfigService?.removeListener(_onConfigChanged);
    _hotelConfigService = hotelConfigService;
    _hotelConfigService?.addListener(_onConfigChanged);
    _initPrefs();
    _onConfigChanged();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('HotelService: failed to load SharedPreferences: $e');
    }
    _onConfigChanged();
  }

  void _onConfigChanged() {
    final configs = _hotelConfigService?.sortedHotelConfigs ?? [];
    if (configs.isEmpty) {
      notifyListeners();
      return;
    }
    final persistedId = _prefs?.getString(_prefsKey);
    if (persistedId != null && persistedId.isNotEmpty && configs.any((c) => c.id == persistedId)) {
      if (_currentHotelId != persistedId) {
        _currentHotelId = persistedId;
      }
      notifyListeners();
      return;
    }
    if (!configs.any((c) => c.id == _currentHotelId)) {
      _currentHotelId = configs.first.id;
    }
    notifyListeners();
  }

  Future<void> _persist(String hotelId) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(_prefsKey, hotelId);
    } catch (e) {
      debugPrint('HotelService: failed to persist hotel: $e');
    }
  }

  void setHotel(String hotelId) {
    if (_currentHotelId != hotelId) {
      if (_hotelConfigService != null && _hotelConfigService!.getHotelConfig(hotelId) == null) return;
      _currentHotelId = hotelId;
      notifyListeners();
      unawaited(_persist(hotelId));
    }
  }

  void cycleNextHotel() {
    final configs = hotelConfigs;
    if (configs.isEmpty) return;
    final currentIndex = configs.indexWhere((c) => c.id == _currentHotelId);
    if (currentIndex < 0) {
      _currentHotelId = configs.first.id;
    } else {
      _currentHotelId = configs[(currentIndex + 1) % configs.length].id;
    }
    notifyListeners();
    unawaited(_persist(_currentHotelId));
  }

  void cyclePreviousHotel() {
    final configs = hotelConfigs;
    if (configs.isEmpty) return;
    final currentIndex = configs.indexWhere((c) => c.id == _currentHotelId);
    if (currentIndex < 0) {
      _currentHotelId = configs.last.id;
    } else {
      _currentHotelId = configs[(currentIndex - 1 + configs.length) % configs.length].id;
    }
    notifyListeners();
    unawaited(_persist(_currentHotelId));
  }
}

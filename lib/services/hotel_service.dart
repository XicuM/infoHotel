import 'package:flutter/material.dart';
import '../models/hotel_config.dart';
import 'hotel_config_service.dart';

class HotelService extends ChangeNotifier {
  String _currentHotelId = '';
  HotelConfigService? _hotelConfigService;

  String get currentHotelId => _currentHotelId;

  HotelConfig? get currentHotelConfig => _hotelConfigService?.getHotelConfig(_currentHotelId);

  List<HotelConfig> get hotelConfigs => _hotelConfigService?.sortedHotelConfigs ?? [];

  void init(HotelConfigService hotelConfigService) {
    if (_hotelConfigService == hotelConfigService) return;
    _hotelConfigService?.removeListener(_onConfigChanged);
    _hotelConfigService = hotelConfigService;
    _hotelConfigService?.addListener(_onConfigChanged);
    _onConfigChanged();
  }

  void _onConfigChanged() {
    final configs = _hotelConfigService?.sortedHotelConfigs ?? [];
    if (configs.isNotEmpty && !configs.any((c) => c.id == _currentHotelId)) {
      _currentHotelId = configs.first.id;
    }
    notifyListeners();
  }

  void setHotel(String hotelId) {
    if (_currentHotelId != hotelId) {
      if (_hotelConfigService != null && _hotelConfigService!.getHotelConfig(hotelId) == null) return;
      _currentHotelId = hotelId;
      notifyListeners();
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
  }
}

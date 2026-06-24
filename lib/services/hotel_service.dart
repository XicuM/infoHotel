import 'package:flutter/material.dart';

class HotelService extends ChangeNotifier {
  String _currentHotel = 'Savines';

  String get currentHotel => _currentHotel;

  void setHotel(String hotel) {
    if (_currentHotel != hotel && (hotel == 'Savines' || hotel == 'Arenal')) {
      _currentHotel = hotel;
      notifyListeners();
    }
  }

  bool get isSavines => _currentHotel == 'Savines';
  bool get isArenal => _currentHotel == 'Arenal';
}

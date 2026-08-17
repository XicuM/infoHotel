import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bus_data.dart';
import '../repositories/storage_repository.dart';

class BusService extends ChangeNotifier {
  static const String _dataFile = 'bus_timetable.json';

  final StorageRepository _storage;
  BusServiceData? _busData;
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdate;

  BusService({StorageRepository? storage})
      : _storage = storage ?? StorageRepository();

  BusServiceData? get busData => _busData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;

  List<BusStop> get stops => _busData?.stops ?? [];

  Future<void> init() async {
    await fetchBusData();
  }

  Future<void> fetchBusData({bool force = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dynamic raw = await _storage.readJson(_dataFile);
      if (raw != null && raw is Map<String, dynamic>) {
        _busData = BusServiceData.fromJson(raw);
        _lastUpdate = _busData?.lastUpdate ?? DateTime.now();
        _error = null;
      } else {
        _error = 'Bus timetable data not found or invalid format.';
      }
    } catch (e) {
      _error = 'Unable to load bus timetable: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }
}

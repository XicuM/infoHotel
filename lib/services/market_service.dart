import 'package:flutter/foundation.dart';
import '../models/market.dart';
import '../repositories/storage_repository.dart';

class MarketService extends ChangeNotifier {
  final StorageRepository _storage;
  static const String _tagsFile = 'markets.json';

  List<MarketModel> _markets = [];
  List<MarketModel> get markets => _markets;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  MarketService({StorageRepository? storage}) 
    : _storage = storage ?? StorageRepository();

  Future<void> init() async {
    await _loadMarkets();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMarkets() async {
    final dynamic data = await _storage.readJson(_tagsFile);
    if (data is List) {
      _markets = data.map((j) => MarketModel.fromJson(j as Map<String, dynamic>)).toList();
      return;
    }
    _markets = [];
  }

  Future<void> _saveMarkets() async {
    final jsonList = _markets.map((m) => m.toJson()).toList();
    await _storage.writeJson(_tagsFile, jsonList);
  }

  Future<void> addMarket(MarketModel market) async {
    _markets.add(market);
    await _saveMarkets();
    notifyListeners();
  }

  Future<void> deleteMarket(String id) async {
    final index = _markets.indexWhere((m) => m.id == id);
    if (index != -1) {
      final m = _markets[index];
      if (m.imagePath.isNotEmpty) await _storage.deleteImage(m.imagePath);
      
      _markets.removeAt(index);
      await _saveMarkets();
      notifyListeners();
    }
  }

  Future<void> updateMarket(MarketModel market) async {
    final index = _markets.indexWhere((m) => m.id == market.id);
    if (index != -1) {
      final oldMarket = _markets[index];
      if (oldMarket.imagePath.isNotEmpty && oldMarket.imagePath != market.imagePath) {
        await _storage.deleteImage(oldMarket.imagePath);
      }
      
      _markets[index] = market;
      await _saveMarkets();
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
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
    _loadDefaultBeaches();
    await _saveBeaches();
  }

  void _loadDefaultBeaches() {
    _beaches = [
      BeachModel(
        id: 'cala_comte',
        name: 'Cala Comte',
        description: 'cala_comte_desc',
        municipality: 'sant_josep',
        services: ['parking', 'restaurant', 'lifeguard', 'sunbeds', 'accessible'],
        imagePath: 'hotel_assets/images/beaches/cala_comte.jpg',
        galleryImages: ['beaches/cala_comte.jpg'],
        distanceKm: 6.2,
      ),
      BeachModel(
        id: 'cala_bassa',
        name: 'Cala Bassa',
        description: 'cala_bassa_desc',
        municipality: 'sant_josep',
        services: ['parking', 'restaurant', 'lifeguard', 'sunbeds', 'wc', 'water_sports'],
        imagePath: 'hotel_assets/images/beaches/cala_bassa.jpg',
        galleryImages: ['beaches/cala_bassa.jpg'],
        distanceKm: 5.5,
      ),
      BeachModel(
        id: 'cala_salada',
        name: 'Cala Salada',
        description: 'cala_salada_desc',
        municipality: 'sant_antoni',
        services: ['restaurant', 'lifeguard', 'wc'],
        imagePath: 'hotel_assets/images/beaches/cala_salada.jpg',
        galleryImages: ['beaches/cala_salada.jpg'],
        distanceKm: 4.1,
      ),
      BeachModel(
        id: 'plata_en_bossa',
        name: "Platja d'en Bossa",
        description: 'plata_en_bossa_desc',
        municipality: 'sant_josep',
        services: ['parking', 'restaurant', 'bar', 'lifeguard', 'sunbeds', 'wc', 'water_sports', 'accessible'],
        imagePath: 'hotel_assets/images/beaches/plata_en_bossa.jpg',
        galleryImages: ['beaches/plata_en_bossa.jpg'],
        distanceKm: 13.8,
      ),
      BeachModel(
        id: 'cala_hort',
        name: "Cala d'Hort",
        description: 'cala_hort_desc',
        municipality: 'sant_josep',
        services: ['restaurant', 'lifeguard', 'sunbeds'],
        imagePath: 'hotel_assets/images/beaches/cala_hort.jpg',
        galleryImages: ['beaches/cala_hort.jpg'],
        distanceKm: 11.0,
      ),
      BeachModel(
        id: 'benirras',
        name: 'Benirràs',
        description: 'benirras_desc',
        municipality: 'sant_joan',
        services: ['parking', 'restaurant', 'bar', 'lifeguard', 'sunbeds', 'wc'],
        imagePath: 'hotel_assets/images/beaches/benirras.jpg',
        galleryImages: ['beaches/benirras.jpg'],
        distanceKm: 18.2,
      ),
      BeachModel(
        id: 'cala_jondal',
        name: 'Cala Jondal',
        description: 'cala_jondal_desc',
        municipality: 'sant_josep',
        services: ['parking', 'restaurant', 'bar', 'sunbeds'],
        imagePath: 'hotel_assets/images/beaches/cala_jondal.jpg',
        galleryImages: ['beaches/cala_jondal.jpg'],
        distanceKm: 12.5,
      ),
      BeachModel(
        id: 'ses_salines',
        name: 'Ses Salines',
        description: 'ses_salines_desc',
        municipality: 'sant_josep',
        services: ['parking', 'restaurant', 'bar', 'lifeguard', 'sunbeds', 'wc', 'water_sports', 'accessible'],
        imagePath: 'hotel_assets/images/beaches/ses_salines.jpg',
        galleryImages: ['beaches/ses_salines.jpg'],
        distanceKm: 16.7,
      ),
      BeachModel(
        id: 'cala_tarida',
        name: 'Cala Tarida',
        description: 'cala_tarida_desc',
        municipality: 'sant_josep',
        services: ['parking', 'restaurant', 'bar', 'lifeguard', 'sunbeds', 'wc', 'water_sports'],
        imagePath: 'hotel_assets/images/beaches/cala_tarida.jpg',
        galleryImages: ['beaches/cala_tarida.jpg'],
        distanceKm: 6.8,
      ),
      BeachModel(
        id: 'cala_vadella',
        name: 'Cala Vadella',
        description: 'cala_vadella_desc',
        municipality: 'sant_josep',
        services: ['parking', 'restaurant', 'lifeguard', 'sunbeds', 'wc'],
        imagePath: 'hotel_assets/images/beaches/cala_vadella.jpg',
        galleryImages: ['beaches/cala_vadella.jpg'],
        distanceKm: 7.7,
      ),
      BeachModel(
        id: 'cala_llonga',
        name: 'Cala Llonga',
        description: 'cala_llonga_desc',
        municipality: 'santa_eularia',
        services: ['parking', 'restaurant', 'bar', 'lifeguard', 'sunbeds', 'wc', 'water_sports', 'accessible'],
        imagePath: 'hotel_assets/images/beaches/cala_llonga.jpg',
        galleryImages: ['beaches/cala_llonga.jpg'],
        distanceKm: 18.7,
      ),
      BeachModel(
        id: 'port_sant_miquel',
        name: 'Port de Sant Miquel',
        description: 'port_sant_miquel_desc',
        municipality: 'sant_joan',
        services: ['parking', 'restaurant', 'bar', 'lifeguard', 'sunbeds', 'wc', 'water_sports'],
        imagePath: 'hotel_assets/images/beaches/port_sant_miquel.jpg',
        galleryImages: ['beaches/port_sant_miquel.jpg'],
        distanceKm: 16.4,
      ),
    ];
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

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/market.dart';
import '../models/excursion.dart';

class ContentService extends ChangeNotifier {
  List<MarketModel> _markets = [];
  List<MarketModel> get markets => _markets;
  
  List<ExcursionModel> _excursions = [];
  List<ExcursionModel> get excursions => _excursions;

  Map<String, dynamic> _hotels = {};
  Map<String, dynamic> get hotels => _hotels;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  late Directory _dataDir;
  static const String _tagsFile = 'markets.json';
  static const String _showsFile = 'shows.json';
  static const String _excursionsFile = 'excursions.json';
  static const String _hotelsFile = 'hotels.json';

  Map<String, String> _showsImages = {};
  Map<String, String> get showsImages => _showsImages;

  // DEV MODE: Set this to true to try and save to assets/data in dev environment if possible
  // In production/release, we likely can't write to assets, so we fallback to AppDocs
  final bool _devMode = !kReleaseMode; 

  Future<void> init() async {
    await _initDataDir();
    await _loadMarkets();
    await _loadShows();
    await _loadExcursions();
    await _loadHotels();
    _isLoading = false;
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  Future<void> _initDataDir() async {
    if (kIsWeb) return; // Web does not support local file system or dart:io
    // 1. Try to find 'infohotel_data' next to the executable (Portable Mode)
    // This allows easy management of data by just placing the folder next to the .exe
    if (Platform.isWindows || Platform.isLinux) {
      try {
        final exeDir = File(Platform.resolvedExecutable).parent;
        final localDataDir = Directory(p.join(exeDir.path, 'infohotel_data'));
        
        if (await localDataDir.exists()) {
          _dataDir = localDataDir;
          debugPrint('Using local executable directory: ${_dataDir.path}');
          return;
        }
      } catch (e) {
        debugPrint('Error resolving executable path: $e');
      }
    }

    // 2. Fallback to ApplicationDocumentsDirectory (Standard App Data)
    final docsDir = await getApplicationDocumentsDirectory();
    _dataDir = Directory(p.join(docsDir.path, 'infohotel_data'));
    if (!await _dataDir.exists()) {
      await _dataDir.create(recursive: true);
    }
    debugPrint('Using application text data directory: ${_dataDir.path}');
  }

  Future<void> _loadMarkets() async {
    if (kIsWeb) {
      _loadDefaultMarkets();
      return;
    }
    final file = File(p.join(_dataDir.path, _tagsFile));
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _markets = jsonList.map((j) => MarketModel.fromJson(j)).toList();
        return;
      } catch (e) {
        debugPrint('Error loading markets.json: $e');
        // Fallback to defaults
      }
    }

    _loadDefaultMarkets();
    await _saveMarkets();
  }

  void _loadDefaultMarkets() {
    _markets = [
      MarketModel(
        id: 'las_dalias',
        name: 'Las Dalias',
        description: 'las_dalias_desc', // Code checks translations if this is a key
        imagePath: 'assets/images/markets/las_dalias_logo.png',
        galleryImages: [
          'markets/las_dalias.jpg',
          'markets/las_dalias_logo.png',
          'markets/las_dalias.jpg',
          'markets/las_dalias_logo.png',
        ],
      ),
      MarketModel(
        id: 'punta_arabi',
        name: 'Punta Arabí',
        description: 'punta_arabi_desc',
        imagePath: 'assets/images/markets/punta_arabi_logo.jpg',
        galleryImages: ['markets/punta_arabi.jpg'],
      ),
      MarketModel(
        id: 'platja_den_bossa',
        name: "Platja d'en Bossa",
        description: 'platja_desc',
        imagePath: 'assets/images/markets/platja_market_logo.png',
        galleryImages: ['markets/platja_den_bossa.jpg'],
      ),
      MarketModel(
        id: 'sant_joan',
        name: 'Sant Joan',
        description: 'sant_joan_desc',
        imagePath: 'assets/images/markets/sant_joan_logo.jpg',
        galleryImages: ['markets/sant_joan.jpg'],
      ),
      MarketModel(
        id: 'sant_miquel',
        name: 'Sant Miquel',
        description: 'sant_miquel_desc',
        imagePath: 'assets/images/markets/sant_miquel_logo.jpg',
        galleryImages: ['markets/sant_miquel.jpg'],
      ),
      MarketModel(
        id: 'sant_rafel',
        name: 'Sant Rafel',
        description: 'sant_rafel_desc',
        imagePath: 'assets/images/markets/sant_rafel_logo.jpg',
        galleryImages: ['markets/sant_rafel.jpg'],
      ),
       MarketModel(
        id: 'forada',
        name: 'Forada',
        description: 'forada_desc',
        imagePath: 'assets/images/markets/forada_logo.jpeg',
        galleryImages: ['markets/forada.jpg'],
      ),
    ];
  }

  Future<void> _saveMarkets() async {
    if (kIsWeb) return;
    final file = File(p.join(_dataDir.path, _tagsFile));
    final jsonString = json.encode(_markets.map((m) => m.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<void> addMarket(MarketModel market) async {
    _markets.add(market);
    await _saveMarkets();
    notifyListeners();
  }

  Future<void> deleteMarket(String id) async {
    _markets.removeWhere((m) => m.id == id);
    await _saveMarkets();
    notifyListeners();
  }

  Future<void> updateMarket(MarketModel market) async {
    final index = _markets.indexWhere((m) => m.id == market.id);
    if (index != -1) {
      _markets[index] = market;
      await _saveMarkets();
      notifyListeners();
    }
  }

  // --- Excursions ---

  Future<void> _loadExcursions() async {
    if (kIsWeb) {
      _loadDefaultExcursions();
      return;
    }
    final file = File(p.join(_dataDir.path, _excursionsFile));
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _excursions = jsonList.map((j) => ExcursionModel.fromJson(j)).toList();
        return;
      } catch (e) {
        debugPrint('Error loading excursions.json: $e');
      }
    }
    _loadDefaultExcursions();
    await _saveExcursions();
  }

  void _loadDefaultExcursions() {
    _excursions = [
      ExcursionModel(
        id: 'alsabini_trans',
        name: 'Alsabini Transfers',
        imagePath: 'assets/images/excursions/alsabini_logo.jpg',
        type: ExcursionType.images,
        content: ['assets/images/excursions/transfers.png'],
      ),
      ExcursionModel(
        id: 'aquabus',
        name: 'Aquabus',
        imagePath: 'assets/images/excursions/aquabus_logo.png',
        type: ExcursionType.pdf,
        content: 'assets/pdf/excursions/aquabus.pdf',
      ),
      ExcursionModel(
        id: 'balearia',
        name: 'Baleària',
        imagePath: 'assets/images/excursions/balearia_logo.png',
        type: ExcursionType.images,
        content: ['assets/images/excursions/balearia.jpg'],
      ),
      ExcursionModel(
        id: 'mediter_pitiusa',
        name: 'Mediterránea Pitiusa',
        imagePath: 'assets/images/excursions/med_pitiusa_logo.jpg',
        type: ExcursionType.images,
        content: ['assets/images/excursions/mediterranea_pitiusa.jpg'],
      ),
      ExcursionModel(
        id: 'alsabini_excur',
        name: 'Alsabini Excursions',
        imagePath: 'assets/images/excursions/alsabini_logo.jpg',
        type: ExcursionType.images,
        content: ['assets/images/excursions/alsabini.jpg'],
      ),
      ExcursionModel(
        id: 'capitan_nemo',
        name: 'Capitán Nemo',
        imagePath: 'assets/images/excursions/nemo_logo.png',
        type: ExcursionType.images,
        content: ['assets/images/excursions/capitan_nemo.jpg'],
      ),
      ExcursionModel(
        id: 'excursions_ibiza',
        name: 'Excursions Ibiza',
        imagePath: 'assets/images/excursions/ex_ibiza_logo.png',
        type: ExcursionType.pdf,
        content: 'assets/pdf/excursions/excursiones_ibiza_esvedraformentera.pdf',
      ),
    ];
  }

  Future<void> _saveExcursions() async {
    if (kIsWeb) return;
    final file = File(p.join(_dataDir.path, _excursionsFile));
    final jsonString = json.encode(_excursions.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<void> addExcursion(ExcursionModel excursion) async {
    _excursions.add(excursion);
    await _saveExcursions();
    notifyListeners();
  }

  Future<void> updateExcursion(ExcursionModel excursion) async {
    final index = _excursions.indexWhere((e) => e.id == excursion.id);
    if (index != -1) {
      _excursions[index] = excursion;
      await _saveExcursions();
      notifyListeners();
    }
  }

  Future<void> deleteExcursion(String id) async {
    _excursions.removeWhere((e) => e.id == id);
    await _saveExcursions();
    notifyListeners();
  }

  // --- Shows ---

  Future<void> _loadShows() async {
    if (kIsWeb) {
      _loadDefaultShows();
      return;
    }
    final file = File(p.join(_dataDir.path, _showsFile));
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _showsImages = Map<String, String>.from(jsonMap);
        return;
      } catch (e) {
        debugPrint('Error loading shows.json: $e');
      }
    }
    _loadDefaultShows();
    await _saveShows();
  }

  void _loadDefaultShows() {
    _showsImages = {
      'background': 'assets/images/shows/shows.png',
      'monday': 'assets/images/shows/monday.jpg',
      'tuesday': 'assets/images/shows/tuesday.jpg',
      'wednesday': 'assets/images/shows/wednesday.jpg',
      'thursday': 'assets/images/shows/thursday.jpg',
      'friday': 'assets/images/shows/friday.jpg',
      'saturday': 'assets/images/shows/saturday.jpg',
      'sunday': 'assets/images/shows/sunday.jpg',
    };
  }

  Future<void> _saveShows() async {
    if (kIsWeb) return;
    final file = File(p.join(_dataDir.path, _showsFile));
    final jsonString = json.encode(_showsImages);
    await file.writeAsString(jsonString);
  }

  Future<void> updateShowImage(String key, String path) async {
    _showsImages[key] = path;
    await _saveShows();
    notifyListeners();
  }

  String getShowImage(String key) {
    return _showsImages[key] ?? 'assets/images/shows/$key.jpg';
  }

  // --- Hotels ---

  Future<void> _loadHotels() async {
    if (kIsWeb) {
      try {
        final jsonString = await rootBundle.loadString('assets/data/hotels.json');
        _hotels = json.decode(jsonString);
      } catch (e) {
        _hotels = {'Savines': [], 'Arenal': []};
      }
      return;
    }
    final file = File(p.join(_dataDir.path, _hotelsFile));
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        _hotels = json.decode(jsonString);
        return;
      } catch (e) {
        debugPrint('Error loading hotels.json: $e');
      }
    }
    
    // Fallback to assets
    try {
      final jsonString = await rootBundle.loadString('assets/data/hotels.json');
      _hotels = json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading default hotels.json: $e');
      _hotels = {'Savines': [], 'Arenal': []};
    }
  }

  Future<void> _saveHotels() async {
    if (kIsWeb) return;
    final file = File(p.join(_dataDir.path, _hotelsFile));
    final jsonString = json.encode(_hotels);
    await file.writeAsString(jsonString);
  }

  Future<void> updateHotels(Map<String, dynamic> hotelsData) async {
    _hotels = hotelsData;
    await _saveHotels();
    notifyListeners();
  }

  Future<String> saveImage(String sourcePath, {String subFolder = 'markets'}) async {
    if (kIsWeb) return sourcePath; // Can't save files on Web
    final fileName = p.basename(sourcePath);
    // Save directly to the asset folder as requested
    final assetFolder = 'assets/images/$subFolder';
    final dir = Directory(assetFolder);
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    final destPath = '$assetFolder/$fileName';
    await File(sourcePath).copy(destPath);
    
    return destPath;
  }
}

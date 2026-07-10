import 'dart:async';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/bus_data.dart';
import '../config/env.dart';
import '../utils/cache_helper.dart';
import '../utils/gtfs_parser.dart';

class BusService extends ChangeNotifier {
  static const String _napBaseUrl = 'https://nap.transportes.gob.es/api';

  // GTFS file ID on the NAP (Punt d'Accés Nacional de Transports).
  // OLD (Servibus/TIB, numeric lines 02-50, Nov 2025): 1273
  // NEW (ALSA autobuses national feed, contains Ibiza T/A/AERO/P/N/U lines): 1133
  // Updated: July 2026. To verify: GET /api/Fichero/downloadLink/1133
  static const int _gtfsFileId = 1133;

  static const Duration _refreshInterval = Duration(hours: 6);

  // Stop IDs as they appear in the ALSA GTFS (stops.txt stop_id column).
  // OLD Servibus IDs: '155' (code 108), '407' (code 408), '148' (code 101).
  // NEW ALSA GTFS IDs (verified July 2026 from BUS_ALSA.zip stops.txt):
  static const List<Map<String, String>> _hotelStops = [
    {'id': '0001454200000001', 'code': '108', 'name': "H. Arenal (S'Arenal dir. Port des Torrent)"},
    {'id': '0001454300000001', 'code': '408', 'name': "H. Arenal (S'Arenal dir. Sant Antoni)"},
    {'id': '0001452800000001', 'code': '101', 'name': 'Estació de Sant Antoni'},
  ];

  BusServiceData? _busData;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;
  Timer? _fetchTimer;

  BusService() {
    _init();
  }

  BusServiceData? get busData => _busData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;

  List<BusStop> get stops => _busData?.stops ?? [];

  Future<void> _init() async {
    if (Env.busApiKey.isEmpty) {
      debugPrint('Bus API deactivated due to missing key.');
      return;
    }

    await _loadDiskCache();
    await fetchBusData();
    _fetchTimer = Timer.periodic(_refreshInterval, (_) {
      fetchBusData();
    });
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDiskCache() async {
    final cacheData = await CacheHelper.readCache('bus_cache.json');
    if (cacheData != null) {
      try {
        final decoded = jsonDecode(cacheData);
        final data = BusServiceData.fromJson(decoded as Map<String, dynamic>);
        
        // Version 1.2+ required: invalidates old Servibus (numeric lines) data.
        // Bump this version whenever the GTFS source or data schema changes.
        if (data.version != '1.2') {
          debugPrint('Bus cache version mismatch (got ${data.version}, expected 1.2). Clearing cache.');
          await CacheHelper.deleteCache('bus_cache.json');
          return;
        }
        
        _busData = data;
        _lastUpdate = _busData?.lastUpdate;
      } catch (e) {
        debugPrint('Error parsing bus disk cache: $e');
      }
    }
  }

  Future<void> _saveDiskCache(BusServiceData data) async {
    await CacheHelper.writeCache('bus_cache.json', jsonEncode(data.toJson()));
  }

  Future<void> fetchBusData({bool force = false}) async {
    if (_busData != null && !force) {
      final now = DateTime.now();
      if (_lastUpdate != null && now.difference(_lastUpdate!).inHours < 6) {
        return;
      }
    }

    _isLoading = _busData == null;
    _error = null;
    notifyListeners();

    try {
      final data = await _fetchAndParseGtfs();
      if (data != null) {
        _busData = data;
        _lastUpdate = DateTime.now();
        await _saveDiskCache(data);
        _error = null; // clear any previous error on success
      } else {
        // If we got null but no specific error was set, set a generic message.
        _error ??= 'Failed to fetch bus data from GTFS source.\n'
            'Note: If the ALSA Ibiza GTFS file ID has changed on the NAP, '
            'update _gtfsFileId in bus_service.dart.';
      }
    } catch (e) {
      _error = 'Unable to fetch bus data: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<BusServiceData?> _fetchAndParseGtfs() async {
    if (Env.busApiKey.isEmpty) {
      _error = 'BUS_API_KEY not configured';
      debugPrint(_error);
      return null;
    }

    final zipBytes = await _downloadGtfsZip();
    if (zipBytes == null) return null;

    return await compute(GtfsParser.parseGtfsInIsolate, GtfsParseParams(
      zipBytes: zipBytes,
      stopIds: _hotelStops.map((s) => s['id']!).toList(),
    ));
  }

  Future<List<int>?> _downloadGtfsZip() async {
    try {
      final downloadUrl = await _getDownloadUrl();
      if (downloadUrl == null) return null;

      final requestUrl = kIsWeb
          ? '${Env.proxyBaseUrl}/api/proxy?url=${Uri.encodeComponent(downloadUrl)}'
          : downloadUrl;
      final response = await http.get(
        Uri.parse(requestUrl),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('GTFS download failed with status: ${response.statusCode}');
        _error = 'GTFS download error (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Error downloading GTFS: $e');
      _error = 'GTFS download failed: $e';
    }
    return null;
  }

  Future<String?> _getDownloadUrl() async {
    try {
      final url = '$_napBaseUrl/Fichero/downloadLink/$_gtfsFileId';
      final requestUrl = kIsWeb
          ? '${Env.proxyBaseUrl}/api/proxy?url=${Uri.encodeComponent(url)}'
          : url;
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {'ApiKey': Env.busApiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('{')) {
          final json = jsonDecode(body);
          return json['url'] as String?;
        }
        return body;
      } else {
        debugPrint('downloadLink failed: ${response.statusCode}');
        _error = 'Bus API error (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Error getting download URL: $e');
      _error = 'Failed to reach bus server: $e';
    }
    return null;
  }

}

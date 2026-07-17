import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../config/env.dart';

import '../utils/cache_helper.dart';

/// Service for fetching weather data from AEMET API
/// Ported from scripts/weather.py in Pygame prototype
class WeatherService extends ChangeNotifier {

  static const String _hourlyUrl =
      '${Env.aemetBaseUrl}/prediccion/especifica/municipio/horaria/${Env.municipalityCode}';
  static const String _dailyUrl =
      '${Env.aemetBaseUrl}/prediccion/especifica/municipio/diaria/${Env.municipalityCode}';

  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;
  DateTime? _lastAttempt;
  Timer? _fetchTimer;

  WeatherService() {
    _init();
  }

  Future<void> _init() async {
    // Fully deactivate if the API key is not configured
    if (Env.aemetApiKey.isEmpty) {
      debugPrint('Weather API deactivated due to missing key.');
      return;
    }

    // Load disk cache first so the UI immediately has data
    await _loadDiskCache();
    // Trigger initial fetch
    await fetchWeather();
    // Set up background periodic timer to fetch every 30 minutes
    _fetchTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      fetchWeather();
    });
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    super.dispose();
  }

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;

  Future<void> _loadDiskCache() async {
    final cacheData = await CacheHelper.readCache('weather_cache.json');
    if (cacheData != null) {
      try {
        final decoded = jsonDecode(cacheData);
        if (decoded is Map<String, dynamic> && decoded.containsKey('timestamp')) {
          _lastUpdate = DateTime.parse(decoded['timestamp']);
          final hourlyData = decoded['hourlyData'] as List<dynamic>? ?? [];
          final dailyData = decoded['dailyData'] as List<dynamic>? ?? [];
          _weatherData = WeatherData.fromAemetResponses(hourlyData, dailyData);
        }
      } catch (e) {
        debugPrint("Error parsing weather disk cache: $e");
      }
    }
  }

  Future<void> _saveDiskCache(List<dynamic> hourlyData, List<dynamic> dailyData) async {
    final data = {
      'timestamp': _lastUpdate?.toIso8601String(),
      'hourlyData': hourlyData,
      'dailyData': dailyData,
    };
    await CacheHelper.writeCache('weather_cache.json', jsonEncode(data));
  }

  /// Fetch weather data from AEMET API
  Future<void> fetchWeather({bool force = false}) async {
    // If we have nothing in memory, try to load from disk first to show *something* instantly
    if (_weatherData == null) {
      await _loadDiskCache();
    }

    final now = DateTime.now();

    // Prevent spamming the API on every page transition if it failed recently
    if (!force && _lastAttempt != null) {
      if (now.difference(_lastAttempt!).inMinutes < 15) {
        debugPrint('Skipping weather API fetch: last attempt was less than 15 minutes ago.');
        return;
      }
    }

    // Return early if we have recent successful data (less than 1 hour old)
    if (!force && _lastUpdate != null && _weatherData != null) {
      if (now.difference(_lastUpdate!).inMinutes < 60) {
        return;
      }
    }

    _isLoading = _weatherData == null;
    _error = null;
    _lastAttempt = now;
    notifyListeners();

    try {
      // Fetch hourly and daily predictions
      final hourlyData = await _fetchData(_hourlyUrl);
      final dailyData = await _fetchData(_dailyUrl);

      if (hourlyData != null && dailyData != null) {
        _weatherData = WeatherData.fromAemetResponses(hourlyData, dailyData);
        _lastUpdate = DateTime.now();
        await _saveDiskCache(hourlyData, dailyData);
      }
    } catch (e) {
      _error = 'Unable to connect to AEMET: $e';
      debugPrint(_error);
      // If error occurs, we still have _weatherData from disk cache loaded above
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<dynamic>?> _fetchData(String url) async {
    try {
      final requestUrl = kIsWeb ? '${Env.proxyBaseUrl}/api/proxy?url=${Uri.encodeComponent(url)}' : url;
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {'api_key': Env.aemetApiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final bodyStr = latin1.decode(response.bodyBytes);
        final json = jsonDecode(bodyStr);
        if (json is Map && json.containsKey('estado') && json['estado'] != 200) {
           debugPrint('AEMET API Error: ${json['descripcion']}');
           return null;
        }
        
        final dataUrl = json['datos'] as String?;

        if (dataUrl != null) {
          final dataRequestUrl = kIsWeb ? '${Env.proxyBaseUrl}/api/proxy?url=${Uri.encodeComponent(dataUrl)}' : dataUrl;
          final dataResponse = await http.get(Uri.parse(dataRequestUrl));
          if (dataResponse.statusCode == 200) {
            final dataStr = latin1.decode(dataResponse.bodyBytes);
            final data = jsonDecode(dataStr);
            if (data is List && data.isNotEmpty) {
              return data[0]['prediccion']['dia'] as List<dynamic>;
            }
          } else {
            debugPrint('AEMET final data fetch failed with status: ${dataResponse.statusCode}');
          }
        }
      } else {
        debugPrint('AEMET metadata fetch failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching AEMET data: $e');
    }
    return null;
  }
}

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
          _weatherData = _parseWeatherData(hourlyData, dailyData);
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
        _weatherData = _parseWeatherData(hourlyData, dailyData);
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
      final requestUrl = kIsWeb ? '/api/proxy?url=${Uri.encodeComponent(url)}' : url;
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
          final dataRequestUrl = kIsWeb ? '/api/proxy?url=${Uri.encodeComponent(dataUrl)}' : dataUrl;
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

  WeatherData _parseWeatherData(
      List<dynamic> hourlyData, List<dynamic> dailyData) {
    final now = DateTime.now();
    final currentHour = now.hour;

    // Parse hourly data (first two days combined)
    final Map<String, dynamic> day0 = hourlyData.isNotEmpty ? (hourlyData[0] as Map<String, dynamic>? ?? {}) : {};
    final Map<String, dynamic> day1 = hourlyData.length > 1 ? (hourlyData[1] as Map<String, dynamic>? ?? {}) : {};

    final hourlyStates = [
      ...(day0['estadoCielo'] as List? ?? []),
      ...(day1['estadoCielo'] as List? ?? []),
    ];

    // Find current hour data
    Map<String, dynamic>? currentState;
    for (var state in hourlyStates) {
      if (int.tryParse(state['periodo']?.toString() ?? '') == currentHour) {
        currentState = state;
        break;
      }
    }

    // Parse temperature values
    final temps = [
      ...(day0['temperatura'] as List? ?? []),
      ...(day1['temperatura'] as List? ?? []),
    ];
    
    final tempValues = <int>[];
    final tempTimes = <String>[];
    for (var t in temps) {
      tempValues.add(int.tryParse(t['value']?.toString() ?? '0') ?? 0);
      tempTimes.add(t['periodo']?.toString() ?? '');
    }

    // Get current temperature
    int? currentTemp;
    for (var i = 0; i < tempTimes.length; i++) {
      if (int.tryParse(tempTimes[i]) == currentHour) {
        currentTemp = tempValues[i];
        break;
      }
    }

    // Parse sunrise/sunset
    final sunrise = day0['orto']?.toString() ?? '07:00';
    final sunset = day0['ocaso']?.toString() ?? '20:00';

    // Parse daily forecasts
    final dailyForecasts = <DayForecast>[];
    for (var i = 0; i < dailyData.length && i < 7; i++) {
      final day = dailyData[i];
      final tempData = day['temperatura'] ?? {};
      final uvMax = day['uvMax'];
      int? parsedUv;
      if (uvMax != null) {
        parsedUv = uvMax is int ? uvMax : int.tryParse(uvMax.toString());
      }

      String uvColor = 'light green';
      if (parsedUv != null) {
        if (parsedUv >= 11) {
          uvColor = 'purple';
        } else if (parsedUv >= 8) {
          uvColor = 'red';
        } else if (parsedUv >= 6) {
          uvColor = 'orange';
        } else if (parsedUv >= 3) {
          uvColor = 'amber';
        }
      }

      final skyStates = day['estadoCielo'] as List? ?? [];
      final skyState =
          skyStates.isNotEmpty ? skyStates[0]['descripcion'] ?? '' : '';

      final precip = day['probPrecipitacion'] as List? ?? [];
      final precipitation = precip.isNotEmpty
          ? int.tryParse(precip[0]['value']?.toString() ?? '0') ?? 0
          : 0;

      final winds = day['viento'] as List? ?? [];
      int windSpeed = 0;
      String windDir = 'N';
      if (winds.isNotEmpty) {
        windSpeed =
            int.tryParse(winds[0]['velocidad']?.toString() ?? '0') ?? 0;
        windDir = winds[0]['direccion']?.toString() ?? 'N';
      }

      dailyForecasts.add(DayForecast(
        date: now.add(Duration(days: i)),
        maxTemp: int.tryParse(tempData['maxima']?.toString() ?? '0') ?? 0,
        minTemp: int.tryParse(tempData['minima']?.toString() ?? '0') ?? 0,
        uvIndex: parsedUv,
        uvColor: uvColor,
        skyState: skyState,
        precipitation: precipitation,
        windSpeed: windSpeed,
        windDirection: windDir,
      ));
    }

    return WeatherData(
      currentTemp: currentTemp ?? 20,
      sunrise: sunrise,
      sunset: sunset,
      skyState: currentState?['descripcion'] ?? '',
      tempValues: tempValues,
      tempTimes: tempTimes,
      dailyForecasts: dailyForecasts,
    );
  }
}

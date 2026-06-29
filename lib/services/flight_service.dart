import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/flight_model.dart';
import '../config/env.dart';
import '../utils/cache_helper.dart';

class IbizaFlightService {
  final String _apiKey;
  final String _baseUrl = "https://aerodatabox.p.rapidapi.com/flights/airports/iata/IBZ";
  final http.Client _client;

  IbizaFlightService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? Env.flightApiKey;

  Future<List<IbizaDeparture>> fetchNextDepartures() async {
    if (_apiKey.isEmpty) {
      throw Exception('FLIGHT_API_KEY is empty. Did you forget to compile/run with --dart-define=FLIGHT_API_KEY=your_key?');
    }

    // Kiosk best practice: Request a fixed 12-hour future window
    final now = DateTime.now();
    final localFrom = now.toIso8601String().substring(0, 16);
    final localTo = now.add(const Duration(hours: 12)).toIso8601String().substring(0, 16);

    final urlString = '$_baseUrl/$localFrom/$localTo?withLeg=true&direction=Departure';
    final requestUrl = kIsWeb ? '/api/proxy?url=${Uri.encodeComponent(urlString)}' : urlString;
    final url = Uri.parse(requestUrl);

    final response = await _client.get(url, headers: {
      'X-RapidAPI-Key': _apiKey,
      'X-RapidAPI-Host': 'aerodatabox.p.rapidapi.com',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['departures'] ?? [];
      final rawFlights = data.map((item) => IbizaDeparture.fromJson(item)).toList();
      
      return rawFlights;
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}

class IbizaFlightRepository {
  // Singleton instance
  static final IbizaFlightRepository _instance = IbizaFlightRepository._internal(IbizaFlightService());
  factory IbizaFlightRepository() => _instance;
  IbizaFlightRepository._internal(this._apiService);

  final IbizaFlightService _apiService;
  
  List<IbizaDeparture> _cachedFlights = [];
  DateTime? _lastFetchedTime;

  DateTime? get lastFetchedTime => _lastFetchedTime;

  Future<void> _loadDiskCache() async {
    final cacheData = await CacheHelper.readCache('flight_cache.json');
    if (cacheData != null) {
      try {
        final decoded = jsonDecode(cacheData);
        if (decoded is Map<String, dynamic> && decoded.containsKey('timestamp')) {
          _lastFetchedTime = DateTime.parse(decoded['timestamp']);
          final list = decoded['flights'] as List;
          _cachedFlights = list.map((item) => IbizaDeparture.fromCache(item)).toList();
        }
      } catch (e) {
        print("Error parsing flight disk cache: $e");
      }
    }
  }

  Future<void> _saveDiskCache() async {
    final data = {
      'timestamp': _lastFetchedTime?.toIso8601String(),
      'flights': _cachedFlights.map((f) => f.toJson()).toList(),
    };
    await CacheHelper.writeCache('flight_cache.json', jsonEncode(data));
  }

  Future<List<IbizaDeparture>> getDepartures({bool forceRefresh = false}) async {
    final now = DateTime.now();

    // If memory cache is empty, try loading from disk first
    if (_cachedFlights.isEmpty) {
      await _loadDiskCache();
    }

    // Cache-hit: If data is fresh (less than 15 minutes old) and not forced, bypass API
    if (!forceRefresh && 
        _cachedFlights.isNotEmpty && 
        _lastFetchedTime != null && 
        now.difference(_lastFetchedTime!) < const Duration(minutes: 15)) {
      return _filterAndGroupFlights(_cachedFlights);
    }

    // Cache-miss: Call the API safely in the background
    try {
      final newFlights = await _apiService.fetchNextDepartures();
      newFlights.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      _cachedFlights = newFlights;
      _lastFetchedTime = now;
      await _saveDiskCache();
    } catch (e) {
      // Offline/Error Fail-safe: Fall back silently to old data if API fails
      if (_cachedFlights.isNotEmpty) {
        return _filterAndGroupFlights(_cachedFlights);
      }
      rethrow; // If app just launched and has no data, bubble up the error to UI
    }

    return _filterAndGroupFlights(_cachedFlights);
  }

  List<IbizaDeparture> _filterAndGroupFlights(List<IbizaDeparture> rawFlights) {
    final now = DateTime.now();
    final filteredFlights = rawFlights.where((f) {
      final refTime = f.estimatedTime ?? f.scheduledTime;
      if (now.difference(refTime).inMinutes > 120) return false;
      
      final rawStatus = f.status.toLowerCase();
      if ((rawStatus.contains('departed') || rawStatus.contains('despegado')) && 
          now.difference(refTime).inMinutes > 30) {
        return false;
      }
      if ((rawStatus.contains('cancelled') || rawStatus.contains('cancelado')) && 
          now.difference(refTime).inMinutes > 60) {
        return false;
      }
      return true;
    }).toList();

    final Map<String, IbizaDeparture> grouped = {};
    for (var f in filteredFlights) {
      final timeKey = '${f.scheduledTime.year}-${f.scheduledTime.month}-${f.scheduledTime.day} ${f.scheduledTime.hour}:${f.scheduledTime.minute}';
      final key = '${f.destination.toLowerCase()}_$timeKey';
      
      if (grouped.containsKey(key)) {
        final existing = grouped[key]!;
        final newNumbers = List<String>.from(existing.flightNumbers);
        bool added = false;
        for (var num in f.flightNumbers) {
          if (!newNumbers.contains(num)) {
            newNumbers.add(num);
            added = true;
          }
        }
        if (added) {
          grouped[key] = IbizaDeparture(
            flightNumbers: newNumbers,
            destination: existing.destination,
            scheduledTime: existing.scheduledTime,
            estimatedTime: existing.estimatedTime ?? f.estimatedTime,
            status: existing.status != 'Scheduled' ? existing.status : f.status,
            gate: existing.gate != '-' ? existing.gate : f.gate,
          );
        }
      } else {
        grouped[key] = IbizaDeparture(
          flightNumbers: List<String>.from(f.flightNumbers),
          destination: f.destination,
          scheduledTime: f.scheduledTime,
          estimatedTime: f.estimatedTime,
          status: f.status,
          gate: f.gate,
        );
      }
    }
    return grouped.values.toList();
  }
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:info_hotel/config/env.dart';
import 'package:info_hotel/services/flight_service.dart';

void main() {
  group('Live API Integration Tests', () {
    // Read the keys from Env class (populated via --dart-define)
    final bool hasAemetKey = Env.aemetApiKey.isNotEmpty;
    final bool hasFlightKey = Env.flightApiKey.isNotEmpty;

    test('Live AEMET Weather API Connection & Parsing Test', () async {
      if (!hasAemetKey) {
        print('[SKIP] Skipping Live AEMET Weather API test because AEMET_API_KEY is not defined.');
        return;
      }

      print('Starting Live AEMET Weather API test...');
      
      // 1. Hourly prediction endpoint
      final hourlyUrl = '${Env.aemetBaseUrl}/prediccion/especifica/municipio/horaria/${Env.municipalityCode}';
      final response = await http.get(
        Uri.parse(hourlyUrl),
        headers: {'api_key': Env.aemetApiKey},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 429) {
        print('[INFO] AEMET API returned 429 (Rate Limited). Connection is working, but request limit was reached.');
        return;
      }
      expect(response.statusCode, 200, reason: 'Failed to connect to AEMET endpoint');
      
      final json = jsonDecode(latin1.decode(response.bodyBytes));
      expect(json['estado'], 200, reason: 'AEMET API returned error state: ${json['descripcion']}');
      
      // 2. Fetch the actual content URL from CDN
      final dataUrl = json['datos'] as String;
      final dataResponse = await http.get(Uri.parse(dataUrl)).timeout(const Duration(seconds: 10));
      expect(dataResponse.statusCode, 200, reason: 'Failed to download data payload from AEMET CDN');
      
      final data = jsonDecode(latin1.decode(dataResponse.bodyBytes));
      expect(data, isNotEmpty, reason: 'AEMET returned empty predictions');
      expect(data[0]['nombre'], 'Sant Antoni de Portmany', reason: 'Incorrect municipality name returned');
      
      print('AEMET Weather API integration test passed successfully!');
    });

    test('Live RapidAPI Aerodatabox Flight API Connection Test', () async {
      if (!hasFlightKey) {
        print('[SKIP] Skipping Live Flight API test because FLIGHT_API_KEY is not defined.');
        return;
      }

      print('Starting Live Flight API test...');
      
      final service = IbizaFlightService();
      try {
        final departures = await service.fetchNextDepartures();
        expect(departures, isNotNull);
        expect(departures, isA<List>());
        print('Flight API integration test passed successfully! Retrieved ${departures.length} departures.');
      } catch (e) {
        fail('Flight API connection threw exception: $e');
      }
    });
  });
}

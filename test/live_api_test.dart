import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:info_hotel/config/env.dart';

void main() {
  group('Live API Integration Tests', () {
    final bool hasAemetKey = Env.aemetApiKey.isNotEmpty;

    test('Live AEMET Weather API Connection & Parsing Test', () async {
      if (!hasAemetKey) {
        print('[SKIP] Skipping Live AEMET Weather API test because AEMET_API_KEY is not defined.');
        return;
      }

      print('Starting Live AEMET Weather API test...');
      
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
      
      final dataUrl = json['datos'] as String;
      final dataResponse = await http.get(Uri.parse(dataUrl)).timeout(const Duration(seconds: 10));
      expect(dataResponse.statusCode, 200, reason: 'Failed to download data payload from AEMET CDN');
      
      final data = jsonDecode(latin1.decode(dataResponse.bodyBytes));
      expect(data, isNotEmpty, reason: 'AEMET returned empty predictions');
      expect(data[0]['nombre'], 'Sant Antoni de Portmany', reason: 'Incorrect municipality name returned');
      
      print('AEMET Weather API integration test passed successfully!');
    });
  });
}

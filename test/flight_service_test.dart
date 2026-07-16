import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:info_hotel/models/flight_model.dart';
import 'package:info_hotel/services/flight_service.dart';
import 'dart:convert';

void main() {
  group('IbizaFlightService Tests', () {
    test('fetchNextDepartures returns a list of IbizaDeparture on success', () async {
      // 1. Arrange: Create a mock HTTP client that returns a successful 200 response
      // matching the AeroDataBox structure.
      final mockResponse = {
        "departures": [
          {
            "departure": {
              "scheduledTime": {
                "utc": "2026-06-25 08:20Z",
                "local": "2026-06-25 10:20+02:00"
              },
              "terminal": "IBZ",
              "gate": "05"
            },
            "arrival": {
              "airport": {
                "name": "Palma De Mallorca"
              }
            },
            "number": "UX 2052",
            "status": "Expected"
          }
        ]
      };

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      // 2. Act: Inject the mock client into our modularized service
      final service = IbizaFlightService(client: mockClient, );
      final departures = await service.fetchNextDepartures();

      // 3. Assert: Verify the model parsed correctly
      expect(departures, isA<List<IbizaDeparture>>());
      expect(departures.length, 1);
      expect(departures[0].flightNumbers.first, 'UX 2052');
      expect(departures[0].destination, 'Palma De Mallorca');
      expect(departures[0].status, 'Expected');
      expect(departures[0].gate, '05');
    });

    test('fetchNextDepartures throws an exception on API error', () async {
      // 1. Arrange: Return a 401 Unauthorized
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final service = IbizaFlightService(client: mockClient, );

      // 2 & 3. Act & Assert: Expect an exception to be thrown
      expect(() => service.fetchNextDepartures(), throwsException);
    });
  });
}

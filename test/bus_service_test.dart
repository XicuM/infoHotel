import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_hotel/models/bus_data.dart';
import 'package:info_hotel/repositories/storage_repository.dart';
import 'package:info_hotel/services/bus_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BusService Offline Data Tests', () {
    late BusService busService;
    late Directory tempDir;

    final mockBusData = {
      'version': '1.5',
      'lastUpdate': '2026-08-17T11:00:00.000Z',
      'stops': [
        {
          'id': '0001454200000001',
          'code': '108',
          'name': 'Hotel',
          'direction': 'bus_dir_port_des_torrent',
          'lines': [
            {
              'number': 'T3',
              'color': '#1E88E5',
              'textColor': '#ffffff',
              'destination': 'Port des Torrent',
              'headsign': 'Port des Torrent',
              'times': ['07:15', '07:45', '08:15']
            }
          ]
        }
      ]
    };

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('bus_service_test_');
      final file = File('${tempDir.path}/bus_timetable.json');
      await file.writeAsString(jsonEncode(mockBusData));

      final storage = StorageRepository();
      storage.initForTest(tempDir);
      busService = BusService(storage: storage);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Loads offline bus_timetable.json successfully', () async {
      await busService.init();

      expect(busService.isLoading, isFalse);
      expect(busService.error, isNull);
      expect(busService.stops.length, 1);

      final stop = busService.stops.first;
      expect(stop.id, '0001454200000001');
      expect(stop.code, '108');
      expect(stop.name, 'Hotel');
      expect(stop.lines.length, 1);

      final line = stop.lines.first;
      expect(line.number, 'T3');
      expect(line.times, ['07:15', '07:45', '08:15']);
    });
  });
}

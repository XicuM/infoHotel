import 'dart:convert';
import 'package:archive/archive.dart';
import '../models/bus_data.dart';

class GtfsParseParams {
  final List<int> zipBytes;
  final List<String> stopIds;

  GtfsParseParams({required this.zipBytes, required this.stopIds});
}

class GtfsParser {
  static const Map<String, String> routeColors = {
    '02': '#ea2423',
    '03': '#ea2423',
    '03_1': '#ea2423',
    '08': '#ea2423',
    '10': '#ea2423',
    '11': '#ea2423',
    '12A': '#ea2423',
    '12B': '#ea2423',
    '13': '#ea2423',
    '14': '#ea2423',
    '15': '#ea2423',
    '16': '#ea2423',
    '17': '#ea2423',
    '18A': '#ea2423',
    '19': '#ea2423',
    '20A': '#ea2423',
    '20B': '#ea2423',
    '25A': '#ea2423',
    '27': '#ea2423',
    '30': '#ea2423',
    '31': '#ea2423',
    '35': '#ea2423',
    '41': '#ea2423',
    '42B': '#ea2423',
    '45': '#ea2423',
    '50': '#ea2423',
    '50B': '#ea2423',
    'N03': '#ea2423',
    'N08': '#ea2423',
    'N13': '#ea2423',
    'N20': '#ea2423',
  };

  static BusServiceData parseGtfsInIsolate(GtfsParseParams params) {
    final archive = ZipDecoder().decodeBytes(params.zipBytes);

    final stopsData = <String, Map<String, dynamic>>{};
    final routesData = <String, Map<String, dynamic>>{};
    final tripsData = <String, Map<String, dynamic>>{};
    final stopTimesData = <String, List<Map<String, dynamic>>>{};

    for (final file in archive) {
      if (!file.isFile) continue;
      final content = utf8.decode(file.content as List<int>);
      final lines = const LineSplitter().convert(content);
      if (lines.isEmpty) continue;

      final rows = lines.skip(1);

      if (file.name.endsWith('stops.txt')) {
        for (final row in rows) {
          final cols = _parseCsvRow(row);
          if (cols.length > 1) {
            final stopId = cols[0];
            stopsData[stopId] = {
              'id': stopId,
              'code': cols.length > 1 ? cols[1] : '',
              'name': cols.length > 2 ? cols[2] : '',
            };
          }
        }
      } else if (file.name.endsWith('routes.txt')) {
        final headerCols = _parseCsvRow(lines.first);
        
        int routeIdIdx = headerCols.indexOf('route_id');
        int shortNameIdx = headerCols.indexOf('route_short_name');
        int longNameIdx = headerCols.indexOf('route_long_name');
        int colorIdx = headerCols.indexOf('route_color');
        int textColorIdx = headerCols.indexOf('route_text_color');
        
        if (routeIdIdx == -1) routeIdIdx = 0;
        if (shortNameIdx == -1) shortNameIdx = 2;
        if (longNameIdx == -1) longNameIdx = 3;
        if (colorIdx == -1) colorIdx = 6;
        if (textColorIdx == -1) textColorIdx = 7;
        
        for (final row in rows) {
          final cols = _parseCsvRow(row);
          if (cols.length > routeIdIdx) {
            final routeId = cols[routeIdIdx];
            final shortName = cols.length > shortNameIdx ? cols[shortNameIdx] : '';
            final longName = cols.length > longNameIdx ? cols[longNameIdx] : '';
            final color = cols.length > colorIdx ? cols[colorIdx] : '';
            final textColor = cols.length > textColorIdx ? cols[textColorIdx] : '';
            
            routesData[routeId] = {
              'route_id': routeId,
              'short_name': shortName.isNotEmpty ? shortName : longName,
              'long_name': longName,
              'color': color.isNotEmpty ? color : '#ea2423',
              'text_color': textColor.isNotEmpty ? textColor : '#ffffff',
            };
          }
        }
      } else if (file.name.endsWith('trips.txt')) {
        for (final row in rows) {
          final cols = _parseCsvRow(row);
          if (cols.length > 3) {
            final tripId = cols[2];
            tripsData[tripId] = {
              'trip_id': tripId,
              'route_id': cols[0],
              'headsign': cols.length > 3 ? cols[3] : '',
            };
          }
        }
      } else if (file.name.endsWith('stop_times.txt')) {
        for (final row in rows) {
          final cols = _parseCsvRow(row);
          if (cols.length > 4) {
            final tripId = cols[0];
            stopTimesData.putIfAbsent(tripId, () => []);
            stopTimesData[tripId]!.add({
              'trip_id': tripId,
              'arrival': cols[1],
              'departure': cols[2],
              'stop_id': cols[3],
              'sequence': cols[4],
            });
          }
        }
      }
    }

    final stops = <BusStop>[];
    for (final stopInfo in params.stopIds) {
      final stopId = stopInfo;
      final stopMeta = stopsData[stopId];
      if (stopMeta == null) continue;

      final linesForStop = <BusLine>[];
      final lineMap = <String, BusLine>{};

      for (final entry in stopTimesData.entries) {
        final tripId = entry.key;
        final stopTimes = entry.value;

        for (final st in stopTimes) {
          if (st['stop_id'] == stopId) {
            final trip = tripsData[tripId];
            if (trip == null) continue;

            final route = routesData[trip['route_id']];
            if (route == null) continue;

            var routeNum = route['short_name'] as String? ?? '';
            if (routeNum.isEmpty) {
               routeNum = route['long_name'] as String? ?? '?';
            }
            
            var headsign = trip['headsign'] as String? ?? '';
            if (headsign.isEmpty) {
              headsign = route['long_name'] as String? ?? '';
            }
            
            final cleanedDestination = _cleanDestination(headsign);

            if (stopId == '148' && cleanedDestination.contains('Sant Antoni')) {
              continue; // Do not show trips terminating at the station
            }

            final key = '${routeNum}_$headsign';

            if (!lineMap.containsKey(key)) {
              lineMap[key] = BusLine(
                number: routeNum,
                color: routeColors[routeNum] ?? route['color'] ?? '#ea2423',
                textColor: route['text_color'] ?? '#ffffff',
                destination: cleanedDestination,
                headsign: headsign,
                times: [],
              );
            }

            final time = st['departure'] as String;
            if (time.isNotEmpty && _isValidTime(time)) {
              lineMap[key]!.times.add(time);
            }
          }
        }
      }

      for (final line in lineMap.values) {
        line.times.sort();
        final uniqueTimes = <String>[];
        for (final t in line.times) {
          final shortT = t.substring(0, 5);
          if (!uniqueTimes.contains(shortT)) {
            uniqueTimes.add(shortT);
          }
        }
        linesForStop.add(BusLine(
          number: line.number,
          color: line.color,
          textColor: line.textColor,
          destination: line.destination,
          headsign: line.headsign,
          times: uniqueTimes,
        ));
      }

      linesForStop.sort((a, b) {
        final numA = int.tryParse(a.number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        final numB = int.tryParse(b.number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        if (numA != numB) return numA.compareTo(numB);
        if (a.number.contains('N') && !b.number.contains('N')) return 1;
        if (!a.number.contains('N') && b.number.contains('N')) return -1;
        return a.destination.compareTo(b.destination);
      });

      stops.add(BusStop(
        id: stopId,
        code: stopMeta['code'] ?? '',
        name: stopMeta['name'] ?? stopId,
        lines: linesForStop,
      ));
    }

    return BusServiceData(
      stops: stops,
      lastUpdate: DateTime.now(),
      version: '1.1',
    );
  }

  static String _cleanDestination(String dest) {
    if (dest.isEmpty) return dest;
    final cleaned = dest
        .replaceAll('Estació de Sant Antoni', 'Sant Antoni')
        .replaceAll('Eivissa/CETIS', 'Eivissa')
        .replaceAll('Airport', 'Aeroport');
    return cleaned;
  }

  static bool _isValidTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    return h >= 0 && h < 24 && m >= 0 && m < 60;
  }

  static List<String> _parseCsvRow(String row) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < row.length; i++) {
      final c = row[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString().trim());
    return result;
  }
}

import 'dart:convert';
import 'package:archive/archive.dart';
import '../models/bus_data.dart';

class GtfsParseParams {
  final List<int> zipBytes;
  final List<String> stopIds;
  final Map<String, String> stopNames;
  final Map<String, String> stopDirections;

  GtfsParseParams({
    required this.zipBytes,
    required this.stopIds,
    this.stopNames = const {},
    this.stopDirections = const {},
  });
}

class GtfsParser {
  // New ALSA Ibiza network (from April 2026)
  // Route codes are the short_name after stripping the 'ALSA - ' prefix.
  // T-lines (Troncals): blue — connect main towns
  // A-lines (Accessibilitat): green — connect smaller areas to hubs
  // Aero-lines: purple — airport connections
  // P-lines: orange — beach/leisure routes (Platja)
  // D-lines: dark teal — night disco/party routes
  // U-lines: cyan — urban Eivissa city routes
  // N-lines: dark navy — night services
  static const Map<String, String> routeColors = {
    // T-Lines (Troncals) — blue
    'T1': '#1565C0',
    'T2': '#1976D2',
    'T3': '#1E88E5',
    'T3-U6': '#1E88E5',
    'T4': '#2196F3',
    'T5': '#42A5F5',
    'T6': '#64B5F6',
    'T7': '#90CAF9',
    // A-Lines (Accessibilitat) — green
    'A1': '#2E7D32',
    'A2': '#388E3C',
    'A4': '#43A047',
    'A7': '#4CAF50',
    'A8': '#4CAF50',
    'A9': '#4CAF50',
    'A10': '#66BB6A',
    'A11': '#66BB6A',
    'A16': '#81C784',
    // Aero-Lines (Airport) — purple (note: lowercase 'ero' in ALSA GTFS)
    'Aero1': '#6A1B9A',
    'Aero2': '#7B1FA2',
    'Aero3': '#8E24AA',
    'Aero4': '#9C27B0',
    'Aero5': '#AB47BC',
    // P-Lines (Platja/Beach) — orange
    'P1': '#E65100',
    'P2': '#EF6C00',
    'P3': '#F57C00',
    'P4': '#FB8C00',
    'P5': '#FFA726',
    'P7': '#FFB74D',
    'P9': '#FFCC02',
    // D-Lines (Disco/Night party routes) — dark teal
    'D1': '#00695C',
    'D2': '#00796B',
    'D3': '#00897B',
    'D4': '#009688',
    'D5': '#26A69A',
    'D6': '#4DB6AC',
    // U-Lines (Urbans Eivissa) — cyan
    'U1': '#006064',
    'U2': '#00838F',
    'U4': '#0097A7',
    'U7': '#00ACC1',
    'U12': '#26C6DA',
    // Night lines — dark navy
    'N1': '#0D1B2A',
    'N2': '#1B263B',
    'N3': '#415A77',
    'N4': '#1B263B',
    'N5': '#415A77',
    'N6': '#415A77',
    // Legacy Servibus lines (kept for backward compatibility)
    '02': '#ea2423',
    '03': '#ea2423',
    '08': '#ea2423',
    '10': '#ea2423',
    '11': '#ea2423',
    '13': '#ea2423',
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
            // ALSA national GTFS prefixes all short names with 'ALSA - ' (e.g. 'ALSA - T1')
            routeNum = _cleanRouteName(routeNum);
            
            var headsign = trip['headsign'] as String? ?? '';
            if (headsign.isEmpty) {
              headsign = route['long_name'] as String? ?? '';
            }
            
            final cleanedDestination = _cleanDestination(headsign);

            // Skip trips that terminate at Sant Antoni station (new ALSA stop ID)
            if (stopId == '0001452800000001' && cleanedDestination.contains('Sant Antoni')) {
              continue;
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
        // Priority order: T → A → Aero → P → D → U → N → others
        final prefixOrder = {'T': 0, 'A': 1, 'AERO': 2, 'P': 3, 'D': 4, 'U': 5, 'N': 6};
        final prefixA = _getLinePrefix(a.number);
        final prefixB = _getLinePrefix(b.number);
        final orderA = prefixOrder[prefixA] ?? 5;
        final orderB = prefixOrder[prefixB] ?? 5;
        if (orderA != orderB) return orderA.compareTo(orderB);
        // Within same prefix, sort by trailing number
        final numA = int.tryParse(a.number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        final numB = int.tryParse(b.number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
        if (numA != numB) return numA.compareTo(numB);
        return a.destination.compareTo(b.destination);
      });

      final displayName = params.stopNames[stopId] ?? stopMeta['name'] ?? stopId;
      final direction = params.stopDirections[stopId] ?? '';

      stops.add(BusStop(
        id: stopId,
        code: stopMeta['code'] ?? '',
        name: displayName,
        direction: direction,
        lines: linesForStop,
      ));
    }

    return BusServiceData(
      stops: stops,
      lastUpdate: DateTime.now(),
      version: '1.5', // bumped from 1.4 → direction as translation keys
    );
  }

  /// Returns the alphabetic prefix of a line number (e.g. 'T' for 'T1', 'AERO' for 'AERO2').
  static String _getLinePrefix(String lineNumber) {
    final match = RegExp(r'^([A-Za-z]+)').firstMatch(lineNumber);
    return match?.group(1)?.toUpperCase() ?? '';
  }

  /// Strips provider-specific prefixes like 'ALSA - ' from route short names.
  static String _cleanRouteName(String name) {
    var clean = name.trim();
    // Remove 'ALSA - ' prefix
    if (clean.startsWith('ALSA - ')) {
      clean = clean.substring(7).trim();
    }
    return clean;
  }

  static String _cleanDestination(String dest) {
    if (dest.isEmpty) return dest;
    var cleaned = dest;
    // Strip 'ALSA - ' prefix from headsigns too
    if (cleaned.startsWith('ALSA - ')) {
      cleaned = cleaned.substring(7).trim();
    }
    // Remove route code prefix (e.g. 'T1- Sant Antoni...' → 'Sant Antoni...')
    cleaned = cleaned.replaceFirst(RegExp(r'^[A-Za-z0-9]+-\s*'), '');
    cleaned = cleaned
        .replaceAll('Estació de Sant Antoni', 'Sant Antoni')
        .replaceAll('Eivissa/CETIS', 'Eivissa (CETIS)')
        .replaceAll('Airport', 'Aeroport')
        .replaceAll("Aeroport d'Eivissa", 'Aeroport')
        .replaceAll('Ibiza Airport', 'Aeroport');
    // Title-case first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
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

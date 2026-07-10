class BusLine {
  final String number;
  final String color;
  final String textColor;
  final String destination;
  final String headsign;
  final List<String> times;

  const BusLine({
    required this.number,
    required this.color,
    required this.textColor,
    required this.destination,
    required this.headsign,
    required this.times,
  });

  String get id => '${number}_$headsign';

  factory BusLine.fromJson(Map<String, dynamic> json) {
    return BusLine(
      number: json['number'] ?? '',
      color: json['color'] ?? '#ea2423',
      textColor: json['textColor'] ?? '#ffffff',
      destination: json['destination'] ?? '',
      headsign: json['headsign'] ?? '',
      times: List<String>.from(json['times'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'color': color,
      'textColor': textColor,
      'destination': destination,
      'headsign': headsign,
      'times': times,
    };
  }
}

class BusStop {
  final String id;
  final String code;
  final String name;
  final String direction;
  final List<BusLine> lines;

  const BusStop({
    required this.id,
    required this.code,
    required this.name,
    this.direction = '',
    required this.lines,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      direction: json['direction'] ?? '',
      lines: (json['lines'] as List<dynamic>?)
              ?.map((e) => BusLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'direction': direction,
      'lines': lines.map((e) => e.toJson()).toList(),
    };
  }
}

class BusServiceData {
  final List<BusStop> stops;
  final DateTime lastUpdate;
  final String? version;

  const BusServiceData({
    required this.stops,
    required this.lastUpdate,
    this.version,
  });

  factory BusServiceData.fromJson(Map<String, dynamic> json) {
    return BusServiceData(
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => BusStop.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : DateTime.now(),
      version: json['version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stops': stops.map((e) => e.toJson()).toList(),
      'lastUpdate': lastUpdate.toIso8601String(),
      'version': version,
    };
  }
}

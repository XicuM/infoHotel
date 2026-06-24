class IbizaDeparture {
  final List<String> flightNumbers;
  final String destination;
  final DateTime scheduledTime;
  final DateTime? estimatedTime;
  final String status;
  final String gate;

  IbizaDeparture({
    required this.flightNumbers,
    required this.destination,
    required this.scheduledTime,
    this.estimatedTime,
    required this.status,
    required this.gate,
  });

  factory IbizaDeparture.fromJson(Map<String, dynamic> json) {
    DateTime? getParsedTime(String key) {
      if (json['departure']?[key]?['utc'] != null) {
        return DateTime.parse(json['departure'][key]['utc']).toLocal();
      }
      return null;
    }

    return IbizaDeparture(
      flightNumbers: [json['number'] ?? '---'],
      destination: json['arrival']?['airport']?['name'] ?? 'Unknown',
      scheduledTime: getParsedTime('scheduledTime') ?? DateTime.now(),
      estimatedTime: getParsedTime('revisedTime') ?? getParsedTime('actualTime') ?? getParsedTime('estimatedTime'),
      status: json['status'] ?? 'Scheduled',
      gate: json['departure']?['gate'] ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flightNumbers': flightNumbers,
      'destination': destination,
      'scheduledTime': scheduledTime.toIso8601String(),
      'estimatedTime': estimatedTime?.toIso8601String(),
      'status': status,
      'gate': gate,
    };
  }

  factory IbizaDeparture.fromCache(Map<String, dynamic> json) {
    return IbizaDeparture(
      flightNumbers: json['flightNumbers'] != null 
          ? List<String>.from(json['flightNumbers']) 
          : [json['flightNumber'] ?? '---'],
      destination: json['destination'] ?? 'Unknown',
      scheduledTime: DateTime.parse(json['scheduledTime']),
      estimatedTime: json['estimatedTime'] != null ? DateTime.parse(json['estimatedTime']) : null,
      status: json['status'] ?? 'Scheduled',
      gate: json['gate'] ?? '-',
    );
  }
}

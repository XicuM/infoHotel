/// Weather data models
/// Ported from scripts/weather.py data structures

class WeatherData {
  final int currentTemp;
  final String sunrise;
  final String sunset;
  final String skyState;
  final List<int> tempValues;
  final List<String> tempTimes;
  final List<DayForecast> dailyForecasts;

  WeatherData({
    required this.currentTemp,
    required this.sunrise,
    required this.sunset,
    required this.skyState,
    required this.tempValues,
    required this.tempTimes,
    required this.dailyForecasts,
  });

  factory WeatherData.fromAemetResponses(List<dynamic> hourlyData, List<dynamic> dailyData) {
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

  /// Get translation key for sky state
  String get skyStateKey => skyState
      .toLowerCase()
      .replaceAll(' y ', ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
}

class DayForecast {
  final DateTime date;
  final int maxTemp;
  final int minTemp;
  final int? uvIndex;
  final String uvColor;
  final String skyState;
  final int precipitation;
  final int windSpeed;
  final String windDirection;

  DayForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    this.uvIndex,
    required this.uvColor,
    required this.skyState,
    required this.precipitation,
    required this.windSpeed,
    required this.windDirection,
  });

  /// Get translation key for sky state
  String get skyStateKey => skyState
      .toLowerCase()
      .replaceAll(' y ', ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');

  /// Get the sky state image asset path
  String get skyStateAsset {
    return 'assets/images/weather/sky_states/$skyStateKey.png';
  }

  /// Get wind icon asset based on speed (in Beaufort scale)
  String get windAsset {
    int beaufort = 0;
    final knots = windSpeed / 1.852;
    while (beaufort < knots) {
      beaufort += 5;
    }
    return 'assets/images/weather/wind/$beaufort.png';
  }
}

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

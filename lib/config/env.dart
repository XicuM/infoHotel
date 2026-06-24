/// Environment configuration
class Env {
  /// AEMET OpenData API Key
  /// Load from build config: flutter run --dart-define=AEMET_API_KEY=your_key
  static const String aemetApiKey = String.fromEnvironment(
    'AEMET_API_KEY',
    defaultValue: '', // Supply your AEMET API Key via --dart-define
  );

  /// Base URL for AEMET API
  static const String aemetBaseUrl = 'https://opendata.aemet.es/opendata/api';
  
  /// AEMET Municipality Code (Sant Antoni de Portmany)
  static const String municipalityCode = '07046';

  /// RapidAPI Key for Aerodatabox Flight API
  /// Load from build config: flutter run --dart-define=FLIGHT_API_KEY=your_key
  static const String flightApiKey = String.fromEnvironment(
    'FLIGHT_API_KEY',
    defaultValue: '',
  );
}

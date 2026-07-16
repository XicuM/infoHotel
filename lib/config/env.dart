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

  /// NAP (National Access Point) API Key for Ibiza Bus GTFS data
  /// Load from build config: flutter run --dart-define=BUS_API_KEY=your_key
  static const String busApiKey = String.fromEnvironment(
    'BUS_API_KEY',
    defaultValue: '',
  );

  /// Proxy base URL for local web debugging (e.g. http://localhost:8080).
  /// When empty, uses the relative path /api/proxy (production Pi setup).
  /// Load from build config: flutter run --dart-define=PROXY_URL=http://localhost:8080
  static const String proxyBaseUrl = String.fromEnvironment(
    'PROXY_URL',
    defaultValue: '',
  );
}

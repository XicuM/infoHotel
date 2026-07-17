/// Application configuration and performance flags
class AppConfig {
  /// Flag to enable performance optimizations for low-power devices like Raspberry Pi 3B+.
  /// Can be set during build: flutter run --dart-define=LOW_POWER=true
  static const bool lowPowerMode = bool.fromEnvironment(
    'LOW_POWER',
    defaultValue: true,
  );

  /// When true, hotel_assets (hotels.json, markets.json, etc.) are not loaded,
  /// causing the app to fall back to baked-in defaults with no private data.
  /// Useful for screenshots and public demos.
  /// Can be set during build: flutter run --dart-define=SKIP_HOTEL_ASSETS=true
  static const bool skipHotelAssets = bool.fromEnvironment(
    'SKIP_HOTEL_ASSETS',
    defaultValue: false,
  );
}

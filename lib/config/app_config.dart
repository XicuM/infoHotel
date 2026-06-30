/// Application configuration and performance flags
class AppConfig {
  /// Flag to enable performance optimizations for low-power devices like Raspberry Pi 3B+.
  /// Can be set during build: flutter run --dart-define=LOW_POWER=true
  static const bool lowPowerMode = bool.fromEnvironment(
    'LOW_POWER',
    defaultValue: true,
  );
}

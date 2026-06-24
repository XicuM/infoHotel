import 'package:flutter/material.dart';

/// Color palette matching Material Design colors with shades
/// Ported from the Pygame prototype's utils/utils.py
class AppColors {
  // Material colors with shades
  static const Map<String, Map<int, Color>> palette = {
    'red': {
      50: Color(0xFFFFEBEE),
      100: Color(0xFFFFCDD2),
      200: Color(0xFFEF9A9A),
      300: Color(0xFFE57373),
      400: Color(0xFFEF5350),
      500: Color(0xFFF44336),
      600: Color(0xFFE53935),
      700: Color(0xFFD32F2F),
      800: Color(0xFFC62828),
      900: Color(0xFFB71C1C),
    },
    'green': {
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50),
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
    'blue': {
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
    'purple': {
      50: Color(0xFFF3E5F5),
      100: Color(0xFFE1BEE7),
      200: Color(0xFFCE93D8),
      300: Color(0xFFBA68C8),
      400: Color(0xFFAB47BC),
      500: Color(0xFF9C27B0),
      600: Color(0xFF8E24AA),
      700: Color(0xFF7B1FA2),
      800: Color(0xFF6A1B9A),
      900: Color(0xFF4A148C),
    },
    'grey': {
      50: Color(0xFFFAFAFA),
      100: Color(0xFFF5F5F5),
      200: Color(0xFFEEEEEE),
      300: Color(0xFFE0E0E0),
      400: Color(0xFFBDBDBD),
      500: Color(0xFF9E9E9E),
      600: Color(0xFF757575),
      700: Color(0xFF616161),
      800: Color(0xFF424242),
      900: Color(0xFF212121),
    },
    'orange': {
      50: Color(0xFFFFF3E0),
      100: Color(0xFFFFE0B2),
      200: Color(0xFFFFCC80),
      300: Color(0xFFFFB74D),
      400: Color(0xFFFFA726),
      500: Color(0xFFFF9800),
      600: Color(0xFFFB8C00),
      700: Color(0xFFF57C00),
      800: Color(0xFFEF6C00),
      900: Color(0xFFE65100),
    },
    'amber': {
      50: Color(0xFFFFF8E1),
      100: Color(0xFFFFECB3),
      200: Color(0xFFFFE082),
      300: Color(0xFFFFD54F),
      400: Color(0xFFFFCA28),
      500: Color(0xFFFFC107),
      600: Color(0xFFFFB300),
      700: Color(0xFFFFA000),
      800: Color(0xFFFF8F00),
      900: Color(0xFFFF6F00),
    },
    'light green': {
      50: Color(0xFFF1F8E9),
      100: Color(0xFFDCEDC8),
      200: Color(0xFFC5E1A5),
      300: Color(0xFFAED581),
      400: Color(0xFF9CCC65),
      500: Color(0xFF8BC34A),
      600: Color(0xFF7CB342),
      700: Color(0xFF689F38),
      800: Color(0xFF558B2F),
      900: Color(0xFF33691E),
    },
  };

  /// Get a color by name and shade
  static Color get(String name, [int shade = 500]) {
    final colorName = name.toLowerCase();
    if (palette.containsKey(colorName)) {
      return palette[colorName]![shade] ?? palette[colorName]![500]!;
    }
    // Handle simple color names
    switch (colorName) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  // Primary section colors
  static Color get yellowSecondary => const Color(0xFFF7CF29);
  static Color get services => get('green', 400);
  static Color get servicesLight => get('green', 100);
  static Color get information => get('red', 400);
  static Color get informationLight => get('red', 100);
  static Color get excursions => get('purple', 400);
  static Color get excursionsLight => get('purple', 100);
  static Color get weather => get('blue', 400);
  static Color get weatherLight => get('blue', 100);

  /// Filter for inverting colors of maps in dark mode
  static const ColorFilter darkMapFilter = ColorFilter.matrix([
    -1.0, 0.0, 0.0, 0.0, 255.0, //
    0.0, -1.0, 0.0, 0.0, 255.0, //
    0.0, 0.0, -1.0, 0.0, 255.0, //
    0.0, 0.0, 0.0, 1.0, 0.0, //
  ]);

}

/// App theme configuration
class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: 64),
      displayMedium: base.displayMedium?.copyWith(fontSize: 52),
      displaySmall: base.displaySmall?.copyWith(fontSize: 44),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 40),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 36),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 32),
      titleLarge: base.titleLarge?.copyWith(fontSize: 28),
      titleMedium: base.titleMedium?.copyWith(fontSize: 24),
      titleSmall: base.titleSmall?.copyWith(fontSize: 20),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 20),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 18),
      bodySmall: base.bodySmall?.copyWith(fontSize: 16),
      labelLarge: base.labelLarge?.copyWith(fontSize: 18),
      labelMedium: base.labelMedium?.copyWith(fontSize: 16),
      labelSmall: base.labelSmall?.copyWith(fontSize: 14),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.get('blue', 500),
        brightness: Brightness.light,
      ),
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.get('blue', 500),
        brightness: Brightness.dark,
        surface: const Color(0xB31E1E1E), // Semi-transparent dark surface (~70%)
      ),
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0x80000000), // Semi-transparent black for cards
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Color(0x40FFFFFF),
      ),
    );
  }
}

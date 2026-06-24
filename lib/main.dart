import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/language_service.dart';
import 'services/weather_service.dart';
import 'services/hotel_service.dart';
import 'services/content_service.dart';
import 'views/main_layout.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize multiple locales for the intl package
  await Future.wait([
    initializeDateFormatting('en', null),
    initializeDateFormatting('es', null),
    initializeDateFormatting('de', null),
    initializeDateFormatting('fr', null),
    initializeDateFormatting('it', null),
    initializeDateFormatting('nl', null),
  ]);
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Set preferred orientations for kiosk mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI for kiosk mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const InfoHotelApp());
}

class InfoHotelApp extends StatelessWidget {
  const InfoHotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HotelService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => WeatherService()),
        ChangeNotifierProvider(create: (_) => ContentService()..init()),
      ],
      child: MaterialApp(
        title: 'Info Hotel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Force dark mode for new UI
        home: const MainLayout(),
      ),
    );
  }
}

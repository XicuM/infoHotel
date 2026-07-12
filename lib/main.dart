import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/language_service.dart';
import 'services/weather_service.dart';
import 'services/hotel_service.dart';
import 'services/content_service.dart';
import 'services/market_service.dart';
import 'services/excursion_service.dart';
import 'services/show_service.dart';
import 'services/beach_service.dart';
import 'services/hotel_config_service.dart';
import 'repositories/storage_repository.dart';
import 'services/bus_service.dart';
import 'views/main_layout.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'config/http_overrides.dart';

import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  setupHttpOverrides();

  try {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    debugPrint('----------------------------------------');
    debugPrint('INFO_HOTEL_VERSION: ${packageInfo.version}+${packageInfo.buildNumber}');
    debugPrint('----------------------------------------');
  } catch (e) {
    debugPrint('Failed to get package info: $e');
  }

  final storage = StorageRepository();
  await storage.init();

  // Initialize multiple locales for the intl package
  await Future.wait([
    initializeDateFormatting('en', null),
    initializeDateFormatting('es', null),
    initializeDateFormatting('de', null),
    initializeDateFormatting('fr', null),
    initializeDateFormatting('it', null),
    initializeDateFormatting('nl', null),
  ]);
  if (!kIsWeb) {
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
  }

  // Set preferred orientations for kiosk mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(InfoHotelApp(storage: storage));
}

class InfoHotelApp extends StatelessWidget {
  final StorageRepository storage;
  
  const InfoHotelApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HotelService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => WeatherService()),
        ChangeNotifierProvider(create: (_) => ContentService(storage: storage)),
        ChangeNotifierProvider(create: (_) => MarketService(storage: storage)..init()),
        ChangeNotifierProvider(create: (_) => ExcursionService(storage: storage)..init()),
        ChangeNotifierProvider(create: (_) => ShowService(storage: storage)..init()),
        ChangeNotifierProvider(create: (_) => BeachService(storage: storage)..init()),
        ChangeNotifierProvider(create: (_) => HotelConfigService(storage: storage)..init()),
        ChangeNotifierProvider(create: (_) => BusService()),
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

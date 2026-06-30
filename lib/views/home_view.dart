import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/app_config.dart';
import '../services/language_service.dart';
import '../services/weather_service.dart';
import '../widgets/navigation_button.dart';
import 'services/services_view.dart';
import 'information/information_view.dart';
import 'excursions/excursions_view.dart';
import 'weather/weather_view.dart';
import 'webpages_view.dart';
import 'information/flight_board_view.dart';
import '../widgets/app_image.dart';
import 'package:window_manager/window_manager.dart';

/// Modernized Home screen for the hotel kiosk
class HomeView extends StatefulWidget {
  final String hotel;

  const HomeView({
    super.key,
    this.hotel = 'Savines',
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            AppImage(path: 
              widget.hotel == 'Savines'
                  ? 'assets/images/background/savines.jpg'
                  : 'assets/images/background/arenal.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black87),
            ),
            
            // Dark Gradient Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    children: [
                      // Navigation Menu
                      Expanded(
                        flex: 1,
                        child: _buildNavigationMenu(),
                      ),
                      // Weather & Touch Info
                      Expanded(
                        flex: 1,
                        child: _buildInfoPanel(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant Hotel Logo
          AppImage(path: 
            widget.hotel == 'Savines'
                ? 'assets/images/logo/savines.png'
                : 'assets/images/logo/arenal.png',
            height: 90,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                widget.hotel.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                ),
              );
            },
          ),

          // Premium Clock
          const _HomeClockWidget(),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Consumer2<WeatherService, LanguageService>(
      builder: (context, weatherService, langService, child) {
        final weather = weatherService.weatherData;

        return Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Weather Card
              if (weather != null)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: AppConfig.lowPowerMode ? null : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${weather.currentTemp}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 96,
                              fontWeight: FontWeight.w200,
                              height: 1.0,
                            ),
                          ),
                          if (weather.skyState.isNotEmpty)
                            Text(
                              langService.translate(weather.skyStateKey).toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Optional: A dynamic weather icon could go here if we had mapping
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 80,
                        color: Colors.amber.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 60),

              // Touch Screen Hint - Pill shape
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      langService.translate('touch_screen').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppImage(path: 
                      'assets/images/touch.png',
                      width: 32,
                      height: 32,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.touch_app, size: 32, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationMenu() {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NavigationButton(
            titleKey: 'hotel_services',
            color: AppColors.services,
            icon: Icons.room_service,
            onTap: () => _navigateTo(const ServicesView()),
          ),
          const SizedBox(height: 12),
          NavigationButton(
            titleKey: 'tourist_info',
            color: AppColors.information,
            icon: Icons.map,
            onTap: () => _navigateTo(const InformationView()),
          ),
          const SizedBox(height: 12),
          NavigationButton(
            titleKey: 'excursions',
            color: AppColors.excursions,
            icon: Icons.directions_bus,
            onTap: () => _navigateTo(const ExcursionsView()),
          ),
          const SizedBox(height: 12),
          NavigationButton(
            titleKey: 'weather',
            color: AppColors.weather,
            icon: Icons.wb_sunny,
            onTap: () => _navigateTo(const WeatherView()),
          ),
          const SizedBox(height: 12),
          NavigationButton(
            titleKey: 'flight_board',
            color: Colors.black87,
            icon: Icons.flight_takeoff,
            onTap: () => _navigateTo(const FlightBoardView()),
          ),
          const SizedBox(height: 12),
          NavigationButton(
            titleKey: 'webpages',
            color: Colors.white,
            icon: Icons.public,
            onTap: () => _navigateTo(const WebpagesView()),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

class _HomeClockWidget extends StatefulWidget {
  const _HomeClockWidget();

  @override
  State<_HomeClockWidget> createState() => _HomeClockWidgetState();
}

class _HomeClockWidgetState extends State<_HomeClockWidget> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    final interval = AppConfig.lowPowerMode ? const Duration(seconds: 30) : const Duration(seconds: 10);
    _timer = Timer.periodic(interval, (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: AppConfig.lowPowerMode ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Text(
        _formatTime(_currentTime),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.w200,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

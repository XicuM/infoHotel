import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/language_service.dart';
import '../services/weather_service.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 80), // Premium spacing from the right
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Welcome Text
                  Consumer<LanguageService>(
                    builder: (context, langService, _) {
                      return Text(
                        langService.translate('welcome'),
                        style: const TextStyle(
                          fontSize: 60, // Slightly smaller for more modern look
                          fontWeight: FontWeight.w100,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      );
                    },
                  ),

                  // Clock & Date
                  const _WelcomeClockWidget(),

                  const SizedBox(height: 80), // More breathing room

                  // Weather
                  Consumer<WeatherService>(
                    builder: (context, weatherService, _) {
                      final weather = weatherService.weatherData;
                      if (weather == null) {
                        return const SizedBox.shrink();
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Weather Icon
                           const Icon(
                             Icons.wb_sunny_rounded, 
                             size: 48, 
                             color: Colors.white, // All white
                           ),
                           
                           const SizedBox(width: 24),

                           // Temperature and state
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.end,
                             children: [
                                Text(
                                 '${weather.currentTemp}°',
                                 style: const TextStyle(
                                   fontSize: 56,
                                   fontWeight: FontWeight.w300,
                                   color: Colors.white, // All white
                                 ),
                               ),
                                if (weather.skyState.isNotEmpty)
                                  Consumer<LanguageService>(
                                    builder: (context, langService, _) {
                                      return Text(
                                        langService.translate(weather.skyStateKey),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white70,
                                        ),
                                      );
                                    },
                                  ),
                             ],
                           ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeClockWidget extends StatefulWidget {
  const _WelcomeClockWidget();

  @override
  State<_WelcomeClockWidget> createState() => _WelcomeClockWidgetState();
}

class _WelcomeClockWidgetState extends State<_WelcomeClockWidget> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
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

  String _formatDate(DateTime time, LanguageService langService) {
    try {
      String locale = langService.currentLanguage;
      return DateFormat.yMMMMEEEEd(locale).format(time);
    } catch (e) {
      return DateFormat.yMMMMEEEEd('en').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(_currentTime),
          style: const TextStyle(
            fontSize: 160,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: -5,
            height: 1.0, 
          ),
        ),
        Text(
          _formatDate(_currentTime, langService),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

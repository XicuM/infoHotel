import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/language_service.dart';
import '../../services/weather_service.dart';
import '../../models/weather_data.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/language_bar.dart';
import '../../widgets/app_image.dart';

/// Weather view showing forecast data from AEMET
/// Ported from layout/weather.py and scripts/weather.py
class WeatherView extends StatefulWidget {
  const WeatherView({super.key});

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView> {
  @override
  void initState() {
    super.initState();
    // Refresh weather on view open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherService>().fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'weather',
        backgroundColor: AppColors.weather,
        actions: [
          _buildWeatherHeader(),
        ],
      ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: Consumer<WeatherService>(
              builder: (context, weatherService, child) {
                if (weatherService.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (weatherService.error != null) {
                  return Center(
                    child: Text(
                      weatherService.error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final weather = weatherService.weatherData;
                if (weather == null) {
                  return const Center(
                    child: Text(
                      'No weather data available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return _buildWeatherContent(weather);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherHeader() {
    return Consumer<WeatherService>(
      builder: (context, weatherService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<LanguageService>(
                builder: (context, langService, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        langService.translate('last_update'),
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      if (weatherService.lastUpdate != null)
                        Text(
                          '${weatherService.lastUpdate!.hour}:${weatherService.lastUpdate!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 12),
              AppImage(path: 
                'assets/images/weather/aemet.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherContent(WeatherData weather) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel - Today's details
          Expanded(
            flex: 2,
            child: _buildTodayPanel(weather),
          ),

          const SizedBox(width: 16),

          // Right panel - Weekly forecast
          Expanded(
            flex: 3,
            child: _buildWeeklyForecast(weather),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPanel(WeatherData weather) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.55),
            Colors.black.withOpacity(0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // UV Index
          _buildUvIndex(weather),

          const SizedBox(height: 24),

          // Sun arc with sunrise/sunset
          _buildSunArc(weather),

          const SizedBox(height: 24),

          // Temperature graph
          Expanded(
            child: _buildTempGraph(weather),
          ),
        ],
      ),
    );
  }

  Widget _buildUvIndex(WeatherData weather) {
    DayForecast? targetForecast;
    for (var f in weather.dailyForecasts) {
      if (f.uvIndex != null && f.uvIndex! > 0) {
        targetForecast = f;
        break;
      }
    }
    targetForecast ??= weather.dailyForecasts.isNotEmpty
        ? weather.dailyForecasts[0]
        : null;

    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // UV gradient capsule bar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Row(
                children: [
                  _uvColorBox('light green', 400),
                  _uvColorBox('amber', 400),
                  _uvColorBox('orange', 400),
                  _uvColorBox('red', 400),
                  _uvColorBox('purple', 400),
                ],
              ),
            ),
            // UV value display
            if (targetForecast != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.get(targetForecast.uvColor, 700),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          langService.translate('uv_index'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          targetForecast.uvIndex != null ? '${targetForecast.uvIndex}' : '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _uvColorBox(String color, int shade) {
    return Expanded(
      child: Container(
        height: 10,
        color: AppColors.get(color, shade),
      ),
    );
  }

  Widget _buildSunArc(WeatherData weather) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return Column(
          children: [
            // Sun arc visualization
            SizedBox(
              height: 100,
              child: CustomPaint(
                size: const Size(200, 100),
                painter: SunArcPainter(
                  sunrise: weather.sunrise,
                  sunset: weather.sunset,
                ),
              ),
            ),
            // Sunrise/sunset times
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langService.translate('sunrise'),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      weather.sunrise,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      langService.translate('sunset'),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      weather.sunset,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTempGraph(WeatherData weather) {
    if (weather.tempValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size.infinite,
      painter: TempGraphPainter(
        tempValues: weather.tempValues,
        tempTimes: weather.tempTimes,
      ),
    );
  }

  Widget _buildWeeklyForecast(WeatherData weather) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: weather.dailyForecasts.length,
          itemBuilder: (context, index) {
            final forecast = weather.dailyForecasts[index];
            return _buildDayCard(forecast, index, langService);
          },
        );
      },
    );
  }

  Widget _buildDayCard(
      DayForecast forecast, int index, LanguageService langService) {
    String dayName;
    if (index == 0) {
      dayName = langService.translate('today');
    } else if (index == 1) {
      dayName = langService.translate('tomorrow');
    } else {
      dayName = langService.getWeekday(forecast.date.weekday - 1);
    }

    final isToday = index == 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isToday
              ? [
                  Colors.white.withOpacity(0.18),
                  Colors.black.withOpacity(0.5),
                ]
              : [
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? Colors.white30 : Colors.white10,
          width: isToday ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Day name
          Text(
            dayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? Colors.white : Colors.white70,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 6),

          // Sky state icon
          Expanded(
            child: AppImage(path: 
              forecast.skyStateAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.cloud, size: 48, color: Colors.white54),
            ),
          ),

          const SizedBox(height: 6),

          // Temperature — styled pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TempChip(
                value: '${forecast.maxTemp}°',
                color: const Color(0xFFEF5350),
              ),
              const SizedBox(width: 6),
              _TempChip(
                value: '${forecast.minTemp}°',
                color: const Color(0xFF42A5F5),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Precipitation
          _WeatherStat(
            icon: Icons.umbrella,
            label: '${forecast.precipitation}%',
          ),

          const SizedBox(height: 2),

          // Wind
          _WeatherStat(
            icon: Icons.air,
            label: '${forecast.windSpeed}',
          ),
        ],
      ),
    );
  }
}

class _TempChip extends StatelessWidget {
  final String value;
  final Color color;

  const _TempChip({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WeatherStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

/// Custom painter for sun arc visualization
class SunArcPainter extends CustomPainter {
  final String sunrise;
  final String sunset;

  SunArcPainter({required this.sunrise, required this.sunset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    // Draw arc
    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
      pi,
      pi,
      false,
      paint,
    );

    // Calculate sun position based on current time
    final now = DateTime.now();
    final sunriseMinutes = _parseTime(sunrise);
    final sunsetMinutes = _parseTime(sunset);
    final nowMinutes = now.hour * 60 + now.minute;

    if (nowMinutes >= sunriseMinutes && nowMinutes <= sunsetMinutes) {
      final progress =
          (nowMinutes - sunriseMinutes) / (sunsetMinutes - sunriseMinutes);
      final angle = pi + (progress * pi);
      final sunX = center.dx + radius * cos(angle);
      final sunY = center.dy + radius * sin(angle);

      // Draw sun
      final sunPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(sunX, sunY), 12, sunPaint);
    }
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for temperature graph
class TempGraphPainter extends CustomPainter {
  final List<int> tempValues;
  final List<String> tempTimes;

  TempGraphPainter({required this.tempValues, required this.tempTimes});

  @override
  void paint(Canvas canvas, Size size) {
    if (tempValues.isEmpty) return;

    final tMin = tempValues.reduce(min);
    final tMax = tempValues.reduce(max);
    // Add padding to range
    final range = tMax - tMin + 4;
    // Prevent division by zero
    final meaningfulRange = range == 0 ? 1.0 : range.toDouble();

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final axisPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final path = Path();

    // Padding settings
    const leftPad = 30.0;
    const bottomPad = 25.0;
    final graphW = size.width - leftPad;
    final graphH = size.height - bottomPad;

    // Draw Y Axis Grid & Labels (Min, Mid-low, Mid, Mid-high, Max)
    // We'll draw 6 lines
    for (int i = 0; i <= 5; i++) {
        final ratio = i / 5.0; // 0.0, 0.2, 0.4, 0.6, 0.8, 1.0
        final y = graphH - (ratio * graphH);
        
        // Draw horizontal grid line
        canvas.drawLine(
            Offset(leftPad, y), 
            Offset(size.width, y), 
            axisPaint
        );

        // Calculate temp value for this line
        final val = ((graphH - y) / graphH * range) - 2 + tMin;
        
        textPainter.text = TextSpan(
            text: '${val.round()}°', 
            style: const TextStyle(color: Colors.white70, fontSize: 10)
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Plot Points
    for (var i = 0; i < tempValues.length; i++) {
      // X coordinate
      final x = leftPad + (i / (tempValues.length - 1)) * graphW;
      
      // Y coordinate
      // We normalize: tMin - 2 to tMax + 2
      final y = graphH -
          ((tempValues[i] - tMin + 2) / meaningfulRange) * graphH;
          
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw X Axis Labels (Time)
      // Show every 4th label to avoid clutter
      if (tempValues.length < 12 || i % 4 == 0) {
          if (i < tempTimes.length) {
              textPainter.text = TextSpan(
                  text: tempTimes[i], 
                  style: const TextStyle(color: Colors.white70, fontSize: 10)
              );
              textPainter.layout();
              textPainter.paint(
                  canvas, 
                  Offset(x - textPainter.width/2, size.height - 15)
              );
          }
      }
    }

    // Draw graph line
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

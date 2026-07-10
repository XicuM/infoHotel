import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../services/language_service.dart';
import '../../services/weather_service.dart';
import '../../models/weather_data.dart';
import '../../widgets/app_bar_widget.dart';
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
                final weather = weatherService.weatherData;
                
                if (weatherService.isLoading && weather == null) {
                  return const Center(
                    child: AppConfig.lowPowerMode 
                        ? Icon(Icons.hourglass_empty, color: Colors.white, size: 36) 
                        : CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (weather == null) {
                  return Center(
                    child: Text(
                      weatherService.error ?? 'No weather data available',
                      style: const TextStyle(color: Colors.white),
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
            color: Colors.grey[850],
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
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      if (weatherService.lastUpdate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (weatherService.error != null)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                              ),
                            Text(
                              '${weatherService.lastUpdate!.hour}:${weatherService.lastUpdate!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 12),
              Transform.scale(
                scale: 1.4,
                child: AppImage(
                  path: 'assets/images/weather/aemet.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row with Today/Conditions on the left, and Sun Arc on the right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Today + Current Conditions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<LanguageService>(
                      builder: (context, langService, child) {
                        return Text(
                          langService.translate('today').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCurrentConditions(weather),
                  ],
                ),
              ),
              // Right: Sun Arc
              _buildSunArc(weather),
            ],
          ),

          const SizedBox(height: 20),

          // Temperature graph
          Expanded(
            child: _buildTempGraph(weather),
          ),

          const SizedBox(height: 20),

          // UV Index on bottom
          _buildUvIndex(weather),
        ],
      ),
    );
  }

  Widget _buildCurrentConditions(WeatherData weather) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppImage(
              path: 'assets/images/weather/sky_states/${weather.skyStateKey}.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.cloud, size: 80, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.currentTemp}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    weather.skyState.isNotEmpty 
                        ? langService.translate(weather.skyStateKey) 
                        : '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return SizedBox(
          width: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sun arc visualization
              Center(
                child: SizedBox(
                  height: 120,
                  width: 120,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(120, 120),
                      painter: SunArcPainter(
                        sunrise: weather.sunrise,
                        sunset: weather.sunset,
                        currentMinutes: nowMinutes,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        langService.translate('sunrise'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        weather.sunrise,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        langService.translate('sunset'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        weather.sunset,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTempGraph(WeatherData weather) {
    if (weather.tempValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: TempGraphPainter(
          tempValues: weather.tempValues,
          tempTimes: weather.tempTimes,
        ),
      ),
    );
  }

  Widget _buildWeeklyForecast(WeatherData weather) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        // Skip today (index 0) and take up to 6 days to form a 2x3 grid
        final futureForecasts = weather.dailyForecasts.skip(1).take(6).toList();

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: futureForecasts.length,
          itemBuilder: (context, index) {
            final forecast = futureForecasts[index];
            // Pass index + 1 so 'Tomorrow' logic (index == 1) still works correctly
            return _buildDayCard(forecast, index + 1, langService);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: _getWindAngle(forecast.windDirection),
                child: const Icon(Icons.arrow_upward, size: 14, color: Colors.white54),
              ),
              const SizedBox(width: 4),
              Text(
                '${forecast.windSpeed}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getWindAngle(String dir) {
    switch (dir) {
      case 'N': return 0;
      case 'NE': return pi / 4;
      case 'E': return pi / 2;
      case 'SE': return 3 * pi / 4;
      case 'S': return pi;
      case 'SO': return 5 * pi / 4;
      case 'O': return 3 * pi / 2;
      case 'NO': return 7 * pi / 4;
      default: return 0;
    }
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

/// Custom painter for full day/night 24h circle
class SunArcPainter extends CustomPainter {
  final String sunrise;
  final String sunset;
  final int currentMinutes;

  SunArcPainter({
    required this.sunrise,
    required this.sunset,
    required this.currentMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;

    final nightPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
      
    final dayPaint = Paint()
      ..color = Colors.amber.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    // Draw full 24h circle (Night)
    canvas.drawCircle(center, radius, nightPaint);

    final sunriseMinutes = _parseTime(sunrise);
    final sunsetMinutes = _parseTime(sunset);

    // Calculate angles
    // 00:00 -> bottom (pi/2)
    // 06:00 -> left (pi)
    // 12:00 -> top (-pi/2)
    // 18:00 -> right (0)
    // Map time in minutes to angle: angle = (minutes / (24*60)) * 2*pi + pi/2
    double getAngle(int minutes) {
      return (minutes / (24.0 * 60.0)) * 2 * pi + pi / 2;
    }

    final startAngle = getAngle(sunriseMinutes);
    final endAngle = getAngle(sunsetMinutes);
    double sweepAngle = endAngle - startAngle;
    if (sweepAngle < 0) sweepAngle += 2 * pi;

    // Draw day arc
    canvas.drawArc(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
      startAngle,
      sweepAngle,
      false,
      dayPaint,
    );

    // Calculate sun/moon position
    final nowAngle = getAngle(currentMinutes);

    final isDay = currentMinutes >= sunriseMinutes && currentMinutes <= sunsetMinutes;
    
    final iconRadius = radius;
    final iconX = center.dx + iconRadius * cos(nowAngle);
    final iconY = center.dy + iconRadius * sin(nowAngle);

    if (isDay) {
      // Draw sun
      final sunPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(iconX, iconY), 8, sunPaint);
      final glowPaint = Paint()
        ..color = Colors.amber.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(iconX, iconY), 12, glowPaint);
    } else {
      // Draw moon (crescent)
      final moonPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(iconX, iconY), 7, moonPaint);
      
      final shadowPaint = Paint()
        ..color = Colors.black45
        ..blendMode = BlendMode.srcOver
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(iconX + 3, iconY - 3), 6, shadowPaint);
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
  bool shouldRepaint(covariant SunArcPainter oldDelegate) {
    return oldDelegate.sunrise != sunrise ||
        oldDelegate.sunset != sunset ||
        oldDelegate.currentMinutes != currentMinutes;
  }
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
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.amber.withOpacity(0.5),
          Colors.amber.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final path = Path();
    final fillPath = Path();

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
            style: const TextStyle(color: Colors.white70, fontSize: 14)
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Plot Points with Bezier curves
    final points = <Offset>[];
    for (var i = 0; i < tempValues.length; i++) {
      final x = leftPad + (i / (tempValues.length - 1)) * graphW;
      final y = graphH - ((tempValues[i] - tMin + 2) / meaningfulRange) * graphH;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, points[0].dy);
      
      for (var i = 1; i < points.length; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final controlX = (p0.dx + p1.dx) / 2;
        
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      // Close fill path
      fillPath.lineTo(points.last.dx, graphH);
      fillPath.lineTo(points.first.dx, graphH);
      fillPath.close();

      // Draw gradient fill
      canvas.drawPath(fillPath, fillPaint);
      
      // Draw smooth line
      canvas.drawPath(path, paint);

      // Draw Time Labels
      for (var i = 0; i < points.length; i++) {
        if (tempValues.length < 12 || i % 4 == 0) {
          if (i < tempTimes.length) {
            textPainter.text = TextSpan(
              text: tempTimes[i], 
              style: const TextStyle(color: Colors.white70, fontSize: 14)
            );
            textPainter.layout();
            textPainter.paint(
              canvas, 
              Offset(points[i].dx - textPainter.width/2, size.height - 15)
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TempGraphPainter oldDelegate) {
    if (oldDelegate.tempValues.length != tempValues.length ||
        oldDelegate.tempTimes.length != tempTimes.length) {
      return true;
    }
    for (int i = 0; i < tempValues.length; i++) {
      if (oldDelegate.tempValues[i] != tempValues[i]) return true;
    }
    for (int i = 0; i < tempTimes.length; i++) {
      if (oldDelegate.tempTimes[i] != tempTimes[i]) return true;
    }
    return false;
  }
}

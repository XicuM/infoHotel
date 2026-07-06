import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/content_service.dart';
import '../../services/hotel_config_service.dart';
import '../../services/show_service.dart';
import '../../models/hotel_config.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/app_image.dart';

class ShowsView extends StatelessWidget {
  const ShowsView({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    final isOddWeek = weekNumber % 2 == 1;

    return Consumer3<ContentService, HotelConfigService, ShowService>(
      builder: (context, contentService, hotelConfigService, showService, child) {
        final isEditMode = contentService.isEditMode;
        final hotelConfigs = hotelConfigService.sortedHotelConfigs;
        if (hotelConfigs.length < 2) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            titleKey: 'shows',
            backgroundColor: Colors.transparent,
            titleColor: Colors.white,
            onBack: () => Navigator.of(context).pop(),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                path: showService.getShowImage('background'),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[900]);
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              if (isEditMode)
                Positioned(
                  top: 100,
                  right: 20,
                  child: FloatingActionButton.extended(
                    heroTag: 'editBg',
                    onPressed: () => _pickImage(context, 'background', contentService),
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Background'),
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: _buildShowsGrid(context, isOddWeek, contentService, showService, hotelConfigs),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShowsGrid(BuildContext context, bool isOddWeek, ContentService contentService, ShowService showService, List<HotelConfig> hotelConfigs) {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxItemHeight = constraints.maxHeight;
            final widthFromHeight = (maxItemHeight - 110) / 1.4142;
            final widthFromWidth = (constraints.maxWidth - 40) / 7 - 8;
            final cardWidth = widthFromHeight < widthFromWidth ? widthFromHeight : widthFromWidth;

            Widget buildItem(int index) {
              final day = days[index];
              final hotelIndex = (index + (isOddWeek ? 1 : 0)) % 2;
              final currentHotel = hotelConfigs[hotelIndex % hotelConfigs.length];
              final isToday = DateTime.now().weekday == index + 1;

              return SizedBox(
                width: cardWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isToday ? Colors.amber.withValues(alpha: 0.9) : Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isToday ? Colors.amberAccent : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          langService.getWeekday(index).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isToday ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    // Show image poster
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1 / 1.4142, // A4 ratio
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppImage(
                                path: showService.getShowImage(days[index].toLowerCase()),
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.black45,
                                    child: const Icon(Icons.theater_comedy, size: 48, color: Colors.white30),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // Edit Mode Overlay
                          if (contentService.isEditMode)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white, size: 32),
                                  onPressed: () => _pickImage(context, day, contentService),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Venue indicator tag
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AppImage(
                          path: currentHotel.showsLogo,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currentHotel.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(7, (index) => buildItem(index)),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, String dayKey, ContentService contentService) async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (result != null && (result.files.single.path != null || kIsWeb)) {
      final newPath = await contentService.saveImage(
        result.files.single.path ?? '',
        subFolder: 'shows',
        bytes: result.files.single.bytes,
        originalName: result.files.single.name,
      );
      context.read<ShowService>().updateShowImage(dayKey, newPath);
    }
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}

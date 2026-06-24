import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/content_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/app_image.dart';

/// Modernized Shows view displaying weekly entertainment schedule
class ShowsView extends StatelessWidget {
  const ShowsView({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    final isOddWeek = weekNumber % 2 == 1;

    return Consumer<ContentService>(
      builder: (context, contentService, child) {
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
              // Background shows image
              AppImage(
                path: contentService.getShowImage('background'),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[900]);
                },
              ),
              
              // Dark Glass Gradient Overlay
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
              
              // Edit Background Button
              if (contentService.isEditMode)
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

              // Content Layout
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: _buildShowsGrid(context, isOddWeek, contentService),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShowsGrid(BuildContext context, bool isOddWeek, ContentService contentService) {
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
            final maxItemHeight = (constraints.maxHeight - 40) / 2;
            final widthFromHeight = (maxItemHeight - 150) / 1.4142;
            final widthFromWidth = constraints.maxWidth / 4 - 32;
            final cardWidth = widthFromHeight < widthFromWidth ? widthFromHeight : widthFromWidth;
            
            Widget buildItem(int index) {
              final day = days[index];
              final isSavines = (index + (isOddWeek ? 1 : 0)) % 2 == 1;
              final isToday = DateTime.now().weekday == index + 1;

              return SizedBox(
                width: cardWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    // Day Name Badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isToday ? Colors.amber.withValues(alpha: 0.9) : Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isToday ? Colors.amberAccent : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        langService.getWeekday(index).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: 1.0,
                          color: isToday ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Show image poster
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1 / 1.4142, // A4 ratio
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AppImage(
                                path: contentService.getShowImage(day),
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.black45,
                                    child: const Icon(Icons.theater_comedy, size: 64, color: Colors.white30),
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white, size: 40),
                                  onPressed: () => _pickImage(context, day, contentService),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Venue indicator tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AppImage(
                        path: isSavines
                            ? 'assets/images/shows/savines.png'
                            : 'assets/images/shows/arenal.png',
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            isSavines ? 'Savines' : 'Arenal',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(4, (index) => buildItem(index)),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(3, (index) => buildItem(index + 4)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, String key, ContentService contentService) async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final newPath = await contentService.saveImage(result.files.single.path!, subFolder: 'shows');
      await contentService.updateShowImage(key, newPath);
    }
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}

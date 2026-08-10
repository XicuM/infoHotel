import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/content_service.dart';
import '../../services/hotel_config_service.dart';
import '../../services/hotel_service.dart';
import '../../services/show_service.dart';
import '../../models/hotel_config.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/app_image.dart';
import '../../widgets/asset_image_picker_modal.dart';

class ShowsView extends StatefulWidget {
  const ShowsView({super.key});

  @override
  State<ShowsView> createState() => _ShowsViewState();
}

class _ShowsViewState extends State<ShowsView> {
  static const days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  late int _selectedWeek;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    _selectedWeek = weekNumber % 2 == 1 ? 1 : 2;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ContentService, HotelConfigService, ShowService>(
      builder: (context, contentService, hotelConfigService, showService, child) {
        final isEditMode = contentService.isEditMode;
        final hotelConfigs = hotelConfigService.sortedHotelConfigs;
        final hotelService = Provider.of<HotelService>(context);
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            titleKey: 'shows',
            backgroundColor: Colors.transparent,
            titleColor: Colors.white,
            onBack: () => Navigator.of(context).pop(),
          ),
          body: SafeArea(
            child: Consumer<LanguageService>(
              builder: (context, langService, child) {
                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildShowsGrid(
                            context,
                            langService,
                            contentService,
                            showService,
                            hotelConfigs,
                          ),
                        ),
                      ),
                    ),
                    _buildFooterControls(
                      context,
                      langService,
                      showService,
                      hotelConfigs,
                      isEditMode,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterControls(
    BuildContext context,
    LanguageService langService,
    ShowService showService,
    List<HotelConfig> hotelConfigs,
    bool isEditMode,
  ) {
    final currentStartHotelIndex = showService.getStartHotelIndex(_selectedWeek);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWeekButton(1, langService.translate('week_1')),
              const SizedBox(width: 8),
              _buildWeekButton(2, langService.translate('week_2')),
            ],
          ),
          if (isEditMode)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  langService.translate('monday_starts_at'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                  ),
                  child: DropdownButton<int>(
                    value: currentStartHotelIndex % hotelConfigs.length,
                    dropdownColor: Colors.grey[900],
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.amberAccent),
                    items: List.generate(
                      hotelConfigs.length,
                      (index) => DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                          hotelConfigs[index].name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        showService.setStartHotelIndex(_selectedWeek, val);
                      }
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWeekButton(int week, String label) {
    final isSelected = _selectedWeek == week;
    return InkWell(
      onTap: () => setState(() => _selectedWeek = week),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amberAccent : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.amber : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildShowsGrid(
    BuildContext context,
    LanguageService langService,
    ContentService contentService,
    ShowService showService,
    List<HotelConfig> hotelConfigs,
  ) {
    final now = DateTime.now();
    final currentCalendarWeek = _getWeekNumber(now) % 2 == 1 ? 1 : 2;
    final isCurrentWeek = _selectedWeek == currentCalendarWeek;
    final startHotelIndex = showService.getStartHotelIndex(_selectedWeek);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxItemHeight = constraints.maxHeight;
        final widthFromHeight = (maxItemHeight - 122) / 1.4142;
        final widthFromWidth = (constraints.maxWidth - 40) / 7 - 8;
        final cardWidth = widthFromHeight < widthFromWidth ? widthFromHeight : widthFromWidth;

        Widget buildItem(int index) {
          final day = days[index];
          final hotelIndex = (startHotelIndex + index) % hotelConfigs.length;
          final currentHotel = hotelConfigs[hotelIndex];
          final isToday = isCurrentWeek && (now.weekday == index + 1);
          final posterPath = showService.getShowImage(day, week: _selectedWeek);
          final showTime = showService.getShowTime(day, week: _selectedWeek);

          return SizedBox(
            width: cardWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.amber.withValues(alpha: 0.9) : Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday ? Colors.amberAccent : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          langService.getWeekday(index).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isToday ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _getDateString(index, langService),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isToday ? Colors.black87 : Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_filled,
                              size: 10,
                              color: isToday ? Colors.black87 : Colors.amberAccent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              showTime,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                color: isToday ? Colors.black : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          child: posterPath.isNotEmpty
                              ? AppImage(
                                  path: posterPath,
                                  fit: BoxFit.fill,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildNoShowCard(langService);
                                  },
                                )
                              : _buildNoShowCard(langService),
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
                              onPressed: () => _showPosterOptionsDialog(
                                context,
                                day,
                                showService,
                                langService,
                              ),
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
  }

  Widget _buildNoShowCard(LanguageService langService) {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 36, color: Colors.white30),
          const SizedBox(height: 8),
          Text(
            langService.translate('no_show_scheduled'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPosterOptionsDialog(
    BuildContext context,
    String dayKey,
    ShowService showService,
    LanguageService langService,
  ) async {
    final dayIndex = days.indexOf(dayKey);
    final dayName = langService.getWeekday(dayIndex).toUpperCase();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          dayName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.amberAccent),
              title: Text(
                langService.translate('select_poster'),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                final selected = await AssetImagePickerModal.show(context, subFolder: 'shows');
                if (selected is String && selected.isNotEmpty) {
                  showService.updateShowImage(dayKey, selected, week: _selectedWeek);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.amberAccent),
              title: Text(
                langService.translate('edit_time'),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${langService.translate('start_time')}: ${showService.getShowTime(dayKey, week: _selectedWeek)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditTimeDialog(context, dayKey, showService, langService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(
                langService.translate('remove_poster'),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                showService.removeShowImage(dayKey, week: _selectedWeek);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTimeDialog(
    BuildContext context,
    String dayKey,
    ShowService showService,
    LanguageService langService,
  ) async {
    final current = showService.getShowTime(dayKey, week: _selectedWeek);
    final controller = TextEditingController(text: current);
    final quickTimes = ['20:00', '20:30', '21:00', '21:30', '22:00', '22:30'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              langService.translate('edit_time'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langService.translate('start_time'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    prefixIcon: const Icon(Icons.access_time, color: Colors.amberAccent),
                    hintText: '21:30',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.amberAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quick Presets:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickTimes.map((t) {
                    final isSelected = controller.text.trim() == t;
                    return ActionChip(
                      label: Text(t),
                      backgroundColor: isSelected ? Colors.amberAccent : Colors.black45,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onPressed: () {
                        setState(() {
                          controller.text = t;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                onPressed: () {
                  final newTime = controller.text.trim();
                  if (newTime.isNotEmpty) {
                    showService.updateShowTime(dayKey, newTime, week: _selectedWeek);
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getDateString(int dayIndex, LanguageService langService) {
    final now = DateTime.now();
    final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final currentWeekParity = (_getWeekNumber(now) % 2 == 1) ? 1 : 2;

    int weekOffset = 0;
    if (_selectedWeek != currentWeekParity) {
      weekOffset = _selectedWeek > currentWeekParity ? 1 : -1;
    }

    final targetDate = currentMonday.add(Duration(days: weekOffset * 7 + dayIndex));
    final monthName = langService.getMonth(targetDate.month);
    return '$monthName ${targetDate.day}';
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}

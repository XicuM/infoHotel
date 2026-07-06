import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/grid_widget.dart';
import '../../widgets/generic_menu_view.dart';
import '../../widgets/localized_text_field.dart';
import '../../l10n/translations.dart';
import '../../services/language_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_image.dart';
import 'safety_rules_view.dart';
import '../../models/hotel_config.dart';
import '../../services/content_service.dart';
import '../../services/hotel_config_service.dart';

// ─── Data model ────────────────────────────────────────────────────────────────

class _ScheduleEntry {
  final String label; // e.g. 'Breakfast', 'Snacks'
  final String time;  // e.g. '08:00 – 10:00'
  final Map<String, String> localizedLabels;
  const _ScheduleEntry(this.label, this.time, {this.localizedLabels = const {}});
}

class _FeatureBullet {
  final IconData icon;
  final String text; // translation key or literal
  final bool isLiteral;
  final Map<String, String> localizedTexts;
  const _FeatureBullet(this.icon, this.text, {this.isLiteral = true, this.localizedTexts = const {}});
}

class _FacilityData {
  final String titleKey;
  final String? logoPath;
  final List<String> imagePaths;
  final bool isLiteral;
  final String? descriptionKey;
  /// Deprecated raw hours string – kept for fallback
  final String? hours;
  final bool hasSafetyRules;

  // New rich fields
  final List<_ScheduleEntry> schedule;
  final List<_FeatureBullet> features;
  final IconData? headerIcon;
  final Color? accentColor;

  // Localized title & description
  final Map<String, String> localizedTitles;
  final Map<String, String> localizedDescriptions;

  const _FacilityData(
    this.titleKey,
    this.imagePaths, {
    this.logoPath,
    this.isLiteral = false,
    this.descriptionKey,
    this.hours,
    this.hasSafetyRules = false,
    this.schedule = const [],
    this.features = const [],
    this.headerIcon,
    this.accentColor,
    this.localizedTitles = const {},
    this.localizedDescriptions = const {},
  });

  factory _FacilityData.fromJson(Map<String, dynamic> json) {
    return _FacilityData(
      json['titleKey'] ?? '',
      List<String>.from(json['imagePaths'] ?? []),
      logoPath: json['logoPath'],
      isLiteral: json['isLiteral'] ?? false,
      descriptionKey: json['descriptionKey'],
      hours: json['hours'],
      hasSafetyRules: json['hasSafetyRules'] ?? false,
      schedule: (json['schedule'] as List?)?.map((e) => _ScheduleEntry(
        e['label'] ?? '',
        e['time'] ?? '',
        localizedLabels: (e['localizedLabels'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      )).toList() ?? const [],
      features: (json['features'] as List?)?.map((e) => _FeatureBullet(
        _parseIcon(e['icon']),
        e['text'] ?? '',
        isLiteral: e['isLiteral'] ?? true,
        localizedTexts: (e['localizedTexts'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      )).toList() ?? const [],
      headerIcon: json['headerIcon'] != null ? _parseIcon(json['headerIcon']) : null,
      accentColor: json['accentColor'] != null ? Color(int.parse(json['accentColor'], radix: 16) | 0xFF000000) : null,
      localizedTitles: (json['localizedTitles'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      localizedDescriptions: (json['localizedDescriptions'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
    );
  }

  _FacilityData copyWith({
    String? logoPath,
    List<String>? imagePaths,
    bool? isLiteral,
    bool? hasSafetyRules,
    List<_ScheduleEntry>? schedule,
    List<_FeatureBullet>? features,
    IconData? headerIcon,
    Color? accentColor,
    Map<String, String>? localizedTitles,
    Map<String, String>? localizedDescriptions,
  }) {
    return _FacilityData(
      titleKey,
      imagePaths ?? this.imagePaths,
      logoPath: logoPath ?? this.logoPath,
      isLiteral: isLiteral ?? this.isLiteral,
      descriptionKey: descriptionKey,
      hours: hours,
      hasSafetyRules: hasSafetyRules ?? this.hasSafetyRules,
      schedule: schedule ?? this.schedule,
      features: features ?? this.features,
      headerIcon: headerIcon ?? this.headerIcon,
      accentColor: accentColor ?? this.accentColor,
      localizedTitles: localizedTitles ?? this.localizedTitles,
      localizedDescriptions: localizedDescriptions ?? this.localizedDescriptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titleKey': titleKey,
      if (logoPath != null) 'logoPath': logoPath,
      'imagePaths': imagePaths,
      'isLiteral': isLiteral,
      if (descriptionKey != null) 'descriptionKey': descriptionKey,
      if (hours != null) 'hours': hours,
      'hasSafetyRules': hasSafetyRules,
      'schedule': schedule.map((e) => {
        'label': e.label,
        'time': e.time,
        'localizedLabels': e.localizedLabels,
      }).toList(),
      'features': features.map((e) => {
        'icon': _iconToString(e.icon),
        'text': e.text,
        'isLiteral': e.isLiteral,
        'localizedTexts': e.localizedTexts,
      }).toList(),
      if (headerIcon != null) 'headerIcon': _iconToString(headerIcon!),
      if (accentColor != null) 'accentColor': accentColor!.value.toRadixString(16).substring(2).toUpperCase(),
      'localizedTitles': localizedTitles,
      'localizedDescriptions': localizedDescriptions,
    };
  }
}

IconData _parseIcon(String name) {
  switch (name) {
    case 'restaurant_menu': return Icons.restaurant_menu;
    case 'local_pizza': return Icons.local_pizza;
    case 'tapas': return Icons.tapas;
    case 'child_friendly': return Icons.child_friendly;
    case 'restaurant': return Icons.restaurant;
    case 'local_bar': return Icons.local_bar;
    case 'lunch_dining': return Icons.lunch_dining;
    case 'icecream': return Icons.icecream;
    case 'deck': return Icons.deck;
    case 'pool': return Icons.pool;
    case 'child_care': return Icons.child_care;
    case 'wb_sunny': return Icons.wb_sunny;
    case 'beach_access': return Icons.beach_access;
    case 'water': return Icons.water;
    case 'sports_tennis': return Icons.sports_tennis;
    case 'sports': return Icons.sports;
    case 'sports_handball': return Icons.sports_handball;
    case 'golf_course': return Icons.golf_course;
    case 'free_breakfast': return Icons.free_breakfast;
    case 'fitness_center': return Icons.fitness_center;
    case 'spa': return Icons.spa;
    case 'table_bar': return Icons.table_bar;
    case 'scuba_diving': return Icons.scuba_diving;
    case 'school': return Icons.school;
    case 'sailing': return Icons.sailing;
    case 'map_outlined': return Icons.map_outlined;
    case 'thermostat': return Icons.thermostat;
    default: return Icons.help;
  }
}

String _iconToString(IconData icon) {
  if (icon == Icons.restaurant_menu) return 'restaurant_menu';
  if (icon == Icons.local_pizza) return 'local_pizza';
  if (icon == Icons.tapas) return 'tapas';
  if (icon == Icons.child_friendly) return 'child_friendly';
  if (icon == Icons.restaurant) return 'restaurant';
  if (icon == Icons.local_bar) return 'local_bar';
  if (icon == Icons.lunch_dining) return 'lunch_dining';
  if (icon == Icons.icecream) return 'icecream';
  if (icon == Icons.deck) return 'deck';
  if (icon == Icons.pool) return 'pool';
  if (icon == Icons.child_care) return 'child_care';
  if (icon == Icons.wb_sunny) return 'wb_sunny';
  if (icon == Icons.beach_access) return 'beach_access';
  if (icon == Icons.water) return 'water';
  if (icon == Icons.sports_tennis) return 'sports_tennis';
  if (icon == Icons.sports) return 'sports';
  if (icon == Icons.sports_handball) return 'sports_handball';
  if (icon == Icons.golf_course) return 'golf_course';
  if (icon == Icons.free_breakfast) return 'free_breakfast';
  if (icon == Icons.fitness_center) return 'fitness_center';
  if (icon == Icons.spa) return 'spa';
  if (icon == Icons.table_bar) return 'table_bar';
  if (icon == Icons.scuba_diving) return 'scuba_diving';
  if (icon == Icons.school) return 'school';
  if (icon == Icons.sailing) return 'sailing';
  if (icon == Icons.map_outlined) return 'map_outlined';
  if (icon == Icons.thermostat) return 'thermostat';
  return 'help';
}

// ─── Facilities grid ───────────────────────────────────────────────────────

class FacilitiesView extends StatelessWidget {
  final String hotelId;

  const FacilitiesView({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    final contentService = context.watch<ContentService>();
    final langService = context.watch<LanguageService>();
    final hotelService = context.watch<HotelConfigService>();
    final isEditMode = contentService.isEditMode;
    final config = hotelService.getHotelConfig(hotelId);
    final facilitiesData = hotelService.hotels[hotelId] as List<dynamic>? ?? [];
    final facilities = facilitiesData.map((e) => _FacilityData.fromJson(e as Map<String, dynamic>)).toList();

    final List<CardData> cards = [];
    for (int i = 0; i < facilities.length; i++) {
      final facility = facilities[i];
      
      String cardImage = 'hotel_assets/images/ui/placeholder.png';
      if (facility.logoPath != null && facility.logoPath!.isNotEmpty) {
        cardImage = facility.logoPath!.startsWith('hotel_assets/') ? facility.logoPath! : 'hotel_assets/images/${facility.logoPath!}';
      } else if (facility.imagePaths.isNotEmpty) {
        cardImage = facility.imagePaths.first.startsWith('hotel_assets/') ? facility.imagePaths.first : 'hotel_assets/images/${facility.imagePaths.first}';
      }

      cards.add(
        CardData(
          imagePath: cardImage,
          title: facility.localizedTitles[langService.currentLanguage] ?? 
              (facility.isLiteral ? facility.titleKey : langService.translate(facility.titleKey)),
          onTap: () => _showFacilityDetail(context, facility, i, contentService),
        ),
      );
    }

    if (isEditMode) {
      cards.add(
        CardData(
          iconData: Icons.add_photo_alternate_outlined,
          title: 'Add New',
          onTap: () => _addNewFacility(context, contentService, hotelId),
        ),
      );
    }

    return GenericMenuView(
      titleKey: config?.name ?? hotelId,
      appBarColor: AppColors.services,
      parentRoute: '/services',
      cards: cards,
      crossAxisCount: 4,
      childAspectRatio: 0.8,
      actions: isEditMode ? [
        IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
          tooltip: 'Delete Hotel',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Hotel?'),
                content: Text('Are you sure you want to delete "${config?.name ?? hotelId}" and all its facilities? This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                      context.read<HotelConfigService>().deleteHotel(hotelId);
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 16),
      ] : null,
    );
  }

  void _showFacilityDetail(BuildContext context, _FacilityData facility, int index, ContentService contentService) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FacilityDetailView(facility: facility, hotelId: hotelId, facilityIndex: index),
      ),
    );
  }
}

void _addNewFacility(BuildContext context, ContentService contentService, String hotelId) async {
  final updatedHotels = Map<String, dynamic>.from(context.read<HotelConfigService>().hotels);
  final hotelFacilities = List<dynamic>.from(updatedHotels[hotelId] ?? []);

  final newFacilityJson = {
    'titleKey': 'New Service',
    'logoPath': null,
    'imagePaths': ['ui/placeholder.png'],
    'isLiteral': true,
    'hasSafetyRules': false,
    'schedule': <dynamic>[],
    'features': <dynamic>[],
    'headerIcon': 'help',
    'accentColor': '2196F3',
    'localizedTitles': {'en': 'New Service'},
    'localizedDescriptions': {'en': 'Service description'},
  };

  hotelFacilities.add(newFacilityJson);
  updatedHotels[hotelId] = hotelFacilities;
  await context.read<HotelConfigService>().updateHotels(updatedHotels);

  final newFacility = _FacilityData.fromJson(newFacilityJson);
  final newIndex = hotelFacilities.length - 1;

  if (context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FacilityDetailView(
          facility: newFacility,
          hotelId: hotelId,
          facilityIndex: newIndex,
        ),
      ),
    );
  }
}

// ─── Facility detail view ───────────────────────────────────────────────────────

/// Facility detail view — premium redesign with Edit Mode
class FacilityDetailView extends StatefulWidget {
  final _FacilityData facility;
  final String hotelId;
  final int facilityIndex;

  const FacilityDetailView({
    super.key,
    required this.facility,
    required this.hotelId,
    required this.facilityIndex,
  });

  @override
  State<FacilityDetailView> createState() => _FacilityDetailViewState();
}

class _FacilityDetailViewState extends State<FacilityDetailView> {
  late PageController _pageController;
  int _currentPage = 0;

  // Buffers for edits
  late Map<String, String> _localizedTitles;
  late Map<String, String> _localizedDescriptions;
  late String? _logoPath;
  late List<String> _imagePaths;
  late List<_ScheduleEntry> _schedule;
  late List<_FeatureBullet> _features;
  late bool _hasSafetyRules;
  late IconData? _headerIcon;
  late Color? _accentColor;
  late bool _isLiteral;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initBuffers();
  }

  void _initBuffers() {
    _localizedTitles = Map.from(widget.facility.localizedTitles);
    _localizedDescriptions = Map.from(widget.facility.localizedDescriptions);
    _logoPath = widget.facility.logoPath;
    _imagePaths = List.from(widget.facility.imagePaths);
    _schedule = List.from(widget.facility.schedule);
    _features = List.from(widget.facility.features);
    _hasSafetyRules = widget.facility.hasSafetyRules;
    _headerIcon = widget.facility.headerIcon;
    _accentColor = widget.facility.accentColor;
    _isLiteral = widget.facility.isLiteral;

    // Seed default translation if localizedTitles is empty
    if (_localizedTitles.isEmpty) {
      _localizedTitles['en'] = widget.facility.isLiteral 
          ? widget.facility.titleKey 
          : Translations.get(widget.facility.titleKey, 'en');
    }
    if (_localizedDescriptions.isEmpty && widget.facility.descriptionKey != null) {
      _localizedDescriptions['en'] = Translations.get(widget.facility.descriptionKey!, 'en');
    }
  }

  @override
  void didUpdateWidget(FacilityDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.facility.titleKey != oldWidget.facility.titleKey || widget.hotelId != oldWidget.hotelId) {
      _initBuffers();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getTitle(LanguageService langService) {
    final currentLang = langService.currentLanguage;
    if (_localizedTitles.containsKey(currentLang) && _localizedTitles[currentLang]!.isNotEmpty) {
      return _localizedTitles[currentLang]!;
    }
    return _isLiteral
        ? widget.facility.titleKey
        : langService.translate(widget.facility.titleKey);
  }

  String? _getDescription(LanguageService langService) {
    final currentLang = langService.currentLanguage;
    if (_localizedDescriptions.containsKey(currentLang) && _localizedDescriptions[currentLang]!.isNotEmpty) {
      return _localizedDescriptions[currentLang]!;
    }
    if (widget.facility.descriptionKey != null) {
      return Translations.get(widget.facility.descriptionKey!, currentLang);
    }
    return null;
  }

  void _saveChanges(ContentService contentService) {
    final updatedFacility = widget.facility.copyWith(
      logoPath: _logoPath,
      imagePaths: _imagePaths,
      isLiteral: _isLiteral,
      hasSafetyRules: _hasSafetyRules,
      schedule: _schedule,
      features: _features,
      headerIcon: _headerIcon,
      accentColor: _accentColor,
      localizedTitles: _localizedTitles,
      localizedDescriptions: _localizedDescriptions,
    );
    
    final updatedFacilityJson = updatedFacility.toJson();

    final currentHotels = Map<String, dynamic>.from(context.read<HotelConfigService>().hotels);
    final hotelFacilities = List<dynamic>.from(currentHotels[widget.hotelId] ?? []);
    if (widget.facilityIndex >= 0 && widget.facilityIndex < hotelFacilities.length) {
      hotelFacilities[widget.facilityIndex] = updatedFacilityJson;
      currentHotels[widget.hotelId] = hotelFacilities;
      context.read<HotelConfigService>().updateHotels(currentHotels);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = context.watch<LanguageService>();
    final contentService = context.watch<ContentService>();
    final isEditMode = contentService.isEditMode;
    final isMap = widget.facility.titleKey == 'hotel_map';
    final accent = _accentColor ?? AppColors.services;

    final displayImages = _imagePaths;

    final title = _getTitle(langService);

    if (isMap && !isEditMode) {
      return _buildMapView(context, langService, displayImages, title, accent);
    }

    return _buildDetailView(context, langService, displayImages, title, accent, isEditMode, contentService);
  }

  Widget _buildMapView(
    BuildContext context,
    LanguageService langService,
    List<String> images,
    String title,
    Color accent,
  ) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      appBar: CustomAppBar(
        titleKey: title,
        backgroundColor: AppColors.services,
        parentRoute: '/hotel-services',
      ),
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
              border: const Border(right: BorderSide(color: Colors.white12)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.legend_toggle, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Legend',
                        style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.white12),
                  const SizedBox(height: 16),
                  Text(
                    _getDescription(langService) ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: images.isNotEmpty
                ? AppImage(
                    path: images.first.startsWith('hotel_assets/')
                        ? images.first
                        : 'hotel_assets/images/${images.first}',
                    fit: BoxFit.contain,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(
    BuildContext context,
    LanguageService langService,
    List<String> images,
    String title,
    Color accent,
    bool isEditMode,
    ContentService contentService,
  ) {
    final double panelWidth = isEditMode ? 480.0 : 320.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        titleKey: title,
        backgroundColor: AppColors.services,
        parentRoute: '/hotel-services',
        onBack: () {
          if (isEditMode) _saveChanges(contentService);
          Navigator.of(context).pop();
        },
        actions: isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 32),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Service?'),
                        content: const Text(
                            'Are you sure you want to delete this service? This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.of(context).pop(); // Close detail view
                              
                              final currentHotels =
                                  Map<String, dynamic>.from(context.read<HotelConfigService>().hotels);
                              final hotelFacilities =
                                  List<dynamic>.from(currentHotels[widget.hotelId] ?? []);
                              if (widget.facilityIndex >= 0 &&
                                  widget.facilityIndex < hotelFacilities.length) {
                                hotelFacilities.removeAt(widget.facilityIndex);
                                currentHotels[widget.hotelId] = hotelFacilities;
                                context.read<HotelConfigService>().updateHotels(currentHotels);
                              }
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.white, size: 32),
                  onPressed: () {
                    _saveChanges(contentService);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Changes saved successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
              ]
            : null,
      ),
      body: Row(
        children: [
          Container(
            width: panelWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.88),
                  const Color(0xFF0D0D0D).withValues(alpha: 0.95),
                ],
              ),
              border: const Border(right: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [accent, accent.withValues(alpha: 0.0)]),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: isEditMode
                        ? _buildEditForm(context, langService, contentService, accent)
                        : _buildReadOnlyContent(context, langService, accent),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: images.isEmpty
                ? const SizedBox.shrink()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, i) {
                          final imgPath = images[i];
                          final fullPath = imgPath.startsWith('hotel_assets/')
                              ? imgPath
                              : 'hotel_assets/images/$imgPath';
                          return AppImage(
                            path: fullPath,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (i) {
                              final isActive = _currentPage == i;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isActive ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                      if (images.length > 1) ...[
                        if (_currentPage > 0)
                          Positioned(
                            left: 12,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _NavArrow(
                                icon: Icons.chevron_left,
                                onTap: () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                          ),
                        if (_currentPage < images.length - 1)
                          Positioned(
                            right: 12,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _NavArrow(
                                icon: Icons.chevron_right,
                                onTap: () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyContent(
    BuildContext context,
    LanguageService langService,
    Color accent,
  ) {
    final descText = _getDescription(langService);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_headerIcon != null) ...[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(_headerIcon, color: accent, size: 28),
          ),
          const SizedBox(height: 14),
        ],
        if (descText != null && descText.isNotEmpty) ...[
          Text(
            descText,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_schedule.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.schedule,
            label: langService.translate('opening_hours'),
            accent: accent,
          ),
          const SizedBox(height: 10),
          ..._schedule.map(
            (entry) => _ScheduleChip(entry: entry, accent: accent),
          ),
          const SizedBox(height: 20),
        ] else if (widget.facility.hours != null) ...[
          _SectionHeader(
            icon: Icons.schedule,
            label: langService.translate('opening_hours'),
            accent: accent,
          ),
          const SizedBox(height: 10),
          _LegacyHoursCard(hours: widget.facility.hours!, accent: accent),
          const SizedBox(height: 20),
        ],
        if (_features.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.star_outline,
            label: 'Highlights',
            accent: accent,
          ),
          const SizedBox(height: 10),
          ..._features.map(
            (f) => _FeatureRow(bullet: f, accent: accent),
          ),
          const SizedBox(height: 20),
        ],
        if (widget.facility.hasSafetyRules) ...[
          const SizedBox(height: 4),
          _SafetyRulesButton(
            hotelId: widget.hotelId,
            langService: langService,
          ),
        ],
      ],
    );
  }

  Widget _buildEditForm(
    BuildContext context,
    LanguageService langService,
    ContentService contentService,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BASIC INFORMATION',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        LocalizedTextField(
          enabled: true,
          localizedValues: _localizedTitles,
          defaultValue: widget.facility.titleKey,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Service Title',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
          onValuesChanged: (values) {
            setState(() {
              _localizedTitles = values;
            });
          },
        ),
        const SizedBox(height: 16),
        LocalizedTextField(
          enabled: true,
          localizedValues: _localizedDescriptions,
          defaultValue: widget.facility.descriptionKey ?? '',
          maxLines: null,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
          decoration: const InputDecoration(
            labelText: 'Description / Map Legend (Optional)',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          onValuesChanged: (values) {
            setState(() {
              _localizedDescriptions = values;
            });
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'STYLING & ICON',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<IconData>(
                value: _headerIcon,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Header Icon',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                items: [
                  Icons.restaurant_menu,
                  Icons.local_pizza,
                  Icons.tapas,
                  Icons.child_friendly,
                  Icons.restaurant,
                  Icons.local_bar,
                  Icons.lunch_dining,
                  Icons.icecream,
                  Icons.deck,
                  Icons.pool,
                  Icons.child_care,
                  Icons.wb_sunny,
                  Icons.beach_access,
                  Icons.water,
                  Icons.sports_tennis,
                  Icons.sports,
                  Icons.sports_handball,
                  Icons.golf_course,
                  Icons.free_breakfast,
                  Icons.fitness_center,
                  Icons.spa,
                  Icons.table_bar,
                  Icons.scuba_diving,
                  Icons.school,
                  Icons.sailing,
                  Icons.map_outlined,
                  Icons.thermostat,
                  Icons.help,
                ].map((icon) {
                  return DropdownMenuItem<IconData>(
                    value: icon,
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(_iconToString(icon), style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (icon) {
                  if (icon != null) {
                    setState(() {
                      _headerIcon = icon;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: _accentColor?.value.toRadixString(16).substring(2).toUpperCase() ?? '2196F3',
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Accent Color (Hex)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  if (val.length == 6) {
                    final parsedColor = int.tryParse(val, radix: 16);
                    if (parsedColor != null) {
                      setState(() {
                        _accentColor = Color(parsedColor | 0xFF000000);
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accentColor ?? Colors.blue,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Has Safety Rules Button', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Adds link to pool safety rules', style: TextStyle(color: Colors.white54, fontSize: 12)),
          value: _hasSafetyRules,
          activeColor: accent,
          onChanged: (val) {
            setState(() {
              _hasSafetyRules = val;
            });
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'CARD LOGO',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (_logoPath != null && _logoPath!.isNotEmpty)
          Stack(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppImage(
                    path: _logoPath!.startsWith('hotel_assets/') ? _logoPath! : 'hotel_assets/images/$_logoPath',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _logoPath = null),
                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                ),
              ),
            ],
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.add_photo_alternate, size: 18),
            label: const Text('Add Logo Image'),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
              if (result != null && (result.files.single.path != null || kIsWeb)) {
                final savedPath = await contentService.saveImage(
                  result.files.single.path ?? '',
                  subFolder: 'facilities/${widget.hotelId.toLowerCase()}',
                  bytes: result.files.single.bytes,
                  originalName: result.files.single.name,
                );
                final relativePath = savedPath.replaceFirst('hotel_assets/images/', '');
                setState(() {
                  _logoPath = relativePath;
                });
              }
            },
          ),
        const SizedBox(height: 24),
        const Text(
          'IMAGE GALLERY',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (_imagePaths.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No images in gallery.', style: TextStyle(color: Colors.white38)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_imagePaths.length, (index) {
              final imgPath = _imagePaths[index];
              final fullPath = imgPath.startsWith('hotel_assets/') ? imgPath : 'hotel_assets/images/$imgPath';
              return SizedBox(
                width: 85,
                height: 85,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AppImage(
                        path: fullPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image, color: Colors.white24),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imagePaths.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(Icons.close, color: Colors.red, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_a_photo, size: 18),
          label: const Text('Add Image'),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
            if (result != null && (result.files.single.path != null || kIsWeb)) {
              final savedPath = await contentService.saveImage(
                result.files.single.path ?? '',
                subFolder: 'facilities/${widget.hotelId.toLowerCase()}',
                bytes: result.files.single.bytes,
                originalName: result.files.single.name,
              );
              final relativePath = savedPath.replaceFirst('hotel_assets/images/', '');
              setState(() {
                _imagePaths.add(relativePath);
              });
            }
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SCHEDULE (OPENING HOURS)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green, size: 20),
              onPressed: () {
                setState(() {
                  _schedule.add(const _ScheduleEntry('', '', localizedLabels: {}));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_schedule.length, (index) {
          return _ScheduleEntryEditor(
            key: ValueKey('schedule_$index'),
            entry: _schedule[index],
            onDelete: () {
              setState(() {
                _schedule.removeAt(index);
              });
            },
            onChanged: (updated) {
              _schedule[index] = updated;
            },
          );
        }),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HIGHLIGHTS (FEATURES)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green, size: 20),
              onPressed: () {
                setState(() {
                  _features.add(const _FeatureBullet(Icons.star, '', isLiteral: true, localizedTexts: {}));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_features.length, (index) {
          return _FeatureBulletEditor(
            key: ValueKey('feature_$index'),
            bullet: _features[index],
            onDelete: () {
              setState(() {
                _features.removeAt(index);
              });
            },
            onChanged: (updated) {
              _features[index] = updated;
            },
          );
        }),
      ],
    );
  }
}

// ─── Schedule entry editor stateful widget ──────────────────────────────────────

class _ScheduleEntryEditor extends StatefulWidget {
  final _ScheduleEntry entry;
  final VoidCallback onDelete;
  final ValueChanged<_ScheduleEntry> onChanged;

  const _ScheduleEntryEditor({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_ScheduleEntryEditor> createState() => _ScheduleEntryEditorState();
}

class _ScheduleEntryEditorState extends State<_ScheduleEntryEditor> {
  late TextEditingController _timeController;
  late Map<String, String> _localizedLabels;

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: widget.entry.time);
    _localizedLabels = Map.from(widget.entry.localizedLabels);
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LocalizedTextField(
                    localizedValues: _localizedLabels,
                    defaultValue: widget.entry.label,
                    decoration: const InputDecoration(
                      labelText: 'Label (e.g. Breakfast)',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onValuesChanged: (values) {
                      _localizedLabels = values;
                      widget.onChanged(_ScheduleEntry(
                        values['en'] ?? widget.entry.label,
                        _timeController.text,
                        localizedLabels: _localizedLabels,
                      ));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            TextField(
              controller: _timeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Time (e.g. 08:00 – 10:00)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              onChanged: (val) {
                widget.onChanged(_ScheduleEntry(
                  _localizedLabels['en'] ?? widget.entry.label,
                  val,
                  localizedLabels: _localizedLabels,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature bullet editor stateful widget ──────────────────────────────────────

class _FeatureBulletEditor extends StatefulWidget {
  final _FeatureBullet bullet;
  final VoidCallback onDelete;
  final ValueChanged<_FeatureBullet> onChanged;

  const _FeatureBulletEditor({
    super.key,
    required this.bullet,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_FeatureBulletEditor> createState() => _FeatureBulletEditorState();
}

class _FeatureBulletEditorState extends State<_FeatureBulletEditor> {
  late Map<String, String> _localizedTexts;
  late IconData _icon;

  @override
  void initState() {
    super.initState();
    _localizedTexts = Map.from(widget.bullet.localizedTexts);
    _icon = widget.bullet.icon;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<IconData>(
                    value: _icon,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Icon',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    items: [
                      Icons.restaurant_menu,
                      Icons.local_pizza,
                      Icons.tapas,
                      Icons.child_friendly,
                      Icons.restaurant,
                      Icons.local_bar,
                      Icons.lunch_dining,
                      Icons.icecream,
                      Icons.deck,
                      Icons.pool,
                      Icons.child_care,
                      Icons.wb_sunny,
                      Icons.beach_access,
                      Icons.water,
                      Icons.sports_tennis,
                      Icons.sports,
                      Icons.sports_handball,
                      Icons.golf_course,
                      Icons.free_breakfast,
                      Icons.fitness_center,
                      Icons.spa,
                      Icons.table_bar,
                      Icons.scuba_diving,
                      Icons.school,
                      Icons.sailing,
                      Icons.map_outlined,
                      Icons.thermostat,
                      Icons.help,
                    ].map((icon) {
                      return DropdownMenuItem<IconData>(
                        value: icon,
                        child: Row(
                          children: [
                            Icon(icon, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(_iconToString(icon), style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _icon = val;
                        widget.onChanged(_FeatureBullet(
                          _icon,
                          _localizedTexts['en'] ?? widget.bullet.text,
                          isLiteral: true,
                          localizedTexts: _localizedTexts,
                        ));
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LocalizedTextField(
              localizedValues: _localizedTexts,
              defaultValue: widget.bullet.text,
              decoration: const InputDecoration(
                labelText: 'Text',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              onValuesChanged: (values) {
                _localizedTexts = values;
                widget.onChanged(_FeatureBullet(
                  _icon,
                  values['en'] ?? widget.bullet.text,
                  isLiteral: true,
                  localizedTexts: _localizedTexts,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small reusable pieces ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _SectionHeader({required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 15),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final _ScheduleEntry entry;
  final Color accent;

  const _ScheduleChip({required this.entry, required this.accent});

  @override
  Widget build(BuildContext context) {
    final langService = context.watch<LanguageService>();
    final label = entry.localizedLabels.containsKey(langService.currentLanguage) &&
            entry.localizedLabels[langService.currentLanguage]!.isNotEmpty
        ? entry.localizedLabels[langService.currentLanguage]!
        : entry.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.12), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  entry.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyHoursCard extends StatelessWidget {
  final String hours;
  final Color accent;

  const _LegacyHoursCard({required this.hours, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              hours,
              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final _FeatureBullet bullet;
  final Color accent;

  const _FeatureRow({required this.bullet, required this.accent});

  @override
  Widget build(BuildContext context) {
    final langService = context.watch<LanguageService>();
    final text = bullet.localizedTexts.containsKey(langService.currentLanguage) &&
            bullet.localizedTexts[langService.currentLanguage]!.isNotEmpty
        ? bullet.localizedTexts[langService.currentLanguage]!
        : (bullet.isLiteral
            ? bullet.text
            : langService.translate(bullet.text));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(bullet.icon, color: accent, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyRulesButton extends StatelessWidget {
  final String hotelId;
  final LanguageService langService;

  const _SafetyRulesButton({required this.hotelId, required this.langService});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SafetyRulesView(hotelId: hotelId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              langService.translate('safety_rules'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(widget.icon, color: Colors.white, size: 28),
      ),
    );
  }
}

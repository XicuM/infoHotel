import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/grid_widget.dart';
import '../../l10n/translations.dart';
import '../../services/language_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_image.dart';
import 'safety_rules_view.dart';
import '../../services/content_service.dart';

// ─── Data model ────────────────────────────────────────────────────────────────

class _ScheduleEntry {
  final String label; // e.g. 'Breakfast', 'Snacks'
  final String time;  // e.g. '08:00 – 10:00'
  const _ScheduleEntry(this.label, this.time);
}

class _FeatureBullet {
  final IconData icon;
  final String text; // translation key or literal
  final bool isLiteral;
  const _FeatureBullet(this.icon, this.text, {this.isLiteral = true});
}

class _FacilityData {
  final String titleKey;
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

  const _FacilityData(
    this.titleKey,
    this.imagePaths, {
    this.isLiteral = false,
    this.descriptionKey,
    this.hours,
    this.hasSafetyRules = false,
    this.schedule = const [],
    this.features = const [],
    this.headerIcon,
    this.accentColor,
  });

  factory _FacilityData.fromJson(Map<String, dynamic> json) {
    return _FacilityData(
      json['titleKey'] ?? '',
      List<String>.from(json['imagePaths'] ?? []),
      isLiteral: json['isLiteral'] ?? false,
      descriptionKey: json['descriptionKey'],
      hours: json['hours'],
      hasSafetyRules: json['hasSafetyRules'] ?? false,
      schedule: (json['schedule'] as List?)?.map((e) => _ScheduleEntry(e['label'], e['time'])).toList() ?? const [],
      features: (json['features'] as List?)?.map((e) => _FeatureBullet(_parseIcon(e['icon']), e['text'], isLiteral: e['isLiteral'] ?? true)).toList() ?? const [],
      headerIcon: json['headerIcon'] != null ? _parseIcon(json['headerIcon']) : null,
      accentColor: json['accentColor'] != null ? Color(int.parse(json['accentColor'], radix: 16) | 0xFF000000) : null,
    );
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

// ─── Savines service grid ───────────────────────────────────────────────────────

/// Savines hotel services sub-page
class SavinesServicesView extends StatelessWidget {
  const SavinesServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final contentService = context.watch<ContentService>();
    final facilitiesData = contentService.hotels['Savines'] as List<dynamic>? ?? [];
    final facilities = facilitiesData.map((e) => _FacilityData.fromJson(e as Map<String, dynamic>)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'Hotel Ses Savines',
        backgroundColor: AppColors.services,
        parentRoute: '/services',
      ),
      body: CardGrid(
        cards: facilities.map((facility) {
          return CardData(
            imagePath: 'assets/images/${facility.imagePaths.first}',
            titleKey: facility.isLiteral ? null : facility.titleKey,
            title: facility.isLiteral ? facility.titleKey : null,
            onTap: () => _showFacilityDetail(context, facility),
          );
        }).toList(),
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
    );
  }

  void _showFacilityDetail(BuildContext context, _FacilityData facility) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FacilityDetailView(facility: facility, hotel: 'Savines'),
      ),
    );
  }
}

// ─── Arenal service grid ────────────────────────────────────────────────────────

/// Arenal hotel services sub-page
class ArenalServicesView extends StatelessWidget {
  const ArenalServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final contentService = context.watch<ContentService>();
    final facilitiesData = contentService.hotels['Arenal'] as List<dynamic>? ?? [];
    final facilities = facilitiesData.map((e) => _FacilityData.fromJson(e as Map<String, dynamic>)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'Hotel Arenal',
        backgroundColor: AppColors.services,
        parentRoute: '/services',
      ),
      body: CardGrid(
        cards: facilities.map((facility) {
          return CardData(
            imagePath: 'assets/images/${facility.imagePaths.first}',
            titleKey: facility.isLiteral ? null : facility.titleKey,
            title: facility.isLiteral ? facility.titleKey : null,
            onTap: () => _showFacilityDetail(context, facility),
          );
        }).toList(),
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
    );
  }

  void _showFacilityDetail(BuildContext context, _FacilityData facility) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FacilityDetailView(facility: facility, hotel: 'Arenal'),
      ),
    );
  }
}

// ─── Facility detail view ───────────────────────────────────────────────────────

/// Facility detail view — premium redesign
class FacilityDetailView extends StatefulWidget {
  final _FacilityData facility;
  final String hotel;

  const FacilityDetailView({
    super.key,
    required this.facility,
    required this.hotel,
  });

  @override
  State<FacilityDetailView> createState() => _FacilityDetailViewState();
}

class _FacilityDetailViewState extends State<FacilityDetailView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langService = context.watch<LanguageService>();
    final isMap = widget.facility.titleKey == 'hotel_map';
    final accent = widget.facility.accentColor ?? AppColors.services;

    // Images to display in the detail view
    final hasDashTwo = widget.facility.imagePaths.any((p) => p.contains('-2'));
    final displayImages = isMap
        ? widget.facility.imagePaths
        : (hasDashTwo
            ? widget.facility.imagePaths.where((p) => p.contains('-2')).toList()
            : widget.facility.imagePaths);

    final title = widget.facility.isLiteral
        ? widget.facility.titleKey
        : langService.translate(widget.facility.titleKey);

    if (isMap) {
      return _buildMapView(context, langService, displayImages, title, accent);
    }

    return _buildDetailView(context, langService, displayImages, title, accent);
  }

  // ── Map layout ──────────────────────────────────────────────────────────────

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
          // Map legend panel
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
              border: Border(right: BorderSide(color: Colors.white12)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Legend header
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
                  if (widget.facility.descriptionKey != null)
                    Text(
                      Translations.get(
                          widget.facility.descriptionKey!, langService.currentLanguage),
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
          // Map image
          Expanded(
            child: images.isNotEmpty
                ? AppImage(
                    path: 'assets/images/${images.first}',
                    fit: BoxFit.contain,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Facility detail layout ──────────────────────────────────────────────────

  Widget _buildDetailView(
    BuildContext context,
    LanguageService langService,
    List<String> images,
    String title,
    Color accent,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        titleKey: title,
        backgroundColor: AppColors.services,
        parentRoute: '/hotel-services',
      ),
      body: Row(
        children: [
          // ── Left panel: info ──────────────────────────────────────────────
          Container(
            width: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.88),
                  const Color(0xFF0D0D0D).withValues(alpha: 0.95),
                ],
              ),
              border: Border(right: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent top bar
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.0)]),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Facility icon + title
                        if (widget.facility.headerIcon != null) ...[
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accent.withValues(alpha: 0.35)),
                            ),
                            child: Icon(widget.facility.headerIcon, color: accent, size: 28),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Schedule ──────────────────────────────────────
                        if (widget.facility.schedule.isNotEmpty) ...[
                          _SectionHeader(
                            icon: Icons.schedule,
                            label: langService.translate('opening_hours'),
                            accent: accent,
                          ),
                          const SizedBox(height: 10),
                          ...widget.facility.schedule.map(
                            (entry) => _ScheduleChip(entry: entry, accent: accent),
                          ),
                          const SizedBox(height: 20),
                        ] else if (widget.facility.hours != null) ...[
                          // Legacy fallback
                          _SectionHeader(
                            icon: Icons.schedule,
                            label: langService.translate('opening_hours'),
                            accent: accent,
                          ),
                          const SizedBox(height: 10),
                          _LegacyHoursCard(hours: widget.facility.hours!, accent: accent),
                          const SizedBox(height: 20),
                        ],

                        // ── Features ──────────────────────────────────────
                        if (widget.facility.features.isNotEmpty) ...[
                          _SectionHeader(
                            icon: Icons.star_outline,
                            label: 'Highlights',
                            accent: accent,
                          ),
                          const SizedBox(height: 10),
                          ...widget.facility.features.map(
                            (f) => _FeatureRow(bullet: f, accent: accent),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Safety rules ──────────────────────────────────
                        if (widget.facility.hasSafetyRules) ...[
                          const SizedBox(height: 4),
                          _SafetyRulesButton(
                            hotel: widget.hotel,
                            langService: langService,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right panel: images ───────────────────────────────────────────
          Expanded(
            child: images.isEmpty
                ? const SizedBox.shrink()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // PageView of images
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, i) {
                          return AppImage(
                            path: 'assets/images/${images[i]}',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      // Gradient overlay at bottom
                      Positioned(
                        left: 0, right: 0, bottom: 0,
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
                      // Page indicator dots
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0, right: 0,
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
                      // Nav arrows
                      if (images.length > 1) ...[
                        if (_currentPage > 0)
                          Positioned(
                            left: 12,
                            top: 0, bottom: 0,
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
                            top: 0, bottom: 0,
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
                  entry.label,
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
                bullet.isLiteral
                    ? bullet.text
                    : context.watch<LanguageService>().translate(bullet.text),
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
  final String hotel;
  final LanguageService langService;

  const _SafetyRulesButton({required this.hotel, required this.langService});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SafetyRulesView(hotel: hotel),
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

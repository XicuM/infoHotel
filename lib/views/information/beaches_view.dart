import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../l10n/translations.dart';
import '../../models/beach.dart';
import '../../services/content_service.dart';
import '../../services/beach_service.dart';
import '../../services/language_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/grid_widget.dart';
import '../../widgets/generic_menu_view.dart';
import '../../widgets/localized_text_field.dart';
import '../../widgets/app_image.dart';

class BeachesView extends StatelessWidget {
  const BeachesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ContentService, BeachService, LanguageService>(
      builder: (context, contentService, beachService, langService, child) {
        final beaches = beachService.beaches;
        final isEditMode = contentService.isEditMode;

        List<CardData> cards = beaches.map((beach) {
          final isAbsolute = beach.imagePath.startsWith('/') || beach.imagePath.startsWith('http');
          final cardImage = isAbsolute
              ? beach.imagePath
              : (beach.imagePath.startsWith('hotel_assets/')
                  ? beach.imagePath
                  : 'hotel_assets/images/${beach.imagePath}');

          return CardData(
            imagePath: cardImage,
            title: beach.getName(langService.currentLanguage),
            onTap: () => _navigateToBeach(context, beach, isEditMode),
            isLocalImage: beach.isLocalImage,
          );
        }).toList();

        if (isEditMode) {
          cards.add(CardData(
            iconData: Icons.add_photo_alternate_outlined,
            title: 'Add New',
            onTap: () => _addNewBeach(context, contentService),
          ));
        }

        return GenericMenuView(
          titleKey: 'beaches',
          appBarColor: const Color(0xFF00BCD4),
          parentRoute: '/information',
          onBack: () => Navigator.of(context).pop(),
          isLoading: beachService.isLoading,
          cards: cards,
          crossAxisCount: 4,
          childAspectRatio: 0.8,
        );
      },
    );
  }

  void _navigateToBeach(BuildContext context, BeachModel beach, bool isEditMode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BeachDetailView(beach: beach),
      ),
    );
  }

  void _addNewBeach(BuildContext context, ContentService contentService) async {
    final newId = 'beach_${DateTime.now().millisecondsSinceEpoch}';
    final newBeach = BeachModel(
      id: newId,
      name: 'New Beach',
      localizedNames: {'en': 'New Beach'},
      description: 'Description',
      localizedDescriptions: {'en': 'Description'},
      imagePath: 'hotel_assets/images/ui/placeholder.png',
      galleryImages: [],
      isCustom: true,
      municipality: '',
      services: [],
    );

    await context.read<BeachService>().addBeach(newBeach);
    if (context.mounted) {
      _navigateToBeach(context, newBeach, true);
    }
  }
}

class BeachDetailView extends StatefulWidget {
  final BeachModel beach;

  const BeachDetailView({super.key, required this.beach});

  @override
  State<BeachDetailView> createState() => _BeachDetailViewState();
}

class _BeachDetailViewState extends State<BeachDetailView> {
  late PageController _pageController;
  int _currentPage = 0;

  late Map<String, String> _localizedNames;
  late Map<String, String> _localizedDescriptions;
  late Map<String, String> _localizedMunicipalities;
  late List<String> _galleryImages;
  late String _imagePath;
  late List<String> _services;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initBuffers();
  }

  void _initBuffers() {
    _localizedNames = Map.from(widget.beach.localizedNames);
    _localizedDescriptions = Map.from(widget.beach.localizedDescriptions);
    _localizedMunicipalities = Map.from(widget.beach.localizedMunicipalities);
    _galleryImages = List.from(widget.beach.galleryImages);
    _imagePath = widget.beach.imagePath;
    _services = List.from(widget.beach.services);
  }

  @override
  void didUpdateWidget(BeachDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.beach.id != oldWidget.beach.id) {
      _initBuffers();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _saveChanges(BeachService beachService) {
    final updatedBeach = BeachModel(
      id: widget.beach.id,
      name: widget.beach.name,
      description: widget.beach.description,
      municipality: widget.beach.municipality,
      imagePath: _imagePath,
      galleryImages: _galleryImages,
      isCustom: true,
      localizedNames: _localizedNames,
      localizedDescriptions: _localizedDescriptions,
      localizedMunicipalities: _localizedMunicipalities,
      services: _services,
      distanceKm: widget.beach.distanceKm,
    );

    beachService.updateBeach(updatedBeach);
  }

  static const Map<String, IconData> _serviceIcons = {
    'parking': Icons.local_parking,
    'restaurant': Icons.restaurant,
    'bar': Icons.local_bar,
    'lifeguard': Icons.health_and_safety,
    'sunbeds': Icons.beach_access,
    'wc': Icons.wc,
    'water_sports': Icons.sailing,
    'accessible': Icons.accessible,
  };

  String _getServiceTranslationKey(String service) {
    const keys = {
      'parking': 'service_parking',
      'restaurant': 'service_restaurant',
      'bar': 'service_bar',
      'lifeguard': 'service_lifeguard',
      'sunbeds': 'service_sunbeds',
      'wc': 'service_wc',
      'water_sports': 'service_water_sports',
      'accessible': 'service_accessible',
    };
    return keys[service] ?? service;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ContentService>(
      builder: (context, langService, contentService, child) {
        final isEditMode = contentService.isEditMode;
        final currentLang = langService.currentLanguage;

        final title = _localizedNames.containsKey(currentLang) || widget.beach.isCustom
            ? (_localizedNames[currentLang] ?? '')
            : Translations.get(widget.beach.name, currentLang);

        String actualDesc = '';
        if (_localizedDescriptions.containsKey(currentLang) || widget.beach.isCustom) {
          actualDesc = _localizedDescriptions[currentLang] ?? '';
        } else {
          actualDesc = Translations.get(widget.beach.description, currentLang);
        }

        String municipalityText = '';
        if (_localizedMunicipalities.containsKey(currentLang) || widget.beach.isCustom) {
          municipalityText = _localizedMunicipalities[currentLang] ?? '';
        } else {
          municipalityText = Translations.get(widget.beach.municipality, currentLang);
        }

        final double panelWidth = isEditMode ? 480.0 : 320.0;
        final accent = const Color(0xFF00BCD4);

        final displayImages = _galleryImages.isEmpty ? [_imagePath] : _galleryImages;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: CustomAppBar(
            titleKey: title,
            backgroundColor: accent,
            parentRoute: '/beaches',
            onBack: () {
              if (isEditMode) _saveChanges(context.read<BeachService>());
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
                            title: const Text('Delete Beach?'),
                            content: const Text('Are you sure you want to delete this beach? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  await context.read<BeachService>().deleteBeach(widget.beach.id);
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
                        _saveChanges(context.read<BeachService>());
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
                        gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.0)]),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: isEditMode
                            ? _buildEditForm(context, langService, contentService, accent)
                            : _buildReadOnlyContent(context, actualDesc, municipalityText, langService, accent),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: displayImages.isEmpty
                    ? const SizedBox.shrink()
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: displayImages.length,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemBuilder: (context, i) {
                              final imgPath = displayImages[i];
                              final isAbsolute = imgPath.startsWith('/') || imgPath.startsWith('http');
                              final fullPath = isAbsolute
                                  ? imgPath
                                  : (imgPath.startsWith('hotel_assets/')
                                      ? imgPath
                                      : 'hotel_assets/images/$imgPath');

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
                          if (displayImages.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(displayImages.length, (i) {
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
                          if (displayImages.length > 1) ...[
                            if (_currentPage > 0)
                              Positioned(
                                left: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentPage < displayImages.length - 1)
                              Positioned(
                                right: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 30),
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
      },
    );
  }

  Widget _buildReadOnlyContent(
    BuildContext context,
    String descText,
    String municipalityText,
    LanguageService langService,
    Color accent,
  ) {
    final currentLang = langService.currentLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (municipalityText.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.location_on, color: accent, size: 15),
              const SizedBox(width: 6),
              Text(
                municipalityText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (widget.beach.distanceKm > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.1), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: accent, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${widget.beach.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  Translations.get('from_hotel', currentLang),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (descText.isNotEmpty) ...[
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
        if (_services.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.room_service, color: accent, size: 15),
              const SizedBox(width: 6),
              Text(
                'SERVICES',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services.map((service) {
              final icon = _serviceIcons[service] ?? Icons.check_circle_outline;
              final labelKey = _getServiceTranslationKey(service);
              final label = Translations.get(labelKey, currentLang);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.15), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
          localizedValues: _localizedNames,
          defaultValue: widget.beach.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Beach Name',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
          onValuesChanged: (values) {
            setState(() {
              _localizedNames = values;
            });
          },
        ),
        const SizedBox(height: 16),
        LocalizedTextField(
          enabled: true,
          localizedValues: _localizedMunicipalities,
          defaultValue: widget.beach.municipality,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Municipality',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          onValuesChanged: (values) {
            setState(() {
              _localizedMunicipalities = values;
            });
          },
        ),
        const SizedBox(height: 16),
        LocalizedTextField(
          enabled: true,
          localizedValues: _localizedDescriptions,
          defaultValue: widget.beach.description,
          maxLines: null,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
          decoration: const InputDecoration(
            labelText: 'Description',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          onValuesChanged: (values) {
            setState(() {
              _localizedDescriptions = values;
            });
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'SERVICES',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _serviceIcons.entries.map((entry) {
            final service = entry.key;
            final icon = entry.value;
            final isSelected = _services.contains(service);
            return FilterChip(
              selected: isSelected,
              avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white54),
              label: Text(service.replaceAll('_', ' '), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white54)),
              selectedColor: accent.withValues(alpha: 0.3),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              side: BorderSide(color: isSelected ? accent : Colors.white24),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _services.add(service);
                  } else {
                    _services.remove(service);
                  }
                });
              },
            );
          }).toList(),
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
        if (_imagePath.isNotEmpty)
          Stack(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppImage(
                    path: _imagePath.startsWith('/') || _imagePath.startsWith('http') || _imagePath.startsWith('hotel_assets/')
                        ? _imagePath
                        : 'hotel_assets/images/$_imagePath',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _imagePath = ''),
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
                  subFolder: 'beaches',
                  bytes: result.files.single.bytes,
                  originalName: result.files.single.name,
                );
                setState(() {
                  _imagePath = savedPath.replaceFirst('hotel_assets/images/', '');
                });
              }
            },
          ),
        const SizedBox(height: 24),
        const Text(
          'IMAGES',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (_galleryImages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No images in gallery.', style: TextStyle(color: Colors.white38)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_galleryImages.length, (index) {
              final imgPath = _galleryImages[index];
              final isAbsolute = imgPath.startsWith('/') || imgPath.startsWith('http');
              final fullPath = isAbsolute
                  ? imgPath
                  : (imgPath.startsWith('hotel_assets/')
                      ? imgPath
                      : 'hotel_assets/images/$imgPath');

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
                            _galleryImages.removeAt(index);
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
                bytes: result.files.single.bytes,
                originalName: result.files.single.name,
              );
              setState(() {
                _galleryImages.add(savedPath);
                if (_imagePath.isEmpty || _imagePath.contains('placeholder')) {
                  _imagePath = savedPath;
                }
              });
            }
          },
        ),
      ],
    );
  }
}

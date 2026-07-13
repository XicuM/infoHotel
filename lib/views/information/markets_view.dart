import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../l10n/translations.dart';
import '../../models/market.dart';
import '../../services/content_service.dart';
import '../../services/market_service.dart';
import '../../services/language_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/grid_widget.dart';
import '../../widgets/generic_menu_view.dart';
import '../../widgets/localized_text_field.dart';
import '../../widgets/app_image.dart';
import '../pdf_viewer_view.dart';

/// Markets view showing hippy markets on the island
class MarketsView extends StatelessWidget {
  const MarketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ContentService, MarketService, LanguageService>(
      builder: (context, contentService, marketService, langService, child) {
        final markets = marketService.markets;
        final isEditMode = contentService.isEditMode;

        List<CardData> cards = markets.map((market) {
          final isAbsolute = market.imagePath.startsWith('/') || market.imagePath.startsWith('http');
          final cardImage = isAbsolute
              ? market.imagePath
              : (market.imagePath.startsWith('hotel_assets/')
                  ? market.imagePath
                  : 'hotel_assets/images/${market.imagePath}');
          
          return CardData(
            imagePath: cardImage,
            title: market.name,
            onTap: () => _navigateToMarket(context, market, isEditMode),
            isLocalImage: market.isLocalImage,
          );
        }).toList();

        if (isEditMode) {
           cards.add(CardData(
             iconData: Icons.add_photo_alternate_outlined,
             title: 'Add New',
             onTap: () => _addNewMarket(context, contentService),
           ));
        }

        return GenericMenuView(
          titleKey: 'hippy_markets',
          appBarColor: const Color(0xFFEC407A), // Pink 400
          parentRoute: '/information',
          onBack: () => Navigator.of(context).pop(),
          isLoading: marketService.isLoading,
          cards: cards,
          crossAxisCount: 4, // More premium spacious look
          childAspectRatio: 0.8,
        );
      },
    );
  }

  void _navigateToMarket(BuildContext context, MarketModel market, bool isEditMode) {
    if (!isEditMode && market.pdfPath != null && market.pdfPath!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerView(
            pdfPath: market.pdfPath!,
            title: market.name,
            backgroundColor: const Color(0xFFEC407A),
            isLocal: !market.pdfPath!.startsWith('hotel_assets/'),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MarketDetailView(market: market),
      ),
    );
  }

  void _addNewMarket(BuildContext context, ContentService contentService) async {
    final newId = 'market_${DateTime.now().millisecondsSinceEpoch}';
    final newMarket = MarketModel(
      id: newId,
      name: 'New Market',
      localizedNames: {'en': 'New Market'},
      description: 'Description',
      localizedDescriptions: {'en': 'Description'},
      imagePath: 'hotel_assets/images/ui/placeholder.png', // Needs a valid placeholder or logic to handle missing
      galleryImages: [],
      isCustom: true,
    );
    
    await context.read<MarketService>().addMarket(newMarket);
    if (context.mounted) {
       _navigateToMarket(context, newMarket, true);
    }
  }
}


/// Market detail view
class MarketDetailView extends StatefulWidget {
  final MarketModel market;

  const MarketDetailView({super.key, required this.market});

  @override
  State<MarketDetailView> createState() => _MarketDetailViewState();
}

class _MarketDetailViewState extends State<MarketDetailView> {
  late PageController _pageController;
  int _currentPage = 0;

  // Buffers for edits
  late Map<String, String> _localizedNames;
  late Map<String, String> _localizedDescriptions;
  late Map<String, String> _localizedOpeningHours;
  late List<String> _galleryImages;
  late String _imagePath;
  late String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initBuffers();
  }
  
  void _initBuffers() {
    _localizedNames = Map.from(widget.market.localizedNames);
    _localizedDescriptions = Map.from(widget.market.localizedDescriptions);
    _localizedOpeningHours = Map.from(widget.market.localizedOpeningHours);
    _galleryImages = List.from(widget.market.galleryImages);
    _imagePath = widget.market.imagePath;
    _pdfPath = widget.market.pdfPath;
  }
  
  @override
  void didUpdateWidget(MarketDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.market.id != oldWidget.market.id) {
       _initBuffers();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _saveChanges(MarketService marketService) {
    final updatedMarket = MarketModel(
      id: widget.market.id,
      name: widget.market.name, 
      description: widget.market.description,
      openingHours: widget.market.openingHours,
      imagePath: _imagePath,
      galleryImages: _galleryImages,
      isCustom: true,
      pdfPath: _pdfPath,
      localizedNames: _localizedNames,
      localizedDescriptions: _localizedDescriptions,
      localizedOpeningHours: _localizedOpeningHours,
    );
    
    marketService.updateMarket(updatedMarket);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ContentService>(
      builder: (context, langService, contentService, child) {
        final isEditMode = contentService.isEditMode;
        final currentLang = langService.currentLanguage;

        // Resolve title for AppBar (read-only)
        final title = _localizedNames.containsKey(currentLang) || widget.market.isCustom
            ? (_localizedNames[currentLang] ?? '')
            : Translations.get(widget.market.name, currentLang);
            
        String actualDesc = '';
        String? hoursText;

        if (_localizedDescriptions.containsKey(currentLang) && _localizedDescriptions[currentLang]!.isNotEmpty) {
          actualDesc = _localizedDescriptions[currentLang]!;
        } else {
          actualDesc = Translations.get(widget.market.description, currentLang);
        }

        hoursText = _localizedOpeningHours[currentLang];
        if (hoursText == null || hoursText.isEmpty) {
          hoursText = widget.market.openingHours;
        }

        final double panelWidth = isEditMode ? 480.0 : 320.0;
        final accent = const Color(0xFFEC407A); // Pink 400
        
        final displayImages = _galleryImages.isEmpty ? [_imagePath] : _galleryImages;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: CustomAppBar(
            titleKey: title, 
            backgroundColor: accent,
            parentRoute: '/markets',
            onBack: () {
              if (isEditMode) _saveChanges(context.read<MarketService>());
              Navigator.of(context).pop();
            },
            actions: isEditMode ? [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 32),
                onPressed: () {
                   showDialog(
                     context: context, 
                     builder: (context) => AlertDialog(
                       title: const Text('Delete Market?'),
                       content: const Text('Are you sure you want to delete this market? This cannot be undone.'),
                       actions: [
                         TextButton(
                           onPressed: () => Navigator.of(context).pop(),
                           child: const Text('Cancel'),
                         ),
                         TextButton(
                           onPressed: () async {
                             Navigator.of(context).pop(); // Close dialog
                             Navigator.of(context).pop(); // Close detail view
                             await context.read<MarketService>().deleteMarket(widget.market.id);
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
                  _saveChanges(context.read<MarketService>());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Changes saved successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
            ] : null,
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
                            : _buildReadOnlyContent(context, actualDesc, hoursText, accent),
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
    String? hoursText,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (hoursText != null && hoursText.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.schedule, color: accent, size: 15),
              const SizedBox(width: 6),
              Text(
                'OPENING HOURS',
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.1), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              hoursText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_pdfPath != null && _pdfPath!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PDF Brochure Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Close edit mode to view', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
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
          defaultValue: widget.market.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Market Name',
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
          localizedValues: _localizedDescriptions,
          defaultValue: widget.market.description,
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
        LocalizedTextField(
          enabled: true,
          localizedValues: _localizedOpeningHours,
          defaultValue: widget.market.openingHours,
          maxLines: null,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
          decoration: const InputDecoration(
            labelText: 'Opening Hours',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          onValuesChanged: (values) {
            setState(() {
              _localizedOpeningHours = values;
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
                  subFolder: 'markets',
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
          'BROCHURE (PDF)',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (_pdfPath != null && _pdfPath!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(child: Text('Selected PDF:\n${_pdfPath!.split('/').last}', style: const TextStyle(color: Colors.white, fontSize: 13))),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _pdfPath = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ] else ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Select PDF'),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.pickFiles(
                type: FileType.custom, 
                allowedExtensions: ['pdf'],
                withData: true,
              );
              if (result != null && (result.files.single.path != null || kIsWeb)) {
                // Using saveImage since it works identically for any file type based on StorageRepository logic
                final savedPath = await contentService.saveImage(
                  result.files.single.path ?? '',
                  bytes: result.files.single.bytes,
                  originalName: result.files.single.name,
                  subFolder: 'markets',
                );
                setState(() {
                  _pdfPath = savedPath;
                });
              }
            },
          ),
        ],
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
                // Also update main image if empty or not set
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


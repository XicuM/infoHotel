import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/translations.dart';
import '../../models/market.dart';
import '../../services/content_service.dart';
import '../../services/language_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/grid_widget.dart';
import '../../widgets/localized_text_field.dart';
import '../../widgets/app_image.dart';

/// Markets view showing hippy markets on the island
class MarketsView extends StatelessWidget {
  const MarketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ContentService, LanguageService>(
      builder: (context, contentService, langService, child) {
        final markets = contentService.markets;
        final isEditMode = contentService.isEditMode;

        List<CardData> cards = markets.map((market) {
          return CardData(
            imagePath: market.isLocalImage || market.imagePath.startsWith('assets/')
                ? market.imagePath
                : 'assets/images/${market.imagePath}',
            title: market.name,
            onTap: () => _navigateToMarket(context, market),
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

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(
            titleKey: 'hippy_markets',
            backgroundColor: const Color(0xFFEC407A), // Pink 400
            parentRoute: '/information',
            onBack: () => Navigator.of(context).pop(),
          ),
          body: Column(
            children: [
              // Premium Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEC407A).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFEC407A), width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_outlined, color: Color(0xFFEC407A), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        langService.translate('hippy_markets'),
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main grid content
              Expanded(
                child: contentService.isLoading
                    ? Center(child: CircularProgressIndicator(color: const Color(0xFFEC407A)))
                    : CardGrid(
                        cards: cards,
                        crossAxisCount: 4, // More premium spacious look
                        childAspectRatio: 0.8,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToMarket(BuildContext context, MarketModel market) {
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
      imagePath: 'assets/images/ui/placeholder.png', // Needs a valid placeholder or logic to handle missing
      galleryImages: [],
      isCustom: true,
    );
    
    await contentService.addMarket(newMarket);
    if (context.mounted) {
       _navigateToMarket(context, newMarket);
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
  // Buffers for edits
  late Map<String, String> _localizedNames;
  late Map<String, String> _localizedDescriptions;

  @override
  void initState() {
    super.initState();
    _initBuffers();
  }
  
  void _initBuffers() {
    _localizedNames = Map.from(widget.market.localizedNames);
    _localizedDescriptions = Map.from(widget.market.localizedDescriptions);
  }
  
  @override
  void didUpdateWidget(MarketDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.market.id != oldWidget.market.id) {
       _initBuffers();
    }
  }

  void _saveChanges(ContentService contentService) {
     final updatedMarket = MarketModel(
        id: widget.market.id,
        name: widget.market.name, 
        description: widget.market.description,
        imagePath: widget.market.imagePath,
        galleryImages: widget.market.galleryImages,
        isCustom: true,
        localizedNames: _localizedNames,
        localizedDescriptions: _localizedDescriptions,
      );
      contentService.updateMarket(updatedMarket);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ContentService>(
      builder: (context, langService, contentService, child) {
        final isEditMode = contentService.isEditMode;
        final currentLang = langService.currentLanguage;

        // Resolve title for AppBar (read-only)
        final title = _localizedNames.containsKey(currentLang) 
            ? _localizedNames[currentLang]! 
            : Translations.get(widget.market.name, currentLang);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(
            titleKey: title, 
            backgroundColor: const Color(0xFFEC407A),
            parentRoute: '/markets',
            onBack: () {
              if (isEditMode) _saveChanges(contentService);
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
                             await contentService.deleteMarket(widget.market.id);
                           },
                           style: TextButton.styleFrom(foregroundColor: Colors.red),
                           child: const Text('Delete'),
                         ),
                       ],
                     ),
                   );
                },
              ),
              const SizedBox(width: 16),
            ] : null,
          ),
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.translucent,
             child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Column (Left)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedTextField(
                            enabled: isEditMode,
                            localizedValues: _localizedNames,
                            defaultValue: widget.market.name,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                            onValuesChanged: (values) {
                              _localizedNames = values;
                              _saveChanges(contentService);
                            },
                          ),
                          
                          const SizedBox(height: 8),

                          LocalizedTextField(
                            enabled: isEditMode,
                            localizedValues: _localizedDescriptions,
                            defaultValue: widget.market.description,
                            maxLines: null,
                            style: const TextStyle(fontSize: 20, height: 1.5, color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            ),
                            onValuesChanged: (values) {
                              _localizedDescriptions = values;
                              _saveChanges(contentService);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Image Gallery (Right)
                  Expanded(
                    flex: 3,
                    child: _buildImageGallery(context, widget.market, contentService),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGallery(BuildContext context, MarketModel market, ContentService contentService) {
    return Column(
      children: [
        if (contentService.isEditMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Change Main Logo/Image'),
              onPressed: () async {
                 FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image);
                 if (result != null && result.files.single.path != null) {
                   final newPath = await contentService.saveImage(result.files.single.path!);
                   final updatedMarket = MarketModel(
                        id: market.id,
                        name: market.name,
                        description: market.description,
                        imagePath: newPath,
                        galleryImages: market.galleryImages,
                        isCustom: true,
                        localizedNames: _localizedNames,
                        localizedDescriptions: _localizedDescriptions,
                      );
                      contentService.updateMarket(updatedMarket);
                 }
              },
            ),
          ),
          
        Expanded(
          child: Builder(
            builder: (context) {
              if (market.galleryImages.isEmpty) {
                return Center(
                  child: _buildImage(market.imagePath, market.isLocalImage),
                );
              }
          
              return GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: market.galleryImages.map((path) {
                   bool isLocal = !path.startsWith('markets/'); 
                   return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImage(isLocal ? path : 'assets/images/$path', isLocal),
                  );
                }).toList(),
              );
            }
          ),
        ),
      ],
    );
  }
  
  Widget _buildImage(String path, bool isLocal) {
    return AppImage(
      path: path,
      fit: isLocal ? BoxFit.cover : BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }
}

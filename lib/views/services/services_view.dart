import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/language_service.dart';
import '../../services/content_service.dart';
import '../../services/hotel_config_service.dart';
import '../../services/hotel_service.dart';
import '../../models/hotel_config.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/card_widget.dart';
import 'shows_view.dart';
import 'hotel_services_view.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/show_service.dart';

class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final showService = context.watch<ShowService>();
    return Consumer4<ContentService, HotelConfigService, LanguageService, HotelService>(
      builder: (context, contentService, hotelConfigService, langService, activeHotelService, child) {
        final hotelConfigs = hotelConfigService.sortedHotelConfigs;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(
            titleKey: 'facilities',
            backgroundColor: AppColors.services,
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.services.withOpacity(0.18),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border(
                    left: BorderSide(color: AppColors.services, width: 3),
                  ),
                ),
                child: Text(
                  langService.translate('info_for_all_clients'),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (contentService.isEditMode || !hotelConfigs.every((h) => !h.showShows))
                        Expanded(
                          flex: 20,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              InfoCard(
                                imagePath: showService.getShowImage('card_image'),
                                titleKey: 'shows',
                                isLocalImage: !showService.getShowImage('card_image').startsWith('hotel_assets/'),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ShowsView(),
                                    ),
                                  );
                                },
                              ),
                              if (contentService.isEditMode)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                      onPressed: () => _editShowsConfig(context, hotelConfigService, showService, contentService),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 16),
                      ...hotelConfigs.map((config) {
                        return Expanded(
                          flex: 40,
                          child: InfoCard(
                            imagePath: config.cardImage,
                            title: config.name,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FacilitiesView(hotelId: config.id),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      ...hotelConfigs.map((c) => const SizedBox(width: 16)),
                      if (contentService.isEditMode)
                        Expanded(
                          flex: 20,
                          child: InfoCard(
                            iconData: Icons.add_business,
                            titleKey: 'add_hotel',
                            onTap: () => _addHotel(context, hotelConfigService),
                          ),
                        ),
                    ].whereType<Widget>().toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editShowsConfig(BuildContext context, HotelConfigService hotelConfigService, ShowService showService, ContentService contentService) {
    final hotelConfigs = hotelConfigService.sortedHotelConfigs;
    Map<String, bool> hotelShowsMap = {
      for (var h in hotelConfigs) h.id: h.showShows
    };
    
    String newImagePath = showService.getShowImage('card_image');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Shows Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Card Image', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(newImagePath, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image_search),
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
                        if (result != null && (result.files.single.path != null || kIsWeb)) {
                          final localPath = await contentService.saveImage(
                            result.files.single.path ?? '',
                            subFolder: 'shows',
                            bytes: result.files.single.bytes,
                            originalName: result.files.single.name,
                          );
                          setDialogState(() {
                            newImagePath = localPath;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Enable Shows per Hotel', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...hotelConfigs.map((h) => CheckboxListTile(
                  title: Text(h.name),
                  value: hotelShowsMap[h.id],
                  onChanged: (val) {
                    setDialogState(() {
                      hotelShowsMap[h.id] = val ?? false;
                    });
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update image
                showService.updateShowImage('card_image', newImagePath);
                
                // Update hotels
                for (var h in hotelConfigs) {
                  if (h.showShows != hotelShowsMap[h.id]) {
                    final updatedConfig = HotelConfig(
                      id: h.id,
                      name: h.name,
                      background: h.background,
                      logo: h.logo,
                      cardImage: h.cardImage,
                      showsLogo: h.showsLogo,
                      sortOrder: h.sortOrder,
                      showShows: hotelShowsMap[h.id] ?? false,
                    );
                    hotelConfigService.saveHotelConfig(updatedConfig);
                  }
                }
                
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _addHotel(BuildContext context, HotelConfigService hotelConfigService) {
    final nameController = TextEditingController(text: 'New Hotel');
    final bgController = TextEditingController(text: 'hotel_assets/images/background/savines.jpg');
    final logoController = TextEditingController(text: 'hotel_assets/images/logo/savines.png');
    final cardImageController = TextEditingController(text: 'hotel_assets/images/facilities/savines.png');
    final showsLogoController = TextEditingController(text: 'hotel_assets/images/shows/savines.png');
    bool showShows = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Hotel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Hotel Name'),
                ),
                TextField(
                  controller: bgController,
                  decoration: const InputDecoration(labelText: 'Background Image Path'),
                ),
                TextField(
                  controller: logoController,
                  decoration: const InputDecoration(labelText: 'Logo Image Path'),
                ),
                TextField(
                  controller: cardImageController,
                  decoration: const InputDecoration(labelText: 'Card Image Path'),
                ),
                TextField(
                  controller: showsLogoController,
                  decoration: const InputDecoration(labelText: 'Shows Logo Path'),
                ),
                SwitchListTile(
                  title: const Text('Show Shows'),
                  value: showShows,
                  onChanged: (v) => setDialogState(() => showShows = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final id = nameController.text.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
                if (id.isEmpty || nameController.text.isEmpty) return;
                
                final maxOrder = context.read<HotelConfigService>().sortedHotelConfigs.fold(0, (max, c) => c.sortOrder > max ? c.sortOrder : max);
                
                final config = HotelConfig(
                  id: id,
                  name: nameController.text,
                  background: bgController.text,
                  logo: logoController.text,
                  cardImage: cardImageController.text,
                  showsLogo: showsLogoController.text,
                  showShows: showShows,
                  sortOrder: maxOrder + 1,
                );
                context.read<HotelConfigService>().saveHotelConfig(config);
                Navigator.of(ctx).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

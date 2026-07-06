import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/excursion.dart';
import '../../services/content_service.dart';
import '../../services/excursion_service.dart';
import '../../services/language_service.dart';
import '../../widgets/grid_widget.dart';
import '../../widgets/generic_menu_view.dart';
import '../pdf_viewer_view.dart';
import '../image_viewer_view.dart';
import 'excursion_edit_view.dart';

/// Modernized Excursions view with grid of excursion companies
class ExcursionsView extends StatelessWidget {
  const ExcursionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ContentService, ExcursionService, LanguageService>(
      builder: (context, contentService, excursionService, langService, child) {
        final excursions = excursionService.excursions;
        final isEditMode = contentService.isEditMode;

        List<CardData> cards = excursions.map((excursion) {
          return CardData(
            imagePath: excursion.imagePath,
            title: excursion.getName(langService.currentLanguage),
            onTap: () => isEditMode
                ? _editExcursion(context, excursion)
                : _openExcursion(context, excursion),
            isLocalImage: excursion.isLocalImage,
          );
        }).toList();

        if (isEditMode) {
          // Add "Add New" card in edit mode
          cards.add(CardData(
            iconData: Icons.add_photo_alternate_outlined,
            title: 'Add New',
            onTap: () => _addNewExcursion(context),
          ));
        }

        return GenericMenuView(
          titleKey: 'excursions',
          appBarColor: AppColors.excursions,
          cards: cards,
          isLoading: excursionService.isLoading,
          crossAxisCount: 4,
          childAspectRatio: 0.8,
        );
      },
    );
  }

  void _editExcursion(BuildContext context, ExcursionModel excursion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExcursionEditView(excursion: excursion),
      ),
    );
  }

  void _addNewExcursion(BuildContext context) {
    final newExcursion = ExcursionModel(
      id: 'excursion_${DateTime.now().millisecondsSinceEpoch}',
      name: 'New Excursion',
      localizedNames: {'en': 'New Excursion'},
      imagePath: 'hotel_assets/images/ui/placeholder.png',
      type: ExcursionType.images,
      content: [],
      isLocalImage: false,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExcursionEditView(excursion: newExcursion, isNew: true),
      ),
    );
  }

  void _openExcursion(BuildContext context, ExcursionModel excursion) {
    if (excursion.type == ExcursionType.pdf) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerView(
            pdfPath: excursion.content as String,
            title: excursion.name,
            backgroundColor: AppColors.excursions,
            isLocal: !(excursion.content as String).startsWith('hotel_assets/'),
            logoPath: excursion.imagePath,
            isLogoLocal: excursion.isLocalImage,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageViewerView(
            imagePaths: (excursion.content as List).cast<String>(),
            title: excursion.name,
            backgroundColor: AppColors.excursions,
            parentRoute: '/excursions',
            logoPath: excursion.imagePath,
            isLogoLocal: excursion.isLocalImage,
          ),
        ),
      );
    }
  }
}

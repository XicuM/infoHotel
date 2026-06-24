import 'package:flutter/material.dart';
import 'card_widget.dart';

/// Grid layout widget matching the Pygame Grid element
/// Displays cards in a 5-column layout
class CardGrid extends StatelessWidget {
  final List<CardData> cards;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;

  const CardGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 5,
    this.spacing = 16,
    this.childAspectRatio = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return InfoCard(
          imagePath: card.imagePath,
          iconData: card.iconData,
          titleKey: card.titleKey,
          title: card.title,
          onTap: card.onTap,
          isLocalImage: card.isLocalImage,
        );
      },
    );
  }
}

/// Data class for card items
class CardData {
  final String? imagePath;
  final IconData? iconData;
  final String? titleKey;
  final String? title;
  final VoidCallback? onTap;
  final bool isLocalImage;

  const CardData({
    this.imagePath,
    this.iconData,
    this.titleKey,
    this.title,
    this.onTap,
    this.isLocalImage = false,
  });
}

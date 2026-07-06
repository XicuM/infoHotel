import 'package:flutter/material.dart';
import 'app_bar_widget.dart';
import 'grid_widget.dart';
import '../config/app_config.dart';

/// A generalized menu view that displays a Scaffold with a CustomAppBar,
/// an optional banner, and a grid of cards (CardGrid).
class GenericMenuView extends StatelessWidget {
  final String titleKey;
  final Color appBarColor;
  final List<CardData> cards;
  final bool isLoading;
  final Widget? banner;
  final String? parentRoute;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final int crossAxisCount;
  final double childAspectRatio;

  const GenericMenuView({
    super.key,
    required this.titleKey,
    required this.appBarColor,
    required this.cards,
    this.isLoading = false,
    this.banner,
    this.parentRoute,
    this.onBack,
    this.actions,
    this.crossAxisCount = 4,
    this.childAspectRatio = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: titleKey,
        backgroundColor: appBarColor,
        parentRoute: parentRoute,
        onBack: onBack,
        actions: actions,
      ),
      body: Column(
        children: [
          if (banner != null) banner!,
          Expanded(
            child: isLoading
                ? Center(child: AppConfig.lowPowerMode 
                    ? Icon(Icons.hourglass_empty, color: appBarColor, size: 36) 
                    : CircularProgressIndicator(color: appBarColor))
                : CardGrid(
                    cards: cards,
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                  ),
          ),
        ],
      ),
    );
  }
}

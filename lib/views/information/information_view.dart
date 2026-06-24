import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/grid_widget.dart';
import 'maps_view.dart';
import 'markets_view.dart';
import 'taxi_view.dart';
import 'car_rental_view.dart';
import '../pdf_viewer_view.dart';

/// Tourist information view
/// Ported from layout/information/information.py
class InformationView extends StatelessWidget {
  const InformationView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CardData> cards = [
      CardData(
        imagePath: 'assets/images/information/maps.jpg',
        titleKey: 'maps',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MapsView(),
            ),
          );
        },
      ),
      CardData(
        imagePath: 'assets/images/information/bus.jpg',
        titleKey: 'bus',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PdfViewerView(
                pdfPath: 'assets/pdf/bus_map.pdf',
                title: 'Bus Map',
                backgroundColor: AppColors.information,
                enableBookMode: false,
              ),
            ),
          );
        },
      ),
      CardData(
        iconData: Icons.local_taxi,
        titleKey: 'taxi',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TaxiView(),
            ),
          );
        },
      ),
      CardData(
        iconData: Icons.car_rental,
        titleKey: 'car_rental',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CarRentalView(),
            ),
          );
        },
      ),
      CardData(
        imagePath: 'assets/images/information/markets.jpg',
        titleKey: 'hippy_markets',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MarketsView(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'tourist_info',
        backgroundColor: AppColors.information,
      ),
      body: Column(
        children: [
          Expanded(
            child: CardGrid(
              cards: cards,
              crossAxisCount: 4,
              childAspectRatio: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

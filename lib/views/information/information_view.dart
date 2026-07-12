import 'package:flutter/material.dart';
import '../../config/env.dart';
import '../../config/theme.dart';
import '../../widgets/grid_widget.dart';
import '../../widgets/generic_menu_view.dart';
import 'maps_view.dart';
import 'markets_view.dart';
import 'taxi_view.dart';
import 'car_rental_view.dart';
import 'bus_view.dart';
import 'beaches_view.dart';

/// Tourist information view
/// Ported from layout/information/information.py
class InformationView extends StatelessWidget {
  const InformationView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CardData> cards = [
      CardData(
        imagePath: 'hotel_assets/images/information/maps.jpg',
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
        imagePath: 'hotel_assets/images/information/beaches.jpg',
        titleKey: 'beaches',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BeachesView(),
            ),
          );
        },
      ),
      if (Env.busApiKey.isNotEmpty)
        CardData(
          imagePath: 'hotel_assets/images/information/bus.jpg',
          titleKey: 'bus',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BusView(),
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
        imagePath: 'hotel_assets/images/information/markets.jpg',
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

    return GenericMenuView(
      titleKey: 'tourist_info',
      appBarColor: AppColors.information,
      cards: cards,
      crossAxisCount: 4,
      childAspectRatio: 0.8,
    );
  }
}

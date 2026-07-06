import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/grid_widget.dart';
import '../../widgets/generic_menu_view.dart';
import 'taxi_view.dart';
import 'car_rental_view.dart';
import 'bus_view.dart';

class TransportView extends StatelessWidget {
  const TransportView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CardData> cards = [
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
    ];

    return GenericMenuView(
      titleKey: 'transportation',
      appBarColor: AppColors.information,
      cards: cards,
      crossAxisCount: 3,
      childAspectRatio: 0.8,
    );
  }
}

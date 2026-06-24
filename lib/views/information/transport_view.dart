import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/card_widget.dart';
import '../pdf_viewer_view.dart';
import 'taxi_view.dart';
import 'car_rental_view.dart';

class TransportView extends StatelessWidget {
  const TransportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'transportation',
        backgroundColor: AppColors.information,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bus card
            Expanded(
              child: InfoCard(
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
            ),

            const SizedBox(width: 16),

            // Taxi card
            Expanded(
              child: InfoCard(
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
            ),

            const SizedBox(width: 16),

            // Car Rental card
            Expanded(
              child: InfoCard(
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
            ),
          ],
        ),
      ),
    );
  }
}

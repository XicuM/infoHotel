import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/card_widget.dart';
import '../../widgets/language_bar.dart';
import 'maps_view.dart';
import 'markets_view.dart';
import 'flight_board_view.dart';
import '../pdf_viewer_view.dart';

/// Tourist information view
/// Ported from layout/information/information.py
class InformationView extends StatelessWidget {
  const InformationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'tourist_info',
        backgroundColor: AppColors.information,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Maps card
            Expanded(
              child: InfoCard(
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
            ),

            const SizedBox(width: 16),

            // Bus card
            Expanded(
              child: InfoCard(
                imagePath: 'assets/images/information/bus.jpg',
                title: 'Bus',
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

            // Markets card
            Expanded(
              child: InfoCard(
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
            ),

            const SizedBox(width: 16),

            // Flight Board card
            Expanded(
              child: InfoCard(
                iconData: Icons.flight_takeoff,
                titleKey: 'flight_board',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FlightBoardView(),
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

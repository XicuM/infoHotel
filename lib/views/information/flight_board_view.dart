import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class FlightBoardView extends StatelessWidget {
  const FlightBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'flight_board',
        backgroundColor: AppColors.information,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Consumer<LanguageService>(
            builder: (context, langService, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stylish Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.information,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.flight_takeoff, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          langService.translate('scan_flights'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // QR Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          QrImageView(
                            data: 'https://www.aena.es/en/ibiza/flight-info/departures.html',
                            version: QrVersions.auto,
                            size: 300.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            langService.translate('flight_board_desc'),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

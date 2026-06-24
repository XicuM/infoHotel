import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/language_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/card_widget.dart';
import 'shows_view.dart';
import 'hotel_services_view.dart';

/// Services view showing hotel facilities
/// Ported from layout/services/services.py
class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'hotel_services',
        backgroundColor: AppColors.services,
      ),
      body: Column(
        children: [
          // Info banner — glassmorphism style
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
            child: Consumer<LanguageService>(
              builder: (context, langService, child) {
                return Text(
                  langService.translate('info_for_all_clients'),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                );
              },
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shows card
                  SizedBox(
                    width: 220,
                    child: InfoCard(
                      imagePath: 'assets/images/facilities/shows.jpg',
                      titleKey: 'shows',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ShowsView(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Savines hotel card
                  Expanded(
                    child: InfoCard(
                      imagePath: 'assets/images/facilities/savines.png',
                      title: 'Hotel Ses Savines',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SavinesServicesView(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Arenal hotel card
                  Expanded(
                    child: InfoCard(
                      imagePath: 'assets/images/facilities/arenal.png',
                      title: 'Hotel Arenal',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ArenalServicesView(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

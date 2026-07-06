import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/generic_info_modal_view.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class TaxiView extends StatelessWidget {
  const TaxiView({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericInfoModalView(
      titleKey: 'taxi',
      backgroundColor: AppColors.information,
      headerIcon: Icons.local_taxi,
      headerTitle: 'Radio Taxi Sant Antoni',
      headerSubtitle: '+34 971 34 37 64',
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
      bodyContent: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Consumer<LanguageService>(
          builder: (context, langService, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    langService.translate('estimated_fares'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildFareRow('Aeroport (IBZ)', '~ 35€'),
                  const Divider(height: 16),
                  _buildFareRow('Eivissa (Ibiza Town)', '~ 30€'),
                  const Divider(height: 16),
                  _buildFareRow('Santa Eulària', '~ 40€'),
                  const Divider(height: 16),
                  _buildFareRow('Las Dalias', '~ 45€'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFareRow(String destination, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          destination,
          style: const TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        Text(
          price,
          style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

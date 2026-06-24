import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class TaxiView extends StatelessWidget {
  const TaxiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'taxi',
        backgroundColor: AppColors.information,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
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
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.information,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.local_taxi, size: 80, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Radio Taxi Sant Antoni',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '+34 971 34 37 64',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
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
              ),
            ],
          ),
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

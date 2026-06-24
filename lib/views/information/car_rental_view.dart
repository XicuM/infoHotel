import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class CarRentalView extends StatelessWidget {
  const CarRentalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'car_rental',
        backgroundColor: AppColors.information,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
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
                    Icon(Icons.car_rental, size: 80, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Rent a Car / Scooter',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Consumer<LanguageService>(
                    builder: (context, langService, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            langService.translate('car_rental_desc'),
                            style: const TextStyle(fontSize: 24, color: Colors.black87, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.check),
                            label: Text(
                              langService.translate('car_rental_button'),
                              style: const TextStyle(fontSize: 20),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.information,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                          ),
                        ],
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
}

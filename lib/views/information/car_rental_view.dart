import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/generic_info_modal_view.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class CarRentalView extends StatelessWidget {
  const CarRentalView({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericInfoModalView(
      titleKey: 'car_rental',
      backgroundColor: AppColors.information,
      headerIcon: Icons.car_rental,
      headerTitle: 'Rent a Car / Scooter',
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
      bodyContent: Padding(
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
    );
  }
}

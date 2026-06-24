import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../widgets/app_image.dart';

class AirportTransferView extends StatelessWidget {
  const AirportTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'airport_transfer',
        backgroundColor: AppColors.information,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
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
          child: Row(
            children: [
              // Image or map showing stop 18
              Expanded(
                flex: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    bottomLeft: Radius.circular(32),
                  ),
                  child: Container(
                    color: AppColors.information,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.airport_shuttle, size: 120, color: Colors.white),
                        const SizedBox(height: 24),
                        Text(
                          'Transfer Stop 18',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Info content
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Consumer<LanguageService>(
                    builder: (context, langService, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            langService.translate('transfer_info_title'),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            langService.translate('transfer_info_desc'),
                            style: const TextStyle(fontSize: 20, color: Colors.black54, height: 1.5),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.amber, size: 32),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    langService.translate('transfer_reception_note'),
                                    style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
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

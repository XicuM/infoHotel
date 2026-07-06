import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/hotel_config_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/app_image.dart';
import '../../services/language_service.dart';
import '../../services/content_service.dart';
import 'package:provider/provider.dart';

class SafetyRulesView extends StatelessWidget {
  final String hotelId;

  const SafetyRulesView({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ContentService, LanguageService>(
      builder: (context, contentService, langService, _) {
        final hotelService = context.watch<HotelConfigService>();
        final hotelConfig = hotelService.getHotelConfig(hotelId);
        final bgPath = hotelConfig?.background ?? '';

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: CustomAppBar(
            titleKey: 'safety_rules',
            backgroundColor: AppColors.services,
            parentRoute: '/services',
            onBack: () => Navigator.of(context).pop(),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                path: bgPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: _buildRulesPanel(langService)),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPoolsPanel(langService, hotelId),
                            const SizedBox(height: 24),
                            _buildWarningCard(
                              color: const Color(0xFFF9A825),
                              icon: Icons.access_time_filled,
                              title: 'Opening Hours',
                              text: langService.translate('opening_hours_9_20'),
                            ),
                            const SizedBox(height: 20),
                            _buildWarningCard(
                              color: const Color(0xFFE53935),
                              icon: Icons.warning_rounded,
                              title: 'Important',
                              text: langService.translate('no_lifeguard'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRulesPanel(LanguageService langService) {
    final rulesText = langService.translate('pool_safety_list');
    final rules = rulesText.split('\n').where((s) => s.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.services.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.services.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.security, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  langService.translate('safety_rules'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: rules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                var text = rules[index];
                text = text.replaceFirst(RegExp(r'^\d+\.\s*'), '');
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolsPanel(LanguageService langService, String hotelId) {
    final isArenal = hotelId == 'Arenal';
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF29B6F6).withValues(alpha: 0.25),
            const Color(0xFF0288D1).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF29B6F6).withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.pool, color: Color(0xFF29B6F6), size: 42),
          const SizedBox(height: 16),
          Text(
            langService.translate(isArenal ? 'pool_rules_title_outdoor' : 'pool_rules_title_hotel'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (isArenal) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF29B6F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                langService.translate('heated_info'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB3E5FC),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFF29B6F6).withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            langService.translate(isArenal ? 'pool_rules_title_indoor' : 'pool_rules_title_apts'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard({required Color color, required IconData icon, required String title, required String text}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                bottomLeft: Radius.circular(22),
              ),
            ),
            child: Center(child: Icon(icon, color: color, size: 40)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
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

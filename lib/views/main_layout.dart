import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/hotel_config_service.dart';
import '../services/language_service.dart';
import '../services/hotel_service.dart';
import '../services/content_service.dart';
import '../widgets/language_selector.dart';
import 'package:window_manager/window_manager.dart';
import 'services/services_view.dart';
import 'information/information_view.dart';
import 'excursions/excursions_view.dart';
import 'weather/weather_view.dart';
import 'webpages_view.dart';
import 'welcome_view.dart';
import 'information/flight_board_view.dart';
import '../widgets/app_image.dart';
import '../widgets/kiosk_manager.dart';
import '../widgets/main_sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _views;
  late final List<NavigationItem> _navItems;

  @override
  void initState() {
    super.initState();
    // Init hotel service after content service is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hotelService = Provider.of<HotelService>(context, listen: false);
      final contentService = Provider.of<ContentService>(context, listen: false);
      final hotelConfigService = context.read<HotelConfigService>();
      hotelService.init(hotelConfigService);
    });
    _views = [
      const WelcomeView(),
      const WeatherView(),
      const ServicesView(),
      const InformationView(),
      const ExcursionsView(),
      const FlightBoardView(),
      const WebpagesView(),
    ];


    _navItems = [
      NavigationItem(
        titleKey: 'home',
        icon: Icons.home,
        color: AppColors.yellowSecondary,
      ),
      NavigationItem(
        titleKey: 'weather',
        icon: Icons.wb_sunny,
        color: AppColors.weather,
      ),
      NavigationItem(
        titleKey: 'facilities',
        icon: Icons.room_service,
        color: AppColors.services,
      ),
      NavigationItem(
        titleKey: 'tourist_info',
        icon: Icons.map,
        color: AppColors.information,
      ),
      NavigationItem(
        titleKey: 'excursions',
        icon: Icons.directions_bus,
        color: AppColors.excursions,
      ),
      NavigationItem(
        titleKey: 'flight_board',
        icon: Icons.flight_takeoff,
        color: Colors.amber,
      ),
      NavigationItem(
        titleKey: 'webpages',
        icon: Icons.public,
        color: Colors.grey,
      ),
    ];

  }

  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkKioskMode();
  }

  Future<void> _checkKioskMode() async {
    if (kIsWeb) return;
    try {
      final isFullScreen = await windowManager.isFullScreen();
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelService = Provider.of<HotelService>(context);
    final contentService = Provider.of<ContentService>(context, listen: false);

    return KioskManager(
      child: Scaffold(
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: AppConfig.lowPowerMode ? Duration.zero : const Duration(milliseconds: 500),
                layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: AppImage(path: 
                  hotelService.currentHotelConfig?.background ?? '',
                  key: ValueKey<String>(hotelService.currentHotelId),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                ),
              ),
            ),

            if (AppConfig.lowPowerMode)
              Positioned(
                top: 0, bottom: 0, left: 0, width: 280, // Approximate width of sidebar
                child: Container(color: Colors.black.withOpacity(0.5)),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Edit Mode Dark Overlay
            Consumer<ContentService>(
              builder: (context, contentService, _) {
                if (!contentService.isEditMode) return const SizedBox.shrink();
                return Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                );
              },
            ),
            
            Row(
              children: [
                // Sidebar (Left)
                MainSidebar(
                  selectedIndex: _selectedIndex,
                  navItems: _navItems,
                  onItemSelected: (index) => setState(() => _selectedIndex = index),
                ),

                // Main Content (Right)
                Expanded(
                  child: Padding(
                    padding: _selectedIndex == 0 
                        ? EdgeInsets.zero 
                        : const EdgeInsets.fromLTRB(24, 24, 16, 24),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        // Semi-transparent black for content window, but transparent for home
                        color: _selectedIndex == 0 ? Colors.transparent : Colors.black.withOpacity(0.5), 
                        borderRadius: _selectedIndex == 0 ? BorderRadius.zero : BorderRadius.circular(20),
                        border: Border.all(color: _selectedIndex == 0 ? Colors.transparent : Colors.white12),
                      ),
                      child: Navigator(
                        key: ValueKey(_selectedIndex),
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (context) => _views[_selectedIndex],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Global Edit Mode Indicator
            Consumer<ContentService>(
              builder: (context, contentService, _) {
                if (!contentService.isEditMode) return const SizedBox.shrink();
                
                return Positioned(
                  top: 40,
                  left: 24,
                  child: Container(
                    width: 232, // Match sidebar logo area width (280 - 24*2)
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'EDIT MODE ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/language_service.dart';
import '../services/hotel_service.dart';
import '../widgets/language_selector.dart';
import 'package:window_manager/window_manager.dart';
import '../services/content_service.dart';
import 'services/services_view.dart';
import 'information/information_view.dart';
import 'excursions/excursions_view.dart';
import 'weather/weather_view.dart';
import 'webpages_view.dart';
import 'welcome_view.dart';
import 'information/flight_board_view.dart';
import '../widgets/help_popup.dart';
import '../widgets/app_image.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _views;
  late final List<_NavigationItem> _navItems;
  final FocusNode _focusNode = FocusNode();
  bool _isKioskMode = false;
  bool _showHelp = false;

  @override
  void initState() {
    super.initState();
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
      _NavigationItem(
        titleKey: 'home',
        icon: Icons.home,
        color: AppColors.yellowSecondary,
      ),
      _NavigationItem(
        titleKey: 'weather',
        icon: Icons.wb_sunny,
        color: AppColors.weather,
      ),
      _NavigationItem(
        titleKey: 'hotel_services',
        icon: Icons.room_service,
        color: AppColors.services,
      ),
      _NavigationItem(
        titleKey: 'tourist_info',
        icon: Icons.map,
        color: AppColors.information,
      ),
      _NavigationItem(
        titleKey: 'excursions',
        icon: Icons.directions_bus,
        color: AppColors.excursions,
      ),
      _NavigationItem(
        titleKey: 'flight_board',
        icon: Icons.flight_takeoff,
        color: Colors.amber,
      ),
      _NavigationItem(
        titleKey: 'webpages',
        icon: Icons.public,
        color: Colors.grey,
      ),
    ];

  }

  @override
  void dispose() {
    _focusNode.dispose();
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
      if (mounted) {
        this.setState(() {
          _isKioskMode = isFullScreen;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelService = Provider.of<HotelService>(context);

    // Ensure focus for keyboard events
    if (!_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final isAltPressed = HardwareKeyboard.instance.isAltPressed;
          
          if (isAltPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
            hotelService.setHotel('Arenal');
          } else if (isAltPressed && event.logicalKey == LogicalKeyboardKey.keyS) {
            hotelService.setHotel('Savines');
          } else if (event.logicalKey == LogicalKeyboardKey.f11) {
            windowManager.isFullScreen().then((isFullScreen) async {
              bool willBeFullScreen = !isFullScreen;
              await windowManager.setFullScreen(willBeFullScreen);
              // Hide title bar in fullscreen, show it in windowed mode
              await windowManager.setTitleBarStyle(
                willBeFullScreen ? TitleBarStyle.hidden : TitleBarStyle.normal,
              );
              if (mounted) {
                setState(() {
                  _isKioskMode = willBeFullScreen;
                });
              }
            });
          } else if (event.logicalKey == LogicalKeyboardKey.f2) {
            final contentService = Provider.of<ContentService>(context, listen: false);
            contentService.toggleEditMode();
          } else if (event.logicalKey == LogicalKeyboardKey.f1) {
             setState(() {
               _showHelp = !_showHelp;
             });
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
             windowManager.close();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
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
                  hotelService.isSavines
                      ? 'assets/images/background/savines.jpg'
                      : 'assets/images/background/arenal.jpg',
                  key: ValueKey<String>(hotelService.currentHotel),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                ),
              ),
            ),

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
                Container(
                  width: 280, // Slightly wider for premium look
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6), // Darker background for readability
                    border: const Border(right: BorderSide(color: Colors.white12, width: 1)),
                  ),
                  child: Column(
                    children: [
                      // Header / Logo
                      DragToMoveArea(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                          width: double.infinity,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: AppImage(path: 
                              hotelService.isSavines
                                  ? 'assets/images/logo/savines.png'
                                  : 'assets/images/logo/arenal.png',
                              key: ValueKey<String>(hotelService.currentHotel),
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  hotelService.currentHotel,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      
                      // Navigation List
                      Expanded(
                        child: Consumer<LanguageService>(
                          builder: (context, langService, _) {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: _navItems.length,
                              itemBuilder: (context, index) {
                                final item = _navItems[index];
                                final isSelected = _selectedIndex == index;
                                return _NavItem(
                                  item: item,
                                  isSelected: isSelected,
                                  label: langService.translate(item.titleKey),
                                  onTap: () => setState(() => _selectedIndex = index),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      
                      // Language Selector
                      const Divider(height: 1, color: Colors.white12),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        child: LanguageSelector(),
                      ),
                    ],
                  ),
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

            // Help Button (Bottom Right)
            if (!_isKioskMode)
              Positioned(
                bottom: 24,
                right: 24,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  clipBehavior: Clip.none,
                  children: [
                      FloatingActionButton(
                        onPressed: () {
                           setState(() {
                             _showHelp = !_showHelp;
                           });
                        },
                        backgroundColor: AppColors.get('blue', 700),
                        child: const Icon(Icons.help_outline, color: Colors.white),
                      ),
                      if (_showHelp)
                        const Positioned(
                          bottom: 70,
                          right: 0,
                          child: HelpPopup(),
                        ),
                    ],
                  ),
              ),

             // Global F1 Popup Center (kiosk or no kiosk)
             if (_showHelp && _isKioskMode)
                const Center(child: HelpPopup()),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem {
  final String titleKey;
  final IconData icon;
  final Color color;

  _NavigationItem({
    required this.titleKey,
    required this.icon,
    required this.color,
  });
}

/// Premium sidebar navigation item with hover animation and selection highlight
class _NavItem extends StatefulWidget {
  final _NavigationItem item;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  @override
  Widget build(BuildContext context) {
    final color = widget.item.color;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      color.withOpacity(0.22),
                      Colors.transparent,
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                    ],
                  ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected ? color.withOpacity(0.25) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Colored left accent bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: widget.isSelected ? 42 : 0,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: widget.isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              // Icon
              AnimatedScale(
                scale: widget.isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.item.icon,
                  size: 24,
                  color: widget.isSelected ? color : Colors.white38,
                ),
              ),
              const SizedBox(width: 16),
              // Label
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isSelected ? Colors.white : Colors.white54,
                      letterSpacing: widget.isSelected ? 0.4 : 0.1,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
    );
  }
}

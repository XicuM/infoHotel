import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../services/hotel_service.dart';
import '../services/language_service.dart';
import 'language_selector.dart';
import 'app_image.dart';

class NavigationItem {
  final String titleKey;
  final IconData icon;
  final Color color;

  NavigationItem({
    required this.titleKey,
    required this.icon,
    required this.color,
  });
}

class MainSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> navItems;
  final ValueChanged<int> onItemSelected;

  const MainSidebar({
    super.key,
    required this.selectedIndex,
    required this.navItems,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hotelService = Provider.of<HotelService>(context);

    return Container(
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
                child: AppImage(
                  path: hotelService.currentHotelConfig?.logo ?? '',
                  key: ValueKey<String>(hotelService.currentHotelId),
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      hotelService.currentHotelConfig?.name ?? hotelService.currentHotelId,
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
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final isSelected = selectedIndex == index;
                    return _NavItem(
                      item: item,
                      isSelected: isSelected,
                      label: langService.translate(item.titleKey),
                      onTap: () => onItemSelected(index),
                    );
                  },
                );
              },
            ),
          ),
          
          // Language Selector
          const Divider(height: 1, color: Colors.white12),
          const Padding(
            padding: EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
            child: LanguageSelector(),
          ),
          // Help hint
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: Center(
              child: Text(
                'Press Alt+H for help',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium sidebar navigation item with hover animation and selection highlight
class _NavItem extends StatefulWidget {
  final NavigationItem item;
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

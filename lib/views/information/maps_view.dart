import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/language_bar.dart';
import '../../widgets/zoomable_viewer.dart';
import '../../widgets/app_image.dart';
import '../../models/city_data.dart';
import '../../config/maps_data.dart';

/// Maps view showing interactive island map with clickable cities
class MapsView extends StatelessWidget {
  const MapsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'maps',
        backgroundColor: AppColors.get('blue', 400),
        parentRoute: '/information',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Row(
        children: [
          // Lateral list of places
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                itemCount: MapsData.cities.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white24, height: 1),
                itemBuilder: (context, index) {
                  final city = MapsData.cities[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    title: Text(
                      city.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                    onTap: () => _navigateToCity(context, city),
                  );
                },
              ),
              ),
            ),
          ),

          // Map
          Expanded(
            flex: 3,
            child: ClipRect(
              child: ZoomableViewer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Island map background
                    AppImage(
                      path: 'assets/images/maps/island.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.blue[200],
                          child: const Center(
                            child: Text(
                              'Ibiza Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Clickable city areas
                    ..._buildCityHotspots(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Define cities list as a static/const or member
  List<Widget> _buildCityHotspots(BuildContext context) {
    return MapsData.cities.map((city) {
      return Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final x = constraints.maxWidth * city.xPercent - 50;
            final y = constraints.maxHeight * city.yPercent - 25;

            return Stack(
              children: [
                Positioned(
                  left: x,
                  top: y,
                  child: GestureDetector(
                    onTap: () => _navigateToCity(context, city),
                    child: Container(
                      width: 100,
                      height: 50,
                      color: Colors.transparent, // Highlight debug: Colors.red.withOpacity(0.3)
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }).toList();
  }

  void _navigateToCity(BuildContext context, CityData city) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CityMapView(city: city),
      ),
    );
  }
}


/// City map detail view
class CityMapView extends StatelessWidget {
  final CityData city;

  const CityMapView({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: city.name,
        backgroundColor: AppColors.get('blue', 400),
        parentRoute: '/maps',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ZoomableViewer(
        child: AppImage(
          path: 'assets/images/maps/${city.mapFile}',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 80,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    city.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

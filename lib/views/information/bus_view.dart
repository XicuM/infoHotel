import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/bus_data.dart';
import '../../services/bus_service.dart';
import '../../widgets/app_bar_widget.dart';
import 'bus_map_view.dart';

class BusView extends StatefulWidget {
  const BusView({super.key});

  @override
  State<BusView> createState() => _BusViewState();
}

class _BusViewState extends State<BusView> {
  int _selectedStopIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: 'bus_timetable',
        backgroundColor: AppColors.information,
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BusMapView(),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined, color: Colors.white70),
            iconSize: 28,
            tooltip: 'Bus Map',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
        ),
        child: Consumer<BusService>(
          builder: (context, busService, child) {
            if (busService.isLoading && busService.stops.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppConfig.lowPowerMode 
                        ? Icon(Icons.hourglass_empty, color: AppColors.information, size: 36) 
                        : CircularProgressIndicator(color: AppColors.information),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading timetable...',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
              );
            }

            if (busService.error != null && busService.stops.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      busService.error!,
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => busService.fetchBusData(force: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (busService.stops.isEmpty) {
              return const Center(
                child: Text(
                  'No bus data available',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              );
            }

            if (_selectedStopIndex >= busService.stops.length) {
              _selectedStopIndex = 0;
            }

            final selectedStop = busService.stops[_selectedStopIndex];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Colors.black12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Bus Stops',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: busService.stops.length,
                          itemBuilder: (context, index) {
                            final stop = busService.stops[index];
                            final isSelected = _selectedStopIndex == index;
                            return ListTile(
                              title: Text(
                                stop.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.information : Colors.black87,
                                ),
                              ),
                              subtitle: stop.direction.isNotEmpty
                                  ? Text(
                                      stop.direction,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300,
                                        color: isSelected ? AppColors.information.withValues(alpha: 0.7) : Colors.black54,
                                      ),
                                    )
                                  : null,
                              selected: isSelected,
                              selectedTileColor: AppColors.information.withValues(alpha: 0.1),
                              onTap: () {
                                setState(() {
                                  _selectedStopIndex = index;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedStop.lines.length,
                    itemBuilder: (context, index) {
                      return _buildLineCard(selectedStop.lines[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLineCard(BusLine line) {
    final lineColor = _parseColor(line.color);
    final textColor = _parseColor(line.textColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    line.number,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: lineColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _cleanDestinationName(line.destination),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (line.number.startsWith('N'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NOCHE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (RegExp(r'^[Aa]ero', caseSensitive: false).hasMatch(line.number))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AEROPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (line.number.startsWith('P'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PLATJA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (line.number.startsWith('D'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DISCO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (line.number.startsWith('U'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006064),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'URBÀ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (line.number.startsWith('A'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACCÉS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final time in line.times)
                  _buildTimeChip(time),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        time,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          color: Colors.black87,
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final hexClean = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexClean', radix: 16));
    } catch (e) {
      return AppColors.information;
    }
  }

  String _cleanDestinationName(String dest) {
    return dest
        .replaceAll('Estació de Sant Antoni', 'Sant Antoni')
        .replaceAll('Eivissa/CETIS', 'Eivissa (Ibiza Town)')
        .replaceAll('Eivissa', 'Eivissa (Ibiza Town)')
        .replaceAll('Port des Torrent', 'Port des Torrent')
        .replaceAll('Cala Tarida', 'Cala Tarida');
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../widgets/app_bar_widget.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/flight_service.dart';
import '../../models/flight_model.dart';
import '../../widgets/app_image.dart';
import 'package:intl/intl.dart';

class FlightBoardView extends StatefulWidget {
  const FlightBoardView({super.key});

  @override
  State<FlightBoardView> createState() => _FlightBoardViewState();
}

class _FlightBoardViewState extends State<FlightBoardView> {
  late Future<List<IbizaDeparture>> _flightFuture;
  final IbizaFlightRepository _repository = IbizaFlightRepository();
  final FocusNode _focusNode = FocusNode();
  Timer? _refreshTimer;
  Timer? _slideTimer;
  int _slideIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFlights();
    // Auto-reload data periodically. (The repository handles caching to avoid hitting the API too often).
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadFlights();
    });
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _slideIndex++;
        });
      }
    });
  }

  void _loadFlights({bool forceRefresh = false}) {
    setState(() {
      _flightFuture = _repository.getDepartures(forceRefresh: forceRefresh);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _refreshTimer?.cancel();
    _slideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f5) {
          _loadFlights(forceRefresh: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          titleKey: 'flight_board',
          backgroundColor: Colors.black87,
          actions: [
            _buildHeaderWidget(),
          ],
        ),
        body: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.6),
            child: Column(
              children: [
                // Flights List Content
                Expanded(
                  child: FutureBuilder<List<IbizaDeparture>>(
                    future: _flightFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                              const SizedBox(height: 16),
                              Text(
                                "Schedule temporarily unavailable\n${snapshot.error}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 22, color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      }

                      final flights = snapshot.data ?? [];
                      
                      if (flights.isEmpty) {
                        return const Center(
                          child: Text(
                            "No upcoming departures found.",
                            style: TextStyle(fontSize: 24, color: Colors.white70),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            color: Colors.black87,
                            child: Row(
                              children: [
                                Expanded(child: _buildHeaderRow()),
                                const SizedBox(width: 24),
                                Expanded(child: _buildHeaderRow()),
                              ],
                            ),
                          ),
                          // Flights List
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double rowHeight = 48.0;
                                // Account for vertical padding (8 top, 8 bottom)
                                final int maxRows = ((constraints.maxHeight - 16) / rowHeight).floor();
                                final int maxItems = maxRows * 2;
                                
                                final displayFlights = flights.take(maxItems).toList();
                                final int half = (displayFlights.length + 1) ~/ 2;

                                return GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 48,
                                    crossAxisSpacing: 24,
                                    mainAxisSpacing: 0,
                                  ),
                                  itemCount: displayFlights.length,
                                  itemBuilder: (context, index) {
                                    // Order top-to-bottom in the left column, then right column
                                    final int actualIndex = (index % 2 == 0) ? (index ~/ 2) : (half + (index ~/ 2));
                                    final flight = displayFlights[actualIndex];
                                    
                                    final timeString = DateFormat('HH:mm').format(flight.scheduledTime);
                                    
                                    // Row color alternates based on actual vertical row
                                    final isEvenRow = (index ~/ 2) % 2 == 0;
                                    
                                    final langService = Provider.of<LanguageService>(context);
                                    Color statusColor = Colors.white;
                                    String rawStatus = flight.status.toLowerCase().replaceAll(' ', '');
                                    String translatedStatusKey = '';

                                    if (rawStatus.contains('expected') || rawStatus.contains('time') || rawStatus.contains('hora')) {
                                      translatedStatusKey = 'status_expected';
                                      statusColor = Colors.greenAccent;
                                    } else if (rawStatus.contains('delayed') || rawStatus.contains('retrasado')) {
                                      translatedStatusKey = 'status_delayed';
                                      statusColor = Colors.redAccent;
                                    } else if (rawStatus.contains('boarding') || rawStatus.contains('embarque')) {
                                      translatedStatusKey = 'status_boarding';
                                      statusColor = Colors.yellowAccent;
                                    } else if (rawStatus.contains('gateclosed') || rawStatus.contains('cerrada')) {
                                      translatedStatusKey = 'status_gateclosed';
                                      statusColor = Colors.redAccent;
                                    } else if (rawStatus.contains('lastcall') || rawStatus.contains('llamada')) {
                                      translatedStatusKey = 'status_lastcall';
                                      statusColor = Colors.redAccent;
                                    } else if (rawStatus.contains('departed') || rawStatus.contains('despegado')) {
                                      translatedStatusKey = 'status_departed';
                                      statusColor = Colors.greenAccent;
                                    } else if (rawStatus.contains('cancelled') || rawStatus.contains('cancelado')) {
                                      translatedStatusKey = 'status_cancelled';
                                      statusColor = Colors.redAccent;
                                    }

                                    String statusText = translatedStatusKey.isNotEmpty 
                                        ? langService.translate(translatedStatusKey).toUpperCase()
                                        : flight.status.toUpperCase();

                                    if (flight.estimatedTime != null && 
                                        flight.estimatedTime!.difference(flight.scheduledTime).inMinutes.abs() >= 5) {
                                      final estString = DateFormat('HH:mm').format(flight.estimatedTime!);
                                      if (translatedStatusKey == 'status_expected' || translatedStatusKey == '') {
                                        translatedStatusKey = 'status_delayed';
                                        statusText = '${langService.translate('status_delayed').toUpperCase()} $estString';
                                        statusColor = Colors.redAccent;
                                      } else {
                                        statusText = '$statusText $estString';
                                      }
                                    } else if (translatedStatusKey == 'status_delayed' && flight.estimatedTime != null) {
                                      final estString = DateFormat('HH:mm').format(flight.estimatedTime!);
                                      statusText = '$statusText $estString';
                                    }

                                    return Container(
                                      color: isEvenRow ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.3),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              timeString,
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.yellowAccent),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              flight.destination.toUpperCase(),
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 500),
                                              transitionBuilder: (Widget child, Animation<double> animation) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(-0.5, 0.0),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                key: ValueKey<String>(flight.flightNumbers[_slideIndex % flight.flightNumbers.length]),
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  flight.flightNumbers[_slideIndex % flight.flightNumbers.length],
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: flight.gate.isNotEmpty ? Colors.white.withOpacity(0.1) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  flight.gate,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              statusText,
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                            width: double.infinity,
                            color: Colors.white,
                            child: const Text(
                              "Only for reference. Always check the updated times from the official webpage (Aena).",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14, 
                                color: Colors.black, 
                                fontWeight: FontWeight.bold,
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
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.0))),
          Expanded(flex: 4, child: Text('DESTINATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.0))),
          Expanded(flex: 2, child: Text('FLIGHT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.0))),
          Expanded(flex: 2, child: Text('GATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.0))),
          Expanded(flex: 3, child: Text('REMARKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 1.0))),
        ],
      ),
    );
  }

  Widget _buildHeaderWidget() {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    langService.translate('last_update'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (_repository.lastFetchedTime != null)
                    Text(
                      '${_repository.lastFetchedTime!.hour}:${_repository.lastFetchedTime!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              AppImage(
                path: 'assets/images/aena_logo.png',
                height: 28,
                errorBuilder: (context, error, stackTrace) =>
                    const Text('AENA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.5)),
              ),
            ],
          ),
        );
      },
    );
  }
}

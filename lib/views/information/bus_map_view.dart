import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../pdf_viewer_view.dart';

class BusMapView extends StatelessWidget {
  const BusMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return PdfViewerView(
      pdfPath: 'hotel_assets/pdf/bus_map.pdf',
      title: 'bus_map',
      backgroundColor: AppColors.information,
      enableBookMode: false,
    );
  }
}

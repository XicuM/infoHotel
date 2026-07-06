// Basic widget test for Info Hotel app

import 'dart:ui';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_hotel/main.dart';
import 'package:info_hotel/repositories/storage_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('es', null);
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Set viewport to landscape to match the kiosk hardware design
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    
    // Build our app and trigger a frame.
    final storage = StorageRepository();
    storage.initForTest(Directory.systemTemp);
    
    await tester.pumpWidget(InfoHotelApp(storage: storage));

    // Verify the app renders without error
    expect(find.byType(InfoHotelApp), findsOneWidget);

    // Reset viewport size
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

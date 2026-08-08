import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_hotel/repositories/storage_repository.dart';
import 'package:info_hotel/services/show_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShowService 2-Week & Optional Poster Tests', () {
    late ShowService showService;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('show_service_test_');
      final storage = StorageRepository();
      storage.initForTest(tempDir);
      showService = ShowService(storage: storage);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Default show image fallback for week 1 and week 2', () {
      expect(showService.getShowImage('monday', week: 1), 'hotel_assets/images/shows/monday.jpg');
      expect(showService.getShowImage('monday', week: 2), 'hotel_assets/images/shows/monday.jpg');
    });

    test('Updating poster for week 1 does not overwrite week 2 if set', () async {
      await showService.updateShowImage('monday', 'path/to/week1.jpg', week: 1);
      expect(showService.getShowImage('monday', week: 1), 'path/to/week1.jpg');
      expect(showService.getShowImage('monday', week: 2), 'path/to/week1.jpg');

      await showService.updateShowImage('monday', 'path/to/week2.jpg', week: 2);
      expect(showService.getShowImage('monday', week: 1), 'path/to/week1.jpg');
      expect(showService.getShowImage('monday', week: 2), 'path/to/week2.jpg');
    });

    test('Removing poster sets empty string for optional poster', () async {
      await showService.updateShowImage('tuesday', 'path/to/tuesday.jpg', week: 1);
      expect(showService.getShowImage('tuesday', week: 1), 'path/to/tuesday.jpg');

      await showService.removeShowImage('tuesday', week: 1);
      expect(showService.getShowImage('tuesday', week: 1), '');
    });

    test('Default starting hotel index for week 1 and week 2', () {
      expect(showService.getStartHotelIndex(1), 1);
      expect(showService.getStartHotelIndex(2), 0);
    });

    test('Setting starting hotel index per week', () async {
      await showService.setStartHotelIndex(1, 0);
      await showService.setStartHotelIndex(2, 1);

      expect(showService.getStartHotelIndex(1), 0);
      expect(showService.getStartHotelIndex(2), 1);
    });
  });
}

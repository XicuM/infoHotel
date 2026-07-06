import 'package:flutter_test/flutter_test.dart';
import 'package:info_hotel/services/hotel_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HotelService Tests', () {
    late HotelService hotelService;

    setUp(() {
      hotelService = HotelService();
    });

    test('Initial hotel id should be Savines', () {
      expect(hotelService.currentHotelId, 'Savines');
    });

    test('setHotel updates hotel id', () {
      bool notified = false;
      hotelService.addListener(() => notified = true);

      hotelService.setHotel('Arenal');

      expect(hotelService.currentHotelId, 'Arenal');
      expect(notified, isTrue);
    });

    test('setHotel does nothing for same hotel', () {
      bool notified = false;
      hotelService.addListener(() => notified = true);

      hotelService.setHotel('Savines');

      expect(hotelService.currentHotelId, 'Savines');
      expect(notified, isFalse);
    });

    test('currentHotelConfig is null without ContentService', () {
      expect(hotelService.currentHotelConfig, isNull);
    });

    test('hotelConfigs is empty without ContentService', () {
      expect(hotelService.hotelConfigs, isEmpty);
    });

    test('cycleNextHotel does nothing when no configs', () {
      hotelService.cycleNextHotel();
      expect(hotelService.currentHotelId, 'Savines');
    });
  });
}

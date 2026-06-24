import 'package:flutter_test/flutter_test.dart';
import 'package:info_hotel/services/hotel_service.dart';

void main() {
  group('HotelService Tests', () {
    late HotelService hotelService;

    setUp(() {
      hotelService = HotelService();
    });

    test('Initial hotel should be Savines', () {
      expect(hotelService.currentHotel, 'Savines');
      expect(hotelService.isSavines, isTrue);
      expect(hotelService.isArenal, isFalse);
    });

    test('Changing to Arenal updates state', () {
      bool notified = false;
      hotelService.addListener(() {
        notified = true;
      });

      hotelService.setHotel('Arenal');
      
      expect(hotelService.currentHotel, 'Arenal');
      expect(hotelService.isArenal, isTrue);
      expect(hotelService.isSavines, isFalse);
      expect(notified, isTrue);
    });

    test('Changing to invalid hotel does nothing', () {
      bool notified = false;
      hotelService.addListener(() {
        notified = true;
      });

      hotelService.setHotel('InvalidHotel');
      
      expect(hotelService.currentHotel, 'Savines');
      expect(notified, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:info_hotel/models/market.dart';
import 'package:info_hotel/models/excursion.dart';

void main() {
  group('Models Serialization Tests', () {
    test('MarketModel serialization and deserialization', () {
      final market = MarketModel(
        id: 'test_market',
        name: 'Test Market',
        description: 'Test Description',
        imagePath: 'hotel_assets/test.png',
        galleryImages: ['hotel_assets/1.png', 'hotel_assets/2.png'],
        isCustom: true,
        localizedNames: {'en': 'Test Market EN'},
        localizedDescriptions: {'en': 'Desc EN'},
      );

      final json = market.toJson();
      final decodedMarket = MarketModel.fromJson(json);

      expect(decodedMarket.id, 'test_market');
      expect(decodedMarket.name, 'Test Market');
      expect(decodedMarket.description, 'Test Description');
      expect(decodedMarket.imagePath, 'hotel_assets/test.png');
      expect(decodedMarket.galleryImages, ['hotel_assets/1.png', 'hotel_assets/2.png']);
      expect(decodedMarket.isCustom, isTrue);
      expect(decodedMarket.localizedNames['en'], 'Test Market EN');
      expect(decodedMarket.localizedDescriptions['en'], 'Desc EN');
    });

    test('MarketModel localized getters', () {
      final market = MarketModel(
        id: 'test_market',
        name: 'Fallback Name',
        description: 'Fallback Desc',
        imagePath: 'hotel_assets/test.png',
        localizedNames: {'es': 'Nombre ES'},
        localizedDescriptions: {'es': 'Desc ES'},
      );

      expect(market.getName('es'), 'Nombre ES');
      expect(market.getName('en'), 'Fallback Name');
      expect(market.getDescription('es'), 'Desc ES');
      expect(market.getDescription('en'), 'Fallback Desc');
    });

    test('ExcursionModel serialization and deserialization', () {
      final excursion = ExcursionModel(
        id: 'test_excursion',
        name: 'Test Excursion',
        localizedNames: {'en': 'Test Excursion EN'},
        imagePath: 'hotel_assets/test_ex.png',
        type: ExcursionType.pdf,
        content: 'hotel_assets/test.pdf',
        isLocalImage: true,
      );

      final json = excursion.toJson();
      final decodedExcursion = ExcursionModel.fromJson(json);

      expect(decodedExcursion.id, 'test_excursion');
      expect(decodedExcursion.name, 'Test Excursion');
      expect(decodedExcursion.localizedNames['en'], 'Test Excursion EN');
      expect(decodedExcursion.imagePath, 'hotel_assets/test_ex.png');
      expect(decodedExcursion.type, ExcursionType.pdf);
      expect(decodedExcursion.content, 'hotel_assets/test.pdf');
      expect(decodedExcursion.isLocalImage, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:jassspiel/jasskarte.dart';

void main() {
  group('Jasskarte Tests', () {
    test('should create Jasskarte with full constructor', () {
      final karte = Jasskarte('Herz', 'Ass', true, 11, 'assets/Herz/Herz_Ass.png');
      
      expect(karte.symbol, equals('Herz'));
      expect(karte.cardType, equals('Ass'));
      expect(karte.isTrumpf, isTrue);
      expect(karte.value, equals(11));
      expect(karte.path, equals('assets/Herz/Herz_Ass.png'));
    });

    test('should create Jasskarte with wheninit constructor', () {
      final karte = Jasskarte.wheninit('Eichel', 'card123', 'König', 'assets/Eichel/Eichel_König.png');
      
      expect(karte.symbol, equals('Eichel'));
      expect(karte.cid, equals('card123'));
      expect(karte.cardType, equals('König'));
      expect(karte.path, equals('assets/Eichel/Eichel_König.png'));
    });

    test('should convert to JSON correctly', () {
      final karte = Jasskarte.wheninit('Schella', 'card456', '10', 'assets/Schella/Schella_10.png');
      
      final json = karte.toJson();
      
      expect(json['symbol'], equals('Schella'));
      expect(json['cid'], equals('card456'));
      expect(json['cardtype'], equals('10'));
      expect(json['path'], equals('assets/Schella/Schella_10.png'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:jassspiel/enums.dart';

void main() {
  group('Enums Tests', () {
    test('CardType enum should have all expected values', () {
      expect(CardType.values.length, equals(10));
      expect(CardType.values, contains(CardType.notset));
      expect(CardType.values, contains(CardType.sechs));
      expect(CardType.values, contains(CardType.sieben));
      expect(CardType.values, contains(CardType.acht));
      expect(CardType.values, contains(CardType.neun));
      expect(CardType.values, contains(CardType.zehn));
      expect(CardType.values, contains(CardType.unter));
      expect(CardType.values, contains(CardType.ober));
      expect(CardType.values, contains(CardType.koenig));
      expect(CardType.values, contains(CardType.ass));
    });

    test('Symbol enum should have all expected values', () {
      expect(Symbol.values.length, equals(4));
      expect(Symbol.values, contains(Symbol.herz));
      expect(Symbol.values, contains(Symbol.laub));
      expect(Symbol.values, contains(Symbol.schella));
      expect(Symbol.values, contains(Symbol.eichel));
    });

    test('TrumpfOptions enum should have all expected values', () {
      expect(TrumpfOptions.values.length, equals(7));
      expect(TrumpfOptions.values, contains(TrumpfOptions.herz));
      expect(TrumpfOptions.values, contains(TrumpfOptions.laub));
      expect(TrumpfOptions.values, contains(TrumpfOptions.schella));
      expect(TrumpfOptions.values, contains(TrumpfOptions.eichel));
      expect(TrumpfOptions.values, contains(TrumpfOptions.geis));
      expect(TrumpfOptions.values, contains(TrumpfOptions.bock));
      expect(TrumpfOptions.values, contains(TrumpfOptions.slalom));
    });

    test('enum values should be comparable', () {
      expect(CardType.ass, equals(CardType.ass));
      expect(CardType.ass, isNot(equals(CardType.koenig)));
      
      expect(Symbol.herz, equals(Symbol.herz));
      expect(Symbol.herz, isNot(equals(Symbol.eichel)));
      
      expect(TrumpfOptions.bock, equals(TrumpfOptions.bock));
      expect(TrumpfOptions.bock, isNot(equals(TrumpfOptions.geis)));
    });

    test('enum toString should work correctly', () {
      expect(CardType.ass.toString(), equals('CardType.ass'));
      expect(Symbol.herz.toString(), equals('Symbol.herz'));
      expect(TrumpfOptions.bock.toString(), equals('TrumpfOptions.bock'));
    });
  });
}

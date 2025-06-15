import 'package:flutter_test/flutter_test.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/jasskarte.dart';

void main() {
  group('Spieler Tests', () {
    late Spieler spieler;

    setUp(() {
      spieler = Spieler('uid123', 'TestSpieler', 1);
    });

    test('should create Spieler with correct properties', () {
      expect(spieler.uid, equals('uid123'));
      expect(spieler.username, equals('TestSpieler'));
      expect(spieler.playernumber, equals(1));
      expect(spieler.cards, isEmpty);
      expect(spieler.gainedcard, isEmpty);
      expect(spieler.playedcard, isEmpty);
    });

    test('should return correct card count', () {
      final karte1 = Jasskarte('Herz', 'Ass', false, 11, 'path1');
      final karte2 = Jasskarte('Eichel', 'König', false, 4, 'path2');
      
      spieler.cards.add(karte1);
      spieler.cards.add(karte2);
      
      expect(spieler.howmanycards, equals(2));
    });

    test('should return zero card count when no cards', () {
      expect(spieler.howmanycards, equals(0));
    });

    test('should return zero points initially', () {
      final points = spieler.countpoints();
      
      expect(points, equals(0));
    });

    test('should handle card lists independently', () {
      final karte1 = Jasskarte('Herz', 'Ass', false, 11, 'path1');
      final karte2 = Jasskarte('Eichel', 'König', false, 4, 'path2');
      final karte3 = Jasskarte('Laub', '10', false, 10, 'path3');
      
      spieler.cards.add(karte1);
      spieler.gainedcard.add(karte2);
      spieler.playedcard.add(karte3);
      
      expect(spieler.cards.length, equals(1));
      expect(spieler.gainedcard.length, equals(1));
      expect(spieler.playedcard.length, equals(1));
      expect(spieler.cards.first.symbol, equals('Herz'));
      expect(spieler.gainedcard.first.symbol, equals('Eichel'));
      expect(spieler.playedcard.first.symbol, equals('Laub'));
    });
  });
}

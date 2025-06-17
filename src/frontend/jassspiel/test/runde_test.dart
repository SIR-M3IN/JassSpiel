import 'package:flutter_test/flutter_test.dart';
import 'package:jassspiel/runde.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/jasskarte.dart';

void main() {
  group('Runde Tests', () {
    late Runde runde;
    late Spieler testSpieler;

    setUp(() {
      runde = Runde();
      testSpieler = Spieler('uid1', 'TestPlayer', 1);
    });

    test('should create Runde with empty cards list', () {
      expect(runde.cardsPlayed, isEmpty);
    });

    test('should allow setting start player', () {
      runde.startPlayer = testSpieler;
      expect(runde.startPlayer, equals(testSpieler));
      expect(runde.startPlayer.username, equals('TestPlayer'));
    });

    test('should handle cards played list', () {
      final karte1 = Jasskarte('Herz', 'Ass', false, 11, 'path1');
      final karte2 = Jasskarte('Eichel', 'König', false, 4, 'path2');
      
      runde.cardsPlayed.add(karte1);
      runde.cardsPlayed.add(karte2);
      
      expect(runde.cardsPlayed.length, equals(2));
      expect(runde.cardsPlayed.first.symbol, equals('Herz'));
      expect(runde.cardsPlayed.last.symbol, equals('Eichel'));
    });

    test('should call selectRoundWinner without error', () {
      expect(() => runde.selectRoundWinner(), returnsNormally);
    });

    test('should call writeToServer without error', () {
      expect(() => runde.writeToServer(), returnsNormally);
    });

    test('should handle multiple rounds', () {
      final runde2 = Runde();
      final spieler2 = Spieler('uid2', 'Player2', 2);
      final karte1 = Jasskarte('Laub', '10', false, 10, 'path1');
      final karte2 = Jasskarte('Schella', '9', false, 0, 'path2');
      
      runde.startPlayer = testSpieler;
      runde.cardsPlayed.add(karte1);
      
      runde2.startPlayer = spieler2;
      runde2.cardsPlayed.add(karte2);
      
      expect(runde.cardsPlayed.length, equals(1));
      expect(runde2.cardsPlayed.length, equals(1));
      expect(runde.startPlayer.playernumber, equals(1));
      expect(runde2.startPlayer.playernumber, equals(2));
    });
  });
}

import 'package:jassspiel/enums.dart';
import 'package:jassspiel/jasskarte.dart';
import 'package:jassspiel/modus.dart';
import 'spieler.dart';

class Kreuzjassen implements Modus {
  List<Spieler> team1;
  List<Spieler> team2;
  late Spieler trumpfchooser;
  late Spieler currentplayer;
  Kreuzjassen({
    this.team1 = const [],
    this.team2 = const [],
  });

  @override
  List<Jasskarte> availablecards = [];

  @override
  List<Spieler> players;

  @override
  int pointstotal;

  @override
  TrumpfOptions trumpf;

  @override
  Spieler announcewinner() {
    // TODO: implement announcewinner
    throw UnimplementedError();
  }

  @override
  void dealcards() {
    // TODO: implement dealcards
  }
}


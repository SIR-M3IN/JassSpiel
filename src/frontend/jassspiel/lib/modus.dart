import 'package:jassspiel/jasskarte.dart';
import 'package:jassspiel/spieler.dart';

import 'enums.dart';

abstract class Modus{
  late int pointstotal;
  late TrumpfOptions trumpf;
  List<Jasskarte> availablecards = [];
  List<Spieler> players;
  Modus(this.players);
  void dealcards();
  Spieler announcewinner();
}
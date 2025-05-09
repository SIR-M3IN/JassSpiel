import 'package:jassspiel/jasskarte.dart';
import 'package:jassspiel/spieler.dart';

import 'enums.dart';

abstract class Modus{
  late int pointstotal;
  late TrumpfOptions trumpf;
  List<Jasskarte> availablecards = [];
  late List<Spieler> players;
  Modus(this.availablecards);
  void dealcards();
  Spieler announcewinner();
}
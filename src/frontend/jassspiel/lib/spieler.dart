import 'package:uuid/uuid.dart';

import 'jasskarte.dart';

class Spieler{
  String username;
  List<Jasskarte> cards = [];
  List<Jasskarte> gainedcard = [];
  List<Jasskarte> playedcard = [];
  int get howmanycards => cards.length;
  String uid;
  Spieler(this.uid, this.username );
  void draw(){}
  void sortcards(){}
  void playcard(Jasskarte karte){}
  int countpoints()
  {
    int points = 0;
    return points;
  }
}
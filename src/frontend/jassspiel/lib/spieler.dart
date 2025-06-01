import 'jasskarte.dart';

class Spieler{
  String username;
  List<Jasskarte> cards = [];
  List<Jasskarte> gainedcard = [];
  List<Jasskarte> playedcard = [];
  int get howmanycards => cards.length;
  String uid;
  int playernumber;
  Spieler(this.uid, this.username, this.playernumber);
  void draw(){}
  void sortcards(){}
  void playcard(Jasskarte karte){}
  int countpoints()
  {
    int points = 0;
    return points;
  }
}
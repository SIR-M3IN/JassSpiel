import 'jasskarte.dart';

class Spieler{
  String username;
  List<Jasskarte> cards = [];
  List<Jasskarte> gainedcard = [];
  List<Jasskarte> playedcard = [];
  int get howmanycards => cards.length;
  int points;
  Spieler(
    {
      required this.username, 
      required this.points,
      this.cards = const [],
    });
  void draw(){}
  void sortcards(){}
  void playcard(Jasskarte karte){}
  int countpoints()
  {
    int points = 0;
    return points;
  }
}
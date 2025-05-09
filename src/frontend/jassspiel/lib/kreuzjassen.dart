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


  static CardType stringtocardtype(String value) {
  switch (value) {
    case '6':
      return CardType.sechs;
    case '7':
      return CardType.sieben;
    case '8':
      return CardType.acht;
    case '9':
      return CardType.neun;
    case '10':
      return CardType.zehn;
    case 'Unter':
      return CardType.unter;
    case 'Ober':
      return CardType.ober;
    case 'König':
      return CardType.koenig;
    case 'Ass':
      return CardType.ass;
    default:
      throw ArgumentError('Error converting string to cardtype');
    }
  }
  static Symbol stringtosymbol(String symbol)
  {
    switch (symbol) {
    case 'Eichel':
      return Symbol.eichel;
    case 'Schella':
      return Symbol.schella;
    case 'Herz':
      return Symbol.herz;
    case 'Laub':
      return Symbol.herz;
    default:
      throw ArgumentError('Error converting string to symbol');

  }
  }
  static List<Jasskarte> loadAllCards(){
    List<String> types = ['6', '7', '8', '9', '10', 'Unter', 'Ober', 'König', 'Ass'];
    List<String> symbols = ['Eichel', 'Herz', 'Laub', 'Schella'];
    List<Jasskarte> cards = [];
    for (String symbol in symbols) {
      for (String type in types) {
        String path = 'assets/$symbol/${symbol}_$type.png';
        Jasskarte card = Jasskarte.wheninit(stringtosymbol(symbol), stringtocardtype(type), path);
        cards.add(card);
      }
    }
    return cards;
  }
  
  @override
  List<Jasskarte> availablecards = loadAllCards();
  
  @override
  List<Spieler> players = [];
  
  @override
  int pointstotal = 1000;
  
  @override
  TrumpfOptions trumpf = TrumpfOptions.bock;
  
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


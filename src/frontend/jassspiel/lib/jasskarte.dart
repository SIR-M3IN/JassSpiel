import 'enums.dart';

class Jasskarte {
  Symbol symbol;
  CardType cardType;
  late bool isTrumpf;
  late int value;
  String path;
  Jasskarte(this.symbol,this.cardType,this.isTrumpf,this.value, this.path);
  Jasskarte.wheninit (this.symbol, this.cardType, this.path);
}

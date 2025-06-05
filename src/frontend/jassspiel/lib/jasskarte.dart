class Jasskarte {
  String symbol;
  String cardType;
  late bool isTrumpf;
  late String cid;
  late int value;
  String path;
  Jasskarte(this.symbol,this.cardType,this.isTrumpf,this.value, this.path);
  Jasskarte.wheninit (this.symbol, this.cid, this.cardType, this.path);
}

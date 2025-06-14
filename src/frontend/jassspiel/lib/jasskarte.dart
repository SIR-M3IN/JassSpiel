class Jasskarte {
  String symbol;
  String cardType;
  late bool isTrumpf;
  late String cid;
  late int value;
  String path;
  Jasskarte(this.symbol,this.cardType,this.isTrumpf,this.value, this.path);
  Jasskarte.wheninit (this.symbol, this.cid, this.cardType, this.path);
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'cid': cid,
      'cardtype': cardType,
      'path': path,
    };
  }
}

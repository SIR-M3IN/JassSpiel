/// Definiert das Datenmodell für eine Jass-Spielkarte.
///
/// Diese Datei enthält die [Jasskarte]-Klasse, die alle relevanten
/// Informationen und Eigenschaften einer einzelnen Spielkarte kapselt.

/// Repräsentiert eine einzelne Jass-Spielkarte.
///
/// Enthält alle Eigenschaften einer Karte wie Farbe (Symbol), Typ (z.B. 'Ass'),
/// Punktwert und den Pfad zum Kartenbild.
class Jasskarte {  /// Die Farbe der Karte (z.B. 'Herz', 'Eichel').
  String symbol;
  
  /// Der Typ der Karte (z.B. '6', '7', 'Ass', 'König').
  String cardType;
  
  /// Zeigt an, ob die Karte eine Trumpfkarte ist. Wird zur Laufzeit gesetzt.
  late bool isTrumpf;
  
  /// Die eindeutige ID der Karte aus der Datenbank.
  late String cid;
  
  /// Der Punktwert der Karte.
  late int value;
  
  /// Der Pfad zur Bilddatei der Karte in den Assets.
  String path;
  /// Standard-Konstruktor für eine Jasskarte.
  ///
  /// Normalerweise verwendet, wenn alle Kartendetails bekannt sind.
  ///
  /// [symbol] Die Farbe der Karte.
  /// [cardType] Der Typ/Rang der Karte.
  /// [isTrumpf] Ob diese Karte derzeit Trumpf ist.
  /// [value] Der Punktwert der Karte.
  /// [path] Der Asset-Pfad zum Kartenbild.
  Jasskarte(this.symbol,this.cardType,this.isTrumpf,this.value, this.path);
  /// Benannter Konstruktor für die Initialisierung aus Datenbankdaten.
  ///
  /// Verwendet, wenn eine Karte aus der Datenbank geladen wird, wo
  /// anfangs nur die Grunddaten verfügbar sind.
  ///
  /// [symbol] Die Farbe der Karte.
  /// [cid] Die eindeutige Karten-ID aus der Datenbank.
  /// [cardType] Der Typ/Rang der Karte.
  /// [path] Der Asset-Pfad zum Kartenbild.
  Jasskarte.wheninit (this.symbol, this.cid, this.cardType, this.path);
  /// Konvertiert das Kartenobjekt in eine JSON-Map.
  ///
  /// Nützlich für die Serialisierung und das Senden von Kartendaten an eine API.
  /// Gibt eine Map zurück, die die Karte repräsentiert.
  // KI: Hilf mir Klasse zu Json
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'cid': cid,
      'cardtype': cardType,
      'path': path,
    };
  }
}

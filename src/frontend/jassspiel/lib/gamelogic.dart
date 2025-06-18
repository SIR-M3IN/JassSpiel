import 'package:jassspiel/swaggerConnection.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/jasskarte.dart';
import 'package:jassspiel/dbConnection.dart';
import 'package:jassspiel/logger.util.dart';

/// Behandelt die Kern-Spiellogik für das Jass-Kartenspiel.
///
/// Diese Klasse verwaltet die Spielinitialisierung, Spielerverwaltung, Kartenverteilung,
/// Rundenverwaltung und bietet Hilfsmethoden für die Datenserialisierung.
class GameLogic {  /// Die eindeutige Spiel-ID.
  String gid;
  
  /// Verbindung zur Swagger-API für Serverkommunikation.
  late SwaggerConnection swagger;
  
  /// Verbindung zur Datenbank für Datenpersistierung.
  late DbConnection dbConnection;
  
  /// Logger-Instanz für Debugging und Überwachung.
  final log = getLogger();
  /// Erstellt eine neue [GameLogic]-Instanz für das angegebene Spiel.
  ///
  /// [gid] Die eindeutige Spiel-ID, die verwaltet werden soll.
  GameLogic(this.gid) {
    swagger = SwaggerConnection(baseUrl: 'http://localhost:8080');
    dbConnection = DbConnection();
  }  /// Initialisiert das Spiel, indem auf das Beitreten aller vier Spieler gewartet wird.
  ///
  /// Diese Methode blockiert, bis genau 4 Spieler dem Spiel beigetreten sind.
  Future<void> initialize() async {
    await dbConnection.waitForFourPlayers(gid);
  }
  /// Lädt alle Spieler, die sich derzeit im Spiel befinden.
  ///
  /// Gibt eine Liste von [Spieler]-Objekten zurück, die alle Spieler im Spiel repräsentieren.
  Future<List<Spieler>> loadPlayers() async {
    List<Spieler> players = await dbConnection.loadPlayers(gid);
    return players;
  }  /// Mischt das Deck und verteilt Karten an die Spieler, dann gibt die Hand des aktuellen Benutzers zurück.
  ///
  /// Nur Spieler 1 führt den Mischvorgang durch, um Duplizierung zu vermeiden.
  /// Andere Spieler erhalten ihre Karten einfach aus der Datenbank.
  ///
  /// [players] Die Liste aller Spieler im Spiel.
  /// [uid] Die eindeutige ID des aktuellen Benutzers.
  /// Gibt eine Liste von [Jasskarte] zurück, die die Hand des Benutzers repräsentiert.
  Future<List<Jasskarte>> shuffleandgetCards(List<Spieler> players, String uid) async {
    for (var player in players) {
      if (player.uid == uid && player.playernumber == 1) {
        log.i('Player 1 shuffling cards for game $gid');
        //await swagger.shuffleCards(gid);
        List<Jasskarte> cards = await dbConnection.getAllCards();
        await dbConnection.shuffleCards(cards,players,gid);

      }
    }
    //return await swagger.getUrCards(gid, uid);
    return dbConnection.getUrCards(gid, uid);
  }
  /// Startet eine neue Runde im Spiel.
  ///
  /// Nur Spieler 1 initiiert neue Runden, um Konflikte zu vermeiden.
  /// Erhöht den Rundenzähler und erstellt einen neuen Rundendatensatz in der Datenbank.
  ///
  /// [uid] Die eindeutige ID des Benutzers, der versucht, die Runde zu starten.
  Future<void> startNewRound(String uid) async {
    log.d('Starting new round for player $uid in game $gid');
    List<Spieler> players = await loadPlayers();
    for (var player in players) {
      if (player.uid == uid && player.playernumber == 1) {
        //int whichround = await swagger.getWhichRound(gid);
        int whichround = await dbConnection.getWhichRound(gid);
        log.i('Player 1 starting round $whichround for game $gid');
        //await swagger.startNewRound(gid, whichround);
        await dbConnection.startNewRound(gid, whichround);
      }
    }
  }
  /// Konvertiert eine Liste von Karten und Gewinner-Informationen in eine JSON-kompatible Map.
  ///
  /// Diese Methode wird verwendet, um Stichgewinner-Daten an die Server-API zu senden.
  ///
  /// [karten] Die Liste der im Stich gespielten Karten.
  /// [winnerUid] Die Benutzer-ID des Stichgewinners.
  /// [teammateUid] Die Benutzer-ID des Teamkollegen des Gewinners.
  /// Gibt eine Map zurück, die die serialisierten Kartendaten und Gewinner-Informationen enthält.
  Map<String, dynamic> buildCardsForSaveWinnerAsMap(List<Jasskarte> karten, String winnerUid, String teammateUid,) {
    return {
      "playedCards": karten.map((karte) {
        return {
          "cardtype": karte.cardType,
          "cid": karte.cid,
          "path": karte.path,
          "symbol": karte.symbol,
        };
      }).toList(),
      "winnerUid": winnerUid,
      "teammateUid": teammateUid,
    };
  }

  /// Converts a list of cards into a JSON-compatible map.
  ///
  /// This method serializes card data for API communication.
  ///
  /// [karten] The list of cards to serialize.
  /// Returns a map containing the serialized card data.
  Map<String, dynamic> buildCardsAsMap(List<Jasskarte> karten) {
    return {
      "playedCards": karten.map((karte) {
        return {
          "cardtype": karte.cardType,
          "cid": karte.cid,
          "path": karte.path,
          "symbol": karte.symbol,
        };
      }).toList(),
    };
  }
}
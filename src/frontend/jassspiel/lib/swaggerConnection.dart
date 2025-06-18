import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jassspiel/jasskarte.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/logger.util.dart';

class SwaggerConnection {
  final String baseUrl;
  final log = getLogger();
  final http.Client client;

  SwaggerConnection({required this.baseUrl, http.Client? client}) : client = client ?? http.Client();

  /// Sendet einen PUT-Request, um einen Benutzer zu erstellen oder zu aktualisieren. 
  /// Falls der Benutzer (uid) schon existiert, wird sein Name überschrieben. 
  /// Andernfalls wird ein neuer Benutzer mit der uid erstellt. 
  /// Erfolgreiche Antworten haben Statuscode 200 oder 201.
  Future<void> upsertUser(String uid, String name) async {
    final uri = Uri.parse('$baseUrl/users/$uid');
    final resp = await client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('User upsert failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Erzeugt ein neues Spiel durch einen POST-Request. 
  /// Der Server gibt eine neue Spiel-ID (gid) zurück. 
  /// Diese ID wird vom Client verwendet, um weitere Spielaktionen dem richtigen Spiel zuzuordnen.
  Future<String> createGame() async {
    final uri = Uri.parse('$baseUrl/games');
    final resp = await client.post(uri);
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data['gid'] as String;
    }
    throw Exception('Game creation failed: ${resp.statusCode}');
  }

  /// Versucht, einem bestehenden Spiel mit der gegebenen Spiel-ID (gid) beizutreten. 
  /// Der Server gibt 200 zurück, wenn der Beitritt erfolgreich war, 404 falls das Spiel nicht existiert. 
  /// Bei anderen Fehlern wird eine Exception geworfen.
  Future<bool> joinGame(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/join');
    final resp = await client.post(uri);
    if (resp.statusCode == 200) return true;
    if (resp.statusCode == 404) return false;
    throw Exception('Join game error: ${resp.statusCode}');
  }

  /// Lädt alle Spieler, die bereits einem Spiel beigetreten sind. 
  /// Gibt eine Liste von Spieler-Objekten zurück, welche jeweils uid, name und playernumber enthalten. 
  /// Die Daten kommen vom Endpoint /games/{gid}/players.
  Future<List<Spieler>> loadPlayers(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/players');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Spieler(e['uid'], e['name'], e['playernumber'] as int)).toList();
    }
    throw Exception('Load players error: ${resp.statusCode}');
  }

  /// Lädt alle verfügbaren Spielkarten aus der Datenbank. 
  /// Die Antwort enthält eine Liste von Kartenobjekten, die zu Jasskarte-Instanzen umgewandelt werden. 
  /// Jede Karte enthält Symbol, Typ, ID und Pfad zur Bilddatei.
  Future<List<Jasskarte>> getAllCards() async {
    final uri = Uri.parse('$baseUrl/cards');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Jasskarte.wheninit(
        e['symbol'], e['cid'], e['cardtype'], e['path']
      )).toList();
    }
    throw Exception('Get cards failed: ${resp.statusCode}');
  }

  /// Lädt eine einzelne Karte anhand ihrer eindeutigen Karten-ID (cid). 
  /// Die Rückgabe ist eine Jasskarte, basierend auf den vom Server gelieferten Daten.
  Future<Jasskarte> getCardByCid(String cid) async {
    final uri = Uri.parse('$baseUrl/cards/$cid');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return Jasskarte.wheninit(e['symbol'], e['cid'], e['cardtype'], e['path']);
    }
    throw Exception('Get card error: ${resp.statusCode}');
  }

  /// Fordert den Server auf, die Karten für ein bestimmtes Spiel zu mischen. 
  /// Der Endpunkt /games/{gid}/cards/shuffle führt die Logik im Backend aus. 
  /// Diese Funktion hat keinen Rückgabewert, wirft aber bei Fehler eine Exception.
  Future<void> shuffleCards(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/cards/shuffle');
    final resp = await client.post(uri);
    if (resp.statusCode != 200) throw Exception('Shuffle error: ${resp.statusCode}');
  }

  /// Lädt die aktuelle Runden-ID (rid) eines Spiels. 
  /// Diese ID wird für alle rundenbezogenen API-Aufrufe (z. B. Spielzüge, Gewinner) benötigt. 
  /// Gibt einen leeren String zurück, wenn keine Runde aktiv ist.
  Future<String> getCurrentRoundId(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/current-round-id');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['rid'] as String;
    }
    return '';
  }

  /// Startet eine neue Spielrunde für das angegebene Spiel. 
  /// Die Rundennummer (whichround) muss angegeben werden. 
  /// Die Methode ruft den Endpunkt /games/{gid}/rounds mit JSON-Daten auf.
  Future<void> startNewRound(String gid, int whichround) async {
    final uri = Uri.parse('$baseUrl/games/$gid/rounds');
    final resp = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'whichround': whichround}),
    );
    if (resp.statusCode != 201) throw Exception('Start round error: ${resp.statusCode}');
  }

  /// Speichert einen Spielzug: welcher Spieler (uid) welche Karte (cid) in einer bestimmten Runde (rid) gespielt hat. 
  /// Die Daten werden per POST an den Server geschickt.
  Future<void> addPlayInRound(String rid, String uid, String cid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/plays');
    final resp = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'cid': cid}),
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) 
    throw Exception('Add play error: ${resp.statusCode}');
  }

  /// Gibt alle Karten zurück, die in einer Runde bereits gespielt wurden. 
  /// Die Karten werden als Liste zurückgegeben und enthalten dieselben Informationen wie bei getAllCards().
  Future<List<Jasskarte>> getPlayedCards(String rid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/played-cards');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Jasskarte.wheninit(
        e['symbol'], e['cid'], e['cardtype'], e['path']
      )).toList();
    }
    return [];
  }

  /// Fragt ab, welche Karte in einer Runde zuerst gespielt wurde. 
  /// Wird oft für Spielregeln oder zum Erkennen der angespielten Farbe benötigt.
  Future<String?> getFirstCardCid(String rid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/first-card-cid');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['cid'] as String?;
    }
    return null;
  }

  /// Gibt die uid des Spielers zurück, der laut Server gerade am Zug ist. 
  /// Diese Information wird laufend benötigt, um die Spielreihenfolge korrekt einzuhalten.
  Future<String> getWhosTurn(String rid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/turn');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['uid']?.toString() ?? '';
    }
    return '';
  }

  /// Aktualisiert auf dem Server, welcher Spieler als Nächstes an der Reihe ist. 
  /// Dies wird nach jedem gültigen Spielzug aufgerufen.
  Future<void> updateWhosTurn(String rid, String uid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/turn');
    final resp = await client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    );
    if (resp.statusCode != 200) throw Exception('Update turn error: ${resp.statusCode}');
  }

  /// Setzt das Trumpf-Symbol eines Spiels (z. B. "Herz", "Schelle", "Eichel"). 
  /// Dieses Symbol wird für die Spiellogik beim Vergleichen von Karten verwendet.
  Future<void> updateTrumpf(String gid, String symbol) async {
    final uri = Uri.parse('$baseUrl/games/$gid/trumpf-suit');
    final resp = await client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      // use camelCase key matching OpenAPI model attribute_map
      body: jsonEncode({'trumpfSymbol': symbol}),
    );
    if (resp.statusCode != 200) throw Exception('Update trumpf error: ${resp.statusCode}');
  }

  /// Liefert die Spielerposition (playernumber) eines Benutzers innerhalb eines bestimmten Spiels. 
  /// Wird z. B. gebraucht, um die Zugreihenfolge zu bestimmen.
  Future<int> getUrPlayernumber(String uid, String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/users/$uid/player-number');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['playernumber'] as int;
    }
    throw Exception('Get player number error: ${resp.statusCode}');
  }

  /// Fragt den Server, wer nach dem Spieler mit der angegebenen Nummer (playernumber) an der Reihe ist. 
  /// Die Rückgabe ist die uid des nächsten Spielers.
  Future<String> getNextPlayerUid(String gid, int playernumber) async {
    final uri = Uri.parse('$baseUrl/games/$gid/next-player-uid?playernumber=$playernumber');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['uid'] as String;
    }
    throw Exception('Get next player error: ${resp.statusCode}');
  }

  /// Lädt die Karten, die einem bestimmten Spieler in einem Spiel zugewiesen sind. 
  /// Wird typischerweise einmal zu Beginn der Runde verwendet.
  Future<List<Jasskarte>> getUrCards(String gid, String uid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/users/$uid/cards');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Jasskarte.wheninit(
        e['symbol'], e['cid'], e['cardtype'], e['path']
      )).toList();
    }
    throw Exception('Get user cards error: ${resp.statusCode}');
  }

  /// Speichert die erzielten Punkte nach einer Runde. 
  /// Die Methode akzeptiert ein JSON-Objekt, das UID und Punktestand enthält, und gibt die neue Gesamtpunktzahl zurück.
  Future<int> savePointsForUsers(String gid, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/games/$gid/update-scores');
    final resp = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200  || resp.statusCode == 201  || resp.statusCode == 204) {
      final e = jsonDecode(resp.body);
      return e['totalPoints'] as int? ?? 0;
    }
    throw Exception('Save points error: ${resp.statusCode}');
  }

  /// Fragt den Server, welche der gespielten Karten die Runde gewinnt. 
  /// Der Server berücksichtigt Trumpf und Spielregeln. 
  /// Die Rückgabe ist die uid des Spielers mit der besten Karte.
  Future<String> determineWinningCard(String gid, List<Jasskarte> cards) async {
    final uri = Uri.parse('$baseUrl/cards/determine-winning-card?gid=$gid');
    final payload = {
      'cards': cards.map((c) => c.toJson()).toList(),
    };
    final resp = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode != 200) {
      throw Exception('determineWinningCard failed: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['winnerUid'] as String;  // statt 'winningCid'
  }

  /// Gibt zurück, die wievielte Runde aktuell läuft. 
  /// Nützlich für Anzeigen oder Rundenwechsel.
  Future<int> getWhichRound(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/current-round-number');
    final resp = await client.get(uri);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['whichround'] as int;
    }
    throw Exception('Get which round failed: ${resp.statusCode}');
  }
  /// Speichert den Runden-Gewinner auf dem Server. 
  /// Die Methode wird aufgerufen, nachdem die Gewinnkarte bestimmt wurde.
  Future<void> updateWinner(String rid, String uid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/winner');
    final resp = await client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'winnerUid': uid}),    );
    log.i('Updated winner: $uid in round $rid');
    if (resp.statusCode != 200 && resp.statusCode != 201 && resp.statusCode != 204) throw Exception('Update winner error: ${resp.statusCode}');
  }
}

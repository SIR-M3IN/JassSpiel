import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/jasskarte.dart';

/// Stellt eine Verbindung zur Supabase-Datenbank her, um alle spielbezogenen Daten zu verwalten.
///
/// Diese Klasse kapselt alle Methoden, die für die Interaktion mit dem Backend benötigt werden,
/// einschließlich des Abrufens von Kartendaten, der Benutzerverwaltung, dem Erstellen und Beitreten von Spielen
/// und der Verwaltung des Spielzustands.
class DbConnection {
  /// Die Supabase-Client-Instanz für Datenbankoperationen.
  late final SupabaseClient client;
  
  /// UUID-Generator zum Erstellen eindeutiger Bezeichner.
  final Uuid _uuid = const Uuid();
  
  /// Erstellt eine neue [DbConnection] und initialisiert den Supabase-Client.
  DbConnection() {
    // Initialize with your Supabase credentials
    client = SupabaseClient(
      'https://wzhaxvxfhdcrpyiswybf.supabase.co', 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6aGF4dnhmaGRjcnB5aXN3eWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDA1MTEsImV4cCI6MjA2MjAxNjUxMX0.yzYZ4jHfAlq2CgpkN_oAue71LLNzAYzP0ABSj1YbFNs'
    );
  }
  /// Ruft alle verfügbaren Jass-Karten aus der Datenbank ab.
  ///
  /// Gibt eine Liste von [Jasskarte]-Objekten zurück.
  Future<List<Jasskarte>> getAllCards() async {
    final response = await client
        .from('card')
        .select('CID, symbol, cardtype');
    List<Jasskarte> cards = [];
    for (final item in response) {
      final card = Jasskarte.wheninit(
        item['symbol'],
        item['CID'],
        item['cardtype'],
        'assets/${item['symbol']}/${item['symbol']}_${item['cardtype']}.png',
      );
      cards.add(card);
    }
    return cards;
  }
  /// Ruft eine bestimmte Karte anhand ihrer eindeutigen Karten-ID (CID) ab.
  ///
  /// [cid] Der eindeutige Bezeichner für die Karte.
  /// Gibt ein [Jasskarte]-Objekt zurück, falls gefunden, andernfalls wird eine Ausnahme ausgelöst.
  Future<Jasskarte> getCardByCid(String cid) async {
    final response = await client
        .from('card')
        .select('CID, symbol, cardtype')
        .eq('CID', cid)
        .maybeSingle();
    if (response != null) {
      return Jasskarte.wheninit(
        response['symbol'],
        response['CID'],
        response['cardtype'],
        'assets/${response['symbol']}/${response['symbol']}_${response['cardtype']}.png',
      );
    } else {
      throw Exception('Card with CID $cid not found');
    }
  }
  /// Ruft die vorhandene Benutzer-ID (UID) aus dem lokalen Speicher ab
  /// oder erstellt eine neue, falls sie nicht existiert.
  ///
  /// Dadurch wird sichergestellt, dass der Benutzer eine dauerhafte Identität über Sitzungen hinweg hat.
  /// Gibt die eindeutige ID des Benutzers zurück.
  Future<String> getOrCreateUid() async {
    final prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString('UID');
    if (uid == null) {
      uid = _uuid.v4();
      await prefs.setString('UID', uid);
    }
    return uid;
  }
  /// Speichert oder aktualisiert die Informationen eines Benutzers in der Datenbank.
  ///
  /// [uid] Die eindeutige ID des Benutzers.
  /// [name] Der Anzeigename des Benutzers.
  /// Falls der Benutzer nicht existiert, wird ein neuer Datensatz erstellt.
  /// Falls der Benutzer existiert, wird sein Name aktualisiert.
  Future<void> saveUserIfNeeded(String uid, String name) async {
    final existing = await client
        .from('User')
        .select()
        .eq('UID', uid)
        .maybeSingle();
    if (existing == null) {
      await client.from('User').insert({'UID': uid, 'name': name});
    } else {
      await client.from('User').update({'name': name}).eq('UID', uid);
    }
  }
  /// Erstellt ein neues Spiel mit einem eindeutigen Spielcode.
  ///
  /// Generiert einen eindeutigen Code, erstellt einen neuen Spieleintrag in der Datenbank
  /// und gibt den Spielcode zurück.
  Future<String> createGame() async {
    String code;
    do {
      code = _generateCode();
    } while (!await isCodeAvailable(code));

    await client.from('games').insert({
      'GID': code,
      'status': 'waiting',
      'participants': 1,
      'room_name': 'Neuer Raum',
    });
    return code;
  }
  /// Ermöglicht einem Spieler, einem bestehenden Spiel mit einem Spielcode beizutreten.
  ///
  /// [code] Der Spielcode zum Beitreten.
  /// Erhöht die Teilnehmerzahl für das Spiel.
  /// Gibt `true` zurück, wenn dem Spiel erfolgreich beigetreten wurde, andernfalls `false`.
  Future<bool> joinGame(String code) async {
    final resp = await client
        .from('games')
        .select('participants')
        .eq('GID', code)
        .maybeSingle();
    if (resp != null) {
      final current = resp['participants'] as int? ?? 0;
      await client.from('games').update({'participants': current + 1}).eq('GID', code);
      return true;
    }
    return false;
  }

/// Ruft die Karten ab, die in einer bestimmten Runde gespielt wurden.
///
/// [rid] Der eindeutige Bezeichner für die Runde.
/// Gibt eine Liste von [Jasskarte]-Objekten zurück, die in der Runde gespielt wurden.
Future<List<Jasskarte>> getPlayedCards(String rid) async {
  final response = await client
      .from('plays')
      .select('CID, card(symbol, cardtype), rounds!inner(GID)')
      .eq('RID', rid);

  print('DEBUG getPlayedCards raw response: $response');

  List<Jasskarte> playedCards = [];
  for (final item in response) {
    final cardData = item['card'];
    if (cardData == null) {
      print('WARN getPlayedCards: Kein "card"-Feld in $item');
      continue;
    }
    final card = Jasskarte.wheninit(
      cardData['symbol'] as String,
      item['CID'] as String,
      cardData['cardtype'] as String,
      'assets/${cardData['symbol']}/${cardData['symbol']}_${cardData['cardtype']}.png',
    );
    playedCards.add(card);
  }
  print('DEBUG getPlayedCards liefert ${playedCards.length} Karten zurück');
  return playedCards;
}
    /// Fügt einen Spieler zu einem bestimmten Spiel hinzu.
  ///
  /// [gid] Die Spiel-ID.
  /// [uid] Die Benutzer-ID des hinzuzufügenden Spielers.
  /// [name] Der Name des Spielers.
  /// Stellt sicher, dass der Benutzer existiert und weist ihm die nächste verfügbare Spielernummer zu.
  Future<void> addPlayerToGame(String gid, String uid, String name) async {
    await saveUserIfNeeded(uid, name);

    final existing = await client
        .from('usergame')
        .select()
        .eq('UID', uid)
        .eq('GID', gid)
        .maybeSingle();
    if (existing != null) return;

    final result = await client
        .from('usergame')
        .select('playernumber')
        .eq('GID', gid);

    final numbers = result.map((e) => e['playernumber'] as int).toList();
    final number = (numbers.isEmpty ? 1 : (numbers.reduce(max) + 1));

    await client.from('usergame').insert({
      'GID': gid,
      'UID': uid,
      'playernumber': number,
    });
  }
  /// Lädt alle Spieler, die sich derzeit in einem bestimmten Spiel befinden.
  ///
  /// [gid] Die Spiel-ID.
  /// Gibt eine Liste von [Spieler]-Objekten zurück, die die Spieler im Spiel repräsentieren.
  Future<List<Spieler>> loadPlayers(String gid) async {
    final response = await client
        .from('usergame')
        .select('playernumber, User!usergame_UID_fkey(UID,name)')
        .eq('GID', gid);

    return response.map<Spieler>((item) {
      return Spieler(
        item['User']['UID'],
        item['User']['name'],
        item['playernumber'] as int,
      );
    }).toList();
  }
  /// Mischt das Kartendeck und teilt die Karten an die Spieler im Spiel aus.
  ///
  /// [cards] Die Liste aller zu mischenden [Jasskarte].
  /// [players] Die Liste der [Spieler] im Spiel.
  /// [gid] Die Spiel-ID.
  Future<void> shuffleCards(List<Jasskarte> cards, List<Spieler> players, String gid) async {
    cards.shuffle();
    print('Shuffle Cards Called');
    for (var i = 0; i < players.length; i++) {
      final hand = cards.sublist(i * 9, (i + 1) * 9);
      for (final card in hand) {
        await client.from('cardingames').insert({
          'UID': players[i].uid,
          'CID': card.cid,
          'GID': gid,
        });
      }
    }
  }
  /// Ruft die Karten ab, die der aktuelle Benutzer in einem bestimmten Spiel hält.
  ///
  /// [gid] Die Spiel-ID.
  /// [uid] Die ID des aktuellen Benutzers.
  /// Gibt eine Liste von [Jasskarte]-Objekten zurück, die die Hand des Benutzers repräsentieren.
  Future<List<Jasskarte>> getUrCards(String gid, String uid) async {
    final response = await client
        .from('cardingames')
        .select('CID, card(symbol, cardtype)')
        .eq('UID', uid)
        .eq('GID', gid);
    List<Jasskarte> cards = [];
    for (final item in response) {
      final cardData = item['card']; // Hier liegen symbol und cardtype
      final card = Jasskarte.wheninit(
        cardData['symbol'],
        item['CID'],
        cardData['cardtype'],
        'assets/${cardData['symbol']}/${cardData['symbol']}_${cardData['cardtype']}.png',
      );
      cards.add(card);
    }
    return cards;
  }
  /// Ruft die Kartenhand für den aktuellen Benutzer in einem bestimmten Spiel ab.
  ///
  /// [gid] Die Spiel-ID.
  /// Gibt eine Liste von [Jasskarte]-Objekten zurück, die die Hand des Benutzers repräsentieren.
  Future<List<Jasskarte>> getMyHand(String gid) async {
    final uid = await getOrCreateUid();
    return await getUrCards(gid, uid);
  }
  /// Zählt die Anzahl der Karten, die ein Benutzer in einem bestimmten Spiel hält.
  ///
  /// [gid] Die Spiel-ID.
  /// [uid] Die Benutzer-ID.
  /// Gibt die Anzahl der Karten in der Hand des Benutzers zurück.
  Future<int> getCardCount(String gid, String uid) async {
    final response = await client
        .from('cardingames')
        .select('CID')
        .eq('UID', uid)
        .eq('GID', gid);
    return response.length;
  }  /// Zeichnet ein Kartenspiel in der Datenbank für eine bestimmte Runde auf.
  ///
  /// [rid] Die Runden-ID.
  /// [uid] Die Benutzer-ID des Spielers, der den Zug macht.
  /// [cid] Die ID der gespielten Karte.
  Future<void> addPlayInRound(String rid, String uid, String cid) async {
    await client.from('plays').insert({
      'RID': rid,
      'UID': uid,
      'CID': cid,
    });    
    print('DEBUG: Card $cid for player $uid in round $rid inserted');
  }
  /// Ruft die neueste Runden-ID für ein bestimmtes Spiel ab.
  ///
  /// [gid] Die Spiel-ID.
  /// Gibt die Runden-ID zurück oder einen leeren String, falls keine Runden gefunden werden.
  Future<String> GetRoundID(String gid) async {
    final response = await client
        .from('rounds')
        .select('RID')
        .eq('GID', gid)
        .order('whichround', ascending: false)
        .limit(1)
        .maybeSingle();
    if (response != null) {
      return response['RID'];
    } else {
      return '';
    }
  }  

  /// Überprüft, ob eine bestimmte Karte eine Trumpfkarte im angegebenen Spiel ist.
  ///
  /// [cid] Die Karten-ID.
  /// [gid] Die Spiel-ID.
  /// Gibt `true` zurück, wenn die Karte eine Trumpfkarte ist, andernfalls `false`.
  Future<bool> isTrumpf(String cid, String gid) async {
    final response = await client
      .from('cardingames')
      .select('isTrumpf')
      .eq('CID', cid)
      .eq('GID', gid)
      .maybeSingle();
    print('DEBUG isTrumpf response: $response');
    return response?['isTrumpf'] as bool? ?? false;
  }
  /// Ruft den Kartentyp für eine bestimmte Karten-ID ab.
  ///
  /// [cid] Die Karten-ID.
  /// Gibt den Kartentyp als String zurück.
  Future<String> getCardType(String cid) async {
    final response = await client.from('card').select('cardtype').eq('CID', cid).maybeSingle();
    print('DEBUG getCardType response: $response');
    return response?['cardtype'] as String? ?? '';
  }
  /// Berechnet den Basiswert einer Karte für die Punktevergabe, unter Berücksichtigung, ob es sich um eine Trumpfkarte handelt.
  ///
  /// [cid] Die Karten-ID.
  /// [gid] Die Spiel-ID.
  /// Gibt den Kartenwert als ganze Zahl zurück.
  Future<int> getCardValue(String cid, String gid) async {
    String cardType = await getCardType(cid);
    if (await isTrumpf(cid, gid) == true) {
      switch (cardType) {
        case 'Ass':
          return 11;
        case 'König':
          return 4;
        case 'Ober':
          return 3;
        case 'Unter':
          return 20;
        case '10':
          return 10;
        case '9':
          return 14;
        default:
          print("Have been here trumpf");
          return 0;
      }
    } else {
      print("Do not annoy me");
      switch (cardType) {
        case 'Ass':
          return 11;
        case 'König':
          return 4;
        case 'Ober':
          return 3;
        case 'Unter':
          return 2;
        case '10':
          return 10;
        default:
          print("Have been here");
          return 0;
      }
    }
  }
  /// Berechnet den Gesamtwert einer Karte für einen Stich, unter Berücksichtigung, ob es sich um eine Trumpfkarte handelt.
  ///
  /// [cid] Die Karten-ID.
  /// [gid] Die Spiel-ID.
  /// Gibt den Kartenwert als ganze Zahl zurück.
  Future<int> getCardWorth(String cid, String gid) async {
    if (await isTrumpf(cid, gid)) {
      switch (await getCardType(cid)) {
        case 'Ass':
          return 19;
        case 'König':
          return 18;
        case 'Ober':
          return 17;
        case 'Unter':
          return 21;
        case '10':
          return 15;
        case '9':
          return 20;
        case '8':
          return 13;
        case '7':
          return 12;
        case '6':
          return 11;
        default:
          return 0;
      }
    } else {
      switch (await getCardType(cid)) {
        case 'Ass':
          return 9;
        case 'König':
          return 8;
        case 'Ober':
          return 7;
        case 'Unter':
          return 6;
        case '10':
          return 5;
        case '9':
          return 4;
        case '8':
          return 3;
        case '7':
          return 2;
        case '6':
          return 1;
        default:
          return 0;
      }
    }
  }
  /// Speichert die Punkte für die Benutzer basierend auf den im Stich gewonnenen Karten.
  ///
  /// [cards] Die Liste der im Stich gewonnenen Karten.
  /// [gid] Die Spiel-ID.
  /// [winnerUid] Die Benutzer-ID des Stichgewinners.
  /// [teammateUid] Die Benutzer-ID des Teamkollegen des Stichgewinners.
  /// Gibt die Gesamtpunktzahl zurück.
  Future<int> savePointsForUsers(List<Jasskarte> cards, String gid, String winnerUid, String teammateUid) async {
    int totalPoints = 0;
    print(cards.length);
    for (var card in cards) {
      totalPoints += await getCardValue(card.cid, gid);
      print("Total Points: $totalPoints");
    }
    final response = await client
        .from('usergame')
        .select('UID, score')
        .eq('GID', gid)
        .or('UID.eq.$winnerUid,UID.eq.$teammateUid');

    final scores = {for (var item in response) item['UID']: item['score'] as int? ?? 0};

    final winnerUpdate = await client.from('usergame')
        .update({'score': (scores[winnerUid]! + totalPoints).toInt()})
        .match({'UID': winnerUid, 'GID': gid});
    print("Winner update: $winnerUpdate");

    final teammateUpdate = await client.from('usergame')
        .update({'score': (scores[teammateUid]! + totalPoints).toInt()})
        .match({'UID': teammateUid, 'GID': gid});
    print("Teammate update: $teammateUpdate");

    return totalPoints;
  }  
    /// Ermittelt die Gewinnerkarte aus einer Liste von Karten basierend auf den Spielregeln.
  ///
  /// [cards] Die Liste der zu bewertenden Karten.
  /// [gid] Die Spiel-ID.
  /// [firstCard] Eine Referenzkarte zur Bestimmung der Gewinnkriterien.
  /// Gibt die Benutzer-ID des Spielers zurück, der die Gewinnerkarte gespielt hat.
  Future<String> getWinningCard(List<Jasskarte> cards, String gid, Jasskarte firstCard) async {
    Jasskarte? winningCard;
    for (var card in cards) {
      if (card.symbol != firstCard.symbol && await isTrumpf(card.cid, gid) != true) {
        continue;
      }
      if (winningCard == null || await getCardWorth(card.cid, gid) > await getCardWorth(winningCard.cid, gid)) {
        winningCard = card;
        print('Winning Card: ${winningCard.cid} with worth ${await getCardWorth(winningCard.cid, gid)} and IstTrumpf: ${await isTrumpf(winningCard.cid, gid)}');
      }
    }
    final response = await client
        .from('cardingames')
        .select('UID')
        .eq('CID', winningCard != null ? winningCard.cid : '')
        .eq('GID', gid)
        .maybeSingle();
    print('WINNINGUID: ${response?['UID']}');
    return response?['UID'] as String? ?? '';
  }
  /// Aktualisiert die Gewinner-Informationen im Runden-Datensatz.
  ///
  /// [uid] Die Benutzer-ID des Gewinners.
  /// [rid] Die Runden-ID.
  Future<void> updateWinnerDB(String uid, String rid) async{
    await client.from('rounds').update({'winnerid': uid}).eq('RID', rid);
  }  /// Wartet auf genau vier Spieler, die dem angegebenen Spiel beitreten.
  ///
  /// [gid] Die Spiel-ID, die auf Spielerbeitritte überwacht werden soll.
  /// Gibt einen [Future] zurück, der mit einer Liste von [Spieler] abgeschlossen wird, sobald 4 Spieler beigetreten sind.
  // Mit hilfe von KI: Hilf mir das ich warte bis 4 Spieler im Spiel sind
  Future<List<Spieler>> waitForFourPlayers(String gid) {
    final completer = Completer<List<Spieler>>();
    void checkPlayers() async {
      final players = await loadPlayers(gid);
      if (players.length == 4) {
        completer.complete(players);
      }
    }

    checkPlayers();
    final channel = client.channel('public:usergame');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'usergame',
      callback: (_) => checkPlayers(),
    ).subscribe();

    return completer.future;
  }
  
/// Kanal für Echtzeit-Spiel-Updates.
RealtimeChannel? _playsChannel;

/// Benachrichtiger für neue Kartenspiele, überträgt die Karten-ID, wenn eine neue Karte gespielt wird.
final ValueNotifier<String?> newCard = ValueNotifier(null);

/// Abonniert Echtzeit-Updates für Karten, die in der angegebenen Runde gespielt werden.
///
/// [currentRid] Die Runden-ID, die auf neue Kartenspiele überwacht werden soll.
/// Diese Methode richtet einen Echtzeit-Listener ein, der [newCard] aktualisiert, wenn Karten gespielt werden.
Future<void> subscribeToPlayedCards(String currentRid) async{
  if (currentRid.isEmpty) return;
  try {    
    if (_playsChannel != null) {
      try {
        client.removeChannel(_playsChannel!);
      } catch (e) {
        print('Channel removal error (ignored): $e');
      }
    }
    _playsChannel = client
        .channel('public:plays:RID=eq.$currentRid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'plays',
          callback: (payload) {
          final newRecord = payload.newRecord;
          // payload.newRecord is non-null when callback runs
          final newCid = newRecord['CID'];
          if (newCid != null) {
            newCard.value = newCid;
          }
          },
        )
        .subscribe();

    currentRid = currentRid;
  } catch (e) {
    print('Realtime subscription error (ignored): $e');
    // Continue without realtime updates - game will still work
  }
}
  /// Generiert einen zufälligen 4-stelligen Spielcode mit alphanumerischen Zeichen.
  ///
  /// Schließt verwirrende Zeichen wie 'I', 'O', '0', '1' für bessere Benutzerfreundlichkeit aus.
  /// Gibt einen String mit dem generierten Code zurück.
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
  /// Überprüft, ob ein Spielcode verfügbar ist (d.h. nicht bereits von einem anderen Spiel verwendet wird).
  ///
  /// [code] Der zu überprüfende Spielcode.
  /// Gibt `true` zurück, wenn der Code verfügbar ist, andernfalls `false`.
  Future<bool> isCodeAvailable(String code) async {
    final resp = await client.from('games').select('GID').eq('GID', code).maybeSingle();
    return resp == null;
  }    /// Startet eine neue Runde im Spiel und initialisiert sie in der Datenbank.
  ///
  /// [gid] Die Spiel-ID.
  /// [whichround] Die aktuelle Rundennummer.
  Future<void> startNewRound(String gid, int whichround) async {
    await client.from('rounds').insert({
      'GID': gid,
      'whichround': whichround + 1,
    });    

  }
  /// Ruft die aktuelle Rundennummer für ein bestimmtes Spiel ab.
  ///
  /// [gid] Die Spiel-ID.
  /// Gibt die Rundennummer zurück oder -1, falls keine Runden gefunden werden.
  Future<int> getWhichRound(String gid) async {
    final response = await client
        .from('rounds')
        .select('whichround')
        .eq('GID', gid)
        .order('whichround', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      return response['whichround'] as int;
    } else {
      return -1;
    }
  }
  /// Aktualisiert die Spielzug-Informationen in der Datenbank.
  ///
  /// [rid] Die Runden-ID.
  /// [uid] Die Benutzer-ID des Spielers, der am Zug ist.
  void updateWhosTurn(String rid, String uid) async {
    await client.from('rounds').update({'whoIsAtTurn': uid}).eq('RID', rid);
  }
  /// Ruft die Benutzer-ID des Spielers ab, der in der aktuellen Runde am Zug ist.
  ///
  /// [rid] Die Runden-ID.
  /// Gibt die Benutzer-ID als String zurück.
  Future<String> getWhosTurn(String rid) async {
    final response = await client
      .from('rounds')
      .select('whoIsAtTurn')
      .eq('RID', rid)
      .order('whichround', ascending: false)
      .limit(1)
      .maybeSingle();
    if (response != null && response['whoIsAtTurn'] != null) {
      return response['whoIsAtTurn'] as String;
    }
    return '';
  }
  /// Ruft die Spielernummer für den aktuellen Benutzer im angegebenen Spiel ab.
  ///
  /// [uid] Die Benutzer-ID.
  /// [gid] Die Spiel-ID.
  /// Gibt die Spielernummer als ganze Zahl zurück.
  Future<int> getUrPlayernumber(String uid, String gid) async {
    final response = await client
      .from('usergame')
      .select('playernumber')
      .eq('UID', uid)
      .eq('GID', gid)
      .maybeSingle();
  	if (response != null && response['playernumber'] != null) {
      return response['playernumber'];
    }
    else{ throw Exception('Error');}
  }
  /// Ruft die Benutzer-ID des nächsten Spielers in der Zugreihenfolge ab.
  ///
  /// [gid] Die Spiel-ID.
  /// [playernumber] Die Spielernummer, für die der nächste Benutzer gefunden werden soll.
  /// Gibt die Benutzer-ID als String zurück.
  Future<String> getNextUserUid(String gid, int playernumber) async{
    final response = await client
      .from('usergame')
      .select('UID')
      .eq('GID', gid)
      .eq('playernumber', playernumber)
      .maybeSingle();
      if(response != null && response['UID'] != null) {
        return response['UID'];
      }
      else {throw Exception('Error in getNextUserUid gid: $gid playernumber $playernumber');}
  }    
    /// Aktualisiert den Trumpf-Status für Karten im Spiel.
  ///
  /// [gid] Die Spiel-ID.
  /// [trumpf] Das Symbol der Trumpfkarte.
  Future<void> updateTrumpf(String gid, String trumpf) async {
    await client.from('cardingames')
        .update({'isTrumpf': false})
        .eq('GID', gid);
    
    final cardResponse = await client
        .from('card')
        .select('CID')
        .eq('symbol', trumpf);
    
    List<String> trumpfCardIds = cardResponse.map<String>((item) => item['CID'] as String).toList();
    
    if (trumpfCardIds.isNotEmpty) {
      for (String cardId in trumpfCardIds) {
        await client.from('cardingames')
            .update({'isTrumpf': true})
            .eq('GID', gid)
            .eq('CID', cardId);
      }
      print('DEBUG: ${trumpfCardIds.length} cards of $trumpf for GID $gid set to true');
    }
  } 
  /// Ruft eine Liste offener Spiele ab, die beigetreten werden können.
  ///
  /// Gibt eine Liste von Maps zurück, die Spiel-ID, Raumname und Teilnehmerzahl enthalten.
  Future<List<Map<String, dynamic>>> getOpenGames() async {
    final response = await client
        .from('games')
        .select('GID, room_name, participants')
        .eq('status', 'waiting')
        .lt('participants', 4);
    return List<Map<String, dynamic>>.from(response as List);
  }
  /// Ruft die aktuelle Punktzahl eines Spielers in einem bestimmten Spiel ab.
  ///
  /// [uid] Die Benutzer-ID.
  /// [gid] Die Spiel-ID.
  /// Gibt die Punktzahl als ganze Zahl zurück.
  Future<int> getPlayerScore(String uid, String gid) async {
    final response = await client
        .from('usergame')
        .select('score')
        .eq('UID', uid)
        .eq('GID', gid)
        .maybeSingle();
    
    if (response != null && response['score'] != null) {
      return response['score'] as int;
    }
    return 0;
  }  /// Gibt das aktuelle Trumpf-Symbol für das angegebene Spiel zurück.
  ///
  /// [gid] Die Spiel-ID, für die das Trumpf-Symbol überprüft werden soll.
  /// Gibt das Trumpf-Symbol als String zurück oder null, falls nicht gesetzt.
  Future<String?> getTrumpfSymbol(String gid) async {
    // Find a card marked as trumpf in this game
    final response = await client
      .from('cardingames')
      .select('CID')
      .eq('GID', gid)
      .eq('isTrumpf', true)
      .limit(1)
      .maybeSingle();
    if (response != null && response['CID'] != null) {
      final cardId = response['CID'] as String;
      // Retrieve the symbol of that card
      final symbolResp = await client
        .from('card')
        .select('symbol')
        .eq('CID', cardId)
        .maybeSingle();
      if (symbolResp != null && symbolResp['symbol'] != null) {
        return symbolResp['symbol'] as String;
      }
    }
    return null;
  }
}


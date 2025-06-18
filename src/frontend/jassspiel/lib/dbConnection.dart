import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/jasskarte.dart';

/// Provides a connection to the Supabase database to handle all game-related data.
///
/// This class encapsulates all the methods needed to interact with the backend,
/// including fetching card data, managing users, creating and joining games,
/// and handling game state.
class DbConnection {
  late final SupabaseClient client;
  final Uuid _uuid = const Uuid();
  DbConnection() {
    // Initialize with your Supabase credentials
    client = SupabaseClient(
      'https://wzhaxvxfhdcrpyiswybf.supabase.co', 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6aGF4dnhmaGRjcnB5aXN3eWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDA1MTEsImV4cCI6MjA2MjAxNjUxMX0.yzYZ4jHfAlq2CgpkN_oAue71LLNzAYzP0ABSj1YbFNs'
    );
  }

  /// Fetches all available Jass cards from the database.
  ///
  /// Returns a list of [Jasskarte] objects.
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

  /// Fetches a specific card by its unique card ID (CID).
  ///
  /// [cid] The unique identifier for the card.
  /// Returns a [Jasskarte] object if found, otherwise throws an exception.
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

  /// Retrieves the existing user ID (UID) from local storage,
  /// or creates a new one if it doesn't exist.
  ///
  /// This ensures that the user has a persistent identity across sessions.
  /// Returns the user's unique ID.
  Future<String> getOrCreateUid() async {
    final prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString('UID');
    if (uid == null) {
      uid = _uuid.v4();
      await prefs.setString('UID', uid);
    }
    return uid;
  }

  /// Saves or updates a user's information in the database.
  ///
  /// [uid] The user's unique ID.
  /// [name] The user's display name.
  /// If the user doesn't exist, a new record is created.
  /// If the user exists, their name is updated.
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

  /// Creates a new game with a unique game code.
  ///
  /// Generates a unique code, creates a new game record in the database,
  /// and returns the game code.
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

  /// Allows a player to join an existing game using a game code.
  ///
  /// [code] The game code to join.
  /// Increments the participant count for the game.
  /// Returns `true` if the game was joined successfully, `false` otherwise.
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

/// Fetches the cards that have been played in a specific round.
///
/// [rid] The unique identifier for the round.
/// Returns a list of [Jasskarte] objects that have been played in the round.
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
  
  /// Adds a player to a specific game.
  ///
  /// [gid] The game ID.
  /// [uid] The user ID of the player to add.
  /// [name] The name of the player.
  /// It ensures the user exists and assigns them the next available player number.
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

  /// Loads all players currently in a specific game.
  ///
  /// [gid] The game ID.
  /// Returns a list of [Spieler] objects representing the players in the game.
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

  /// Shuffles the deck of cards and deals them to the players in the game.
  ///
  /// [cards] The list of all [Jasskarte] to be shuffled.
  /// [players] The list of [Spieler] in the game.
  /// [gid] The game ID.
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

  /// Fetches the cards held by the current user in a specific game.
  ///
  /// [gid] The game ID.
  /// [uid] The current user's ID.
  /// Returns a list of [Jasskarte] objects representing the user's hand.
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

  /// Fetches the hand of cards for the current user in a specific game.
  ///
  /// [gid] The game ID.
  /// Returns a list of [Jasskarte] objects representing the user's hand.
  Future<List<Jasskarte>> getMyHand(String gid) async {
    final uid = await getOrCreateUid();
    return await getUrCards(gid, uid);
  }

  /// Counts the number of cards held by a user in a specific game.
  ///
  /// [gid] The game ID.
  /// [uid] The user ID.
  /// Returns the number of cards in the user's hand.
  Future<int> getCardCount(String gid, String uid) async {
    final response = await client
        .from('cardingames')
        .select('CID')
        .eq('UID', uid)
        .eq('GID', gid);
    return response.length;
  }  
  /// Records a card play in the database for a specific round.
  ///
  /// [rid] The round ID.
  /// [uid] The user ID of the player making the play.
  /// [cid] The card ID being played.
  Future<void> addPlayInRound(String rid, String uid, String cid) async {
    final existingPlays = await client
        .from('plays')
        .select('CID')
        .eq('RID', rid);

    await client.from('plays').insert({
      'RID': rid,
      'UID': uid,
      'CID': cid,
    });    
    print('DEBUG: Card $cid for player $uid in round $rid inserted');
  }

  /// Retrieves the most recent round ID for a specific game.
  ///
  /// [gid] The game ID.
  /// Returns the round ID, or an empty string if no rounds are found.
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


  /// Checks if a specific card is a trump card in the given game.
  ///
  /// [cid] The card ID.
  /// [gid] The game ID.
  /// Returns `true` if the card is a trump card, `false` otherwise.
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

  /// Retrieves the card type for a specific card ID.
  ///
  /// [cid] The card ID.
  /// Returns the card type as a string.
  Future<String> getCardType(String cid) async {
    final response = await client.from('card').select('cardtype').eq('CID', cid).maybeSingle();
    print('DEBUG getCardType response: $response');
    return response?['cardtype'] as String? ?? '';
  }

  /// Calculates the base value of a card for scoring, considering if it's a trump card.
  ///
  /// [cid] The card ID.
  /// [gid] The game ID.
  /// Returns the card value as an integer.
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

  /// Calculates the total worth of a card for a trick, considering if it's a trump card.
  ///
  /// [cid] The card ID.
  /// [gid] The game ID.
  /// Returns the card worth as an integer.
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

  /// Saves the points for the users based on the cards won in a trick.
  ///
  /// [cards] The list of cards won in the trick.
  /// [gid] The game ID.
  /// [winnerUid] The user ID of the trick winner.
  /// [teammateUid] The user ID of the trick winner's teammate.
  /// Returns the total points scored.
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
  
  /// Determines the winning card from a list of cards based on game rules.
  ///
  /// [cards] The list of cards to evaluate.
  /// [gid] The game ID.
  /// [firstCard] A reference card to determine the winning criteria.
  /// Returns the user ID of the player who played the winning card.
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

  /// Updates the winner information in the round record.
  ///
  /// [uid] The user ID of the winner.
  /// [rid] The round ID.
  Future<void> updateWinnerDB(String uid, String rid) async{
    await client.from('rounds').update({'winnerid': uid}).eq('RID', rid);
  }

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
  
RealtimeChannel? _playsChannel;
final ValueNotifier<String?> newCard = ValueNotifier(null);

Future<void> subscribeToPlayedCards(String currentRid) async{
  if (currentRid.isEmpty) return;
  // if a previous subscription exists, remove it properly
  if (_playsChannel != null) {
    client.removeChannel(_playsChannel!);
    
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
}

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Checks if a game code is available (i.e., not already taken by another game).
  ///
  /// [code] The game code to check.
  /// Returns `true` if the code is available, `false` otherwise.
  Future<bool> isCodeAvailable(String code) async {
    final resp = await client.from('games').select('GID').eq('GID', code).maybeSingle();
    return resp == null;
  }  
  /// Starts a new round in the game, initializing it in the database.
  ///
  /// [gid] The game ID.
  /// [whichround] The current round number.
  Future<void> startNewRound(String gid, int whichround) async {
    await client.from('rounds').insert({
      'GID': gid,
      'whichround': whichround + 1,
    });    

  }

  /// Retrieves the current round number for a specific game.
  ///
  /// [gid] The game ID.
  /// Returns the round number, or -1 if no rounds are found.
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

  /// Updates the player turn information in the database.
  ///
  /// [rid] The round ID.
  /// [uid] The user ID of the player whose turn it is.
  void updateWhosTurn(String rid, String uid) async {
    await client.from('rounds').update({'whoIsAtTurn': uid}).eq('RID', rid);
  }

  /// Retrieves the user ID of the player whose turn it is in the current round.
  ///
  /// [rid] The round ID.
  /// Returns the user ID as a string.
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

  /// Retrieves the player number for the current user in the specified game.
  ///
  /// [uid] The user ID.
  /// [gid] The game ID.
  /// Returns the player number as an integer.
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

  /// Retrieves the user ID of the next player in turn order.
  ///
  /// [gid] The game ID.
  /// [playernumber] The player number to find the next user for.
  /// Returns the user ID as a string.
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
  
  /// Updates the trumpf status for cards in the game.
  ///
  /// [gid] The game ID.
  /// [trumpf] The symbol of the trumpf card.
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

  /// Retrieves a list of open games available for joining.
  ///
  /// Returns a list of maps containing game ID, room name, and participant count.
  Future<List<Map<String, dynamic>>> getOpenGames() async {
    final response = await client
        .from('games')
        .select('GID, room_name, participants')
        .eq('status', 'waiting')
        .lt('participants', 4);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Retrieves the current score of a player in a specific game.
  ///
  /// [uid] The user ID.
  /// [gid] The game ID.
  /// Returns the score as an integer.
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
  }

  /// Returns the current trumpf symbol for the given game, or null if not set
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


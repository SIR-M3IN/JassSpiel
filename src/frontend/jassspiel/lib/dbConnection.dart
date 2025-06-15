import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/jasskarte.dart';

class DbConnection {
  final SupabaseClient client = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  static Future<void> initialize({required String url, required String anonKey}) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

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

  Future<String> getOrCreateUid() async {
    final prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString('UID');
    if (uid == null) {
      uid = _uuid.v4();
      await prefs.setString('UID', uid);
    }
    return uid;
  }

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

  Future<List<Jasskarte>> getMyHand(String gid) async {
    final uid = await getOrCreateUid();
    return await getUrCards(gid, uid);
  }


  Future<int> getCardCount(String gid, String uid) async {
    final response = await client
        .from('cardingames')
        .select('CID')
        .eq('UID', uid)
        .eq('GID', gid);
    return response.length;
  }  
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

  Future<String> getCardType(String cid) async {
    final response = await client.from('card').select('cardtype').eq('CID', cid).maybeSingle();
    print('DEBUG getCardType response: $response');
    return response?['cardtype'] as String? ?? '';
  }
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
  Future<int> savePointsForUsers(List<Jasskarte> cards, String gid, String winnerUid, String teammateUid) async {
    int totalPoints = 0;
    print(cards);
    for (var card in cards) {
      totalPoints += await getCardValue(card.cid, gid);
    }
    print("Total Points: $totalPoints");
    // print("WinnerUID: $winnerUid");
    // print("GID: $gid");
    // print("TeammateUID: $teammateUid");
    final response = await client
        .from('usergame')
        .select('UID, score')
        .eq('GID', gid)
        .or('UID.eq.$winnerUid,UID.eq.$teammateUid');
        
    print("RESPONSE: $response");
    final scores = {for (var item in response) item['UID']: item['score'] as int? ?? 0};
    print("Score $scores");
    await client.from('usergame').upsert([
      {'UID': winnerUid, 'GID': gid, 'score': scores[winnerUid]! + totalPoints},
      {'UID': teammateUid, 'GID': gid, 'score': scores[teammateUid]! + totalPoints},
    ]);
    print("here");

    return totalPoints;
  }
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
  Future<void> updateWinnerDB(String uid, String rid) async{
    await client.from('rounds').update({'winnerid': uid}).eq('RID', rid);
  }
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

  Future<bool> isCodeAvailable(String code) async {
    final resp = await client.from('games').select('GID').eq('GID', code).maybeSingle();
    return resp == null;
  }  
  Future<void> startNewRound(String gid, int whichround) async {
    await client.from('rounds').insert({
      'GID': gid,
      'whichround': whichround + 1,
    });    

  }

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

  void updateWhosTurn(String rid, String uid) async {
    await client.from('rounds').update({'whoIsAtTurn': uid}).eq('RID', rid);
  }

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

  Future<List<Map<String, dynamic>>> getOpenGames() async {
    final response = await client
        .from('games')
        .select('GID, room_name, participants')
        .eq('status', 'waiting')
        .lt('participants', 4);
    return List<Map<String, dynamic>>.from(response as List);
  }
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
}


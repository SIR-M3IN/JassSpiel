import 'dart:async';
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
    print('GetAllCards Called');
    final response = await client
        .from('card')
        .select('CID, symbol, cardtype');
    List<Jasskarte> cards = [];
    print('Response length: ${response.length}');
    for (final item in response) {
      final card = Jasskarte.wheninit(
        item['symbol'],
        item['CID'],
        item['cardtype'],
        'assets/${item['symbol']}/${item['symbol']}_${item['cardtype']}.png',
      );
      cards.add(card);
      print('Card added: ${card.symbol}, ${card.cid}, ${card.cardType}');
    }
    return cards;
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
  // Variante A: Sofern FOREIGN KEY korrekt eingerichtet ist
  final response = await client
      .from('plays')
      .select('CID, card(symbol, cardtype)')
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
    // Stelle sicher, dass der User existiert
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
    print('GID: $gid, UID: $uid');
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

  Future<void> addPlayInRound(String rid, String uid, String cid) async {
    await client.from('plays').insert({
      'RID': rid,
      'UID': uid,
      'CID': cid,
    });
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
      throw Exception('No round found for GID: $gid');
    }
  }

  Future<bool> isTrumpf(String cid) async {
    final response = await client.from('card').select('istrumpf').eq('CID', cid).maybeSingle();
    return response?['istrumpf'] as bool? ?? false;
  }

  Future<String> getCardType(String cid) async {
    final response = await client.from('card').select('cardtype').eq('CID', cid).maybeSingle();
    return response?['cardtype'] as String? ?? '';
  }

  Future<int> getCardValue(String cid) async {
    if (await isTrumpf(cid)) {
      switch (await getCardType(cid)) {
        case 'ASS':
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
          return 0;
      }
    } else {
      switch (await getCardType(cid)) {
        case 'ASS':
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
          return 0;
      }
    }
  }

  Future<String> getWinningCard(List<Jasskarte> cards) async {
    Jasskarte? winningCard;
    for (var card in cards) {
      if (winningCard == null || await getCardValue(card.cid) > await getCardValue(winningCard.cid)) {
        winningCard = card;
      }
    }

    final response = await client
        .from('cardingames')
        .select('UID')
        .eq('CID', winningCard != null ? winningCard.cid : '')
        .maybeSingle();
    return response?['UID'] as String? ?? '';
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
    await client.from('rounds').update({'whosturn': uid}).eq('RID', rid);
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
      if(response != null && response['UID']){
        return response['UID'];
      }
      else {throw Exception('Error in getNextUserUid gid: $gid playernumber $playernumber');}
  }
}


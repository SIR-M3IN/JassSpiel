import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jassspiel/jasskarte.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/logger.util.dart';

class SwaggerConnection {
  final String baseUrl;
  final log = getLogger();

  SwaggerConnection({required this.baseUrl});

  Future<void> upsertUser(String uid, String name) async {
    final uri = Uri.parse('$baseUrl/users/$uid');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('User upsert failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<String> createGame() async {
    final uri = Uri.parse('$baseUrl/games');
    final resp = await http.post(uri);
    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return data['gid'] as String;
    }
    throw Exception('Game creation failed: ${resp.statusCode}');
  }

  Future<bool> joinGame(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/join');
    final resp = await http.post(uri);
    if (resp.statusCode == 200) return true;
    if (resp.statusCode == 404) return false;
    throw Exception('Join game error: ${resp.statusCode}');
  }

  Future<List<Spieler>> loadPlayers(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/players');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Spieler(e['uid'], e['name'], e['playernumber'] as int)).toList();
    }
    throw Exception('Load players error: ${resp.statusCode}');
  }

  Future<List<Jasskarte>> getAllCards() async {
    final uri = Uri.parse('$baseUrl/cards');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Jasskarte.wheninit(
        e['symbol'], e['cid'], e['cardtype'], e['path']
      )).toList();
    }
    throw Exception('Get cards failed: ${resp.statusCode}');
  }

  Future<Jasskarte> getCardByCid(String cid) async {
    final uri = Uri.parse('$baseUrl/cards/$cid');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return Jasskarte.wheninit(e['symbol'], e['cid'], e['cardtype'], e['path']);
    }
    throw Exception('Get card error: ${resp.statusCode}');
  }

  Future<void> shuffleCards(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/cards/shuffle');
    final resp = await http.post(uri);
    if (resp.statusCode != 200) throw Exception('Shuffle error: ${resp.statusCode}');
  }

  Future<String> getCurrentRoundId(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/current-round-id');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['rid'] as String;
    }
    throw Exception('Get round id error: ${resp.statusCode}');
  }

  Future<void> startNewRound(String gid, int whichround) async {
    final uri = Uri.parse('$baseUrl/games/$gid/rounds');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'whichround': whichround}),
    );
    if (resp.statusCode != 201) throw Exception('Start round error: ${resp.statusCode}');
  }

  Future<void> addPlayInRound(String rid, String uid, String cid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/plays');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'cid': cid}),
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) 
    throw Exception('Add play error: ${resp.statusCode}');
  }

  Future<List<Jasskarte>> getPlayedCards(String rid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/played-cards');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Jasskarte.wheninit(
        e['symbol'], e['cid'], e['cardtype'], e['path']
      )).toList();
    }
    throw Exception('Get played cards error: ${resp.statusCode}');
  }

  Future<String?> getFirstCardCid(String rid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/first-card-cid');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['cid'] as String?;
    }
    throw Exception('Get first card cid error: ${resp.statusCode}');
  }

  Future<String> getWhosTurn(String rid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/turn');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['uid'] as String;
    }
    throw Exception('Get turn error: ${resp.statusCode}');
  }

  Future<void> updateWhosTurn(String rid, String uid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/turn');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    );
    if (resp.statusCode != 200) throw Exception('Update turn error: ${resp.statusCode}');
  }

  Future<void> updateTrumpf(String gid, String symbol) async {
    final uri = Uri.parse('$baseUrl/games/$gid/trumpf-suit');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      // use camelCase key matching OpenAPI model attribute_map
      body: jsonEncode({'trumpfSymbol': symbol}),
    );
    if (resp.statusCode != 200) throw Exception('Update trumpf error: ${resp.statusCode}');
  }

  Future<int> getUrPlayernumber(String uid, String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/users/$uid/player-number');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['playernumber'] as int;
    }
    throw Exception('Get player number error: ${resp.statusCode}');
  }

  Future<String> getNextPlayerUid(String gid, int playernumber) async {
    final uri = Uri.parse('$baseUrl/games/$gid/next-player-uid?playernumber=$playernumber');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final e = jsonDecode(resp.body);
      return e['uid'] as String;
    }
    throw Exception('Get next player error: ${resp.statusCode}');
  }

  Future<List<Jasskarte>> getUrCards(String gid, String uid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/users/$uid/cards');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Jasskarte.wheninit(
        e['symbol'], e['cid'], e['cardtype'], e['path']
      )).toList();
    }
    throw Exception('Get user cards error: ${resp.statusCode}');
  }

  Future<int> savePointsForUsers(String gid, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/games/$gid/update-scores');
    final resp = await http.post(
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

  Future<String> determineWinningCard(String gid, List<Jasskarte> cards) async {
    final uri = Uri.parse('$baseUrl/cards/determine-winning-card?gid=$gid');
    final payload = {
      'cards': cards.map((c) => c.toJson()).toList(),
    };
    final resp = await http.post(
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

  Future<int> getWhichRound(String gid) async {
    final uri = Uri.parse('$baseUrl/games/$gid/current-round-number');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['whichround'] as int;
    }
    throw Exception('Get which round failed: ${resp.statusCode}');
  }
  Future<void> updateWinner(String rid, String uid) async {
    final uri = Uri.parse('$baseUrl/rounds/$rid/winner');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'winnerUid': uid}),    );
    log.i('Updated winner: $uid in round $rid');
    if (resp.statusCode != 200 && resp.statusCode != 201 && resp.statusCode != 204) throw Exception('Update winner error: ${resp.statusCode}');
  }
}

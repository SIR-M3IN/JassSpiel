import 'package:jassspiel/swaggerConnection.dart';
import 'package:jassspiel/spieler.dart';
import 'package:jassspiel/jasskarte.dart';
import 'package:jassspiel/dbConnection.dart';
import 'package:jassspiel/logger.util.dart';

class GameLogic {
  String gid;
  late SwaggerConnection swagger;
  late DbConnection dbConnection;
  final log = getLogger();

  GameLogic(this.gid) {
    swagger = SwaggerConnection(baseUrl: 'http://localhost:8080');
    dbConnection = DbConnection();
  }Future<void> initialize() async {
    await dbConnection.waitForFourPlayers(gid);
  }

  Future<List<Spieler>> loadPlayers() async {
    List<Spieler> players = await dbConnection.loadPlayers(gid);
    return players;
  }
  Future<List<Jasskarte>> shuffleandgetCards(List<Spieler> players, String uid) async {
    for (var player in players) {
      if (player.uid == uid && player.playernumber == 1) {
        log.i('Player 1 shuffling cards for game $gid');
        await swagger.shuffleCards(gid);
      }
    }
    return await swagger.getUrCards(gid, uid);
  }

  Future<void> startNewRound(String uid) async {
    log.d('Starting new round for player $uid in game $gid');
    List<Spieler> players = await loadPlayers();
    for (var player in players) {
      if (player.uid == uid && player.playernumber == 1) {
        int whichround = await swagger.getWhichRound(gid);
        log.i('Player 1 starting round $whichround for game $gid');
        await swagger.startNewRound(gid, whichround);
      }
    }
  }

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
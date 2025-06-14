import 'package:jassspiel/swaggerConnection.dart';

import 'jasskarte.dart';
import 'dbConnection.dart';
import 'spieler.dart';
class GameLogic{
  String gid;
  DbConnection dbConnection = DbConnection();
  SwaggerConnection swagger = SwaggerConnection(baseUrl: 'http://localhost:8080');
  GameLogic(this.gid);
  Future<void> initialize() async {
    await dbConnection.waitForFourPlayers(gid);  }
  Future<List<Spieler>> loadPlayers() async {
    List<Spieler> players = await dbConnection.loadPlayers(gid);
    return players;
  }
  
  Future<List<Jasskarte>> shuffleandgetCards(List<Spieler> players, String uid) async {
    for (var player in players) {
      if (player.uid == uid && player.playernumber == 1) {
          print('Shuffling cards');
          await swagger.shuffleCards(gid); 
      }
    }
    return await swagger.getUrCards(gid, uid); 
  }
  Future<void> startNewRound(String uid) async {
    List<Spieler> players = await loadPlayers();
    for (var player in players) {
      if (player.uid == uid && player.playernumber == 1) {
        int whichround = await swagger.getWhichRound(gid);
        await swagger.startNewRound(gid, whichround);
      }
    }
  }
  Map<String, dynamic> buildCardsForSaveWinnerAsMap(List<Jasskarte> karten,String winnerUid, String teammateUid,) {
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
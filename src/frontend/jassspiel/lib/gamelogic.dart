import 'jasskarte.dart';
import 'dbConnection.dart';
import 'spieler.dart';
class GameLogic{
  String gid;
  DbConnection dbConnection = DbConnection();
  GameLogic(this.gid);
  Future<void> initialize() async {
    await dbConnection.waitForFourPlayers(gid);  }
  Future<List<Spieler>> loadPlayers() async {
    List<Spieler> players = await dbConnection.loadPlayers(gid);
    return players;
  }
  Future<List<Jasskarte>> shuffleandgetCards(List<Spieler> players, String uid) async {
    print('Players Length: ${players.length}');
    for (var player in players) {
      //if (player.uid == uid && player.playernumber == 1) {
          List<Jasskarte> cards = await dbConnection.getAllCards();
          print('Shuffling cards');
          await dbConnection.shuffleCards(cards, players, gid); 
      //}
    }
    return await dbConnection.getUrCards(gid, uid);
    
  }
}
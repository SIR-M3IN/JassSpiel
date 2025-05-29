import 'jasskarte.dart';
import 'dbConnection.dart';
import 'spieler.dart';
class GameLogic{
  String gid;
  DbConnection dbConnection = DbConnection();
  GameLogic(this.gid);
  Future<void> initialize() async {
    await dbConnection.waitForFourPlayers(gid);
    await dbConnection.getAllCards();
  }
  Future<List<Spieler>> loadPlayers() async {
    return await dbConnection.loadPlayers(gid);
  }
}
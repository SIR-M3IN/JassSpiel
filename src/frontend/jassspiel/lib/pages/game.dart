import 'package:flutter/material.dart';
import 'package:jassspiel/DBConnection.dart';
import 'package:jassspiel/gamelogic.dart';
import '../spieler.dart';
import '../jasskarte.dart';

void main() {
  runApp(const CardGameApp());
}
// KI: Baue mir ein Widget welches genau 1x aufgerufen wird, wenn die App gestartet wird. Außerdem soll es den Parameter GID definieren
class InitWidget extends StatefulWidget {
  final String gid;
  final String uid;
  const InitWidget({required this.gid, required this.uid, super.key});

  @override
  _InitWidgetState createState() => _InitWidgetState();
}

class _InitWidgetState extends State<InitWidget> {
  late GameLogic gameLogic;
  bool loading = true;
  List<Spieler> players = [];

  @override
  void initState() {
    super.initState();
    gameLogic = GameLogic(widget.gid);
    _loadPlayersAndWait();
  }

  Future<void> _loadPlayersAndWait() async {
    while (mounted) {
      List<Spieler> loadedPlayers = await gameLogic.loadPlayers();

      if (!mounted) return;

      if (loadedPlayers.length == 4) {
        setState(() {
          players = loadedPlayers;
          loading = false;
        });

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameScreen(gid: widget.gid, uid: widget.uid),
          ),
        );

        break;
      } else {
        if (!mounted) return;

        setState(() {
          loading = true;
        });
      }

      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: loading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Waiting for players...', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 16),
                  Text('Party Code: ${widget.gid}', style: const TextStyle(fontSize: 18)),
                ],
              )
            : const Text('Players loaded!'),
      ),
    );
  }
}




class CardGameApp extends StatelessWidget {
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(gid: 'temp', uid: 'temp'), 
    );
  }
}

class GameScreen extends StatefulWidget {
  final String gid;
  final String uid;
  GameScreen({required this.gid, required this.uid, super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}
class _GameScreenState extends State<GameScreen> {
  DbConnection db = DbConnection();
  late GameLogic gameLogic;
  int counter = 0;
  List<Jasskarte> playedCards = [];
  late Future<List<Jasskarte>> playerCards = Future.value([]);
  

void _addPlayedCard(Jasskarte card) {
  setState(() {
    playedCards.add(card);
  });

  playerCards.then((list) {
    final updated = List<Jasskarte>.from(list)..remove(card);
    setState(() {
      playerCards = Future.value(updated); 
    });
  });
}


  

@override
void initState() {
  super.initState();
  gameLogic = GameLogic(widget.gid);
  _initializeGame();
}

void _initializeGame() async {
  DbConnection con = DbConnection();
  List<Spieler> players = await con.loadPlayers(widget.gid);
  Future<List<Jasskarte>> loadedCards = gameLogic.shuffleandgetCards(players, widget.uid);
  gameLogic.startNewRound(widget.uid);
  setState(() {playerCards = loadedCards;}); // damit das UI aktualisiert wird
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 38, 82, 7),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: playerAvatar('Player 1')),
                ),
                Positioned(
                  top: 180,
                  left: 16,
                  child: playerAvatar('Player 4'),
                ),
                Positioned(
                  top: 180,
                  right: 16,
                  child: playerAvatar('Player 3'),
                ),

                // Zentrale Spielfläche
              Center(
                child: 
                DragTarget<Jasskarte>(
                  onAcceptWithDetails: (DragTargetDetails<Jasskarte> details) async {
                    String roundId = await db.GetRoundID(widget.gid);
                    String whosturn = await db.getWhosTurn(roundId);
                    if (whosturn != widget.uid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Es ist nicht dein Zug!')),
                      );
                      return;
                    }
                    _addPlayedCard(details.data);
                    db.addPlayInRound(roundId, widget.uid, details.data.cid);
                    int urplayernumber = await db.getUrPlayernumber(widget.uid, widget.gid);
                    String nextplayer = await db.getNextUserUid(widget.gid, urplayernumber+1);
                    db.updateWhosTurn(roundId, nextplayer);
                    counter++;
                    if (counter == 4) {
                      counter = 0;
                      gameLogic.startNewRound(widget.uid);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: 330,
                      height: 130,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          if (index < playedCards.length) {
                            return PlayedCard(playedCards[index]);
                          } else {
                            return const SizedBox(width: 70, height: 100);
                          }
                        }),
                      ),
                    );
                  },
                ),

              ),

// KI: Kartenhand des Spielers geht nicht fixen bitte 
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                    child: FutureBuilder<List<Jasskarte>>(
                    future: playerCards,
                    builder: (context, snapshot) {
                      print('Snapshot state: ${snapshot.connectionState}');
                      print('Snapshot error: ${snapshot.error}');
                      print('Snapshot data: ${snapshot.data}');

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Fehler: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Keine Karten gefunden'));
                      } else {
                        return CardHand(cards: snapshot.data!);
                      }
                    },
                  ),

                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget playerAvatar(String name) {
    return Column(
      children: [
        const CircleAvatar(radius: 24, child: Icon(Icons.person)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class PlayedCard extends StatelessWidget {
  final Jasskarte card;

  const PlayedCard(this.card, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Image.asset(
        card.path,
        width: 70,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }
}


class CardHand extends StatelessWidget {
  final List<Jasskarte> cards;

  const CardHand({required this.cards, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: cards.map((card) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: 60,
                    height: 90,
                    child: CardWidget(card: card),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}


class CardWidget extends StatelessWidget {
  final Jasskarte card;

  const CardWidget({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return Draggable<Jasskarte>(
      data: card,

      // 👇 Das ist das "fliegende" Bild
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 80,
          height: 120,
          child: Image.asset(
            card.path,
            fit: BoxFit.cover,
          ),
        ),
      ),

      // 👇 Das wird an der Ursprungsposition angezeigt, während du ziehst
      childWhenDragging: const SizedBox(
        width: 80,
        height: 120,
      ),

      // 👇 Das ist das normale Bild, wenn NICHT gezogen wird
      child: SizedBox(
        width: 80,
        height: 120,
        child: Image.asset(
          card.path,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

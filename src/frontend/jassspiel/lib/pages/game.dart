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
  String currentRoundid = '';
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
// KI: Hilfe mir die Karten bei allen spielern anzuzeigen
  void _handleNewCardFromListener() async {
  final cardCid = db.neueKarte.value;
  if (cardCid != null) {
    if (playedCards.any((existingCard) => existingCard.cid == cardCid)) {
        return; 
    }
    Jasskarte newCard = await db.getCardByCid(cardCid);
    if (!mounted) return;

    setState(() {
      playedCards.add(newCard);
    });
  }

  }
  

@override
void initState() {
  super.initState();
  gameLogic = GameLogic(widget.gid);
  _initializeGame();
  db.neueKarte.addListener(_handleNewCardFromListener);

}

void _initializeGame() async {
  List<Spieler> players = await db.loadPlayers(widget.gid);
  String currentRoundid = await db.GetRoundID(widget.gid);
  if (currentRoundid.isEmpty) {
    await gameLogic.startNewRound(widget.uid);
    currentRoundid = await db.GetRoundID(widget.gid); 
  }
  db.subscribeToPlayedCards(currentRoundid);
  List<Jasskarte> cards = [];
  while (cards.length < 9) {
    cards = await gameLogic.shuffleandgetCards(players, widget.uid);
  }
  for (var card in cards) {
    if (card.symbol == 'Schella' && card.cardType == '6'){
        await gameLogic.startNewRound(widget.uid);
        String roundId = await db.GetRoundID(widget.gid);
        db.updateWhosTurn(roundId, widget.uid);
    }
  }
  setState(() {playerCards = Future.value(cards);});
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
              String roundId = '';
                int tries = 0;

                // Maximal 10 Versuche (z. B. über 5 Sekunden)
                while ((roundId.isEmpty) && tries < 10) {
                  roundId = await db.GetRoundID(widget.gid);
                  if (roundId.isNotEmpty) {
                    break;
                  }

                  await Future.delayed(const Duration(milliseconds: 50));
                  tries++;
                }
                    String whosturn = await db.getWhosTurn(roundId);
                    if (whosturn != widget.uid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Es ist nicht dein Zug!')),
                      );
                      return;
                    }
                    _addPlayedCard(details.data);
                    int urplayernumber = await db.getUrPlayernumber(widget.uid, widget.gid);
                    if (urplayernumber == 4) {
                      urplayernumber = 0;
                    }
                    String nextplayer = await db.getNextUserUid(widget.gid, urplayernumber+1);
                    db.updateWhosTurn(roundId, nextplayer);
                    db.addPlayInRound(roundId, widget.uid, details.data.cid);
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


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
  while (true) {
    List<Spieler> loadedPlayers = await gameLogic.loadPlayers();
    print(loadedPlayers.length);

    if (loadedPlayers.length == 4) {
      if (!mounted) return;

      setState(() {
        players = loadedPlayers;
        loading = false;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameScreen(gid: widget.gid, uid: widget.uid),
        ),
      );

      break;
    } else {
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
            ? const Text('Waiting for players...', style: TextStyle(fontSize: 24))
            : Text('Players loaded!'),
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
  late List<String> playedCards = [];
  GameScreen({required this.gid, required this.uid, super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}
class _GameScreenState extends State<GameScreen> {
  DbConnection db = DbConnection();
  late List<String> playedCards = [];
  late Future<List<Jasskarte>> playerCards = Future.value([]);

  final laubCards = [ 
    'Laub_6.png',
    'Laub_7.png',
    'Laub_8.png',
    'Laub_9.png',
    'Laub_10.png',
    'Laub_Ass.png',
    'Laub_König.png',
    'Laub_Ober.png',
    'Laub_Unter.png',
  ];
  

  void _addPlayedCard(String card) async {
    setState(() {
      playedCards.add(card);
      
    });
    
  }
  

@override
void initState() {
  super.initState();
  _initializeGame();
}

void _initializeGame() async {
  GameLogic log = GameLogic(widget.gid);
  DbConnection con = DbConnection();

  List<Spieler> players = await con.loadPlayers(widget.gid);

  playerCards = log.shuffleandgetCards(players, widget.uid);


  setState(() {}); // damit das UI aktualisiert wird
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
                child: DragTarget<String>(
                onAcceptWithDetails: (DragTargetDetails<String> details) {
                  _addPlayedCard(details.data);
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
                        List<String> cardNames = snapshot.data!.map((k) => k.path).toList();

                        return CardHand(cards: cardNames);
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
  final String image;

  const PlayedCard(this.image, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Image.asset(
        image,
        width: 70,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }
}

class CardHand extends StatelessWidget {
  final List<String> cards;

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
                    child: CardWidget(assetName: card),
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
  final String assetName;

  const CardWidget({required this.assetName, super.key});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: assetName,
      feedback: Material(
        color: Colors.transparent,
        child: Image.asset(
          assetName,
          width: 80,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Image.asset(
          assetName,
          width: 80,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
      child: Image.asset(
        assetName,
        width: 80,
        height: 120,
        fit: BoxFit.cover,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:jassspiel/dbConnection.dart';
import 'package:jassspiel/gamelogic.dart';
import '../spieler.dart';
import '../jasskarte.dart';
import 'package:jassspiel/pages/showTrumpfDialogPage.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple,
              Colors.indigo,
              Colors.blue,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: loading
                ? Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '⏳ Waiting for players...',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Party Code: ${widget.gid}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text(
                    '🎉 Players loaded!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
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
  const GameScreen({required this.gid, required this.uid, super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}
class _GameScreenState extends State<GameScreen> {
  DbConnection db = DbConnection();
  late GameLogic gameLogic;
  int counter = 0;
  String currentRoundid = '';
  List<Jasskarte> playedCards = [];
  List<Spieler> players = []; 
  int myPlayerNumber = 1; 
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

Future<bool> _isCardAllowed(Jasskarte card, String roundId) async {
  String? firstCardCid = await db.getFirstCardInRound(roundId);
  
  if (firstCardCid == null) {
    return true;
  }
  
  Jasskarte? firstCard = await db.getFirstCardInRoundAsCard(roundId);
  if (firstCard == null) {
    return true; 
  }
  
  bool isCardTrumpf = await db.isTrumpf(card.cid, widget.gid);
  if (isCardTrumpf) {
    return true;
  }
  
  List<Jasskarte> myCards = await db.getUrCards(widget.gid, widget.uid);
  
  bool hasSameSuit = myCards.any((k) => k.symbol == firstCard.symbol);
  
  if (hasSameSuit) {
    return card.symbol == firstCard.symbol;
  }
  return true;
}

void _updateCardStates() {
  setState(() {
  });
}

// KI: Hilf mir die Karten bei allen Spielern anzuzeigen
void _handleNewCardFromListener() async {
  print("New card received");
  final cardCid = db.newCard.value;
  if (cardCid != null) {

    if (playedCards.any((existingCard) => existingCard.cid == cardCid)) {
        return; 
    }
    Jasskarte newCard = await db.getCardByCid(cardCid);
    if (!mounted) return;

    setState(() {
      playedCards.add(newCard);
    });
    
    _updateCardStates();
      if (playedCards.length == 4) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      String currentRoundId = await db.GetRoundID(widget.gid);
      db.clearFirstCardForRound(currentRoundId);
      
      setState(() {
        playedCards = [];
      });
      _updateCardStates();
    }
  }

  }
  

@override
void initState() {
  super.initState();
  gameLogic = GameLogic(widget.gid);
  _initializeGame();
  db.newCard.addListener(_handleNewCardFromListener);

}

void _initializeGame() async {
  List<Spieler> loadedPlayers = await db.loadPlayers(widget.gid);
  
  int ownPlayerNumber = await db.getUrPlayernumber(widget.uid, widget.gid);
  
  setState(() {
    players = loadedPlayers; 
    myPlayerNumber = ownPlayerNumber;
  });
  
  String currentRoundid = await db.GetRoundID(widget.gid);
  if (currentRoundid.isEmpty) {
    await gameLogic.startNewRound(widget.uid);
    print('gid: ${widget.gid}');
    while (currentRoundid.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    currentRoundid = await db.GetRoundID(widget.gid);
    }
     
    print('currentRoundid: $currentRoundid');
  }
  db.subscribeToPlayedCards(currentRoundid);  List<Jasskarte> cards = [];
  while (cards.length < 9) {
    cards = await gameLogic.shuffleandgetCards(players, widget.uid);
  }for (var card in cards) {
    if (card.symbol == 'Schella' && card.cardType == '6') {
      await gameLogic.startNewRound(widget.uid);
      
      String roundId = await db.GetRoundID(widget.gid);
      db.updateWhosTurn(roundId, widget.uid);      String? selectedTrumpf = await showTrumpfDialog(context, playerCards: cards);
      if (selectedTrumpf != null) {
        await db.updateTrumpf(widget.gid, selectedTrumpf);
      }
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
              children: [                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: playerAvatar(getPlayerNameByRelativePosition('top'))),
                ),
                Positioned(
                  top: 180,
                  left: 16,
                  child: playerAvatar(getPlayerNameByRelativePosition('left')),
                ),
                Positioned(
                  top: 180,
                  right: 16,
                  child: playerAvatar(getPlayerNameByRelativePosition('right')),
                ),

              Center(
                child:                DragTarget<Jasskarte>(
                  onAcceptWithDetails: (DragTargetDetails<Jasskarte> details) async {
                  String roundId = '';
                  roundId = await db.GetRoundID(widget.gid);
                    String whosturn = await db.getWhosTurn(roundId);
                    if (whosturn != widget.uid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Es ist nicht dein Zug!')),
                      );
                      return;
                    }
                      // Suit constraint rule check
                    bool isAllowed = await _isCardAllowed(details.data, roundId);
                    if (!isAllowed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Suit constraint! You must play the same suit!'),
                          backgroundColor: Colors.red,
                        ),
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
                    _updateCardStates();
                      counter++;
                    if (playedCards.length == 4) {
                      String currentRoundId = await db.GetRoundID(widget.gid);
                      db.clearFirstCardForRound(currentRoundId);
                      
                      gameLogic.startNewRound(widget.uid);
                      String winner = await db.getWinningCard(playedCards, widget.gid);
                      db.updateWinnerDB(winner, roundId);
                      playedCards = [];
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
                ),                ),

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
                        return const Center(child: Text('Lade Karten...'));
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
  // Helper: get name by relative position around table
  String getPlayerNameByRelativePosition(String position) {
    int target;
    switch (position) {
      case 'right':
        target = myPlayerNumber % 4 + 1;
        break;
      case 'top':
        target = (myPlayerNumber + 2) % 4;
        if (target == 0) target = 4;
        break;
      case 'left':
        target = myPlayerNumber - 1;
        if (target < 1) target += 4;
        break;
      default:
        return '';
    }

  for (var player in players) {
    if (player.playernumber == target) {
      return player.username;
    }
  }
  return 'Player $target';
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
      feedback: Transform.scale(
        scale: 1.2,
        child: Image.asset(
          card.path,
          width: 60,
          height: 90,
          fit: BoxFit.cover,
        ),
      ),
      childWhenDragging: Container(
        width: 60,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            card.path,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}


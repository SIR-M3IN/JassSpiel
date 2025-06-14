import 'package:flutter/material.dart';
import 'package:jassspiel/dbConnection.dart';
import 'package:jassspiel/gamelogic.dart';
import 'package:jassspiel/swaggerConnection.dart';
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
  SwaggerConnection swagger = SwaggerConnection(baseUrl: 'http://localhost:8080'); // Initialize swagger
  late GameLogic gameLogic;
  int counter = 0;
  String currentRoundid = '';
  List<Jasskarte> playedCards = [];
  List<Spieler> players = []; 
  int myPlayerNumber = 1; 
  late Future<List<Jasskarte>> playerCards = Future.value([]);
  int _scoreRefreshCounter = 0;

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
  String? firstCardCid = await swagger.getFirstCardCid(roundId); 
  
  if (firstCardCid == null || firstCardCid.isEmpty) { // also check for empty string
    return true;
  }
  
  Jasskarte? firstCard = await swagger.getCardByCid(firstCardCid);

  if (firstCard == null) {
    return true; 
  }
  
  bool isCardTrumpf = await db.isTrumpf(card.cid, widget.gid);
  if (isCardTrumpf) {
    return true;
  }
  
  List<Jasskarte> myCards = await swagger.getUrCards(widget.gid, widget.uid); 
  
  // Add null check for firstCard before accessing its symbol
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
  final cardCid = db.newCard.value; // Remains db (realtime listener)
  if (cardCid != null) {
    if (playedCards.any((existingCard) => existingCard.cid == cardCid)) {
      if (playedCards.length == 4) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        playedCards = [];
      });
    }
        return; 
    }
    // Use swagger to get card details
    Jasskarte newCard = await swagger.getCardByCid(cardCid); 
    if (!mounted) return;

    setState(() {
      playedCards.add(newCard);
    });
    
    _updateCardStates();
      if (playedCards.length == 4) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      // Use swagger to get current round ID
      String currentRoundId = await swagger.getCurrentRoundId(widget.gid); 
      db.clearFirstCardForRound(currentRoundId); // Remains db (local cache)
      
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
  gameLogic = GameLogic(widget.gid); // GameLogic might also need refactoring if it uses db directly
  _initializeGame();
  db.newCard.addListener(_handleNewCardFromListener); // Remains db (realtime listener)

}

void _initializeGame() async {
  // Use swagger to load players
  List<Spieler> loadedPlayers = await swagger.loadPlayers(widget.gid); 
  
  // Use swagger to get own player number
  int ownPlayerNumber = await swagger.getUrPlayernumber(widget.uid, widget.gid); 
  
  setState(() {
    players = loadedPlayers; 
    myPlayerNumber = ownPlayerNumber;
  });
  
  // Use swagger to get current round ID
  String currentRoundIdValue = await swagger.getCurrentRoundId(widget.gid); 
  setState(() {
    currentRoundid = currentRoundIdValue;
  });

  if (currentRoundid.isEmpty) {
    // gameLogic.startNewRound might call swagger.startNewRound or db.startNewRound
    // Assuming gameLogic.startNewRound is already using swagger or is intended to be refactored separately.
    print("HERE");
    await gameLogic.startNewRound(widget.uid); 
    print('gid: ${widget.gid}');
    while (currentRoundid.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      currentRoundIdValue = await swagger.getCurrentRoundId(widget.gid); 
      setState(() {
        currentRoundid = currentRoundIdValue;
      });
    }
     
    print('currentRoundid: $currentRoundid');
  }
  db.subscribeToPlayedCards(currentRoundid); // Remains db (realtime listener)
  List<Jasskarte> cards = [];
  // gameLogic.shuffleandgetCards might use swagger or db.
  // Assuming it's either using swagger or will be refactored.
  while (cards.length < 9) {
    cards = await gameLogic.shuffleandgetCards(players, widget.uid);
  }
  for (var card in cards) {
    if (card.symbol == 'Schella' && card.cardType == '6') {      
      // Use swagger to get current round ID
      String roundId = await swagger.getCurrentRoundId(widget.gid); 
      // Use swagger to update whose turn it is
      await swagger.updateWhosTurn(roundId, widget.uid); 
      String? selectedTrumpf = await showTrumpfDialog(context, playerCards: cards);
      if (selectedTrumpf != null) {
        // Use swagger to update trumpf
        await swagger.updateTrumpf(widget.gid, selectedTrumpf); 
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
                  child: Center(child: playerAvatar(getPlayerNameByRelativePosition('top'), uid: getPlayerUidByRelativePosition('top'))),
                ),
                Positioned(
                  top: 180,
                  left: 16,
                  child: playerAvatar(getPlayerNameByRelativePosition('left'), uid: getPlayerUidByRelativePosition('left')),
                ),
                Positioned(
                  top: 180,
                  right: 16,
                  child: playerAvatar(getPlayerNameByRelativePosition('right'), uid: getPlayerUidByRelativePosition('right')),
                ),

              Center(
                child:                DragTarget<Jasskarte>(
                  onAcceptWithDetails: (DragTargetDetails<Jasskarte> details) async {
                  String roundId = '';
                  // Use swagger to get current round ID
                  roundId = await swagger.getCurrentRoundId(widget.gid); 
                  // Use swagger to get whose turn it is
                  String whosturn = await swagger.getWhosTurn(roundId); 
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
                          content: Text('Karte nicht erlaubt!'), // Added message
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                      _addPlayedCard(details.data);
                    int urplayernumber = await swagger.getUrPlayernumber(widget.uid, widget.gid); 
                    if (urplayernumber == 4) {
                      urplayernumber = 0;
                    }
                    String nextplayer = await swagger.getNextPlayerUid(widget.gid, urplayernumber+1); 
                    // Use swagger to update whose turn it is
                    await swagger.updateWhosTurn(roundId, nextplayer); 
                    await swagger.addPlayInRound(roundId, widget.uid, details.data.cid);
                    _updateCardStates();
                      counter++;
                    if (playedCards.length == 4) {
                      String currentRoundIdFromSwagger = await swagger.getCurrentRoundId(widget.gid); 
                      db.clearFirstCardForRound(currentRoundIdFromSwagger);
                      String winner = await swagger.determineWinningCard(widget.gid, playedCards);
                      var winnernumber = await swagger.getUrPlayernumber(winner, widget.gid); 
                      int teammatePlayerNumber;
                      if (winnernumber == 1) { teammatePlayerNumber = 3;}
                      else if (winnernumber == 2){ teammatePlayerNumber = 4;}
                      else if (winnernumber == 3) {teammatePlayerNumber = 1;}
                      else {teammatePlayerNumber = 2;}

                      String teammateuid = await swagger.getNextPlayerUid(widget.gid, teammatePlayerNumber); 
                      print("Here does the error happen?");
                      await swagger.savePointsForUsers(widget.gid, gameLogic.buildCardsForSaveWinnerAsMap(playedCards, winner, teammateuid,));
                      print("Here does the error happen?");
                      setState(() {
                        _scoreRefreshCounter++;
                      });
                      print("Error here");
                      await gameLogic.startNewRound(widget.uid); 
                            
                      roundId = await swagger.getCurrentRoundId(widget.gid);
                      print("NVM");
                      await swagger.updateWinner(roundId, winner);
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
  }  Widget playerAvatar(String name, {String? uid}) {
    return Column(
      children: [
        const CircleAvatar(radius: 24, child: Icon(Icons.person)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: Colors.white)),
        if (uid != null)
          FutureBuilder<int>(
            key: ValueKey('score_${uid}_$_scoreRefreshCounter'),
            future: db.getPlayerScore(uid, widget.gid), // Remains db, no swagger equivalent
            builder: (context, snapshot) {
              final score = snapshot.data ?? 0;
              return Text(
                'Punkte: $score',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              );
            },
          ),
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

  String? getPlayerUidByRelativePosition(String position) {
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
        return null;
    }

    for (var player in players) {
      if (player.playernumber == target) {
        return player.uid;
      }
    }
    return null;
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


import 'package:flutter/material.dart';
import 'package:jassspiel/dbConnection.dart';
import 'package:jassspiel/gamelogic.dart';
import 'package:jassspiel/logger.util.dart';
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
  final log = getLogger();

  @override
  void initState() {
    super.initState();
    log.i('Initializing game with GID: ${widget.gid}, UID: ${widget.uid}');
    gameLogic = GameLogic(widget.gid);
    _loadPlayersAndWait();
  }

  Future<void> _loadPlayersAndWait() async {
    log.d('Starting to load players and waiting for 4 players');
    while (mounted) {
      List<Spieler> loadedPlayers = await gameLogic.loadPlayers();

      if (!mounted) return;

      if (loadedPlayers.length == 4) {
        log.i('All 4 players loaded, transitioning to game');
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
  //SwaggerConnection swagger = SwaggerConnection(baseUrl: 'http://localhost:8080'); // Initialize swagger
  late GameLogic gameLogic;
  final log = getLogger();
  int counter = 0;
  Jasskarte? firstCard; // First card played in the round
  String currentRoundid = '';
  List<Jasskarte> playedCards = [];  List<Spieler> players = []; 
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

Future<bool> _isCardAllowed(Jasskarte card) async {
  log.d("Checking if card is allowed (local only): ${card.cid}");
  if (firstCard == null) {
    return true;
  }
  // Always allow trumpf
  bool isTrumpf = await db.isTrumpf(card.cid, widget.gid);
  if (isTrumpf) return true;

  // Check if hand has any non-trumpf card matching the first card's suit
  final hand = await playerCards;
  bool hasSameSuit = false;
  for (var k in hand) {
    print("Checking card: ${k.cid} with symbol ${k.symbol}");
    if (k.symbol == firstCard!.symbol) {
      
      final isKTrumpf = await db.isTrumpf(k.cid, widget.gid);
      if (!isKTrumpf) {
        hasSameSuit = true;
        break;
      }
    }
  }
  if (hasSameSuit) {
    return card.symbol == firstCard!.symbol;
  }
  return true;
}



void _updateCardStates() {
  setState(() {
  });
}

// KI: Hilf mir die Karten bei allen Spielern anzuzeigen
void _handleNewCardFromListener() async {
  log.d("New card received from listener");
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
    Jasskarte newCard = await db.getCardByCid(cardCid); 
    if (!mounted) return;

    setState(() {
      playedCards.add(newCard);
      firstCard ??= newCard; 

    });
      _updateCardStates();
      if (playedCards.length == 4) {
      //String winner = await swagger.determineWinningCard(widget.gid, playedCards);
      String winner = await db.getWinningCard(playedCards, widget.gid, firstCard!);
      _showTrickWinnerPopup(winner);
      
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      setState(() {
        playedCards = [];
        firstCard = null;
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
  //List<Spieler> loadedPlayers = await swagger.loadPlayers(widget.gid); 
  //int ownPlayerNumber = await swagger.getUrPlayernumber(widget.uid, widget.gid); 
  List<Spieler> loadedPlayers = await gameLogic.loadPlayers();
  int ownPlayerNumber = loadedPlayers.firstWhere((p) => p.uid == widget.uid).playernumber;
  
  setState(() {
    players = loadedPlayers; 
    myPlayerNumber = ownPlayerNumber;
  });
    //String currentRoundIdValue = await swagger.getCurrentRoundId(widget.gid); 
    String currentRoundIdValue = await db.GetRoundID(widget.gid);
    setState(() {
    currentRoundid = currentRoundIdValue;
  });

  if (currentRoundid.isEmpty) {
    log.i("Starting new round for user ${widget.uid}");
    await gameLogic.startNewRound(widget.uid); 
    log.d('Game GID: ${widget.gid}');
    while (currentRoundid.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;      
      //currentRoundIdValue = await swagger.getCurrentRoundId(widget.gid); 
      currentRoundIdValue = await db.GetRoundID(widget.gid);
      setState(() {
        currentRoundid = currentRoundIdValue;
      });
    }
     
    log.d('Current round ID: $currentRoundid');
  }
  db.subscribeToPlayedCards(currentRoundid);
  List<Jasskarte> cards = [];

  while (cards.length < 9) {
    cards = await gameLogic.shuffleandgetCards(players, widget.uid);
  }
  for (var card in cards) {
    if (card.symbol == 'Schella' && card.cardType == '6') {      
      //String roundId = await swagger.getCurrentRoundId(widget.gid); 
      //await swagger.updateWhosTurn(roundId, widget.uid); 
      String roundId = await db.GetRoundID(widget.gid);
      db.updateWhosTurn(roundId, widget.uid);
      String? selectedTrumpf = await showTrumpfDialog(context, playerCards: cards);
      if (selectedTrumpf != null) {
        //await swagger.updateTrumpf(widget.gid, selectedTrumpf); 
        db.updateTrumpf(widget.gid, selectedTrumpf);
      }
    }
  }
  setState(() {playerCards = Future.value(cards);});
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
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9, // Maintain aspect ratio for the game table
            child: Container(
              padding: const EdgeInsets.all(16.0), // Add some padding
              decoration: BoxDecoration(
                color: Colors.green.shade800, // A richer green for the table
                borderRadius: BorderRadius.circular(20), // More rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              ),
              child: Stack(
                children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: FutureBuilder<String>(
                    future: _getCurrentTurnPlayer(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        String playerName = _getPlayerNameByUid(snapshot.data!);
                        bool isMyTurn = snapshot.data! == widget.uid;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMyTurn ? Colors.orange : Colors.blue.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            isMyTurn ? 'Du bist am Zug' : 'Am Zug: $playerName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                Positioned(
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
                  //roundId = await swagger.getCurrentRoundId(widget.gid); 
                  roundId = await db.GetRoundID(widget.gid);
                  //String whosturn = await swagger.getWhosTurn(roundId);
                  String whosturn = await db.getWhosTurn(roundId);
                  log.d('Card play attempt: ${details.data.cid} by player ${widget.uid}');
                    if (whosturn != widget.uid) {
                      log.w('Player ${widget.uid} attempted to play out of turn (turn: $whosturn)');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Es ist nicht dein Zug!')),
                      );
                      return;
                    }
                    bool isAllowed = await _isCardAllowed(details.data);
                    if (!isAllowed) {
                      log.w('Player ${widget.uid} attempted to play invalid card: ${details.data.cid}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Karte nicht erlaubt!'), // Added message
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                      log.i('Valid card played: ${details.data.cid} by player ${widget.uid}');
                      _addPlayedCard(details.data);
                    //int urplayernumber = await swagger.getUrPlayernumber(widget.uid, widget.gid); 
                    int urplayernumber = await db.getUrPlayernumber(widget.uid, widget.gid);
                    if (urplayernumber == 4) {
                      urplayernumber = 0;
                    }
                    //String nextplayer = await swagger.getNextPlayerUid(widget.gid, urplayernumber+1); 
                    String nextplayer = await db.getNextUserUid(widget.gid, urplayernumber+1);
                    log.d('Updating turn to next player: $nextplayer');
                    //await swagger.updateWhosTurn(roundId, nextplayer); 
                    db.updateWhosTurn(roundId, nextplayer);
                    //await swagger.addPlayInRound(roundId, widget.uid, details.data.cid);
                    db.addPlayInRound(roundId, widget.uid, details.data.cid);
                      log.d('Played cards: ${playedCards.map((c) => c.cid).join(', ')}');
                      counter++;                    if (playedCards.length == 4) {
                      log.i('Round complete with 4 cards, determining winner');
                      //String winner = await swagger.determineWinningCard(widget.gid, playedCards);
                      String winner = await db.getWinningCard(playedCards, widget.gid, firstCard!);
                      log.i('Round winner determined: $winner');
                      
                      _showTrickWinnerPopup(winner);
                      
                      await Future.delayed(const Duration(seconds: 3));
                      
                      if (mounted) {
                        Navigator.of(context).pop();
                      }                      
                      log.d("Updating round winner: $winner");
                      //await swagger.updateWinner(roundId, winner);
                      db.updateWinnerDB(roundId, winner);

                      log.i("Round completed, starting new round");

                      await gameLogic.startNewRound(widget.uid);
                      // Warte kurz, bis die neue Runde auch wirklich gestartet wurde
                      // String prevRoundId = roundId;
                      // String newRoundId;
                      // do {
                      //   await Future.delayed(const Duration(milliseconds: 500));
                      //   newRoundId = await swagger.getCurrentRoundId(widget.gid);  
                      //   } while (newRoundId == prevRoundId || newRoundId.isEmpty);
                      // roundId = newRoundId;
                      //roundId = await swagger.getCurrentRoundId(widget.gid);
                      roundId = await db.GetRoundID(widget.gid);
                      log.d("New round started, updating turn to winner: $winner");
                      //await swagger.updateWhosTurn(roundId, winner);
                      db.updateWhosTurn(roundId, winner);
                      playedCards = [];
                      firstCard = null;
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: 330,
                      height: 130,
                      padding: const EdgeInsets.all(8), // Added padding
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4), // Darker, more distinct area
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0,2),
                          )
                        ]
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
      ),
    );
  }

  Widget playerAvatar(String name, {String? uid}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28, // Slightly larger avatar
          backgroundColor: Colors.white.withOpacity(0.2),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.deepPurple.shade300,
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
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

  // Neue Methoden für die Am-Zug-Anzeige
  Future<String> _getCurrentTurnPlayer() async {
    if (currentRoundid.isEmpty) return '';
    try {
      //return await swagger.getWhosTurn(currentRoundid);
      return await db.getWhosTurn(currentRoundid);
    } catch (e) {
      return '';
    }
  }

  String _getPlayerNameByUid(String uid) {
    for (var player in players) {
      if (player.uid == uid) {
        return player.username;
      }
    }
    return 'Spieler';
  }

  // Zeigt ein Popup mit dem Stichgewinner
  Future<void> _showTrickWinnerPopup(String winnerUid) async {
    String winnerName = _getPlayerNameByUid(winnerUid);
    bool isMyWin = winnerUid == widget.uid;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isMyWin 
                  ? [Colors.green.shade600, Colors.green.shade800]
                  : [Colors.blue.shade600, Colors.blue.shade800],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMyWin ? Icons.emoji_events : Icons.star,
                  size: 60,
                  color: Colors.yellow.shade300,
                ),
                const SizedBox(height: 15),
                Text(
                  'Stich gewonnen!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isMyWin ? 'Du hast den Stich gewonnen!' : '$winnerName hat den Stich gewonnen!',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Nächste Runde startet...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    return Container( // Wrap with a container for potential styling
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 130, // Keep height consistent
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16), // Adjusted padding
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: cards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4), // Reduced horizontal padding
                    child: SizedBox(
                      width: 70, // Slightly larger cards in hand
                      height: 100,
                      child: CardWidget(card: card),
                    ),
                  );
                }).toList(),
              ),
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
        scale: 1.25, // Slightly larger feedback
        child: Material( // Added Material for elevation and shadow
          elevation: 8.0,
          shadowColor: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            card.path,
            width: 60,
            height: 90,
            fit: BoxFit.cover,
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 70, // Match new card size
        height: 100, // Match new card size
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Consistent rounding
          color: Colors.blueGrey.withOpacity(0.5),
          border: Border.all(color: Colors.white.withOpacity(0.3))
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Consistent rounding
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7), // Stronger shadow for cards
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8), // Consistent rounding
          child: Image.asset(
            card.path,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}


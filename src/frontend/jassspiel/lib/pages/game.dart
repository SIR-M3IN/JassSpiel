import 'package:flutter/material.dart';
import 'package:jassspiel/dbConnection.dart';
import 'package:jassspiel/gamelogic.dart';
import 'package:jassspiel/logger.util.dart';
import 'package:jassspiel/swaggerConnection.dart';
import '../spieler.dart';
import '../jasskarte.dart';
import 'package:jassspiel/pages/showTrumpfDialogPage.dart';
import 'dart:async';

/// Haupteinstiegspunkt der Jass-Kartenspiel-Anwendung.
///
/// Startet die Flutter-App mit [CardGameApp] als Root-Widget.
//KI: Update UI
void main() {
  runApp(const CardGameApp());
}
/// Widget, das das Spiel initialisiert und wartet, bis alle Spieler beigetreten sind.
///
/// Dieses Widget zeigt einen Ladebildschirm an, während es auf genau 4 Spieler
/// wartet, die dem Spiel beitreten. Sobald alle Spieler beigetreten sind, navigiert es automatisch
/// zum [GameScreen].
// KI: Baue mir ein Widget welches genau 1x aufgerufen wird, wenn die App gestartet wird. Außerdem soll es den Parameter GID definieren
class InitWidget extends StatefulWidget {  /// Die eindeutige Spiel-ID.
  final String gid;
  
  /// Die eindeutige Benutzer-ID.
  final String uid;
  
  /// Erstellt ein [InitWidget].
  ///
  /// Sowohl [gid] als auch [uid] sind erforderliche Parameter.
  const InitWidget({required this.gid, required this.uid, super.key});

  @override
  _InitWidgetState createState() => _InitWidgetState();
}

/// Zustandsklasse für [InitWidget].
class _InitWidgetState extends State<InitWidget> {  /// Spiellogik-Handler für die Verwaltung von Spieloperationen.
  late GameLogic gameLogic;
  
  /// Flag, das anzeigt, ob das Widget derzeit Spieler lädt.
  bool loading = true;
  
  /// Liste der Spieler, die sich derzeit im Spiel befinden.
  List<Spieler> players = [];
  
  /// Logger instance for debugging and monitoring.
  final log = getLogger();
  @override
  void initState() {
    super.initState();
    log.i('Initializing game with GID: ${widget.gid}, UID: ${widget.uid}');
    gameLogic = GameLogic(widget.gid);
    _loadPlayersAndWait();
  }
  /// Fragt kontinuierlich nach Spielern ab, bis genau 4 Spieler beigetreten sind.
  ///
  /// Diese Methode läuft in einer Schleife und überprüft alle 2 Sekunden nach neuen Spielern.
  /// Sobald 4 Spieler gefunden wurden, navigiert sie zum [GameScreen].
  /// Die Methode respektiert den mounted-Zustand des Widgets, um Speicherlecks zu verhindern.
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




/// Root-Anwendungs-Widget für das Jass-Kartenspiel.
///
/// Dieses Widget richtet die Haupt-MaterialApp ein und definiert die anfängliche Route
/// zum Spielbildschirm mit temporären IDs.
class CardGameApp extends StatelessWidget {
  /// Erstellt eine [CardGameApp].
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(gid: 'temp', uid: 'temp'), 
    );
  }
}

/// Haupt-Spielbildschirm-Widget, das den Kartentisch und die Spieloberfläche anzeigt.
///
/// Dieses Widget verwaltet den Spielzustand, zeigt Spieler und Karten an und behandelt
/// alle Spielinteraktionen einschließlich Kartenspielen, Zugverwaltung und Punktevergabe.
class GameScreen extends StatefulWidget {  /// Die eindeutige Spiel-ID.
  final String gid;
  
  /// Die eindeutige ID des aktuellen Benutzers.
  final String uid;
  
  /// Erstellt einen [GameScreen].
  ///
  /// Sowohl [gid] als auch [uid] sind erforderliche Parameter.
  const GameScreen({required this.gid, required this.uid, super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}
/// Zustandsklasse für [GameScreen], die alle Spiellogik und UI-Zustände verwaltet.
class _GameScreenState extends State<GameScreen> {  /// Datenbankverbindung für Echtzeit-Updates und Datenpersistierung.
  DbConnection db = DbConnection();
  
  /// Zähler für Backup-/Fallback-Operationen.
  int backupCounter = 0; 
  
  /// API-Verbindung für Serverkommunikation.
  SwaggerConnection swagger = SwaggerConnection(baseUrl: 'http://localhost:8080'); // Initialize swagger
  
  /// Spiellogik-Handler für zentrale Spieloperationen.
  late GameLogic gameLogic;
  
  /// Logger-Instanz für Debugging und Fehlerverfolgung.
  final log = getLogger();
  
  /// Allzweck-Zähler für verschiedene Operationen.
  int counter = 0;
  
  /// Die erste Karte, die in der aktuellen Runde gespielt wurde, wird für die Farbenvalidierung verwendet.
  Jasskarte? firstCard; // First card played in the round
  
  /// Aktuelle Runden-ID aus der Datenbank.
  String currentRoundid = '';
  
  /// Liste der im aktuellen Stich gespielten Karten (max. 4 Karten).
  List<Jasskarte> playedCards = [];
  
  /// Liste aller Spieler im Spiel.
  List<Spieler> players = []; 
  
  /// Die Spielernummer des aktuellen Benutzers (1-4).
  int myPlayerNumber = 1; 
    /// Future, das die Hand des aktuellen Spielers mit Karten enthält.
  late Future<List<Jasskarte>> playerCards = Future.value([]);
  
  /// Zähler zum Auslösen von Punktestand-Aktualisierungen in der UI.
  int _scoreRefreshCounter = 0;
  
  /// Timer für die periodische Überprüfung, wer am Zug ist.
  late Timer _turnTimer;
  
  /// Timer für das Abfragen des Trumpf-Symbols vom Server.
  late Timer _trumpfPollTimer;
  
  /// Das aktuelle Trumpf-Symbol für die Runde.
  String? _trumpfSymbol;

  /// UID des Spielers, der derzeit am Zug ist.
  String _currentTurnUid = '';

/// Startet alle 3 Sekunden eine Abfrage, um das Trumpf-Symbol vom Server zu holen.
///
/// Die Abfrage stoppt automatisch, sobald das Trumpf-Symbol erfolgreich abgerufen wurde.
/// Dies wird verwendet, um kontinuierlich nach der Trumpf-Auswahl während der Spieleinrichtung zu suchen.
void _startTrumpfPolling() {
  _trumpfPollTimer = Timer.periodic(
    const Duration(seconds: 3),
    (_) async {
      if (_trumpfSymbol != null) {
        _trumpfPollTimer.cancel();
        return;
      }
      final symbol = await db.getTrumpfSymbol(widget.gid);
      if (symbol != null) {
        setState(() {
          _trumpfSymbol = symbol;
        });
        _trumpfPollTimer.cancel();
      }
    },
  );
}

/// Fügt eine gespielte Karte zum Spielzustand hinzu und entfernt sie aus der Hand des Spielers.
///
/// Diese Methode aktualisiert sowohl die [playedCards]-Liste als auch das [playerCards]-Future,
/// um zu reflektieren, dass die Karte gespielt wurde.
///
/// [card] Die Karte, die vom aktuellen Spieler gespielt wurde.
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

/// Validiert, ob eine Karte gemäß den Jass-Regeln legal gespielt werden kann.
///
/// Gibt `true` zurück, wenn die Karte gespielt werden kann, andernfalls `false`.
/// Die Validierungsregeln sind:
/// - Die erste Karte eines Stichs kann immer gespielt werden
/// - Trumpf-Karten können immer gespielt werden
/// - Muss der Farbe folgen, wenn möglich (hat Karten derselben Farbe wie die erste Karte)
/// - Kann jede Karte spielen, wenn keine Karten der geforderten Farbe verfügbar sind
///
/// [card] Die zu validierende Karte zum Spielen.
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
        hasSameSuit = true;
        break;
    }
  }
  if (hasSameSuit) {
    return card.symbol == firstCard!.symbol;
  }
  return true;
}



/// Löst eine Zustandsaktualisierung aus, um kartenbezogene UI-Elemente zu aktualisieren.
///
/// Diese Methode wird nach Kartenstatusänderungen aufgerufen, um sicherzustellen, dass die UI
/// den aktuellen Spielzustand widerspiegelt.
void _updateCardStates() {
  setState(() {
  });
}

/// Handles new card events from the database listener.
///
/// This method is called whenever a new card is played by any player.
/// It adds the card to the played cards list and determines the winner
/// when all 4 cards have been played.
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
        backupCounter = 0;
        firstCard = null;
      });
    }
        return; 
    }
    //Jasskarte newCard = await db.getCardByCid(cardCid); 
    Jasskarte newCard = await swagger.getCardByCid(cardCid); 
    if (!mounted) return;

    setState(() {
      playedCards.add(newCard);
      firstCard ??= newCard; 

    });
      _updateCardStates();
      if (playedCards.length == 4) {
      // String winner = await swagger.determineWinningCard(widget.gid, playedCards);
      // QUICK FIX: Use local DB function instead of failing API
      String winner = await db.getWinningCard(playedCards, widget.gid, firstCard!);
      //String winner = await db.getWinningCard(playedCards, widget.gid, firstCard!);
      _showTrickWinnerPopup(winner);
      
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      setState(() {
        playedCards = [];
        backupCounter = 0;
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
  _initializeGame().then((_) => _startTrumpfPolling());
  db.newCard.addListener(_handleNewCardFromListener); 
  // Setup periodic turn update
  _turnTimer = Timer.periodic(
    const Duration(seconds: 1),
    (_) async {
      if (currentRoundid.isEmpty) return;
      //final turn = await db.getWhosTurn(currentRoundid);
      final turn = await swagger.getWhosTurn(currentRoundid);
      if (turn != _currentTurnUid) {
        backupCounter++;
        // if (backupCounter != playedCards.length) {
        //   //playedCards = await db.getPlayedCards(currentRoundid);
        //   playedCards = await swagger.getPlayedCards(currentRoundid);
        // }
        setState(() {
          _currentTurnUid = turn;
        });
      }
    },
  );
}

@override
void dispose() {
  _turnTimer.cancel();
  _trumpfPollTimer.cancel();
  db.newCard.removeListener(_handleNewCardFromListener);
  super.dispose();
}

/// Initializes the game by loading players and setting up the initial game state.
///
/// This method:
/// - Loads all players and determines the current user's player number
/// - Gets or creates a new round if none exists
/// - Distributes cards to players
/// - Handles trumpf selection if the user has the appropriate card
/// - Sets up real-time listeners for game events
Future<void> _initializeGame() async {
  List<Spieler> loadedPlayers = await swagger.loadPlayers(widget.gid); 
  int ownPlayerNumber = await swagger.getUrPlayernumber(widget.uid, widget.gid); 
  //List<Spieler> loadedPlayers = await gameLogic.loadPlayers();
  //int ownPlayerNumber = loadedPlayers.firstWhere((p) => p.uid == widget.uid).playernumber;
  
  setState(() {
    players = loadedPlayers; 
    myPlayerNumber = ownPlayerNumber;
  });
    String currentRoundIdValue = await swagger.getCurrentRoundId(widget.gid); 
    //String currentRoundIdValue = await db.GetRoundID(widget.gid);
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
      currentRoundIdValue = await swagger.getCurrentRoundId(widget.gid); 
      //currentRoundIdValue = await db.GetRoundID(widget.gid);
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
      String roundId = await swagger.getCurrentRoundId(widget.gid); 
      await swagger.updateWhosTurn(roundId, widget.uid); 
      //String roundId = await db.GetRoundID(widget.gid);
      //db.updateWhosTurn(roundId, widget.uid);
      setState(() {
        _currentTurnUid = widget.uid;
      });
      String? selectedTrumpf = await showTrumpfDialog(context, playerCards: cards);
      if (selectedTrumpf != null) {
        await swagger.updateTrumpf(widget.gid, selectedTrumpf); 
        //db.updateTrumpf(widget.gid, selectedTrumpf);
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_currentTurnUid == widget.uid)
                          ? Colors.orange
                          : Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      (_currentTurnUid == widget.uid)
                          ? 'Du bist am Zug'
                          : 'Am Zug: ${_getPlayerNameByUid(_currentTurnUid)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),                if (_trumpfSymbol != null) ...[
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.06,
                      height: MediaQuery.of(context).size.width * 0.06,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.asset(
                          'other/${_trumpfSymbol!.toLowerCase()}.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
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
                  roundId = await swagger.getCurrentRoundId(widget.gid); 
                  //roundId = await db.GetRoundID(widget.gid);
                  String whosturn = await swagger.getWhosTurn(roundId);
                  //String whosturn = await db.getWhosTurn(roundId);
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
                    int urplayernumber = await swagger.getUrPlayernumber(widget.uid, widget.gid); 
                    //int urplayernumber = await db.getUrPlayernumber(widget.uid, widget.gid);
                    if (urplayernumber == 4) {
                      urplayernumber = 0;
                    }
                    String nextplayer = await swagger.getNextPlayerUid(widget.gid, urplayernumber+1); 
                    //String nextplayer = await db.getNextUserUid(widget.gid, urplayernumber+1);
                    log.d('Updating turn to next player: $nextplayer');
                    await swagger.updateWhosTurn(roundId, nextplayer); 
                    //db.updateWhosTurn(roundId, nextplayer);
                    await swagger.addPlayInRound(roundId, widget.uid, details.data.cid);
                    //db.addPlayInRound(roundId, widget.uid, details.data.cid);
                    log.d('Played cards: ${playedCards.map((c) => c.cid).join(', ')}');
                    counter++;                    
                    if (playedCards.length == 4) {
                    List<Jasskarte> playedcardstemp = playedCards;
                    log.i('Round complete with 4 cards, determining winner');
                    //String winner = await swagger.determineWinningCard(widget.gid, playedCards);
                    String winner = await db.getWinningCard(playedcardstemp, widget.gid, firstCard!);
                    log.i('Round winner determined: $winner');

                    
                    //var winnernumber = await swagger.getUrPlayernumber(winner, widget.gid);
                    int winnernumber = await db.getUrPlayernumber(winner, widget.gid); 
                    int teammatePlayerNumber;
                    if (winnernumber == 1) { teammatePlayerNumber = 3;}
                    else if (winnernumber == 2){ teammatePlayerNumber = 4;}
                    else if (winnernumber == 3) {teammatePlayerNumber = 1;}
                    else {teammatePlayerNumber = 2;}                      
                    String teammateuid = await swagger.getNextPlayerUid(widget.gid, teammatePlayerNumber); 
                    //String teammateuid = await db.getNextUserUid(widget.gid, teammatePlayerNumber);
                    db.savePointsForUsers(playedcardstemp, widget.gid, winner, teammateuid);
                    log.d("Updating round winner: $winner");
                    swagger.updateWinner(roundId, winner);
                    //db.updateWinnerDB(roundId, winner);
                                          
                    _showTrickWinnerPopup(winner);
                    
                    await Future.delayed(const Duration(seconds: 3));
                    
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                    //await swagger.savePointsForUsers(widget.gid, gameLogic.buildCardsForSaveWinnerAsMap(playedCards, winner, teammateuid,));
                    log.d("Points saved for winner team");
                    setState(() {
                      _scoreRefreshCounter++;
                    });
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
                    roundId = await swagger.getCurrentRoundId(widget.gid);
                    //roundId = await db.GetRoundID(widget.gid);
                    log.d("New round started, updating turn to winner: $winner");
                    await swagger.updateWhosTurn(roundId, winner);
                    //db.updateWhosTurn(roundId, winner);
                    playedCards = [];
                    backupCounter = 0;
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

  /// Creates and displays a player avatar with name and score.
  ///
  /// [name] The player's display name.
  /// [uid] Optional user ID for fetching and displaying the player's score.
  ///
  /// Returns a [Widget] containing the player's avatar, name, and current score.
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
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        if (uid != null)
          FutureBuilder<int>(
            key: ValueKey('score_${uid}_$_scoreRefreshCounter'),
            future: db.getPlayerScore(uid, widget.gid), 
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
  }  /// Gets a player's name based on their relative position around the table.
  ///
  /// [position] The relative position ('right', 'top', 'left') from current player.
  ///
  /// Returns the player's username or a fallback name if not found.
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

  /// Gets a player's UID based on their relative position around the table.
  ///
  /// [position] The relative position ('right', 'top', 'left') from current player.
  ///
  /// Returns the player's UID or null if not found.
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
  /// Gets a player's display name by their UID.
  ///
  /// [uid] The unique identifier of the player.
  ///
  /// Returns the player's username or 'Spieler' as fallback.
  // Neue Methoden für die Am-Zug-Anzeige
  String _getPlayerNameByUid(String uid) {
    for (var player in players) {
      if (player.uid == uid) {
        return player.username;
      }
    }
    return 'Spieler';
  }
  /// Shows a popup dialog announcing the winner of the current trick.
  ///
  /// [winnerUid] The UID of the player who won the trick.
  ///
  /// Displays different styling based on whether the current user won or not.
  /// The dialog automatically dismisses after 3 seconds.
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

/// Widget that displays a single played card on the game table.
///
/// This widget is used to show cards that have been played in the current trick.
/// It renders the card image with appropriate sizing for the game table.
class PlayedCard extends StatelessWidget {
  /// The card to be displayed.
  final Jasskarte card;

  /// Creates a [PlayedCard] widget.
  ///
  /// [card] is required and represents the card to display.
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


/// Widget that displays the player's hand of cards in a horizontal scrollable row.
///
/// This widget manages the layout and display of all cards in the current player's hand.
/// Cards are displayed horizontally and can be scrolled if they exceed screen width.
class CardHand extends StatelessWidget {
  /// The list of cards in the player's hand.
  final List<Jasskarte> cards;

  /// Creates a [CardHand] widget.
  ///
  /// [cards] is required and contains all cards currently in the player's hand.
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

/// Widget representing a single draggable card in the player's hand.
///
/// This widget handles the drag-and-drop functionality for playing cards.
/// It provides visual feedback during dragging and maintains proper styling.
class CardWidget extends StatelessWidget {
  /// The card this widget represents.
  final Jasskarte card;

  /// Creates a [CardWidget].
  ///
  /// [card] is required and represents the card to be displayed and made draggable.
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


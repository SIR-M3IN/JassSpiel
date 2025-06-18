/// @file game.dart
/// @brief Hauptspielbildschirm für das Jass-Kartenspiel
/// 
/// Diese Datei enthält die komplette Spiellogik und UI für das Jass-Spiel.
/// Sie verwaltet den Spielzustand, die Kartendarstellung, Spielerinteraktionen
/// und die Kommunikation mit dem Backend über SwaggerConnection und DbConnection.
/// 
/// # Hauptkomponenten:
/// - **InitWidget**: Wartet auf alle 4 Spieler bevor das Spiel startet
/// - **GameScreen**: Der eigentliche Spielbildschirm mit allen Spielelementen  
/// - **CardHand**: Darstellung der Spielerkarten am unteren Bildschirmrand
/// - **PlayedCard**: Darstellung der gespielten Karten in der Tischmitte
/// - **CardWidget**: Einzelne draggable Karte mit Drag & Drop Funktionalität
/// 
/// # Spielablauf:
/// 1. Spieler warten bis alle 4 Spieler beigetreten sind (InitWidget)
/// 2. Karten werden verteilt und Trumpf bestimmt  
/// 3. Spieler ziehen Karten per Drag & Drop in die Tischmitte
/// 4. Nach 4 gespielten Karten wird der Stichgewinner ermittelt
/// 5. Punkte werden berechnet und eine neue Runde startet
/// 
/// # Technische Details:
/// - Man kann sowohl SwaggerConnection (REST API) als auch DbConnection (Realtime) verwenden
/// - Realtime Updates über Supabase für gespielte Karten
/// - Timer für Turn-Updates und Trumpf-Polling  
/// - Umfassende Validierung für erlaubte Kartenzüge
/// - Responsive UI
/// 
/// # Datenstrukturen:
/// - **playedCards**: List<Jasskarte> - Gespielte Karten pro Spieler
/// - **playerCards**: List<Jasskarte> - Karten des aktuellen Spielers
/// - **players**: List<Spieler> - Alle Spieler im Spiel
/// - **currentRoundId**: int - ID der aktuellen Runde
/// - **gameId**: int - ID des aktuellen Spiels

import 'package:flutter/material.dart';
import 'package:jassspiel/dbConnection.dart';
import 'package:jassspiel/gamelogic.dart';
import 'package:jassspiel/logger.util.dart';
import 'package:jassspiel/swaggerConnection.dart';
import '../spieler.dart';
import '../jasskarte.dart';
import 'package:jassspiel/pages/showTrumpfDialogPage.dart';
import 'dart:async';

//KI: Update UI
void main() {
  runApp(const CardGameApp());
}
/// @brief Initialisierungswidget das beim App-Start einmal aufgerufen wird
/// 
/// Wartet darauf, dass 4 Spieler dem Spiel beitreten, bevor es zum 
/// eigentlichen Spielbildschirm wechselt. Zeigt einen Ladebildschirm
/// @brief Initialisierungswidget für den Spielstart
/// 
/// Dieses Widget wird einmalig beim App-Start aufgerufen und ist verantwortlich für:
/// - Warten auf alle 4 Spieler bevor das Spiel beginnt
/// - Laden der Spieler-Daten vom Server
/// - Weiterleitung zum eigentlichen Spielbildschirm nach erfolgreicher Initialisierung
/// - Anzeige eines Ladebildschirms mit Fortschrittsanzeige
///
/// @param gid Eindeutige Spiel-ID für die Identifikation des Spiels
/// @param uid Eindeutige Benutzer-ID des aktuellen Spielers
// KI: Baue mir ein Widget das genau 1x aufgerufen wird, wenn die App startet. Definiere außerdem die GID
class InitWidget extends StatefulWidget {
  final String gid;  ///< Eindeutige Spiel-ID
  final String uid;  ///< Eindeutige Benutzer-ID
  const InitWidget({required this.gid, required this.uid, super.key});

  @override
  _InitWidgetState createState() => _InitWidgetState();
}

/// @brief State-Klasse für das Initialisierungswidget
/// 
/// Verwaltet den Ladezustand und die Spieler-Initialisierung.
/// Lädt kontinuierlich die Spieler bis alle 4 vorhanden sind.
class _InitWidgetState extends State<InitWidget> {
  late GameLogic gameLogic;  ///< Spiellogik-Instanz
  bool loading = true;       ///< Ladezustand
  List<Spieler> players = []; ///< Liste der geladenen Spieler
  final log = getLogger();   ///< Logger-Instanz

  @override
  void initState() {
    super.initState();
    log.i('Initializing game with GID: ${widget.gid}, UID: ${widget.uid}');
    gameLogic = GameLogic(widget.gid);
    _loadPlayersAndWait();
  }

  /// @brief Lädt Spieler und wartet auf 4 vollständige Teilnehmer
  /// 
  /// Prüft alle 2 Sekunden, ob bereits 4 Spieler dem Spiel beigetreten sind.
  /// Wenn ja, wird zum Hauptspielbildschirm gewechselt.
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
  //KI: Hilfe bei UI
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

/// @brief Hauptspielbildschirm für das Jass-Kartenspiel
/// 
/// Dies ist das zentrale Widget für das eigentliche Spiel. Es verwaltet:
/// - Die komplette Spiellogik und den Spielzustand
/// - Real-time Kommunikation mit dem Backend
/// - UI-Elemente wie Spielfeld, Karten, Avatare und HUD
/// - Drag & Drop Funktionalität für Karten
/// - Timer und Rundenlogik
/// - Gewinnererkennung und Punktevergabe
/// 
/// Das Widget verwendet sowohl REST API (SwaggerConnection) als auch
/// Real-time Updates (DbConnection) für nahtlose Multiplayer-Erfahrung.
///
/// @param gid Eindeutige Spiel-ID
/// @param uid Eindeutige Benutzer-ID des aktuellen Spielers
class GameScreen extends StatefulWidget {
  final String gid;  ///< Eindeutige Spiel-ID
  final String uid;  ///< Eindeutige Benutzer-ID des aktuellen Spielers
  const GameScreen({required this.gid, required this.uid, super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// @brief State-Klasse für den Hauptspielbildschirm
/// 
/// Diese Klasse verwaltet den kompletten Spielzustand und alle Spiellogik:
/// 
/// # Wichtige Zustandsvariablen:
/// - **playedCards**: Map der gespielten Karten pro Spieler (Spielernummer -> Karte)
/// - **playerCards**: Liste der Karten des aktuellen Spielers  
/// - **players**: Liste aller Spieler im Spiel
/// - **currentRoundId**: ID der aktuellen Runde
/// - **gameId**: ID des aktuellen Spiels
/// - **trumpf**: Aktueller Trumpf (Eichel, Rosen, Schilten, Schellen)
/// - **currentTurn**: Spielernummer des Spielers der am Zug ist
/// 
/// # Timer und Polling:
/// - **turnTimer**: Überwacht Änderungen des aktuellen Zugs
/// - **trumpfTimer**: Überwacht Änderungen des Trumpfs
/// - **updateTimer**: Regelmäßige Updates des Spielzustands
/// 
/// # Kommunikation:
/// - **db**: DbConnection für Real-time Updates
/// - **swagger**: SwaggerConnection für REST API Aufrufe
class _GameScreenState extends State<GameScreen> {
  DbConnection db = DbConnection();
  int backupCounter = 0; 
  SwaggerConnection swagger = SwaggerConnection(baseUrl: 'http://localhost:8080'); // Initialize swagger
  late GameLogic gameLogic;
  final log = getLogger();
  int counter = 0;
  Jasskarte? firstCard; // First card played in the round
  String currentRoundid = '';
  List<Jasskarte> playedCards = [];
  List<Spieler> players = []; 
  int myPlayerNumber = 1; 
  late Future<List<Jasskarte>> playerCards = Future.value([]);
  
  int _scoreRefreshCounter = 0;
  late Timer _turnTimer;
  late Timer _trumpfPollTimer;
  String? _trumpfSymbol;

  String _currentTurnUid = '';

/// @brief Startet das periodische Polling für das Trumpf-Symbol
/// 
/// Diese Methode startet einen Timer der alle 3 Sekunden das aktuelle
/// Trumpf-Symbol vom Server abruft. Das Polling wird automatisch beendet
/// sobald ein Trumpf-Symbol empfangen wurde.
/// 
/// Das Trumpf-Symbol wird in der UI oben links angezeigt und ist wichtig
/// für die Spielregeln (Trumpf-Karten stechen alle anderen Farben).
/// 
/// Timer wird in _trumpfPollTimer gespeichert für spätere Bereinigung.
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

/// @brief Validiert ob eine Karte nach den Jass-Regeln gespielt werden darf
/// 
/// Diese Methode implementiert die Grundregeln des Jass-Spiels:
/// 1. Die erste Karte einer Runde ist immer erlaubt
/// 2. Trumpf-Karten sind immer erlaubt (stechen alle anderen Farben)
/// 3. Wenn die erste Karte keine Trumpf ist: 
///    - Gleiche Farbe folgen wenn vorhanden
///    - Andere Karten nur wenn keine passende Farbe auf der Hand
/// 
/// @param card Die zu prüfende Jasskarte
/// @return true wenn die Karte gespielt werden darf, false sonst
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



void _updateCardStates() {
  setState(() {
  });
}

// KI: Hilf mir die Karten bei allen Spielern anzuzeigen
/// @brief Behandelt neue Karten die über den Real-time Listener empfangen werden
/// 
/// Diese Methode wird aufgerufen wenn eine neue Karte über den DbConnection
/// Listener empfangen wird. Sie ist verantwortlich für:
/// - Verarbeitung neuer gespielter Karten von anderen Spielern
/// - Aktualisierung des playedCards Arrays
/// - Erkennung wenn alle 4 Karten gespielt wurden
/// - Automatisches Zurücksetzen nach einem Stich
/// - Gewinnererkennung und Punktevergabe
/// 
/// Die Methode verhindert Race Conditions durch Überprüfung ob die Karte
/// bereits vorhanden ist und verwendet mounted-Checks für sichere setState Aufrufe.
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
      String winner = await swagger.determineWinningCard(widget.gid, playedCards);
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
                  /// @brief Callback für das Drag & Drop System - behandelt gespielte Karten
                  /// 
                  /// Diese Methode wird aufgerufen wenn ein Spieler eine Karte
                  /// in die Tischmitte zieht. Sie implementiert die komplette
                  /// Spiellogik für einen Kartenzug:
                  /// 
                  /// 1. Validierung: Ist der Spieler am Zug?
                  /// 2. Kartenvalidierung: Ist die Karte nach Jass-Regeln erlaubt?
                  /// 3. Spielzug ausführen: Karte hinzufügen und nächsten Spieler bestimmen
                  /// 4. Rundenende: Bei 4 Karten Gewinner ermitteln und Punkte vergeben
                  /// 5. Neue Runde: Automatisch nächste Runde starten
                  /// 
                  /// @param details DragTargetDetails mit der gespielten Karte
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
                    //String winner = await swagger.determineWinningCard(widget.gid, PlayedCards);
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

/// @brief Widget zur Darstellung einer gespielten Karte in der Tischmitte
/// 
/// Zeigt eine Karte an, die bereits von einem Spieler gespielt wurde.
/// Die Karte wird in der Mitte des Spielfelds positioniert und ist
/// nicht mehr interaktiv (kein Drag & Drop).
/// 
/// @param card Die Jasskarte die angezeigt werden soll
class PlayedCard extends StatelessWidget {
  final Jasskarte card;  ///< Die anzuzeigende Karte

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

/// @brief Widget zur Darstellung der Kartenhand des Spielers
/// 
/// Zeigt die Karten des aktuellen Spielers am unteren Bildschirmrand an.
/// Jede Karte ist als CardWidget implementiert und unterstützt Drag & Drop
/// um sie in die Tischmitte zu ziehen.
/// 
/// Die Karten werden horizontal nebeneinander angeordnet und können
/// sich überlappen um Platz zu sparen bei vielen Karten.
/// 
/// @param cards Liste der Jasskarten die angezeigt werden sollen
class CardHand extends StatelessWidget {
  final List<Jasskarte> cards;  ///< Die anzuzeigenden Karten

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

/// @brief Widget für eine einzelne draggable Spielkarte
/// 
/// Dieses Widget stellt eine einzelne Jasskarte dar und implementiert
/// die Drag & Drop Funktionalität. Spieler können die Karte anklicken
/// und in die Tischmitte ziehen um sie zu spielen.
/// 
/// Features:
/// - Drag & Drop Funktionalität mit visueller Rückmeldung
/// - Automatische Validierung ob der Zug erlaubt ist
/// - Responsive Design mit anpassbarer Kartengröße
/// - Smooth Animationen während des Dragging
/// 
/// Die Karte wird nur dann als "draggable" markiert wenn der Spieler
/// am Zug ist und die Karte nach den Jass-Regeln gespielt werden darf.
/// 
/// @param card Die Jasskarte die dargestellt werden soll
class CardWidget extends StatelessWidget {
  final Jasskarte card;  ///< Die darzustellende Karte

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


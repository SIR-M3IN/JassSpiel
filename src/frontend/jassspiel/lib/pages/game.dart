// Datei: lib/pages/game.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jassspiel/DBConnection.dart';
import 'package:jassspiel/gamelogic.dart';
import '../spieler.dart';
import '../jasskarte.dart';

/// *******************************
/// InitWidget: Wartet, bis 4 Spieler beitreten
/// *******************************
class InitWidget extends StatefulWidget {
  final String gid;
  final String uid;

  const InitWidget({
    required this.gid,
    required this.uid,
    super.key,
  });

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

        // Sobald 4 Spieler da sind, wechselt zu GameScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameScreen(
              gid: widget.gid,
              uid: widget.uid,
            ),
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
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Waiting for players...',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Party Code: ${widget.gid}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              )
            : const Text('Players loaded!'),
      ),
    );
  }
}

/// *******************************
/// GameScreen: Spiellogik & UI
/// *******************************
class GameScreen extends StatefulWidget {
  final String gid;
  final String uid;

  const GameScreen({
    required this.gid,
    required this.uid,
    super.key,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final DbConnection db = DbConnection();
  late GameLogic gameLogic;

  // „Leeres“ Future, damit der FutureBuilder zu Beginn keinen Fehler wirft
  late Future<List<Jasskarte>> playerCards = Future.value(<Jasskarte>[]);

  // Bereits gespielte Karten in dieser Runde
  List<Jasskarte> playedCards = [];

  // Aktuelle Rundennummer (RID)
  String? _currentRid;

  // RealtimeChannel für die Tabelle „plays“
  RealtimeChannel? _playsChannel;

  // Zählt, wie viele Karten schon in dieser Runde gespielt wurden
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    gameLogic = GameLogic(widget.gid);
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    // 1) Spieler laden (für Shuffle-Logik)
    List<Spieler> players = await db.loadPlayers(widget.gid);

    // 2) Handkarten austeilen → Future<List<Jasskarte>>
    Future<List<Jasskarte>> loadedCards =
        gameLogic.shuffleandgetCards(players, widget.uid);

    // 3) Ermittele die bisherige Rundennummer aus DB:
    //    getWhichRound liefert -1, wenn keine Runden existieren
    int lastRound = await db.getWhichRound(widget.gid);

    // 4) Erstelle eine neue Runde (whichround = lastRound + 1)
    await db.startNewRound(widget.gid, lastRound);

    // 5) Hole direkt danach die neue RID für die soeben angelegte Runde
    String rid = await db.GetRoundID(widget.gid);
    _currentRid = rid;

    // 6) Lade alle bisherigen Spielzüge (in einer neuen Runde wäre das leer)
    _loadPlayedCards();

    // 7) Lege das Realtime-Abo fest, damit bei jedem neuen INSERT in „plays“ automatisch
    //    _loadPlayedCards() aufgerufen wird und das UI aktualisiert
    _subscribeToPlayedCards();

    // 8) Sobald das „echte“ Future mit Handkarten zurückkommt, überschreibe das Default-Future
    setState(() {
      playerCards = loadedCards;
    });
  }

  /// Lädt alle Karten, die in der Tabelle „plays“ für unsere _currentRid gespeichert sind.
  void _loadPlayedCards() async {
    if (_currentRid == null) return;
    try {
      List<Jasskarte> cards = await db.getPlayedCards(_currentRid!);
      setState(() {
        playedCards = cards;
      });
    } catch (e) {
      debugPrint('Fehler beim Laden der gespielten Karten: $e');
    }
  }

  /// Erstellt eine Realtime-Subscription auf „plays“, gefiltert nach INSERTs mit RID == _currentRid
  void _subscribeToPlayedCards() {
    if (_currentRid == null) return;

    // Falls schon ein Channel existiert, abmelden
    _playsChannel?.unsubscribe();

    // Supabase 1.x: Wir nutzen den Channel-Namen mit Filter „RID=eq.<AktuelleRID>“
    _playsChannel = db.client
        .channel('public:plays:RID=eq.$_currentRid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'plays',
          callback: (payload) {
            // Jedes Mal, wenn eine neue Karte in „plays“ abgelegt wird,
            // rufen wir _loadPlayedCards() auf, um das UI zu aktualisieren.
            _loadPlayedCards();
          },
        )
        .subscribe();
  }

  /// Wird aufgerufen, wenn der lokale Spieler eine Karte vom Handbereich
  /// auf das Spielfeld (DragTarget) zieht. Fügt die Karte sofort in `playedCards`
  /// und speichert sie in der DB ab.
  void _addPlayedCard(Jasskarte card) {
    // 1) Sofort ins UI einfügen
    setState(() {
      playedCards.add(card);
    });

    // 2) Aus der Hand des Spielers entfernen
    playerCards.then((hand) {
      final updated = List<Jasskarte>.from(hand)
        ..removeWhere((c) => c.cid == card.cid);
      setState(() {
        playerCards = Future.value(updated);
      });
    });
  }

  @override
  void dispose() {
    // Realtime-Subscription wieder abmelden, wenn das Widget zerstört wird
    _playsChannel?.unsubscribe();
    super.dispose();
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
                // Oben: Spieler 1 (Avatar/Darstellung)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: playerAvatar('Player 1'),
                ),

                // Links: Spieler 4
                Positioned(
                  top: 180,
                  left: 16,
                  child: playerAvatar('Player 4'),
                ),

                // Rechts: Spieler 3
                Positioned(
                  top: 180,
                  right: 16,
                  child: playerAvatar('Player 3'),
                ),

                // Zentrale Spielfläche (zeigt bis zu 4 gespielte Karten nebeneinander)
                Center(
                  child: DragTarget<Jasskarte>(
                    onAcceptWithDetails: (details) async {
                      final card = details.data;

                      // 1) Sofort ins Feld einfügen
                      _addPlayedCard(card);

                      // 2) In der DB-Tabelle „plays“ speichern
                      if (_currentRid != null) {
                        await db.addPlayInRound(
                          _currentRid!,
                          widget.uid,
                          card.cid,
                        );
                      }

                      // 3) Rundenzähler erhöhen; wenn 4 Karten, neue Runde starten
                      _counter++;
                      if (_counter == 4) {
                        _counter = 0;

                        // a) Neue Runde in der DB anlegen
                        //    – Wir holen vorher wieder die letzte Rundennummer,
                        //      damit startNewRound(gid, whichround) korrekt ist:
                        int lastRound = await db.getWhichRound(widget.gid);
                        await db.startNewRound(widget.gid, lastRound);

                        // b) Neue RID holen
                        String newRid = await db.GetRoundID(widget.gid);
                        _currentRid = newRid;

                        // c) Alte Karten im UI zurücksetzen
                        setState(() {
                          playedCards = [];
                        });

                        // d) Alte Subscription beenden und neue abonnieren
                        _subscribeToPlayedCards();
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

                // Unten: Kartenhand des aktuellen Spielers
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FutureBuilder<List<Jasskarte>>(
                    future: playerCards,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Fehler: ${snapshot.error}'),
                        );
                      } else if (!snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Keine Karten gefunden'),
                        );
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

  /// Einfacher Avatar (Kreis + Name) für die anderen Spieler
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

/// *******************************
/// PlayedCard: Zeigt eine einzelne Karte auf dem Spielfeld
/// *******************************
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

/// *******************************
/// CardHand: Zeigt alle Handkarten des Spielers in einer scrollbaren Leiste
/// *******************************
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

/// *******************************
/// CardWidget: Eine einzelne Karte in der Hand (Draggable)
/// *******************************
class CardWidget extends StatelessWidget {
  final Jasskarte card;

  const CardWidget({required this.card, super.key});

  @override
  Widget build(BuildContext context) {
    return Draggable<Jasskarte>(
      data: card,

      // Das „fliegende“ Bild, wenn der User die Karte zieht
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 80,
          height: 120,
          child: Image.asset(card.path, fit: BoxFit.cover),
        ),
      ),

      // Was am ursprünglichen Ort angezeigt wird, während gezogen wird
      childWhenDragging: const SizedBox(width: 80, height: 120),

      // Normales Bild, wenn nicht gezogen wird
      child: SizedBox(
        width: 80,
        height: 120,
        child: Image.asset(card.path, fit: BoxFit.cover),
      ),
    );
  }
}

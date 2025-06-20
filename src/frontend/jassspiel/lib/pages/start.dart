/// Startseite der Jass-Anwendung.
///
/// Diese Datei enthält die UI und Logik für die Startseite. Benutzer können hier:
/// - Ihren Spielernamen eingeben und speichern.
/// - Ein neues Spiel erstellen.
/// - Einem bestehenden Spiel mit einem Code beitreten.
/// - Eine Liste offener Spiele sehen und direkt beitreten.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jassspiel/dbConnection.dart';
import 'package:jassspiel/logger.util.dart';
import 'package:jassspiel/swaggerConnection.dart';

/// Die Startseite der Anwendung.
///
/// Dieses Widget ist der Einstiegspunkt für den Benutzer. Es ermöglicht das Erstellen
/// oder Beitreten zu einem Spiel und zeigt eine Liste verfügbarer Spielräume an.
class StartPage extends StatefulWidget {
  /// Erstellt eine [StartPage].
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

/// Zustandsverwaltung für die [StartPage].
///
/// Verwaltet die Eingabefelder für Name und Code, den Ladezustand und die
/// Interaktion mit der Datenbank zum Erstellen, Beitreten und Auflisten von Spielen.
class _StartPageState extends State<StartPage> {  /// Text-Controller für das Spielername-Eingabefeld.
  final _nameController = TextEditingController();
  
  /// Text-Controller für das Spielcode-Eingabefeld.
  final _codeController = TextEditingController();
  
  /// Logger-Instanz für Debugging und Überwachung.
  final log = getLogger();
  
  /// Flag, das anzeigt, ob gerade eine Operation lädt.
  bool _isLoading = false;
  
  /// Future, das zur Liste offener Spiele aufgelöst wird.
  Future<List<Map<String, dynamic>>>? _openGamesFuture;

  @override
  void initState() {
    super.initState();
    log.i('Start page initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('name');
      if (savedName != null) {
        _nameController.text = savedName;
        log.d('Loaded saved name: $savedName');
      }
    });
    _openGamesFuture = _fetchOpenGames();
  }  /// Holt die Liste offener Spiele aus der Datenbank.
  ///
  /// Gibt einen [Future] zurück, der mit einer Liste von Spieldaten-Maps abgeschlossen wird.
  Future<List<Map<String, dynamic>>> _fetchOpenGames() {
    log.d('Fetching open games');
    return DbConnection().getOpenGames();
  }  /// Speichert den Spielernamen lokal für zukünftige Sitzungen.
  ///
  /// [name] Der zu speichernde Spielername.
  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    log.d('Saved player name: $name');
  }  /// Zeigt eine [SnackBar] mit einer Nachricht an.
  ///
  /// [msg] Die anzuzeigende Nachricht.
  /// [color] Die optionale Hintergrundfarbe der SnackBar.
  void _showSnack(String msg, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color ?? Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = DbConnection();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final formWidth = width > 600 ? width * 0.5 : width * 0.9;
            final spacing = width * 0.04;
            final isWide = width > 600;
            return SingleChildScrollView(
              padding: EdgeInsets.all(spacing),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: formWidth),                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Schriftzug
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: formWidth * 0.8,
                              maxHeight: constraints.maxHeight * 0.25,
                            ),
                            child: Image.asset(
                              'assets/other/JassSchriftzug.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing),                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                          onChanged: _saveName,
                        ),
                      SizedBox(height: spacing),                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: 'Party Code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            prefixIcon: const Icon(Icons.code, color: Colors.deepPurple),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          ),
                        ),
                      SizedBox(height: spacing),
                      isWide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: startButton(db)),
                                SizedBox(width: spacing),
                                Expanded(child: joinButton(db)),
                              ],
                            )
                          : Column(
                              children: [
                                startButton(db),
                                SizedBox(height: spacing),
                                joinButton(db),
                              ],
                            ),                      
                            SizedBox(height: spacing * 2),
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '🎮 Available Rooms',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _openGamesFuture = _fetchOpenGames();
                                    });
                                  },
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),FutureBuilder<List<Map<String, dynamic>>>(
                        future: _openGamesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          }
                          final rooms = snapshot.data ?? [];
                          if (rooms.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              child: const Text(
                                '🔍 No open rooms found.\nCreate a new game!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rooms.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final room = rooms[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber,
                                    child: Text(
                                      '${room['participants']}/4',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    room['room_name'] ?? room['GID'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Code: ${room['GID']}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _joinRoomByCode(room['GID']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('Join', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),            );
          },
        ),
        ),
      ),
    );
  }
  /// Creates the "Start Game" button.
  ///
  /// [db] An instance of [DbConnection] for database operations.
  /// 
  /// Returns a styled [ElevatedButton] widget for starting a new game.
  Widget startButton(DbConnection db) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _onStartPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 5,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Start Game', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }
  /// Creates the "Join Game" button.
  ///
  /// [db] An instance of [DbConnection] for database operations.
  /// 
  /// Returns a styled [ElevatedButton] widget for joining an existing game.
  Widget joinButton(DbConnection db) {
    return ElevatedButton(
      onPressed: _onJoinPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 5,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, color: Colors.white),
          SizedBox(width: 8),
          Text('Join Game', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  /// Handles the logic when the "Start Game" button is pressed.
  ///
  /// Validates the player name, creates a new game, adds the player
  /// and navigates to the game initialization screen.
  void _onStartPressed() async {
    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    log.i('Starting new game for player: $name');
    if (name.isEmpty) {
      log.w('Attempted to start game without name');
      _showSnack('Bitte zuerst einen Namen eingeben.', Colors.red);
      setState(() => _isLoading = false);
      return;
    }
    final db = DbConnection();
    try {
      final uid = await db.getOrCreateUid();
      log.d('Retrieved/created UID: $uid');
      await db.saveUserIfNeeded(uid, name);
      final gid = await db.createGame();
      log.i('Created new game with GID: $gid');
      await db.addPlayerToGame(gid, uid, name);
      if (!mounted) return;
      log.d('Navigating to game initialization');
      Navigator.pushNamed(context, '/init', arguments: {'gid': gid, 'uid': uid});
    } catch (e) {
      log.e('Error starting game: $e');
      _showSnack('Fehler: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  /// Handles the logic when the "Join Game" button is pressed.
  ///
  /// Validates the player name and game code, joins the game,
  /// adds the player and navigates to the initialization screen.
  void _onJoinPressed() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    log.i('Attempting to join game: $code with player: $name');
    if (name.isEmpty || code.isEmpty) {
      log.w('Missing name or code for joining game');
      _showSnack('Name und Partycode sind erforderlich.', Colors.red);
      return;
    }
    final db = DbConnection();
    final swagger = SwaggerConnection(baseUrl: 'http://localhost:8080');
    final uid = await db.getOrCreateUid();
    log.d('Retrieved UID for joining: $uid');
    //await db.saveUserIfNeeded(uid, name);
    await swagger.upsertUser(uid, name);
    //final ok = await db.joinGame(code);
    final ok = await swagger.joinGame(code);
    if (!ok) {
      log.w('Failed to join game - room not found: $code');
      _showSnack('Raum mit Code $code nicht gefunden.', Colors.red);
      return;
    }
    log.i('Successfully joined game: $code');
    await db.addPlayerToGame(code, uid, name);

    log.d('Added player to game, navigating to initialization');
    Navigator.pushNamed(context, '/init', arguments: {'gid': code, 'uid': uid});
  }
  /// Handles the logic for joining a game directly from the room list.
  ///
  /// [code] The game code of the room to join.
  void _joinRoomByCode(String code) async {
    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Bitte zuerst einen Namen eingeben.', Colors.red);
      setState(() => _isLoading = false);
      return;
    }
    final db = DbConnection();
    final swagger = SwaggerConnection(baseUrl: 'http://localhost:8080');
    try {
      final uid = await db.getOrCreateUid();
      //await db.saveUserIfNeeded(uid, name);
      await swagger.upsertUser(uid, name);
      //final ok = await db.joinGame(code);
      final ok = await swagger.joinGame(code);
      if (!ok) {
        _showSnack('Raum mit Code $code nicht gefunden.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      db.addPlayerToGame(code, uid, name);
      if (!mounted) return;
      Navigator.pushNamed(context, '/init', arguments: {'gid': code, 'uid': uid});
    } catch (e) {
      _showSnack('Fehler: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
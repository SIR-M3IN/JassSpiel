import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/game.dart';
import 'pages/start.dart';
import 'package:logger/logger.dart';
import 'logger.util.dart';

/// Haupt-Einstiegspunkt der Jass-Kartenspiel-Anwendung.
///
/// Initialisiert die Flutter-Bindung, richtet das Logging ein, konfiguriert die App
/// für Querformat-Orientierung und startet die Anwendung.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.level = Level.debug;
  final log = getLogger();
  log.d('Debug-Nachricht aus der main-Methode.');  log.i('Info-Nachricht aus der main-Methode.');
  log.e('Error-Nachricht aus der main-Methode.');

  // Supabase initialization is now handled in DbConnection

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const CardGameApp());
  });
}

/// Root-Anwendungs-Widget für das Jass-Kartenspiel.
///
/// Konfiguriert die Haupt-MaterialApp mit Routing, Navigation
/// und behandelt die Routengenerierung für verschiedene Spielbildschirme.
class CardGameApp extends StatelessWidget {
  /// Erstellt eine [CardGameApp].
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPage(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        if (settings.name == '/init') {
          if (args is Map<String, dynamic> &&
              args['gid'] is String &&
              args['uid'] is String) {
            return MaterialPageRoute(
              builder: (context) => InitWidget(
                gid: args['gid'],
                uid: args['uid'],
              ),
            );
          }
        }

        if (settings.name == '/game') {
          if (args is Map<String, dynamic> &&
              args['gid'] is String &&
              args['uid'] is String) {
            return MaterialPageRoute(
              builder: (context) => GameScreen(
                gid: args['gid'],
                uid: args['uid'],
              ),
            );
          }
        }

        // Wenn Route nicht erkannt wird, gehe zu Fehlerseite
        return MaterialPageRoute(
          builder: (context) => const UnknownRoutePage(),
        );
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const UnknownRoutePage(),
        );
      },
    );
  }
}

/// Fallback page displayed when an unknown route is accessed.
///
/// This widget provides a user-friendly error message when navigation
/// to an unrecognized route occurs.
// Fallback-Seite für unbekannte Routen
class UnknownRoutePage extends StatelessWidget {
  /// Creates an [UnknownRoutePage].
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Fehler: Route nicht gefunden',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

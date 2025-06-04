import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/game.dart';
import 'pages/users_page.dart';
import 'pages/start.dart';
import 'package:logger/logger.dart';
import 'logger.util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.level = Level.debug;
  final log = getLogger();
  log.d('Debug-Nachricht aus der main-Methode.');
  log.i('Info-Nachricht aus der main-Methode.');
  log.e('Error-Nachricht aus der main-Methode.');

  await Supabase.initialize(
    url: 'https://wzhaxvxfhdcrpyiswybf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6aGF4dnhmaGRjcnB5aXN3eWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDA1MTEsImV4cCI6MjA2MjAxNjUxMX0.yzYZ4jHfAlq2CgpkN_oAue71LLNzAYzP0ABSj1YbFNs',
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const CardGameApp());
  });
}

class CardGameApp extends StatelessWidget {
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPage(),
        '/users': (context) => const UsersPage(),
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

// Fallback-Seite für unbekannte Routen
class UnknownRoutePage extends StatelessWidget {
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

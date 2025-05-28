// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/start.dart';
import 'pages/game.dart';
import 'pages/users_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wzhaxvxfhdcrpyiswybf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6'
        'Ind6aGF4dnhmaGRjcnB5aXN3eWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDA1'
        'MTEsImV4cCI6MjA2MjAxNjUxMX0.yzYZ4jHfAlq2CgpkN_oAue71LLNzAYzP0ABSj1YbFNs',
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const CardGameApp());
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
        '/game': (context) => const GameScreen(),
        '/users': (context) => const UsersPage(),
      },
    );
  }
}

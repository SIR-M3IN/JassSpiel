// import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'pages/start.dart';
// import 'pages/users_page.dart';
// import 'pages/game.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url: 'https://wzhaxvxfhdcrpyiswybf.supabase.co',
//     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6aGF4dnhmaGRjcnB5aXN3eWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDA1MTEsImV4cCI6MjA2MjAxNjUxMX0.yzYZ4jHfAlq2CgpkN_oAue71LLNzAYzP0ABSj1YbFNs',
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'JassSpiel',
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const Start(),
//         '/users': (context) => const UsersPage(),
//       },

//       onGenerateRoute: (settings) {
//         if (settings.name == '/game') {
//           final args = settings.arguments as Map<String, String>;
//           return MaterialPageRoute(
//             builder: (_) => GamePage(
//               gid: args['gid']!,
//               uid: args['uid']!,
//             ),
//           );
//         }
//         return null;
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/game.dart';
import 'pages/users_page.dart';
import 'pages/start.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
    url: 'https://wzhaxvxfhdcrpyiswybf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6aGF4dnhmaGRjcnB5aXN3eWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDA1MTEsImV4cCI6MjA2MjAxNjUxMX0.yzYZ4jHfAlq2CgpkN_oAue71LLNzAYzP0ABSj1YbFNs',
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
        '/game': (context) => const GameScreen(),
        '/users': (context) => const UsersPage(),
      },

    onGenerateRoute: (settings) {
    if (settings.name == '/init') {
      final args = settings.arguments;
      if (args is Map<String, dynamic> && args['gid'] is String) {
        final gid = args['gid'] as String;
        print(gid);
        return MaterialPageRoute(
          builder: (context) => InitWidget(gid: gid),
        );
      } else {
        // Optionally handle bad/missing arguments
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Missing or invalid gid : ')),
          ),
        );
      }
    }
    return null;
  }

    );
  }
}

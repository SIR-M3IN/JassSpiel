// lib/pages/start.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _uuid = const Uuid();

  String generatePartyCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(5, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<bool> isCodeAvailable(String code) async {
    final resp = await Supabase.instance.client
        .from('games')
        .select('gid')
        .eq('gid', code)
        .maybeSingle();
    return resp == null;
  }

  Future<String> createGameWithCode() async {
    String code;
    do {
      code = generatePartyCode();
    } while (!(await isCodeAvailable(code)));

    await Supabase.instance.client.from('games').insert({
      'gid': code,
      'status': 'waiting',
      'participants': 1,
      'room_name': 'Neuer Raum',
    });

    return code;
  }

  Future<bool> joinGame(String code) async {
    final response = await Supabase.instance.client
        .from('games')
        .select('participants')
        .eq('gid', code)
        .maybeSingle();

    if (response != null) {
      final current = response['participants'] as int? ?? 0;
      await Supabase.instance.client
          .from('games')
          .update({'participants': current + 1})
          .eq('gid', code);
      return true;
    }
    return false;
  }

  void _showSnack(String msg, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JassSpiel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Party Code (zum Beitreten)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons nebeneinander
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Start Game (neuen Raum erstellen)
                ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnack('Bitte zuerst einen Namen eingeben.', Colors.red);
                      return;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('name', name);

                    final gid = await createGameWithCode();
                    print('🎉 Raum erstellt mit Code: $gid');

                    final uid = _uuid.v4();
                    Navigator.pushNamed(
                      context,
                      '/game',
                      arguments: {'gid': gid, 'uid': uid},
                    );
                  },
                  child: const Text('Start Game'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    final code = _codeController.text.trim();
                    if (name.isEmpty || code.isEmpty) {
                      _showSnack('Name und Partycode sind erforderlich.', Colors.red);
                      return;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('name', name);

                    final ok = await joinGame(code);
                    if (!ok) {
                      _showSnack('Raum mit Code $code nicht gefunden.', Colors.red);
                      return;
                    }

                    print('✅ Dem Raum $code beigetreten');
                    final uid = _uuid.v4();
                    Navigator.pushNamed(
                      context,
                      '/game',
                      arguments: {'gid': code, 'uid': uid},
                    );
                  },
                  child: const Text('Join Game'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}

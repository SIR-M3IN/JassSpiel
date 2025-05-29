// start.dart

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

  @override
  void initState() {
    super.initState();

    // Nach dem ersten Frame den gespeicherten Namen laden
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('name');
      if (savedName != null) {
        _nameController.text = savedName;
      }
    });
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
  }

  Future<void> _saveUserIfNeeded(String uid, String name) async {
    final existing = await Supabase.instance.client
        .from('User')
        .select()
        .eq('UID', uid)
        .maybeSingle();
    if (existing == null) {
      await Supabase.instance.client
          .from('User')
          .insert({'UID': uid, 'name': name});
    } else {
      await Supabase.instance.client
          .from('User')
          .update({'name': name})
          .eq('UID', uid);
    }
  }

  Future<String> _getOrCreateUid() async {
    final prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString('UID');
    if (uid == null) {
      uid = _uuid.v4();
      await prefs.setString('UID', uid);
    }
    return uid;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<bool> _isCodeAvailable(String code) async {
    final resp = await Supabase.instance.client
        .from('games')
        .select('GID')
        .eq('GID', code)
        .maybeSingle();
    return resp == null;
  }

  Future<String> _createGame() async {
    String code;
    do {
      code = _generateCode();
    } while (!(await _isCodeAvailable(code)));

    await Supabase.instance.client.from('games').insert({
      'GID': code,
      'status': 'waiting',
      'participants': 1,
      'room_name': 'Neuer Raum',
    });
    return code;
  }

  Future<bool> _joinGame(String code) async {
    final resp = await Supabase.instance.client
        .from('games')
        .select('participants')
        .eq('GID', code)
        .maybeSingle();
    if (resp != null) {
      final current = resp['participants'] as int? ?? 0;
      await Supabase.instance.client
          .from('games')
          .update({'participants': current + 1})
          .eq('GID', code);
      return true;
    }
    return false;
  }

  Future<void> _saveUserToGame(String uid, String gid) async {
    final existing = await Supabase.instance.client
        .from('usergame')
        .select()
        .eq('UID', uid)
        .eq('GID', gid)
        .maybeSingle();
    if (existing == null) {
      await Supabase.instance.client
          .from('usergame')
          .insert({'UID': uid, 'GID': gid, 'score': 0});
    }
  }

  void _showSnack(String msg, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color ?? Colors.black),
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
              onChanged: _saveName,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnack('Bitte zuerst einen Namen eingeben.', Colors.red);
                      return;
                    }
                    final gid = await _createGame();
                    final uid = await _getOrCreateUid();
                    await _saveUserIfNeeded(uid, name);
                    await _saveUserToGame(uid, gid);
                    Navigator.pushNamed(context, '/init', arguments: {'gid': gid});
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
                    final ok = await _joinGame(code);
                    if (!ok) {
                      _showSnack('Raum mit Code $code nicht gefunden.', Colors.red);
                      return;
                    }
                    final uid = await _getOrCreateUid();
                    await _saveUserIfNeeded(uid, name);
                    await _saveUserToGame(uid, code);
                    Navigator.pushNamed(context, '/init', arguments: {'gid':code});
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
}

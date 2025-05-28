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
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadName();

    _nameFocusNode.addListener(() async {
      if (!_nameFocusNode.hasFocus) {
        final name = _nameController.text.trim();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', name);
      }
    });
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('name');
    if (savedName != null) {
      _nameController.text = savedName;
    }
  }

  Future<void> saveUserIfNeeded(String uid, String name) async {
  final existing = await Supabase.instance.client
      .from('User')
      .select()
      .eq('uid', uid)
      .maybeSingle();

  if (existing == null) {
    await Supabase.instance.client.from('User').insert({
      'uid': uid,
      'name': name,
      'totalpoints': 0,
      'gamesplayed': 0,
    });
  } else {
    await Supabase.instance.client
        .from('User')
        .update({'name': name})
        .eq('uid', uid);
    }
  }


  Future<String> getOrCreateUid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    if (uid == null) {
      uid = _uuid.v4();
      await prefs.setString('uid', uid);
    }
    return uid;
  }

  String generatePartyCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(4, (index) => chars[rnd.nextInt(chars.length)]).join();
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

  Future<void> saveUserToGame(String uid, String gid) async {
    final existing = await Supabase.instance.client
        .from('usergame')
        .select()
        .eq('uid', uid)
        .eq('gid', gid)
        .maybeSingle();

    if (existing == null) {
      await Supabase.instance.client.from('usergame').insert({
        'uid': uid,
        'gid': gid,
        'score': 0,
      });
    }
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
              focusNode: _nameFocusNode,
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

                    final gid = await createGameWithCode();
                    final uid = await getOrCreateUid();
                    await saveUserIfNeeded(uid, name); 
                    await saveUserToGame(uid, gid);


                    Navigator.pushNamed(context, '/game', arguments: {'gid': gid, 'uid': uid});
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

                    final ok = await joinGame(code);
                    if (!ok) {
                      _showSnack('Raum mit Code $code nicht gefunden.', Colors.red);
                      return;
                    }
                    
                    final uid = await getOrCreateUid();
                    await saveUserIfNeeded(uid, name);
                    await saveUserToGame(uid, code);

                    Navigator.pushNamed(context, '/game', arguments: {'gid': code, 'uid': uid});
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
    _nameFocusNode.dispose();
    super.dispose();
  }
}

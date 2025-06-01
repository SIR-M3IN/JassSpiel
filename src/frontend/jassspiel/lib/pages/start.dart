import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jassspiel/dbConnection.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    final db = DbConnection();
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
                    final uid = await db.getOrCreateUid();
                    await db.saveUserIfNeeded(uid, name);
                    final gid = await db.createGame();
                    await db.addPlayerToGame(gid, uid, name);
                    Navigator.pushNamed(context, '/init', arguments: {'gid': gid, 'uid': uid});
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
                    final uid = await db.getOrCreateUid();
                    await db.saveUserIfNeeded(uid, name);
                    final ok = await db.joinGame(code);
                    if (!ok) {
                      _showSnack('Raum mit Code $code nicht gefunden.', Colors.red);
                      return;
                    }
                    await db.addPlayerToGame(code, uid, name);
                    Navigator.pushNamed(context, '/init', arguments: {'gid': code});
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
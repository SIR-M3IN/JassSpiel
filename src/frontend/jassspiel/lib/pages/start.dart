import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game.dart';
import 'dart:async'; 

class Start extends StatefulWidget {
  const Start({super.key});
  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final Random _rnd = Random();
  late Future<List<Room>> _roomsFuture;
  StreamSubscription<List<Map<String, dynamic>>>? _userGameSub;

  @override
  void initState() {
    super.initState();
    // 1) einmalig laden
    _roomsFuture = _fetchRooms();

    // 2) Subscription auf UserGame‐Tabelle
    _userGameSub = _supabase
      .from('UserGame')
      .stream(primaryKey: ['uid','gid'])  // eindeutige Schlüssel
      .listen((_) {
        // whenever something changes → neu laden
        setState(() {
          _roomsFuture = _fetchRooms();
        });
      });
  }


  @override
  void dispose() {
    _userGameSub?.cancel();
    super.dispose();
  }

  Future<void> _loadRandomName() async {
    final jsonStr = await rootBundle.loadString(
      'assets/Random_Names/random_double_names.json',
    );
    final List<dynamic> list = json.decode(jsonStr);
    if (list.isNotEmpty) {
      setState(() {
        _nameController.text = list[_rnd.nextInt(list.length)] as String;
      });
    }
  }

  Future<List<Room>> _fetchRooms() async {
    final response = await _supabase
        .from('Games')
        .select('gid, status, UserGame!inner(uid, User(name))');
    return response.map((room) {
      final gid = room['gid'] as String;
      final participants = (room['UserGame'] as List)
          .map((ug) => ug['User']['name'] as String)
          .toList();
      return Room(gid: gid, participants: participants);
    }).toList();
  }

  Future<void> _createAndJoinRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // 1) Upsert User
    final userResp = await _supabase
        .from('User')
        .upsert({'name': name}, onConflict: 'name')
        .select()
        .single();
    final uid = userResp['uid'] as String;

    // 2) Create Game
    final gameResp = await _supabase
        .from('Games')
        .insert({'status': 'waiting'})
        .select()
        .single();
    final gid = gameResp['gid'] as String;

    // 3) Join UserGame
    await _supabase.from('UserGame').insert({
      'uid': uid,
      'gid': gid,
      'score': 0,
    });

    // 4) Navigate with arguments
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GamePage(gid: gid, uid: uid),
      ),
    );
  }

  Widget _buildNameField() => Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              border: InputBorder.none,
              labelText: 'Name',
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadRandomName,
              ),
            ),
          ),
        ),
      );

  Widget _roomCard(Room room) => Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room: ${room.gid}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${room.participants.length} Teilnehmer'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    room.participants.map((n) => Chip(label: Text(n))).toList(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // statt pushNamed mit aktuellen Name-Controller:
                    Navigator.of(context).pushNamed(
                      '/game',
                      arguments: {
                        'gid': room.gid,
                        'uid': _nameController.text.trim(),
                      },
                    );
                  },
                  child: const Text('Enter'),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 24),
            _buildNameField(),
            const SizedBox(height: 24),
            FutureBuilder<List<Room>>(
              future: _roomsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final rooms = snap.data ?? [];
                if (rooms.isEmpty) {
                  return const Text('Keine Räume gefunden.');
                }
                return Column(children: rooms.map(_roomCard).toList());
              },
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAndJoinRoom,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Hilfsklasse für einen Raum
class Room {
  final String gid;
  final List<String> participants;
  Room({required this.gid, required this.participants});
}

import 'package:flutter/material.dart';
import '../dbConnection.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _nameController = TextEditingController();
  final DbConnection _db = DbConnection();
  late Future<List<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = fetchUsers();
  }
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final response = await _db.client
        .from('User')
        .select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertUser(String name) async {
    await _db.client.from('User').insert({
      'name': name,
      'TotalPoints': 0,
      'GamesWon': 0,
      'GamesPlayed': 0,
    });

    // Liste aktualisieren
    setState(() {
      _userFuture = fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alle User')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name eingeben',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      insertUser(name);
                      _nameController.clear();
                    }
                  },
                  child: const Text('Erstellen'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _userFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user['name'] ?? 'Kein Name'),
                      subtitle: Text('Punkte: ${user['TotalPoints']}, Spiele: ${user['GamesPlayed']}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

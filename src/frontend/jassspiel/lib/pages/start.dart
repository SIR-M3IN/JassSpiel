import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  final TextEditingController _nameController = TextEditingController();
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _loadRandomName();
  }

  Future<void> _loadRandomName() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/Random_Names/random_double_names.json',
      );
      final List<dynamic> list = json.decode(jsonStr);
      if (list.isNotEmpty) {
        final randomName = list[_rnd.nextInt(list.length)] as String;
        setState(() {
          _nameController.text = randomName;
        });
      }
    } catch (e) {
      debugPrint('Error loading names: \$e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNameField(),
              const SizedBox(height: 24),
              roomWidget('Room 1', 5, 0),
              roomWidget('Room 2', 3, 1),
              roomWidget('Room 3', 8, 2),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Neue Room-Logik
        },
        tooltip: 'Create Room',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNameField() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              tooltip: 'Neuer Name',
            ),
          ),
        ),
      ),
    );
  }

  Widget roomWidget(String roomName, int participants, int roomId) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$participants Teilnehmer'),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to room
              },
              child: const Text('Enter'),
            ),
          ],
        ),
      ),
    );
  }
}

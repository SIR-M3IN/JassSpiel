import 'package:flutter/material.dart';

class GamePage extends StatelessWidget {
  final String gid;
  final String uid;

  const GamePage({required this.gid, required this.uid, super.key});

  @override
  Widget build(BuildContext context) {
    // Hier kannst du mit gid & uid laden, was in diesem Game passieren soll
    return Scaffold(
      appBar: AppBar(title: Text('Game $gid')),
      body: Center(child: Text('User $uid ist in Game $gid')),
    );
  }
}

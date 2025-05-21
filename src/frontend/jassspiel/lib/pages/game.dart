import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const CardGameApp());
}

class CardGameApp extends StatelessWidget {
  const CardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final laubCards = [
      'Laub_6.png',
      'Laub_7.png',
      'Laub_8.png',
      'Laub_9.png',
      'Laub_10.png',
      'Laub_Ass.png',
      'Laub_König.png',
      'Laub_Ober.png',
      'Laub_Unter.png',
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 38, 82, 7),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: playerAvatar('Player 1')),
                ),
                Positioned(
                  top: 180,
                  left: 16,
                  child: playerAvatar('Player 4'),
                ),
                Positioned(
                  top: 180,
                  right: 16,
                  child: playerAvatar('Player 3'),
                ),
                Center(
                  child: DragTarget<String>(
                    onAcceptWithDetails: (receivedCard) {
                      print('Gespielte Karte: $receivedCard');
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        width: 300,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            PlayedCard('Laub_10.png'),
                            PlayedCard('Laub_8.png'),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CardHand(cards: laubCards),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget playerAvatar(String name) {
    return Column(
      children: [
        const CircleAvatar(radius: 24, child: Icon(Icons.person)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class PlayedCard extends StatelessWidget {
  final String image;

  const PlayedCard(this.image, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Image.asset(
        'assets/Laub/$image',
        width: 70,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }
}

class CardHand extends StatelessWidget {
  final List<String> cards;

  const CardHand({required this.cards, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130, // Höhe für die Karten unten
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24), // Abstand zu den Seiten
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: cards.map((card) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: 60,  // Karten etwas kleiner
                    height: 90,
                    child: CardWidget(assetName: card),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}


// Prompt: Mache das ich die Karten durch Drag and drop bewegen kann
class CardWidget extends StatelessWidget {
  final String assetName;

  const CardWidget({required this.assetName, super.key});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: assetName,
      feedback: Material(
        color: Colors.transparent,
        child: Image.asset(
          'assets/Laub/$assetName',
          width: 80,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Image.asset(
          'assets/Laub/$assetName',
          width: 80,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
      child: Image.asset(
        'assets/Laub/$assetName',
        width: 80,
        height: 120,
        fit: BoxFit.cover,
      ),
    );
  }
}
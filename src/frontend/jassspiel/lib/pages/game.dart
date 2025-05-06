import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class Game extends StatelessWidget {
  const Game({super.key});

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
      appBar: AppBar(title: const Text('Jass Spiel')),
      body: Center(
        child: CardHand(cards: laubCards),
      ),
    );
  }
}

class CardHand extends StatelessWidget {
  final List<String> cards;

  const CardHand({required this.cards, super.key});

  @override
  Widget build(BuildContext context) {
    final double radius = 300;
    final double maxAngle = 30;

    return SizedBox(
      width: radius * 2,
      height: radius,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(cards.length, (i) {
          final t = cards.length == 1 ? 0.5 : i / (cards.length - 1);
          final angleDeg = lerpDouble(-maxAngle, maxAngle, t)!;
          final angle = angleDeg * pi / 180;

          final x = radius * sin(angle);
          final y = radius * (1 - cos(angle));

          return Transform.translate(
            offset: Offset(x, -y),
            child: Transform.rotate(
              angle: angle,
              child: CardWidget(assetName: cards[i]),
            ),
          );
        }),
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final String assetName;

  const CardWidget({required this.assetName, super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Laub/$assetName',
      width: 80,
      height: 120,
      fit: BoxFit.cover,
    );
  }
}

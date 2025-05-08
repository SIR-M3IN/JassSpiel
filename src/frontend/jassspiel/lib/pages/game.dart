import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class Game extends StatelessWidget {
    @override
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
    final double radius = 500;
    final double maxAngle = 20;
    final double curveHeight = 50; // Bogen-Höhe

    return SizedBox(
      width: radius * 2,
      height: curveHeight + 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(cards.length, (i) {
          final t = cards.length == 1 ? 0.5 : i / (cards.length - 1);
          final angleDeg = lerpDouble(-maxAngle, maxAngle, t)!;
          final angle = angleDeg * pi / 180;

          final x = radius * sin(angle);
          final y = (4 * pow(t - 0.5, 2) - 1) * curveHeight;

          return Transform.translate(
            offset: Offset(x, y),
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

class CardWidget extends StatefulWidget {
  final String assetName;

  const CardWidget({required this.assetName, super.key});

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(isHovered ? 1.2 : 1.0)
          ..translate(0.0, isHovered ? -20.0 : 0.0),
        child: Image.asset(
          'assets/Laub/${widget.assetName}',
          width: 80,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
/// Enthält den Dialog für die Trumpf-Farben-Auswahl.
///
/// Diese Datei definiert die [showTrumpfDialog]-Funktion, die einen modalen Dialog anzeigt,
/// in dem der Spieler die Trumpf-Farbe für die aktuelle Runde auswählen kann.
/// Der Dialog zeigt optional die Karten des Spielers als Hilfestellung an.
import 'package:flutter/material.dart';
import 'package:jassspiel/jasskarte.dart';

/// Zeigt einen Dialog zur Auswahl der Trumpf-Farbe an.
///
/// Öffnet einen modalen Dialog, der den Spieler auffordert, eine der vier
/// Farben (Herz, Laub, Schella, Eichel) als Trumpf zu wählen. Der Dialog kann nicht
/// geschlossen werden, ohne eine Auswahl zu treffen.
///
/// [context] Der BuildContext des aufrufenden Widgets.
/// [playerCards] Optionale Liste von [Jasskarte], die dem Spieler gehören,
///   welche im Dialog als Hilfestellung angezeigt werden.
/// 
/// Gibt einen [Future] zurück, der mit der ausgewählten Trumpf-Farbe als String
/// (z.B. 'Herz') abgeschlossen wird, oder null, falls der Dialog anderweitig geschlossen wird.
Future<String?> showTrumpfDialog(BuildContext context, {List<Jasskarte>? playerCards}) {
  String? selectedTrumpf;

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return PopScope(
            canPop: false, // Prevent back button from closing dialog
            child: Dialog(
            backgroundColor: Colors.transparent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final dialogWidth = (screenWidth * 0.9).clamp(300.0, 800.0);
                final availableHeight = screenHeight * 0.9;
                final desiredMinHeight = 400.0;
                final actualMinHeight = availableHeight < desiredMinHeight ? availableHeight : desiredMinHeight;
                return Center(
                  child: Container(
                    width: dialogWidth,
                    constraints: BoxConstraints(
                      minHeight: actualMinHeight,
                      maxHeight: availableHeight,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.deepPurple,
                          Colors.indigo,
                          Colors.blue,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [                            Text(
                              '🎴 Trumpf wählen',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Du musst einen Trumpf wählen!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 16),
                            if (playerCards != null && playerCards.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '🃏 Deine Karten',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      SizedBox(
                                        height: 80,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: playerCards.length,
                                          itemBuilder: (context, i) {
                                            final karte = playerCards[i];
                                            return Container(
                                              margin: EdgeInsets.only(right: i < playerCards.length - 1 ? 6 : 0),
                                              width: 60,
                                              height: 75,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.asset(karte.path, fit: BoxFit.cover),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildTrumpfOption('♥️ Herz', 'Herz', selectedTrumpf, (newValue) {
                                      setState(() {
                                        selectedTrumpf = newValue;
                                      });
                                    }, Colors.red),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTrumpfOption('🍃 Laub', 'Laub', selectedTrumpf, (newValue) {
                                      setState(() {
                                        selectedTrumpf = newValue;
                                      });
                                    }, Colors.green),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTrumpfOption('🔔 Schella', 'Schella', selectedTrumpf, (newValue) {
                                      setState(() {
                                        selectedTrumpf = newValue;
                                      });
                                    }, Colors.orange),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTrumpfOption('🌰 Eichel', 'Eichel', selectedTrumpf, (newValue) {
                                      setState(() {
                                        selectedTrumpf = newValue;
                                      });
                                    }, Colors.brown),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: selectedTrumpf != null
                                    ? () {
                                        Navigator.of(context).pop(selectedTrumpf);
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 5,
                                ),                                child: Text(
                                  'Bestätigen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),                    ),
                  ),
                );              },            ),
            ),
          );
        },
      );
    },
  );
}

/// Creates a single selection option for a trump suit.
///
/// This private helper widget renders a [RadioListTile] for a trump suit.
/// It visually highlights the selected option.
///
/// [title] The text displayed on the button (e.g. '♥️ Herz').
/// [value] The internal value of the option (e.g. 'Herz').
/// [selectedValue] The currently selected value to control highlighting.
/// [onChanged] Callback function called when the option is selected.
/// [color] The color used for highlighting.
/// 
/// Returns a widget representing the trump selection option.
Widget _buildTrumpfOption(String title, String value, String? selectedValue, Function(String?) onChanged, Color color) {
  final isSelected = selectedValue == value;
  return Container(
    decoration: BoxDecoration(
      color: isSelected ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected ? color : Colors.white.withOpacity(0.3),
        width: 2,
      ),
    ),
    child: RadioListTile<String>(
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
      value: value,
      groupValue: selectedValue,
      activeColor: color,
      onChanged: onChanged,
    ),
  );
}

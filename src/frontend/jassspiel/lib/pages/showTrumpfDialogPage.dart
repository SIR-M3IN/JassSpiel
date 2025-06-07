import 'package:flutter/material.dart';


Future<String?> showTrumpfDialog(BuildContext context) {
  String? _selectedTrumpf; // speichert, was gerade ausgewählt ist

  return showDialog<String>(
    context: context,
    barrierDismissible: false, // Klick außerhalb schließt den Dialog nicht automatisch
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Trumpf wählen'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Herz'),
                    value: 'Herz',
                    groupValue: _selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        _selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Laub'),
                    value: 'Laub',
                    groupValue: _selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        _selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Schella'),
                    value: 'Schella',
                    groupValue: _selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        _selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Eichel'),
                    value: 'Eichel',
                    groupValue: _selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        _selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Von Oben'),
                    value: 'Von Oben',
                    groupValue: _selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        _selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Von Unten'),
                    value: 'Von Unten',
                    groupValue: _selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        _selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Slalom'),
                    value: 'Slalom',
                    groupValue: _selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        _selectedTrumpf = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              // Button „Schiaba“ fungiert hier als „Abbrechen / kein Trumpf“
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop('Schiaba');
                },
                child: const Text('Schiaba'),
              ),
              // Button „Bestätigen“ gibt den gewählten Trumpf zurück, wenn einer ausgewählt wurde
              TextButton(
                onPressed: _selectedTrumpf != null
                    ? () {
                        Navigator.of(context).pop(_selectedTrumpf);
                      }
                    : null, // ist nichts gewählt, ist der Button deaktiviert
                child: const Text('Bestätigen'),
              ),
            ],
          );
        },
      );
    },
  );
}

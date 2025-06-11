import 'package:flutter/material.dart';


Future<String?> showTrumpfDialog(BuildContext context) {
  String? selectedTrumpf; // speichert, was gerade ausgewählt ist

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
                    groupValue: selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Laub'),
                    value: 'Laub',
                    groupValue: selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Schella'),
                    value: 'Schella',
                    groupValue: selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        selectedTrumpf = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Eichel'),
                    value: 'Eichel',
                    groupValue: selectedTrumpf,
                    onChanged: (value) {
                      setState(() {
                        selectedTrumpf = value;
                      });
                    },
                  ),
                  // RadioListTile<String>(
                  //   title: const Text('Von Oben'),
                  //   value: 'Von Oben',
                  //   groupValue: selectedTrumpf,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       selectedTrumpf = value;
                  //     });
                  //   },
                  // ),
                  // RadioListTile<String>(
                  //   title: const Text('Von Unten'),
                  //   value: 'Von Unten',
                  //   groupValue: selectedTrumpf,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       selectedTrumpf = value;
                  //     });
                  //   },
                  // ),
                  // RadioListTile<String>(
                  //   title: const Text('Slalom'),
                  //   value: 'Slalom',
                  //   groupValue: selectedTrumpf,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       selectedTrumpf = value;
                  //     });
                  //   },
                  // ),
                ],
              ),
            ),            actions: [
              TextButton(
                onPressed: selectedTrumpf != null
                    ? () {
                        Navigator.of(context).pop(selectedTrumpf);
                      }
                    : null,
                child: const Text('Bestätigen'),
              ),
            ],
          );
        },
      );
    },
  );
}

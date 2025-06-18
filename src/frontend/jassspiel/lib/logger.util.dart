import 'package:logger/logger.dart';

/// Erstellt und gibt eine konfigurierte Logger-Instanz für die Anwendung zurück.
///
/// Der Logger ist konfiguriert mit:
/// - Zeilenlänge von 90 Zeichen
/// - Deaktivierte Farben für bessere Konsolen-Lesbarkeit
/// - Begrenzte Methodenanzahl für sauberere Ausgabe
/// - Erweiterte Fehler-Methodenanzahl für Debugging
///
/// Gibt eine [Logger]-Instanz zurück, die bereit für den Einsatz in der gesamten Anwendung ist.
Logger getLogger() {
  return Logger(
    printer: PrettyPrinter(
      lineLength: 90,
      colors: false,
      methodCount: 1,
      errorMethodCount: 5,
    ),
  );
}
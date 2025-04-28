# Projektidee

Wir entwickeln eine **Vorarlberg Jass App**.

Damit erfüllen wir die Projektanforderungen:

## Frontend (POS)

- Flutter-App mit mindestens 3 Screens (z.B. Startseite, Spiel erstellen, Spielübersicht).
- Verwendung von GIT & GitHub (mit Kanban-Board).
- Einsatz von abstrakten Klassen und Vererbung:
  - **Abstrakte Klasse:** Modi
    - Eigenschaften: Spieleranzahl, Karten pro Spieler, Wer macht Trumpf
  - **Interface:** Spielkarte
    - Eigenschaften: Farbe (Herz, Kreuz, Pik, Karo), Wert (7, 8, 9, 10, Unter, Ober, König, Ass), Punktwert (z.B. 0, 0, 0, 0, 10, 2, 3, 4, 11 usw.)
- Unit-Tests, z.B. für Regeln

## Backend (DBI)

- MariaDB-Datenbank für Spieler-, Spiele- und Ergebnisdaten.
- REST-API (z.B. Python FastAPI) für die Kommunikation zwischen Frontend und Backend.
- Benutzerrollen: „admin“ und „user“.
- API-Endpunkte zur Abfrage von:
  - aktuellem Spielstand
  - Punkten
  - Rankings

## Must-Have Features

- Fixe Jass-Regeln (Vorarlberger Jass)
- Modus Kreuzjassen
- Speicherung von Spielen und Spielergebnissen

## Nice-to-Have Features

- Multiplayer-Modus (Lobby-System) (z.B. über Firebase)
- KI-Gegner
- Karten-Skins
- Mehr Spielmodi
- Schöne Animationen und Übergänge

## Technik

- **Flutter** bietet viele vorgefertigte UI-Elemente, gute Performance für Spiele, gute Dokumentation (auch für Games) und unterstützt Multi-Platform-Entwicklung (auch Web).
- **FastAPI (Python)** ermöglicht uns eine schnelle und flexible Entwicklung der REST-API.
- **MariaDB** Speicherung aller Spiel- und Userdaten.
- **Firebase** vielleicht für multiplayer.

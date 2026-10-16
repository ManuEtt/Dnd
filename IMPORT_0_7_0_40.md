# Würfelraunen 0.7.0+40 – Import

## Ausgangsbasis

Repository `ManuEtt/Dnd`, Commit `7cd36e9bcb7a4533d34bcc95a77ba83d86c2fc4e` (`0.6.9+39`). Das vollständige ZIP enthält das komplette Flutter-/Android-/Backend-Projekt und die Testdateien.

## Aktualisierung

Bei Verwendung des Patch-Pakets muss genau der obige Commit zugrunde liegen. Neue vollständige ZIP-Datei in ein neues, leeres Verzeichnis entpacken, GitHub-Dateien im Repo entsprechend ersetzen/hinzufügen. GitHub Actions führt den normalen Flutter-/Backend-Build aus. Vor produktiver Verwendung Dart-/Flutter-Analyse, Tests und APK-Build prüfen.

Eine bereits installierte APK oder bestehende Datenbank wird durch das ZIP nicht automatisch verändert. Import und bestehende Android-App gesondert behandeln.

## Offene Punkte

Siehe `docs/MONK_FOCUS_0_7_0.md`, insbesondere nicht implementierte Flurry-of-Blows- und Positionsregeln.

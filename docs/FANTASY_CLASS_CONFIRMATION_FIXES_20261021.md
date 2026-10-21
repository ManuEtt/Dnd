# Fantasy-Klassenassistent und Regressionstests (2026-10-21)

## Ausgangslage
Pull Request #97 wurde zusammengeführt, aber die GitHub-Actions-Läufe #39649855710 und #39649819470 scheiterten bei `dart format --output=none --set-exit-if-changed lib test`. Zudem prüften zwei bestehende Charaktereditor-Widgettests noch auf `FilledButton`, obwohl das Inventarformular bereits `FantasyTextButton` verwendet.

## Umsetzung
- Entfernt eine zusätzliche Leerzeile im Inventar-Speichern-Callback, die die Dart-Formatprüfung auslöste.
- Angepasst: zwei bestehende Inventar-Speichern-Widgettests erwarten `FantasyTextButton` statt `FilledButton`.
- Migriert: Bestätigen und Abbrechen des SRD-Klassenassistenten verwenden die wiederverwendbaren Fantasy-Schaltflächen. `srd-confirm-class` und das Original-`onPressed`-Prädikat bleiben erhalten.
- Neue Regressionstests: Abgebrochene manuelle Gegenstandserstellung übernimmt nichts; unvollständiger Klassenassistent zeigt eine deaktivierte Bestätigung und kann ohne Übernahme abgebrochen werden.
- Der vorhandene Barden-Startausrüstungstest prüft zusätzlich, dass die Bestätigung über den neuen Button tatsächlich aktiviert ist.

## Grenzen
Keine Änderung an SRD-Regeln, Klassen-/Ausrüstungsdaten, Trefferpunkten, Charakterpersistenz oder Navigation. Die GitHub-CI ist die maßgebliche Prüfung für Formatierung, statische Analyse, Widgettests und Android-Artefakte.

## Prüfbefehle
```sh
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

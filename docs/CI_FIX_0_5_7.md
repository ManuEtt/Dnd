# CI-Korrektur 0.5.7+27

Basis: GitHub `ManuEtt/Dnd`, `main`-Commit `42b9ad37efcfce29bab62a1eae6fcbcc47a7ef73`.

Der CI-Lauf https://github.com/ManuEtt/Dnd/actions/runs/38729844876 erzielte 351 bestandene und einen fehlgeschlagenen Flutter-Test. `flutter analyze`, Node-Backend und Strukturtests bestanden. Fehler in `ui_character_editor_test.dart`: `StateError: Bad state: No element` aus `WidgetController.scrollUntilVisible` bei „Gegenstand hinzufügen“.

## Änderung

1. `app/lib/ui/character_editor.dart`: stabilen `ValueKey('character-inventory-add')` für den vorhandenen Button ergänzen.
2. `app/test/ui_character_editor_test.dart`: statt eines 500-dp-Sprungs 160-dp-Drag-Schritte auf der echten Editor-`ListView`; nach jedem Schritt pumpen, bis der Button hit-testbar ist. Maximale Schritte begrenzt; danach strikte Erwartung und normale Benutzerinteraktion einschließlich Speichern/Anzahl.
3. `app/pubspec.yaml`: Entwicklungsnummer 0.5.7+27.

## Ausstehende Verifikation

````bash
cd app
flutter pub get
flutter analyze
flutter test test/ui_character_editor_test.dart
flutter test
flutter build apk --debug
````

Die Korrektur ist **nicht** als in Flutter getestet gekennzeichnet. Keine Datei `.github/workflows/autonomous-development.yml` hinzufügen.

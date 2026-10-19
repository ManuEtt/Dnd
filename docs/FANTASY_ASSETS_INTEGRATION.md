# Fantasy-Grafiken: Originalrahmen (Oktober 2026)

## Eingebaut

- Die ursprüngliche Nachtkulisse, die goldenen Symbole und die neun Bildvorlagen bleiben im Repository offline verfügbar.
- Neu: `app/assets/fantasy/ornate_gold_corner.webp` ist ein aus der vom Nutzer bereitgestellten `frames_concept.png` geschnittenes, freigestelltes Goldornament. Es wird gespiegelt an den vier Ecken gerendert, **ohne Strecken** und ohne die Touch-Ziele zu überdecken.
- Der Rahmen ist als `FantasyApprovedCornerFrame` wiederverwendbar und wird in Panels, Schnellaktionen und Charakterporträts eingesetzt.
- Die Charakterbildauswahl ordnet Vorschaubild und Bedienelemente auf schmalen Displays untereinander an; langes Drücken öffnet eine größere Ansicht. Auswahl, eigenes Foto, Löschen und Übernehmen bleiben erhalten.
- Kein Eingriff in D&D-Regeln, Kampagnenstatus, Speicherformat oder bestehende Charakterbilder.

## Noch offen

- Neun einzeln gespeicherte Porträts mit 256 × 256 Pixeln aus dem hochgeladenen ZIP sind **noch nicht** als Einzeldateien im GitHub-Repository integriert: Der derzeitige Porträtatlas ist 288 × 288 Pixel (96 × 96 je Motiv).
- Die weiteren im ursprünglichen Konzeptbogen gezeichneten vollständigen Menü- und Buttonrahmen sind noch nicht als separate skalierbare Assets eingebaut.
- Das Layout und die Grafiken sind nur durch CI bzw. Flutter-Widget-Tests, noch nicht durch Abnahme auf einem physischen Androidgerät geprüft.

## Prüfen

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Widgettests: `app/test/original_fantasy_frame_test.dart`.

Die Goldornamente sind dekorativ. Texte und Interaktionen sind weiterhin echte Flutter-Widgets, keine in Bilder gerenderten Bedienelemente.

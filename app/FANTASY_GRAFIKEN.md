# Würfelraunen – neue Fantasy-Grafiken (2026-10-19)

Die Oberfläche verwendet echte, von der App gezeichnete Fantasy-Elemente,
keine statische Bildschirmabbildung. Texte, Charakterwerte, Schaltflächen,
Spielstände und alle Abenteueraktionen bleiben reale, zugängliche Flutter-Widgets.

## Grafische Bestandteile

- Sechs neue Original-Vektorrunen (W20, Kompass, Helm, Buch, Feder, Mond)
  aus `lib/ui/fantasy_experience.dart`.
- Illustrierte Startkarten, Kapitelleisten und neue Wort-Bild-Marke.
- Ein durchgehendes neues Nachtpanorama aus `lib/ui/fantasy_landscape.dart`
  mit Mondschein, Bergen, Burg, Fenstern, Sternen und Tannen.
- Im `FantasyBackdrop` liegt das Panorama unter den tatsächlichen
  App-Inhalten und fängt keine Touch-Ereignisse ab.
- Derselbe Hintergrund ist in der Charakterbogen-Ansicht sichtbar.
- Originale Portraits und UI-Rahmen bleiben WebP-Assets, werden nicht
  durch Zeichnungen ersetzt und stehen weiterhin offline bereit.

## Reale Ansichten

Start/Kampagnenarchiv, laufendes Abenteuer, Heldenarchiv, Charakterbogen,
Charaktereditor, Kampagnen-Chronik, Einstellungen und mobile Navigation
verwenden das gemeinsame Fantasy-Design.

Das neue Panorama ist **keine interaktive Weltkarte** und enthält keine
erfundenen Quests, Gegner oder Charakterwerte. Es ist reine Dekoration.

## Prüfen und testen

```bash
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Die Regressionstests `test/moonlit_scenery_test.dart` prüfen die
Benutzbarkeit auf 320, 360 und 1024 logischen Pixeln und denselben
Hintergrund im Charakterbogen. Die vorhandenen Gesamttests prüfen den
restlichen Spielbetrieb. APKs müssen über den grünen GitHub-Actions-Lauf
der jeweiligen Revision bezogen werden.

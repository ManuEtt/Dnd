# Würfelraunen – durchgängige Fantasy-Oberfläche (19.10.2026)

## Gestaltung

Als Designreferenz dient eine neu entworfene Würfelraunen-Konzeptillustration:
mondbeschienene Festung, warme Laternen, dunkles Metall, Goldornamente und
deutsche, klar lesbare Beschriftungen. Die Konzeptillustration ist eine
**Gestaltungsvorlage**, keine Behauptung, dass ihre gesamte Collage als
einzelnes App-Hintergrundbild eingebettet wäre.

Die **tatsächlich implementierten** neuen Grafiken liegen als zeichnungs- und
skalierungsunabhängige Flutter-Vektorelemente unter
`app/lib/ui/fantasy_experience.dart`:
- `FantasyRuneEmblem`: sechs eigens gezeichnete Siegel für W20, Kompass,
  Heldenhelm, Buch, Schreibfeder und Mond;
- `FantasyBrandPlaque`: der markante Würfelraunen-Titel mit goldener Rune;
- `FantasyJourneyCard`: responsives, illustriertes Navigationsmotiv mit
  echten `onTap`-Aktionen und vorhandenen lizenzierten Projekt-Illustrationen;
- `FantasyChapterHeading`: ornamentierte Abschnittstrenner;
- `_FantasyStarlightPainter` in `fantasy_ui.dart`: goldene Sternzeichen
  und dezente geometrische Lichtkreise auf allen Hauptseiten.

## Tatsächliche Screens

1. **Startseite:** neue Markenplakette, vier illustrierte Einstiegswege und
   weiterhin alle bisherigen Demo-/Rabenwacht-/KI-/Import-Aktionen.
2. **Abenteuer:** Kompass-Siegel im Charakter-/Kampagnenkopf; originale
   Illustrationen und die unten fixierten Schnellaktionen bleiben erhalten.
3. **Helden:** Archivüberschrift mit Helden-Siegel, vorhandene Originalporträts
   und echte Charakterdaten. Charakterbearbeitung und Charakterbogen erhalten
   das neue Heldenemblem.
4. **Chronik:** Feder-Siegel und illustrierter Einstieg; Erinnerungen,
   Aufträge, Orte und Ereignisse bleiben aus dem tatsächlichen Spielstand.
5. **Einstellungen:** verzierte Gruppenüberschriften mit thematisch
   unterschiedlichen Symbolen. Alle TTS-/Backend-/Datenschutzaktionen bleiben.
6. **Wiederverwendbare Widgets:** Banner mit Mond-Siegel, illustrierte
   Kampagnenkarten mit Kompass-Zeichen, Szenenillustrationen mit Feder-Siegel,
   gemeinsame Theme- und Sternenflächen.

## Grenzen

Es wird **keine** erfundene interaktive Weltkarte und keine simulierte
KI-Kampagne hinzugefügt. Die vorhandenen 13 Original-WebP-Dateien bleiben
identisch, und neue Vektorgrafiken benötigen keine Netzverbindung oder
zusätzliche Assets. Charakterwerte, Würfelregeln, SQL/SQLite, Exporte,
Backend und Spielstände werden nicht verändert.

## Qualität

- Mehrere Android-Größen: 320, 360 und 960 logische Pixel.
- Neu angelegte `app/test/visual_redesign_test.dart` prüfen Siegel,
  Navigationstipp und Layout ohne Flutter-Exceptions.
- Bestehende `flutter test`, `flutter analyze` und Android-Build ausführen.
- Erst nach grüner CI auf `main` eine installierbare Release-Version als
  geprüft bezeichnen.

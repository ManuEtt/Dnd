# Würfelraunen – dekorative Charakterbogen-Ornamente (22.10.2026)

## Designbasis

Die vom Nutzer ausgewählte Fantasy-Charakterbogen-Vorlage zeigt ein
rund gefasstes Heldinnenporträt, runenförmige Metallzier, vergoldete
Karten und eine gealterte Pergamenttafel. Die Vorlage enthält jedoch
Beispielporträts und Dummywerte, die **nicht** in Spielstände oder die
laufende Charakteransicht übernommen werden dürfen.

Ausgangsstand: `main` = `012579022fd547c9ec02faada991f3f3836399d9`.
Die CI dieses Commits war beim Einstieg vollständig erfolgreich.

## IMPLEMENTIERT

- Neue, quelloffene Flutter-Vektorgrafik in
  `app/lib/ui/fantasy_character_ornaments.dart`:
  `FantasyPortraitMedallion` mit zwei goldenen Porträtringen,
  Kompassjuwelen und feinen Strahlen sowie
  `FantasyEngravedFrame` mit vier Zier-Ecken, dünnem
  Doppelrahmen und mittleren Rauten.
- Der Header in `app/lib/ui/fantasy_character_sheet.dart` nutzt
  die Medaillonfassung. **Echter** gespeicherter Porträt-Preset
  oder Fotodatensatz bleibt erhalten; alte Figuren ohne Porträt
  behalten das Initialen-Fallback.
- Pergamentattribute und alle vier Fantasy-Informationskarten in
  `app/lib/ui/fantasy_character_overview.dart` verwenden
  skalierbare Filigranverzierungen. `IgnorePointer` schützt
  die Bedienbarkeit ihrer vorhandenen `Alle anzeigen`-Buttons.
- Keine neuen Grafikpakete, kein externes Asset-Hosting, keine
  Änderung an `HeroCharacter`, `Campaign`, Kampfregeln,
  Speicherschema oder der bereits feststehenden Schnellaktionsleiste.
  Das Erscheinungsbild basiert auf kontrollierbaren Canvas-Pfaden,
  nicht auf einer flachen Screenshot-Grafik.

## GEPLANTE / DURCHGEFÜHRTE TESTS

- `app/test/fantasy_character_ornaments_test.dart`:
  Runenporträt mit Kindinhalt und antippbarem Parent,
  320/360/820dp-Pergamenttafel samt vier Karten,
  zugängliche Kartenaktion trotz Ornament,
  320dp und 1,4-fache Textskalierung, historischer
  Charakterbogen ohne Porträt und ohne Spieldatenmutationen.
- Bestandssuite für Charakterbogen und Schnellaktionen,
  Flutter-Analyse und Android-Debug-/Alpha-Build per Actions.

## Abnahme und Grenzen

**GETESTET:** Nur nach beobachtbar erfolgreich abgeschlossener CI
für den exakten Entwicklungscommit markieren.

**NICHT GETESTET:** Pixelgenauer manueller Vergleich auf einem realen
Android-Gerät, Lesbarkeit bei sämtlichen Display-/Schriftgrößen
und GPU-Performance aller älteren Android-Hardware.

**BLOCKIERT:** Vollständige Bild-zu-Bild-Gleichheit mit der
Illustrationsvorlage. Die tatsächliche Vorlage enthält illustrative
Beispielcharaktere und komplexe gezeichnete Hintergründe; eine
buchstäbliche Bildschirmbild-Kopie würde die dynamischen Spielwerte
unbrauchbar machen.

**NOCH NICHT IMPLEMENTIERT:** Vollständige Bildmanufaktur für
jedes Klassenporträt und jedes einzelne Zaubersymbol. Bestehende
legale und lokale Benutzerporträts bleiben priorisiert.

# Charakterbogen – Referenzdesign-Umsetzung (22.10.2026)

## Ausgangspunkt
Referenz: vom Nutzer bestätigtes Designbild des Fantasy-Charakterbogens
mit großem Porträt, blau-schwarzer Oberfläche, goldenen Ornamenten,
pergamentfarbenen Attributkarten, Fertigkeiten-/Zauber-/Zustände-/
Ausrüstungsübersichten und einer festen unteren Aktionsleiste.

Basis `main`: `8c2cb724d2a60700adbcb0953f2f42a977330b9b`.

## Implementierung

- `app/lib/ui/fantasy_character_sheet.dart`:
  Das Heldenporträt zeigt das bereits gespeicherte Porträtfoto oder
  Preset mit rundem Goldrahmen; andernfalls erscheinen Initialen statt
  eines erfundenen Heldenbildes. Kopfbereich mit integriertem
  Fantasy-Schloss aus dem vorhandenen, offline nutzbaren Asset.
  Vier Statuskacheln mit TP-Leiste, RK, Initiative und Bewegung
  verwenden die Regeln und bestätigten Charakterwerte.
  Detailtabs (Attribute, Zustände, Verteidigung) und Bearbeiten
  bleiben zugänglich.
- `app/lib/ui/fantasy_character_overview.dart`:
  Wiederverwendbare, responsive 6er-Attributgrafik auf hellem
  Pergament mit Runenmedaillons. Auf 320–400 dp 3×2,
  bei ausreichend Breite 6×1, niemals unleserlich sechs enge
  Spalten auf einem schmalen Telefon. Die vier dunkel gerahmten
  Kategoriekarten zeigen echte gespeicherte Fertigkeiten,
  bekannte Zauber, effektive Zustände und Ausrüstung. „Alle anzeigen“
  öffnet eine Detailansicht. Zaubergrad/Angriffsschaden/Reichweite
  werden **nicht** aus einer Bezeichnung erfunden.
- Feste Aktionsleiste: Charakter zum Anfang, Inventar-/Zauberliste,
  W20 mit tatsächlicher Rückkehr zum bestehenden
  `_AdventureState._roll` und bestätigtem Würfeldialog,
  „Mehr“ mit Detailbereichen. Im Heldenarchiv ohne
  Abenteuerkontext wird kein Würfelergebnis erfunden:
  stattdessen erscheint eine erklärende Dialogmeldung.
  Alle Elemente sind Flutter-Widgets, keine Bild-Hotspots.
- Vorhandene Fantasy-Artwork-Dateien, FantasyOrnaments,
  FantasyApprovedCornerFrame und Porträtatlas werden
  ohne zusätzliche Asset-Abhängigkeit wiederverwendet.
  Das Designbild ist eine visuelle Zielvorgabe, keine feste
  Screenshot-Oberfläche; dynamische Namen, Werte und
  Textvergrößerung dürfen davon abweichen.
- Keine Datenbank- oder Schemaänderung, keine automatische
  Charakteränderung beim Zeichnen und keine KI-erfundenen Werte.

## Tests
`app/test/fantasy_character_reference_design_test.dart` für
320/360/400/820 dp, sechs Attribute, TP/RK und festes W20,
echte Verknüpfung, Archivfallback, größere Systemschrift und
alte unvollständige Charaktere.
Bestehende Tests in `app/test/fantasy_character_sheet_test.dart`
sichern Detailnavigation, Rettungswürfe, Erschöpfung,
Zustandsquellen und Bearbeiten.

**IMPLEMENTIERT:** Referenzdesign als dynamische Flutter-Oberfläche.

**GETESTET:** erst nach abgeschlossenem GitHub-Actions-Erfolg.
**NICHT GETESTET:** manuelle visuelle Abnahme auf echtem Android-Gerät.
**BLOCKIERT:** pixelidentische Verwendung des generierten
Konzeptbildes als native verschachtelte Assets (absichtlich
zugunsten dynamischer Widget- und Textgrößenanpassung vermieden).
**NOCH NICHT IMPLEMENTIERT:** aus SRD-Referenzen ungeprüfte
Ausrüstungs- und Zauberstatistiken werden nicht in der Vorschau
als bestätigt angezeigt.

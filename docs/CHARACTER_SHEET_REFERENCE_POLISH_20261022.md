# Würfelraunen – Charakterbogen-Designabgleich und Schnellaktionsprüfung

Datum: 22. Oktober 2026. Ausgangsstand `main`:
`c66607ad0363d79a091ad2309c1d1cfc7c5d6c8a`.

## Anlass und überprüfter Ausgangspunkt

Die vorherige Umsetzung von PR #116 hatte eine zweite
`_ReferenceCharacterDashboard`-Kopie des Referenzdesigns direkt in
`fantasy_character_sheet.dart` angelegt. Zugleich existierte bereits die
umfangreichere `FantasyCharacterOverview` mit stilisierten
Pergamentattributen, vier Fantasy-Panels, regelgebundenen Fertigkeitsboni,
kontextspezifischen Zustands- und Ausrüstungsdaten und Karten mit
`Alle anzeigen`-Aktionen.

Die zweite Implementierung stellte unter **Fertigkeiten** nur
Grundattribute dar, nicht die tatsächlich bestätigten Fertigkeitswürfe.
Sie war damit optisch und fachlich hinter dem vorhandenen Referenzdesign.
Auch die zwei Varianten erschwerten langfristige Korrekturen.

## IMPLEMENTIERT

1. Charakterbogen verwendet nun **`FantasyCharacterOverview(hero: hero)`**
   statt der doppelten, nur rudimentären
   `_ReferenceCharacterDashboard`. Die Kopie einschließlich ihrer
   duplizierten Kacheln wurde entfernt. Die bestehende Kopf-/Porträtgrafik,
   Trefferpunkte, RK, Initiative, Bewegung und Detailsektionen bleiben
   unverändert erhalten.
2. Die angezeigten Fertigkeitsboni stammen aus
   `CharacterRuleEngine.abilityCheck` mit echten bestätigten
   Fähigkeiten, Übungsbonus und – sofern applicable – Klassenregeln;
   die Oberfläche erfindet keine unbekannten Charakterwerte.
3. `FantasyCharacterQuickNavigation` wurde visuell verbessert:
   dunkler Runen-/Metall-Hintergrund mit Goldleiste, aktiver
   Charakter-Tab, zentraler selbst gezeichneter W20 auf blauem
   Arkankreis, mindestens 66dp hohe Seitenschaltflächen,
   Beschriftungen sowie `Semantics` und Tooltips.
   Die Leiste ist weiterhin `Scaffold.bottomNavigationBar` und
   wird nicht in die scrollbare Charakteransicht gezogen.
4. Alle fünf bisherigen Aktionsrückrufe (Charakter, Inventar,
   Würfeln, Zauber, Mehr) bleiben erhalten. Die Würfelaktion
   beauftragt nur den vorhandenen Callback; ohne aktives Abenteuer
   behauptet sie weiterhin keinen Würfelwurf.

## Testnachweis

`app/test/fantasy_sheet_reference_unification_test.dart` prüft
fachliche Boni (z. B. Medizin und Wahrnehmung +7 bei Weisheit 18
und Übung auf Stufe 5), Referenz-Karten,
320/360/820dp, sicht-/antippbare feste Schnellaktionen nach Scrollen,
tatsächliche Callback-Auslösung, größere Systemschrift und
historische Charakterbögen ohne bestätigte Daten.

Zusätzliche Bestandsprüfungen:
`app/test/fantasy_character_reference_design_test.dart`,
`app/test/fantasy_character_sheet_test.dart`,
`app/test/fantasy_pinned_actions_test.dart`.
Der letzte Test prüft die **separate** Schnellaktionsleiste
des Abenteuermodus; deren bewährte feste Position und Aktionstrigger
bleiben unberührt.

## Abgrenzung

- Der Referenzentwurf enthält beispielhafte Porträts und Werte.
  Die App verwendet ausschließlich das tatsächliche, vom Spieler
  bestätigte Porträt sowie echte Spielfigurdaten.
- Grafikkomposition, Hintergründe, Schriften und Abstände werden mit
  vorhandenen Flutter-Widgets und genehmigten App-Assets nachgebildet;
  keine Bildschirmgrafik mit eingebrannten Dummywerten.
- Vollständige visuelle Pixelabnahme und Test auf echtem Android-Gerät
  bleiben offen. Erfolg von Flutter-Analyse, Tests und APK-Build
  wird erst nach abgeschlossener CI als GETESTET dokumentiert.

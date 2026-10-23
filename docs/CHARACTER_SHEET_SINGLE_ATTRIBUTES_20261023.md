# Würfelraunen – doppelte Attribute im Charakterbogen beseitigen

Datum: 23.10.2026. Ausgangsstand `main`:
`008ddb37a23dccb834724443986ff7ae04745abc`.

## IST: festgestellter Darstellungsfehler

Auf der ersten Charakterbogenseite wurden dieselben sechs Attribute
zweimal gerendert:

1. Die stilisierte Pergamentübersicht
   `FantasyCharacterOverview._ParchmentAbilities`
   mit sechs Attributwerten und Modifikatoren.
2. Die noch vorhandene Legacy-Detailgruppe
   `_AbilitiesSection` in `fantasy_character_sheet.dart`
   mit `sheet-abilities-grid` und sechs zusätzlichen
   `_AbilityCard`-Karten.

Die zweite Gruppe war für die Benutzenden redundant und verlängerte
den Scrollbereich unnötig.

## IMPLEMENTIERT

- Die zweite, sechs Karten umfassende Gruppe unter der Überschrift
  `Attribute` aus der Detailansicht entfernt.
- Den jetzt ungenutzten Widget-Typ `_AbilityCard` gelöscht.
- **Behalten:** einziges Pergament-Attributraster,
  Trefferpunkte/RK/Übungsbonus, alle sechs separat berechneten
  **Rettungswürfe**, Regeln zu Klassenmerkmalen, Ressourcen,
  Konzentration und Fertigkeiten.
- Detailreiter `Attribute` in `Regeln` umbenannt; im
  Schnellaktionen-Menü ist dieser unter `Regeln und Rettungswürfe`
  erreichbar.
- Für die weiterhin vorhandenen Rettungswürfe eigene stabile
  `ValueKey('sheet-saving-throw-<ability>')` vergeben,
  ohne Regeln oder Charakterdaten zu verändern.
- Keine Migration, kein Spielstandsupdate, keine Änderung am
  bestätigten Attributwert oder Übungsbonus.

## Tests und Abnahme

- `app/test/fantasy_character_sheet_test.dart` an die neue
  Struktur angepasst: ein Pergamentraster statt zwei Attributrastern,
  sechs eigenständige Rettungswürfe weiterhin erreichbar,
  schmale Screens und große Systemschrift.
- `app/test/fantasy_single_attribute_section_test.dart`
  überprüft 320/360/820dp, die einzige sichtbare
  `Attribute`-Überschrift, die sechs erhaltenen
  Rettungswürfe, die umbenannte Navigation und unverändertes
  JSON des Helden.
- Bestehende Tests für Fantasy-Referenzdesign, W20-Schnellaktionen,
  Fertigkeits- und Zustandsanzeige bleiben relevante Regressionstests.

**GETESTET:** Nach vollständigem grünen GitHub-Actions-Workflow
für den konkreten PR-Commit zu markieren.

**NICHT GETESTET:** Tatsächliche manuelle Android-Geräteabnahme.

**NOCH NICHT IMPLEMENTIERT:** Pixelgenauer Vergleich mit der
Illustrationsvorlage; dieser PR beseitigt ausschließlich die
duplizierte Datenvisualisierung.

**BLOCKIERT:** Keine bekannte fachliche Blockade für das Entfernen
der redundanten Darstellung.

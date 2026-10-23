# Charakterbogen – doppelte Attribute entfernt (23.10.2026)

## Ursache

Der Charakterbogen zeigt seit dem Fantasy-Referenzdesign das vollständige
Attributraster in `FantasyCharacterOverview`: sechs individuelle
Pergament-/Runenkarten einschließlich Wert und Modifikator. Zusätzlich
stand in `_AbilitiesSection` noch der ältere Bereich
`Attribute` mit einem zweiten `sheet-abilities-grid` und sechs
`_AbilityCard`-Kacheln. Dadurch erschienen die Attribute
beim Herunterscrollen ein zweites Mal.

## IMPLEMENTIERT

- Das **zweite, veraltete Raster** in
  `app/lib/ui/fantasy_character_sheet.dart` wird nicht mehr gerendert.
  Die ausschließlich dafür verwendete `_AbilityCard`-Klasse
  wurde entfernt.
- Das neue Pergamentraster in
  `app/lib/ui/fantasy_character_overview.dart` bleibt als
  **einzige Attributübersicht** vollständig erhalten:
  Stärke, Geschicklichkeit, Konstitution, Intelligenz,
  Weisheit und Charisma samt originalen Heldenwerten und Modifikatoren.
- Der erste Detailreiter heißt jetzt **Regeln** statt Attribute;
  das Untermenü benennt ihn **Regeln und Rettungswürfe**.
- **Nicht entfernt:** die sechs SRD-basierten
  Rettungswurf-Anzeigen samt Übungsbonus, Klassenressourcen,
  Mehrklassen-/Zauberinformationen, bestätigte Fertigkeiten,
  Portrait, Status und fixierte W20-Schnellaktionen.
- Keine Auswirkungen auf Persistenz, Kampagne, Charakterdaten
  oder den Regelzustand; es handelt sich nur um die Darstellung.

## GETESTET / NICHT GETESTET

- `app/test/character_sheet_unique_attributes_test.dart`
  überprüft 320/360/820 dp, genau sechs Karten im
  verbleibenden Pergamentraster, fehlendes Legacy-Raster,
  Umbenennung des Detailreiters, weiter bestehende
  Rettungswurf-Boni und unveränderte JSON-Daten und W20-Leiste.
- `app/test/fantasy_character_sheet_test.dart` überprüft
  das einzige Raster bei 320/360/400 dp, größere
  Android-Schrift und die vorhandenen Regelansichten.
- Regressionssuite und APK erst dann als erfolgreich dokumentieren,
  wenn GitHub Actions den exakten PR-Commit geprüft hat.
- Echte Android-Geräteabnahme weiterhin nicht durchgeführt.

# Fantasy-Dialoge: Aktionsflächen (21. Oktober 2026)

## Umfang

Nach dem Button-Grundsystem (PR #93) und der separaten Schnellaktions-
Erweiterung (PR #94) ersetzt dieses unabhängige Arbeitspaket die
bestätigenden und abbrechenden Material-Buttons in folgenden bestehenden
Spieloberflächen:

- `SpellcastingDialog`: Zauberverbrauch (Arkan), Konzentration beenden und
  Abbrechen (Eisen)
- `EquipmentCatalogDialog`: Inventar-Übernahme (Holz/Gold), Abbrechen
  (Eisen); kompakte Listen-Icons bleiben wegen kleiner Displays erhalten
- `EquipmentLoadoutDialog`: Ausrüstungswerte übernehmen (Holz/Gold),
  Abbrechen (Eisen)
- `CharacterEffectDialog`: Schaden, Heilung und temporäre Trefferpunkte
  bestätigen (Arkan), Abbrechen (Eisen)
- `ConditionEffectDialog`: bestätigte Zustandsquelle erfassen (Arkan),
  beenden (Eisen), Abbrechen (Eisen)
- `MulticlassSelectionDialog`: bestätigter Zweitklassenaufstieg (Arkan),
  Abbrechen (Eisen)
- `AbilityAssignmentDialog`: Attribute ausdrücklich übernehmen
  (Holz/Gold), Abbrechen (Eisen)

Insgesamt 15 bislang bestehende Aktionswidgets werden neu gestaltet,
einschließlich des Aktionsbuttons im Ausrüstungs-Detailblatt. Bestehende
`ValueKey`-Kennungen und Controller-Callbacks bleiben erhalten.
Nicht verfügbare Regelaktionen haben weiter `onPressed: null` und
nutzen den transparenten `disabled`-Grafikzustand.

## Sicherheitsgrenzen

Es gibt keine Änderungen an SRD-Regeln, Zauberslots, Multiclass-Vorschlägen,
XP, Charakterpersistenz, Kampagnen oder SQL. Dieses Paket enthält keine
GameState-Mutation außerhalb der bereits bestehenden Dialog-Callbacks.
Die Dialoge geben die gleichen `SpellcastingChoice`,
`EquipmentRulePreview`, `MulticlassProposal` oder anderen bestätigten
Daten wie zuvor zurück.

## Abnahme

- `app/test/fantasy_game_dialog_actions_test.dart`: grafische
  Materialzuordnung, fehlende Bestätigungsfähigkeit und Abbruchaktionen
- `app/test/ui_equipment_loadout_test.dart`: prüft weiterhin
  fehlgeschlagene/erlaubte Vorschau, bestehende ValueKeys und AC
- Alle bisherigen UI-, Integrations-, Regel- und Speicher-Tests
- Projekt-CI: Dart-Format, Flutter Analyze/Test und Android-APK-Build

Der PR bleibt bis zur erfolgreichen CI und fachlichen Prüfung eigenständig.

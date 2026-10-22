# Würfelraunen – Fantasy-Zustandskreis (22.10.2026)

## Entwicklungsziel und Regelbezug

Abgleich gegen den unveränderten `main`-Stand
`0549e3a3e7b386f1f79e46dbd6b0f81f99d29b00` (PR #110).
Keine Schemaänderung, keine neuen Pflichtfelder, keine KI-generierten
Zustände. Eine Runde wird nur aus dem bestätigten `Encounter.round`
angezeigt und niemals aus echter Zeit hochgezählt.

**SRD-Basis:** System Reference Document 5.2.1, Rules Glossary:
*Concentration*, *Incapacitated*, *Paralyzed*, *Poisoned*, *Prone* und
*Exhaustion* (CC BY 4.0, https://www.dndbeyond.com/srd/).
Die Konzentrationsregel enthält Unterbrechung bei
Handlungsunfähigkeit/Tod, anderem Konzentrationseffekt und
Konstitutionsrettungswurf nach Schaden (SG 10 oder halber Schaden,
abgerundet, maximal 30). Die Schadensrettung und Ein-Zauber-Konzentration
waren bereits vor diesem Inkrement vorhanden.

## Neu im Branch

- **SRD-CONCENTRATION-INCAPACITATED:** `ConditionEffectRules.add`
  beendet gespeicherte Konzentration innerhalb derselben bestätigten
  Zustandsänderung bei `handlungsunfähig`, `gelähmt`,
  `versteinert`, `betäubt` oder `bewusstlos`. `vergiftet` und
  `liegend` unterbrechen die Konzentration nicht automatisch.
- **SRD-CONDITION-CAUSE-TURN:** Die bestehende unabhängige
  Quellenliste und die vorhandene Auswertung der bestätigten eigenen
  Zuggrenze bleiben unverändert. Der Fantasy-Zustandskreis zeigt
  Quellen und ihre gespeicherten Endrunden, ohne eine noch nicht
  bestätigte Zauberdauer zu konstruieren.
- **UI-EFFECT-WARD:** Interaktive, aufklappbare Vektor-Runenkarten für
  Konzentration, Erschöpfung und bestehende Zustände im Kampf und
  Charakterbogen. Darstellung ausschließlich aus `HeroCharacter`
  und optional `Encounter`. Die Verwaltung nutzt unverändert den
  bestätigenden Dialog mit Revisionsprüfung.
- **Sicherheit und Rückwärtskompatibilität:** Keine Änderung an
  `HeroCharacter.toJson`, `Encounter`, `schemaVersion`, der
  Datenbank oder bestehenden Kampagnen. Keine Historie wird beim
  bloßen Anzeigen neu berechnet. Unbekannte Zauberdauern bleiben unbekannt.

## Regressionstests

- `app/test/fantasy_effect_ward_rules_test.dart`: Konzentrationsende,
  nicht lähmende Zustände, unabhängige Quellen/Begegnungen,
  Zuggrenzen und doppelte IDs.
- `app/test/fantasy_effect_ward_test.dart`: 320/360/960 dp,
  interaktive Details, bestätigte/andere Begegnungen,
  Quellen, leere historische Charaktere, nur bestätigende Aktionen.
- Bestandsabnahme: `app/test/condition_effects_test.dart`,
  `app/test/fantasy_character_sheet_test.dart`,
  `app/test/character_rule_engine_widget_test.dart` und
  gesamte GitHub-Actions-Pipeline.

**Status zum Zeitpunkt der Quellcodeänderung:**
IMPLEMENTIERT: oben beschriebener Regel- und UI-Inkrement.
NICHT LOKAL GETESTET: Flutter-SDK ist in der Ausführungsumgebung
nicht installiert. Tests/Analyse/APK nur dann als GETESTET markieren,
wenn GitHub Actions tatsächliche Erfolgsergebnisse liefert.
NICHT IMPLEMENTIERT: universelle Rundenzähler für Zauberwirkungen,
vollständige automatische Dauer aller SRD-Zauber und allgemeine
mehrzielige Zaubereffekte. Diese benötigen einen eigenen
regel- und speicherkompatiblen Integrationsschritt.

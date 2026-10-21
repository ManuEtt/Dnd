# SRD 5.2.1 – Taktisches 5-Fuß-Raster für Zauberursprünge

Stand: 21. Oktober 2026. Quelle: D&D SRD 5.2.1, *Combat / Movement and Position / Playing on a Grid*, *Spells / Targets / A Clear Path to the Target* und *Rules Glossary / Cover*. [SRD-Referenz](https://www.dndbeyond.com/srd), Lizenz CC BY 4.0.

## Implementierte Teilprüfung

`app/lib/domain/srd_spell_grid_target_rules.dart` implementiert eine begrenzte, deterministische **2D-Kartenprüfstufe**:

- Validiertes Raster von 1–200 Feldern je Achse; jedes Feld repräsentiert **5 Fuß**. Abstände zwischen den Mittelpunkten belegter Einzelfelder nutzen den maximalen Zeilen-/Spaltenabstand (ein diagonaler Schritt = ein Feld). Zahlen werden nicht aus Erzählung oder Bildschirmposition geschätzt.
- Explizit bestätigte, vollständig sperrende und auf der Ebene durchgehend vorhandene Hindernisfelder (`fullBlockers`), mit eigener `fullBlockersSurveyedConfirmed`-Freigabe. Eine unvollständig erhobene Karte wird abgelehnt, selbst wenn das Hindernis-Set leer ist.
- Prüft die gerade Verbindung **Mittelpunkt–Mittelpunkt** zwischen dem Feld des Zaubernden und einem bestätigten Ursprung. Jedes Hindernis, das dieses Segment auch nur an einer Feldkante/-ecke berührt, sperrt konservativ die Freigabe. Aus einem **gesperrten Mittelpunktstrahl** folgt nicht automatisch *vollständige Deckung*; andere freie Wege können existieren.
- Self verlangt denselben Ursprungsplatz, Touch zusätzlich eine ausdrücklich bestätigte Berührungsreichweite. Die Regeln für Sonderreichweiten, Zieleigenschaften und Flächen bleiben delegiert und werden nicht behauptet.
- Hindernis-Sets werden beim Erstellen kopiert und unveränderlich gemacht; fehlende Felder, Out-of-Bounds, Hindernisse auf Start/Ziel, ungültige Kartengrößen und widersprüchliche räumliche Quellen werden abgewiesen.
- `SrdSpellPreflightRules.preflight` unterstützt die neue optionale `gridTarget`-Eingabe als Alternative zu `targetFacts`. Beide zugleich sind verboten. Die erzeugte räumliche Prüfung wird wie zuvor im `SrdSpellCastPlan` abgelegt. **Kein direkter Abzug aus einer KI-Aussage.**
- Die vorhandene Controller-/SQLite-Integration schreibt den bestätigten Ursprungabstand ins Revisionsjournal, ohne das bestehende Speicherschema oder die dedizierten Kampfzauber zu ändern.

## Nicht abgedeckt

Es gibt derzeit **keine automatisch erfasste Karte**, keine 3D-Höhen oder Hindernisdicken, keine Überprüfung der tatsächlichen Sichtbarkeit, keine 2D-Flächenformen, keinen Nachweis des vollständigen geometrischen Deckungsgrades bei anderen Strahlen, keine Mehrfeldkreaturen und keine automatischen Zieleffekte.

Ein freier Mittelpunktstrahl ist **ein begrenzter geometrischer Nachweis unter der ausdrücklich vollständigen Karte**, kein pauschaler Beweis, dass jeder Zielpunkt/Zauber sichtbar oder erreichbar ist. Insbesondere werden halbe/Dreivierteldeckung und Sichtlinien durch Kreaturen weiterhin separat mit bestätigter `CoverRules`-Regelbasis behandelt. Der Zauberursprung ist nicht immer die betroffene Kreatur (AoE oder Self). Die spezialisierte Regelengine muss weiterhin die Zielgültigkeit und die eigentliche Wirkung bestätigen, ehe Ressourcen verbucht werden.

## Tests und Abnahme

`app/test/srd_spell_grid_target_rules_test.dart` prüft Rasterabstände einschließlich Diagonalen und Grenzwert, Blockade auf und abseits des Strahls, konservativen Eckenkontakt, unbestätigte Karten, ungültige Koordinaten, unveränderliche Hindernisdaten, Self/Touch/Sonderreichweiten und Preflight-Kombination.

`app/test/srd_spell_inventory_persistence_test.dart` lässt die Ende-zu-Ende-Speicherung über die neue geometrische Touch-Prüfung laufen und kontrolliert weiterhin SQL-Revisionsintegrität und Anti-Replay.

Maschinenlesbare Auditpunkte bleiben **partial**: `RULE-SPELLS-SPELL-RANGE`, `RULE-SPELLS-SPELL-TARGETS`, `RULE-SPELLS-SPELL-ATTACK-COVER`. Kein globaler SRD-Vollständigkeitsprozentsatz.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_grid_target_rules_test.dart
flutter test test/srd_spell_inventory_persistence_test.dart
flutter test
flutter build apk --debug
```

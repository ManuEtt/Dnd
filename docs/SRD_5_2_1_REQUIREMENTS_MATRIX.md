# SRD 5.2.1 – Regelanforderungsmatrix (laufender Aufbau)

## Startkampfwerte aus bestätigten Eingaben (19.10.2026)

**CI-Nachweis:** [39201449428](https://github.com/ManuEtt/Dnd/actions/runs/39201449428), Code-Commit `2f7ecb15`, grün. Gerätetest offen.

| ID | Referenz | Anforderung | Umsetzung | Tests | Status |
| --- | --- | --- | --- | --- | --- |
| CHAR-SPEED-SRD | Character Creation / Character Origins: Species | 30 Fuß bei 8 SRD-Spezies, 35 Fuß bei Goliath/Waldelf; unbekannte Spezies nicht raten | `srd_starting_combat_values.dart`, `models.dart`, `condition_rules.dart`, `character_editor.dart` | `srd_starting_combat_values_test.dart`, `ui_starting_combat_values_test.dart` | GETESTET (CI grün, Gerätetest offen) |
| CHAR-AC-BASE | Playing the Game: Armor Class; Classes: Unarmored Defense | Grund-RK 10 + GE, bei ungerüstetem Barbar/Mönch zusätzlich KON/WEI, nur bei bestätigten Werten | `srd_starting_combat_values.dart`, `character_editor.dart` | `srd_starting_combat_values_test.dart`, `ui_starting_combat_values_test.dart` | GETESTET (CI grün, Gerätetest offen) |
| CHAR-AC-EQUIPPED | Equipment: Armor | Rüstung und Schild nur nach aktiver Bestätigung anrechnen | `equipment_rules.dart`, `character_editor.dart` | bisherige Equipment- und neue Kampfwerttests | TEILWEISE; vollständige Sonderfälle/Regressionen offen |



## Inventar-/Charaktererstellung: neues Inkrement (19.10.2026)

| ID | SRD-Abschnitt | Anforderung | Code / UI | Persistenz / Tests | Status |
| --- | --- | --- | --- | --- | --- |
| EQUIP-START-TYPED | Classes: Starting Equipment; Equipment Tables | Alle eindeutigen Klassenstartgegenstände erhalten korrekte Katalog-ID/Preis/Gewicht/Kampf-/RK-Attribute und passende Menge | `starting_equipment_import.dart`, `character_editor.dart` | `InventoryItem.stats`, `starting_equipment_import_test.dart` | IMPLEMENTIERT_UNGETESTET (neue CI ausstehend) |
| EQUIP-IMPORT-BACKFILL | Equipment Tables | Bestätigte Katalog-ID ohne Stats sicher aus Katalog rekonstruieren; individuelle Werte wahren | `models.dart` | Import/Export/JSON-Rundlauf-Tests in `starting_equipment_import_test.dart` | IMPLEMENTIERT_UNGETESTET |
| EQUIP-LEGACY-CONFIRM | Equipment Tables | Bei historischen frei benannten Altgegenständen nur eindeutige Zuordnungen nach Bestätigung ergänzen | `character_editor.dart`, `starting_equipment_import.dart` | `ui_starting_equipment_import_test.dart` | IMPLEMENTIERT_UNGETESTET |
| EQUIP-CHOICES | Classes: Starting Equipment | Nicht eindeutige Gegenstände (Instrument, heiliges Symbol etc.) aktiv wählen lassen | Klassenassistent noch ohne spezifische Gegenstandswahl | E2E-Tests fehlen | FEHLT |
| SRD-COVERAGE-ALL | gesamtes SRD 5.2.1 | Vollständiger lizenzierter Regelkatalog mit Engine, UI, SQLite, Tests und Android-Abnahme | Noch nicht inventarisiert und implementiert | Matrix für alle SRD-Regeln erst zu erstellen | TEILWEISE; kein Vollständigkeitsanspruch |


Stand 18.10.2026, Entwicklungsbranch `feature/condition-source-ledger-20261018`, PR #7.
Dies ist ein **explizit unvollständiger Ausgangsauszug**, keine behauptete Gesamtinventur des SRD. Die übrigen Regelbereiche in [RULE_COVERAGE.md](RULE_COVERAGE.md) sind noch systematisch in Einzelanforderungen mit Quelle und Tests zu zerlegen. Verbindliche Norm: [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0.

| ID | SRD-Abschnitt | Fachregel | Entitäten | Engine-Pfad | UI-Pfad | Persistenz | Tests | Status / Abweichungen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| EFFECT-SOURCE-01 | Rules Glossary: Condition | Mehrere Ursachen desselben Zustands wirken nicht mehrfach; Besitz je Ursache bewahren | HeroCharacter, ConditionEffect | `condition_effects.dart`, `models.dart`, `condition_rules.dart` | `fantasy_character_sheet.dart` | optionales `conditionEffects` neben manueller `conditions`-Liste | `condition_effects_test.dart`, `fantasy_character_sheet_test.dart` | IMPLEMENTIERT_UNGETESTET; CI für PR #7 abwarten |
| EFFECT-SOURCE-02 | Rules Glossary: Condition | Eine bestätigte Quellen-ID gezielt beenden | ConditionEffect | `ConditionEffectRules.removeById` | `condition_effect_dialog.dart`, `ui/app.dart` | erhaltene Effekt-IDs im JSON | `condition_effects_test.dart` | IMPLEMENTIERT_UNGETESTET; SQLite-/UI-/Revisionsprüfungen im PR ausstehend |
| EFFECT-SOURCE-03 | Rules Glossary: Condition; Monk: Self-Restoration | Durch ausdrücklich bestätigte Regel alle Ursachen eines gewählten Zustands beenden | HeroCharacter | `MonkSelfRestoration`, `PaladinLayOnHands`, `ConditionEffectRules.endCondition` | vorhandene Klassenaktion | Zustand und Quellen zusammen im Snapshot | `condition_effects_test.dart`; vorhandene Klassen-/Speichertests | IMPLEMENTIERT_UNGETESTET; Regression ausstehend |
| EFFECT-SOURCE-04 | Rules Glossary: Condition (Dauer von der Quelle abhängig) | Effekt nur beim eigenen bestätigten Zugende der zugehörigen Begegnung ablaufen lassen | Encounter, ConditionEffect | `GameEngine._enemyTurn`, `GameEngine.applyConditionEffect`, `ConditionEffectRules.expireAtOwnTurnEnd` | `condition_effect_dialog.dart`, Quellen-/Endpunktanzeige | Begegnungs-ID und Rundengrenze optional | `condition_effects_test.dart` | TEILWEISE; GameEngine-/Dialog-/SQLite-Tests ergänzt, allgemeine Weltzeit offen |
| EFFECT-SOURCE-05 | Rules Glossary: Concentration; Incapacitated | Hinzufügen von Handlungsunfähigkeit beendet Konzentration/Rage/Dodge sofort | HeroCharacter, Encounter | `GameEngine.applyConditionEffect`, `SpellcastingRules.endConcentration`, `_encounterAfterHeroChange` | `condition_effect_dialog.dart` | atomarer Kampagnencheckpoint | erforderliche Controller-/SQLite-/Kampftests fehlen | IMPLEMENTIERT_UNGETESTET; CI-/Geräteabnahme ausstehend |
| EFFECT-SOURCE-06 | Rules Glossary: Condition | Altimport, manuelle Zustände und Quellen strikt getrennt halten | HeroCharacter | `models.dart`, `rules_engine.dart`, `death_saving_throw_rules.dart` | `character_editor.dart`, `app.dart` | schemaVersion 1, additive Felder | `condition_effects_test.dart`; vollständige SQLite-/UI-Regression nötig | TEILWEISE; Gerätetest und kompletter Import-/Rollbacknachweis ausstehend |

| CORE-UNCONSCIOUS-PRONE | Rules Glossary, Unconscious (S.191) | Bewusstlos bewirkt Liegend; nach Ende von Bewusstlos bleibt Liegend selbständig bestehen | HeroCharacter, ConditionEffect | `condition_rules.dart`, `rules_engine.dart`, `condition_effects.dart`, `death_saving_throw_rules.dart`, `game_engine.dart` | Bestehender Charakterbogen/Zustände | manuelle Liegend-Folge getrennt vom Effekt-Register, additive Schema-1-Werte | `unconscious_prone_test.dart` | IMPLEMENTIERT_UNGETESTET: neuer CI-Lauf offen; abgelegte Gegenstände, Aufstehen/Bewegung nicht enthalten |

**Nächste Abnahme:** CI-/Format-/Analyse-/Backend-/Android-Status prüfen, dann explizite Controller-Aktionen, effektgebundene Konzentrations-/Rage-/Dodgefolgen und transaktionale End-to-End-Tests ergänzen. Bis dahin das Gesamtmerkmal `EFFECT-SOURCE-DURATION` ausdrücklich nur als **TEILWEISE** führen.

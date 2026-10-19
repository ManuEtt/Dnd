## Stufenaufstieg Hauptklasse (19.10.2026)

**CI:** [39203732788](https://github.com/ManuEtt/Dnd/actions/runs/39203732788), Commit `acaaa23d` – grün; Gerätetest ausstehend.

| ID | Quelle | Regel | Engine/UI | Tests und Nachweis | Status |
| --- | --- | --- | --- | --- | --- |
| CLASS-LEVEL-UP-12 | SRD 5.2.1: Class Advancement | Aufstieg aller 12 Basisklassen um genau eine Hauptklassenstufe bis max. 20 | `primary_class_level_up.dart`, `primary_class_level_up_dialog.dart`, `character_editor.dart` | `primary_class_level_up_test.dart`, `ui_primary_class_level_up_test.dart` | GETESTET; CI erfolgreich, Gerätetest offen |
| CLASS-XP-MILESTONE | Character Advancement | EP-Schwelle oder explizit bestätigter Meilenstein, keine erfundenen EP | `primary_class_level_up.dart` | Domain/UI-Tests | GETESTET; CI erfolgreich, Gerätetest offen |
| CLASS-HP-PROGRESSION | Gaining Levels | Durchschnittlicher Trefferwürfel + KON min. 1; KON-Änderung retroaktiv auf Gesamtstufe | `primary_class_level_up.dart` | Domain-Tests | IMPLEMENTIERT_UNGETESTET |
| CLASS-SUBCLASS-CHOICE | Level 3 | Exklusive SRD-Unterklasse bewusst wählen, nicht erfinden | `primary_class_level_up_dialog.dart` | Domain/UI-Tests | TEILWEISE: pro Klasse eine lizenzierte Unterklasse, Zweitklassen-Unterklasse noch offen |
| CLASS-FEAT-ASI | Class Advancement | +2 auf ein oder +1 auf zwei Attribute (Cap 20), Klassen-Meilensteine berücksichtigen | `primary_class_level_up.dart` | Domain-Tests | TEILWEISE: alternative Feats/Epic Boons aufgeschoben |
| CLASS-FEATURE-CHOICES | SRD 5.2.1 Klassenstufentabellen | Spell/Invocation/Metamagic/sonstige Merkmalsentscheidungen vollständig sicher auflösen | Featurekatalog vorhanden; offene Wahlen werden nur protokolliert | weiter erforderliche E2E-Tests | TEILWEISE |

# SRD 5.2.1 – Regelanforderungsmatrix (laufender Aufbau)

## Neue Anforderung (19.10.2026)

| ID | SRD-Abschnitt | Regel | Engine / UI | Persistenz / Tests | Status |
| --- | --- | --- | --- | --- | --- |
| COMBAT-PRONE-STAND | Rules Glossary: Prone | Aufstehen kostet Hälfte der aktuellen Bewegungsrate, in Fuß abrunden; nur wenn positive Bewegungsrate und genügend Bewegungsbudget; keine Aktion | `prone_movement_rules.dart`, `game_engine.dart`, `services/game_controller.dart`, `ui/app.dart` | `Encounter.movementRemainderDecimeters`, `prone_standing_rules_test.dart`, `prone_standing_storage_test.dart` | IMPLEMENTIERT_UNGETESTET, neue CI-/Geräteabnahme offen |
| COMBAT-PRONE-CRAWL | Rules Glossary: Prone / Crawling | Kriechen mit zusätzlichen Bewegungskosten und Terrainanpassung | Noch kein allgemeines Bewegungs-/Positionstool | Tests fehlen | FEHLT |



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

## Neu: SPELL-MAGIC-MISSILE (20.10.2026, 0.8.16+66)

| ID | SRD 5.2.1 | Soll und tatsächliche Umsetzung | Code / Tests | Status |
| --- | --- | --- | --- | --- |
| SPELL-MISSILE-SINGLE | Spells: Magic Missile | Für einen sichtbaren bestätigten Einzelgegner innerhalb 120 Fuß, V/S, eigene Zauberklasse Magier oder Zauberer, Aktion und Platz; drei Geschosse +1 je höherem Grad; einzeln 1W4+1 Energieschaden; validierte Gegner-TP/Journaländerung | `magic_missile_rules.dart`, `game_engine.dart`, `game_controller.dart`, `magic_missile_dialog.dart`; Tests `magic_missile_rules_test.dart`, `magic_missile_storage_test.dart`, `magic_missile_dialog_test.dart` | IMPLEMENTIERT, CI AUSSTEHEND |
| SPELL-MISSILE-DEFENSES | Damage Resistance / Immunity; Spells: Shield | Shield-Reaktion und tatsächlich vorhandene Resistenz-/Immunitätswerte Gegnerseite maschinenlesbar prüfen, keine unbestätigte Verneinung raten | Derzeit nur ausdrückliche Anwenderbestätigung „keine bekannte Schutzwirkung“; keine Gegnerdaten aus Erzählung | TEILWEISE |
| SPELL-MISSILE-MULTITARGET | Magic Missile / Spell Targeting | Bestätigte mehrere Zielkreaturen, Positionsdaten, Reichweite, Deckung und Verteilung von Geschossen | Aktuell nur ein Gegner in `Encounter` | FEHLT |

**Lizenz:** SRD 5.2.1, CC BY 4.0, https://www.dndbeyond.com/srd. Diese Matrix bleibt unvollständig. Ein erfolgreicher Workflow ist vor Freigabe separat nachzuweisen.

**Abnahme 20.10.2026:** COMBAT-PRONE-CRAWL erfolgreich getestet mit [CI 39378443958](https://github.com/ManuEtt/Dnd/actions/runs/39378443958), integriert durch [PR #40](https://github.com/ManuEtt/Dnd/pull/40), Merge `f7c6a68`. Gerätetest offen. Diese Bestätigung bezieht sich ausschließlich auf das Kriech-Regelpaket.

## Neue Anforderungszeilen (20.10.2026, Version 0.8.15+65)

| ID | SRD-Abschnitt | Soll und Umsetzung | Tests | Status |
| --- | --- | --- | --- | --- |
| COMBAT-PRONE-CRAWL | Rules Glossary: Crawling / Difficult Terrain | Liegend und bewegungsfähig: Kriechen kostet 2 Fuß Bewegung je 1 Fuß Strecke; im bestätigten schwierigen Gelände 3 Fuß. Eigener Kampfzug, kein offener Wurf, keine Aktion; UI-Auswahl 5/10 Fuß, Ereignis und SQLite-Revisionsschutz. `crawling_movement_rules.dart` / `game_engine.dart` / `game_controller.dart` / `ui/app.dart` | `prone_crawling_rules_test.dart`, `prone_crawling_storage_test.dart` | GETESTET (CI 39378443958 erfolgreich; Gerätetest ausstehend) |
| COMBAT-TERRAIN-MAP | Playing the Game / Movement | Gelände und Position aus überprüften Kartendaten statt manueller Terrainbestätigung ableiten | Tests fehlen | FEHLT |
| MONSTERS-MOVEMENT | Combat / Monsters | Gegnerbewegung, Kriechen und räumliche Abstände regelkonform umsetzen | Tests fehlen | FEHLT |

**Quelle:** offizielles [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0. Diese fortgeschriebene Matrix ist ausdrücklich noch keine vollständige Inventur des SRD; historische Einträge können sich auf ältere, nicht gemeinsam verifizierte Branches beziehen.

# SRD 5.2.1 – Regelanforderungsmatrix (laufender Aufbau)

## Verifizierte konkrete Klassen-Startausrüstungswahl (Version 0.8.6+56; CI offen)

| Regel-ID | SRD-Abschnitt | Umsetzung | Tests | Status |
| --- | --- | --- | --- | --- |
| EQUIP-CHOICES-INSTRUMENT | Classes / Equipment | Barde wählt konkretes SRD-Instrument mit validiertem Katalogeintrag statt unbestätigter Sammelbezeichnung | `starting_equipment_choices_test.dart`, `ui_srd_start_equipment_choices_test.dart` | IMPLEMENTIERT_UNGETESTET (CI ausstehend) |
| EQUIP-CHOICES-TOOL | Classes / Equipment | Mönch wählt SRD-Handwerkszeug oder Instrument, nur erlaubte Kategorien; korrekte Typ-/Preis-/Gewichtsfelder | `starting_equipment_choices_test.dart` | IMPLEMENTIERT_UNGETESTET |
| EQUIP-CHOICES-OTHER | Classes / Equipment | Heiliges Symbol, Druidenfokus und weitere unaufgelöste Startgegenstände aus dem vollen SRD präzise wählbar machen | Vorhandene SRD-Katalogeinträge reichen noch nicht aus | TEILWEISE; keine erfundenen Eigenschaften |



## Integrationsstatus (19.10.2026)

PR #11 ist auf `main` enthalten. Die PR-#9-Regeln für Startausrüstung/RK/Bewegung sind in `integration/character-creation-20261019` zusammengeführt. Die gemeinsame CI ist noch zu bestätigen. PR #10 enthält überschneidende Klassenaufstiegsregeln und muss getrennt auf zusätzliche Fähigkeiten geprüft werden. `GETESTET` in älteren Zeilen bezieht sich auf die jeweils verlinkte Einzelbranch-CI, **nicht** die Integration.


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


## Stufenaufstieg und Erstellungsprüfung (19.10.2026, neue CI offen)

| ID | SRD 5.2.1 | Umsetzung | Tests | Status |
| --- | --- | --- | --- | --- |
| CHAR-START-AUDIT | Character Creation / Classes / Origins | Explizite Prüfliste für alle 12 Klassen, fehlende Werte und unautomatisierte Herkunfts-/Klassenwahlen | `srd_character_creation_audit_test.dart` | IMPLEMENTIERT_UNGETESTET |
| LEVEL-SAME-CLASS | Character Advancement / Class Features | Bestehende Klasse +1, bis Gesamtstufe 20; Zweitklasse im bestehenden Modell | `srd_class_level_up_test.dart`, `ui_srd_class_level_up_test.dart` | IMPLEMENTIERT_UNGETESTET |
| LEVEL-HP-FIXED | Gaining Levels / Hit Points | Fester Trefferwürfelgewinn plus KO, Minimum 1, Verletzung beibehalten | `srd_class_level_up_test.dart` | IMPLEMENTIERT_UNGETESTET |
| LEVEL-XP-MILESTONE | XP Thresholds / Milestones | Bestätigte XP-Schwelle oder explizit gewählter Meilenstein, keine erfundenen XP | `srd_class_level_up_test.dart` | IMPLEMENTIERT_UNGETESTET |
| LEVEL-CHOICES-PENDING | Features / Feats / Subclasses | Tabellenmerkmale und offene Entscheidungen verfolgen, ohne ungeprüfte Wirkung; lizenzierte Haupt-Unterklasse auf Klassenstufe 3 explizit anwählbar | `srd_class_level_up_test.dart`, `ui_srd_class_level_up_test.dart` | TEILWEISE |
| LEVEL-CHOICES-EXECUTE | Ability Score Improvements / Feats / Spells / Class Features | Alle wählbaren Talente/ASI/Zauber/Klassenmerkmale validieren und regelkonform ausführen | Noch nicht | FEHLT |
| ORIGINS-COMPLETE | Species / Backgrounds / Origin Feats | Alle SRD-Ursprünge, Talente und Sonderregeln inkl. UI und Persistenz | Vier Hintergründe mit Attributsverbesserungen existieren; umfassende Features fehlen | TEILWEISE |



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

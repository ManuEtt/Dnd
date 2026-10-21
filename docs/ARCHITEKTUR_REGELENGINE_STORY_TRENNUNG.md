# Architektur: Regelengine und Kampagnenhandlung getrennt entwickeln

Stand: 21.10.2026. Dies ist die **erste sichere Entkopplungsstufe**; keine Behauptung, der bisherige Monolith sei vollständig beseitigt.

## Drei Verantwortungsbereiche

| Bereich | Code | Verantwortung |
| --- | --- | --- |
| **Regelengine** | `app/lib/domain/*rules.dart`, `dice_engine.dart`, `rules_engine.dart`, `character_rule_engine.dart` u. a. | SRD 5.2.1, Würfel, Kampf, Klassen, Zauber, Charakterwerte. Keine KI-Prosa als Regelquelle. |
| **Story/Kampagne** | **neu:** `app/lib/story/story_campaign_engine.dart`, `story_memory_engine.dart`, `story_rule_boundary.dart`; bestehend: `domain/rabenwacht_campaign.dart`, `domain/ai_story.dart` | Eigene Kampagnenentwicklung, NPC-Beziehungen, Story-Fortschritt, Sitzungsrückblicke, Erzähltexte und verifizierte Erinnerungen. |
| **Integration und Speicherung** | `app/lib/domain/game_engine.dart` (bestehende Fassade), `app/lib/services/game_controller.dart`, `app/lib/data/*` | Freigegebene Regelaktion und Storyänderung in einem transaktionalen Spielzustand, event-sourcing, Revisionen, Rückwärtskompatibilität. |

Bestehende öffentliche Aufrufe wie `GameEngine.applyAiStoryStep`, `replaceNarration`, `saveStoryThread`, `saveSessionRecap` und `MemoryEngine.retrieve` bleiben kompatibel. Ihre Implementierung wurde in `app/lib/story/` verlagert; `GameEngine` delegiert und exportiert den bisherigen MemoryEngine-Namen. Gleiches Kampagnen-JSON (`schemaVersion=1`), gleicher Narrator/Controller und dieselben Audit-Ereignisse. Die IDs und Zeitstempel kommen weiterhin vom ursprünglichen GameEngine-Kontext.

## Regeln für paralleles Arbeiten

**Regel-Track:** Änderungen an Charaktererstellung, Kampf, Würfelmechanik, SRD-Zaubern, Klassen, Monsterprofilen und ihren Tests. Keine direkten Imports aus `app/lib/story/`. Story-Fakten dürfen niemals ungeprüft HP, RK, XP, Ressourcen oder Monsterangriffe festlegen.

**Story-Track:** Rabenwacht, neue Kampagnenkapitel, Questtexte, NPCs, Beziehungen, Erinnerung, KI-Dialoge und deren Tests. Neue Story-Module importieren ausschließlich `domain/models.dart`, `domain/ai_story.dart` und Story-interne Dateien; keine Würfel-/Regelmodule, kein Flutter, keine Backend-Provider. `StoryRuleBoundary.ensureRuleStateUnchanged` vergleicht alle Kampagnen-JSON-Felder außerhalb einer eng gefassten Erzähl-Whitelist und verweigert Änderungen an Helden-/Kampfwerten, Inventar, Quests, Aktionen und jeglichen neuen unbekannten Regelfeldern.

**Integration:** Gemeinsame Änderungen an `models.dart`, `game_engine.dart`, `game_controller.dart` oder Datenbankschema werden ausschließlich in einem kleinen Integrations-PR kombiniert. Gleichzeitige PRs dürfen getrennte Dateien bearbeiten; Merge-Konflikte in gemeinsamen Dateien werden vor dem Test behoben. Jeder Track behält eigene Regressionstests.

`scripts/check_domain_boundaries.py` prüft die direkten Dart-Importgrenzen; `scripts/tests/test_domain_boundaries.py` verankert sie im bestehenden Python-CI-Gate. Die Story-Regelwache hat eigene Flutter-Tests in `app/test/rules_story_separation_test.dart`.

## Offene Arbeiten für die vollständige Trennung

1. **Charakter-/Kampfzustand vom Story-JSON abspalten:** derzeit definiert `domain/models.dart` sowohl `HeroCharacter`/`Encounter` als auch `StoryThread`/`Campaign`. Künftige stabile, versionierte RuleSnapshot-/StorySnapshot-DTOs benötigen eine migrationssichere Adapterebene.
2. **Gemischte GameEngine-Orchestrierung** weiter entflechten: `acceptAdventure`, `act`, `resolveRoll` und `RabenwachtCampaign` enthalten noch gemischte narrative/mechanische Übergänge. Regeln dürfen im finalen Modell nur durch eine explizite, validierte RuleCommand-Schnittstelle ausgelöst werden.
3. **Eigenständige RuleEngine-Orchestrierung:** reine Commands/Results und deterministische Tests ohne Storyprovider, mit einem zentralen Commit über `GameController`.
4. **CI/Branches/Integration:** laufende Regel-PRs (z. B. bestätigte Zusatzgegner-Angriffe) und Story-PRs (Rabenwacht) zunächst getrennt zusammenführen; danach Durchstich mit automatischen Kompatibilitätstests, SQLite-/Backup-Migrationen, Debug- und Alpha-APK sowie echter Android-Abnahme.

**Definition fertig:** Keine `story`-Imports in Regelmodulen; Story-Kommandos können nur Story-Felder mutieren; alle mechanischen Entscheidungen stammen aus einer eigenständig testbaren Regelengine; Savegames/Journal verhalten sich exakt gleich; zwei getrennte PRs aus beiden Bereichen können ohne Bearbeitung derselben Kern-Dateien parallel entwickelt und anschließend kombiniert werden.

## Grobe Arbeitsumfangsschätzung (Entwickleraufwand, keine Lieferzusage)

Die Grundlage (Auslagerung/Abhängigkeitsgrenzen/Tests) ist ein erstes Inkrement. Für eine robuste vollständige Entkopplung sind nach Sichtung des über 5.000-zeiligen bisherigen `game_engine.dart` und des 2.400-zeiligen kombinierten `models.dart` **etwa 5–10 konzentrierte Entwicklertage**, zuzüglich möglicher Migration-/CI-/Integrationskorrekturen, ein realistischer Orientierungswert; bei stark veränderten Kampagnen-/Regel-PRs kann der Umfang erheblich steigen. Ein verbindlicher Kalendertermin wäre ohne vollständige Test- und Änderungsanalyse nicht seriös.

## Validierung

```bash
python3 scripts/check_domain_boundaries.py
python3 -m unittest discover -s scripts/tests -v
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Nicht getestet: Installation auf einem echten Android-Gerät, gleichzeitige externe GitHub-PR-Merges vor Ende ihrer eigenen CI und vollständiger SRD-Konformitätsgrad (noch separat im Anforderungsinventar erfasst).

## Öffentliche Fassaden für getrennte Entwicklung

- `app/lib/rules/rules_api.dart` bündelt die reinen SRD-Regelmodule einschließlich bestätigter Zusatzkreatur-Angriffe. Hier werden keine Storymodule exportiert.
- `app/lib/story/story_api.dart` stellt die kompatible `StoryCampaignEngine` sowie bestätigte KI-Erzählverträge bereit. Bis zur vollständigen Modellmigration bleibt `RabenwachtCampaign` unter dem bestehenden Legacy-Pfad; der Story-Fassadenexport darf die eingeschränkten Importgrenzen nicht umgehen.
- Diese Fassaden übernehmen die nutzbaren API-Bausteine aus dem alternativen Branch `feature/separate-rules-and-story-20261021`. Dessen konkurrierender Story-Orchestrator/Committer ersetzt **nicht** die bereits getestete und gemergte Architektur aus PR #69.

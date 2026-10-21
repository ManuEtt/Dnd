# Würfelraunen – Regelengine und Story getrennt entwickeln

**Stand:** 21. Oktober 2026, Umbauinkrement ab `0.8.29+79`. SRD-Referenz: [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0.

## Verantwortlichkeiten

| Modul | Verantwortlich | Nicht verantwortlich |
| --- | --- | --- |
| `app/lib/rules/` | Öffentliche SRD-Regel-API, Würfel, Kampf, Zauber, Klassenmechanik | Dialoge, Handlungsstränge, Texte, KI |
| `app/lib/story/` | Kampagnenskripte, NPCs, Story-Fortschritt, KI-Narration und Geschichte | Würfelmodifikatoren, XP-Berechnung, Slots, Schadensregeln |
| `app/lib/story/story_rule_port.dart` | Typisierte Anfragen/Antworten zu Proben und Meilensteinen | Eigene Würfel- oder Regelimplementierung |
| `app/lib/domain/rabenwacht_campaign.dart` | Kompatibler Adapter zwischen Rabenwacht-Geschichte und vorhandenen Regeln | Neue Kampagnenhandlung |
| `app/lib/domain/game_engine.dart` | Bestehende Orchestrierung, Journal/Checkpoint, Kampf + Story koordinieren | Langfristig kein Ort mehr für neue Kampagnentexte |
| `app/lib/domain/models.dart` | Gemeinsames persistiertes Datenformat | Kampagnen-Storylogik und textbasierte Regelinterpretation |
| `app/lib/services/game_controller.dart` | Revisionsgeschütztes Speichern, UI-Steuerung, Backend-Zugriff | Neue SRD-Berechnungen oder erzählerische Entscheidungen |

### Was bereits tatsächlich entkoppelt wurde

1. **Rabenwacht-Implementierung** liegt jetzt in `app/lib/story/rabenwacht_campaign.dart`. Die alte Importadresse exportiert ausschließlich den vorhandenen `RabenwachtTurn`-Typ und delegiert die bekannte statische API an das eigenständige Storymodul.
2. Die Kampagne verwendet statt direkter `CharacterRuleEngine.abilityCheck`- und `CampaignExperience.awardOnce`-Aufrufe den `StoryRulePort`. Die konkrete Übersetzung der zwei Regelanforderungen erfolgt im alten Domain-Adapter. Andere Geschichten können diesen Port implementieren bzw. im Test durch ein Testdouble ersetzen, ohne Klassen-/XP-Code zu importieren.
3. Der validierte generative Storyparser `AiStoryPlan`/`AiStoryStep` liegt nun in `app/lib/story/ai_story.dart` mit abwärtskompatiblem Export in `domain/ai_story.dart`.
4. `story_api.dart` bietet die kanonischen Story-Exports; `rules_api.dart` bleibt eine eigene SRD-API.
5. `scripts/tests/test_module_dependencies.py` prüft in jedem bestehenden Python-CI-Lauf, dass Story-Implementierungen nicht direkt Regelmodule importieren, dass die Regeln keine Story-API exportieren und dass authored Storycode nicht in Domain-Compat-Fassaden zurückwandert.
6. Die bestehenden `StoryRuleBoundary`-Prüfungen verhindern unverifizierte Änderungen an regelrelevanten Kampagnenfeldern bei generierten/narrativen Übergängen. Das gemeinsame JSON-Schema wird in diesem Inkrement **nicht** geändert; bisherige Kampagnen bleiben lesbar.

## Zwei unabhängige Entwicklungsstränge

**Strang A – Regelengine:** `feature/rules-<thema>`; nur `app/lib/rules/`, regelorientierte `app/lib/domain/`-Dateien, `app/test/*rules*_test.dart` und die SRD-Anforderungsmatrix bearbeiten. Regeländerungen verlangen deterministische Tests, dokumentierte SRD-Quellen und keine neuen Storyimporte.

**Strang B – Kampagne:** `feature/story-<kampagne>-<thema>`; hauptsächlich `app/lib/story/`, Geschichte-/NPC-/Branch-Tests und passende Dokumentation bearbeiten. Regelproben/Belohnungen ausschließlich über den typisierten Port anfragen. Keine manuellen TP-/EP-/Slotänderungen aus generativer Narration.

**Gemeinsame Änderungen** (Port, Kampagnen-JSON, Persistence, `GameEngine`-Orchestrierung) sind *Integrationsarbeiten*. Diese zuerst in einem kleinen separaten Integrations-PR versionieren, dann beide Arbeitsstränge auf die neue Basis aktualisieren. Niemals gleichzeitig dieselbe Domain-Fassadendatei in unabhängigen Branches ändern, ohne ihre Commits zusammenzuführen.

## Verbleibende Arbeiten

Dies ist ein **erstes reales Architekturinkrement, keine vollständige Entflechtung**. `GameEngine` ist weiterhin ein großer gemeinsamer Orchestrator (mehr als 4.500 Zeilen) und enthält alte kampagnen- und demoabhängige Siege, Begegnungsübergänge sowie freie Erzähltexte. Andere Regelmodule liegen historisch noch unter `domain/`; `rules/` exportiert sie bisher nur. Diese schrittweise extrahieren:

1. Nächste Etappe: komplette Rabenwacht-Encounter-Vorbereitung, Abenteuerübergänge und Kampfergebnis-Erzählung hinter explizite `StoryEvent`-/`RuleAction`-Kommandos legen.
2. Danach: `GameEngine` in regelorientierten Kampfmotor, Story-Orchestrator und gemeinsame ereignisbasierte Persistenz-Fassade aufteilen; Save-Migration und Rollback testen.
3. Abnahme: direkte Story- und Rule-Module in eigenen Test-Suites, vollständige Flutter-/Backend-/APK-CI, Rabenwacht-Enden und Bestands-Spielstände als Regressionen.

## Aufwandseinschätzung

Bei einer entwickelnden Person ist für die **vollständige fachliche Trennung** realistisch mit **8–15 konzentrierten Entwicklungstagen** bzw. ungefähr **2–4 Kalenderwochen** inklusive Regressionen, CI-Korrekturen und Integrationszeit zu rechnen. Der bereits umgesetzte Modul-/Port-Schnitt ist die erste Etappe. Für eine vollständig eigenständige, versionierte Flutter/Dart-Package-Trennung mit getrennten Buildpipelines wären zusätzlich etwa **4–8 Entwicklungstage** einzuplanen. Dies sind **Schätzungen, keine zugesagten Fertigstellungstermine**. Laufende automatische Hintergrundentwicklung ist damit nicht eingerichtet.

## Test-Gates

```bash
python3 -m unittest discover -s scripts/tests -v
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/rules_story_separation_test.dart
flutter test test/rules_story_port_integration_test.dart
flutter test
flutter build apk --debug
```

Kein Merge ohne vollständige CI. Der echte Android-Gerätetest bleibt separat erforderlich.

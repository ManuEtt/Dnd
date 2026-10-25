# Lokaler KI-Spielleiter: doppelte gespeicherte Identitäten schützen

Datum 25.10.2026, [PR #168](https://github.com/ManuEtt/Dnd/pull/168), gestapelt auf [PR #165](https://github.com/ManuEtt/Dnd/pull/165).

## Problem
Das vorhandene `Campaign.fromJson` prüft doppelte Story-Thread-IDs, aber nicht gleichermaßen doppelte NPC-IDs. Zudem kann ein während der Sitzung erzeugter `Campaign.copyWith`-Zustand trotz alter Modellprüfungen mehrere identische Thread-IDs enthalten. Im lokalen `AiStoryStep.fromJson` wurden `storyThreads` über eine Map und `npcs` über ein Set indiziert. Durch dieses Zusammenfallen könnte eine vom Erzähler kommende Beziehungsänderung zwei NPC-Einträge derselben ID gleichzeitig treffen; bei Threads könnte der letzte Status die vorher bestätigte Entscheidung überschreiben.

## Umsetzung
`app/lib/story/ai_story.dart::AiStoryStep.fromJson` erzwingt **vor** Mapping/Referenzzuordnung eindeutige gespeicherte IDs **innerhalb** der Thread- und NPC-Listen mit der bereits existierenden `_unique`-Funktion. Eine gleiche ID in zwei **verschiedenen** Kategorien ist zulässig; für bestehende eindeutige Spielstände bleibt das Format unverändert.

Der vorhandene `StoryCampaignEngine.applyAiStoryStep`-Pfad validiert den aktuellen Kampagnenstand vor Übernahme erneut, sodass auch früher geprüfte KI-Erzählantworten bei nachträglichen Identitätskonflikten scheitern. Keine direkte Mutation/kein Ersatz alter Daten durch generativen Text.

## Regressionen
`app/test/ai_story_test.dart` ergänzt drei Fälle: doppelte gespeicherte NPC-Kennung mit unterschiedlichen Beziehungen (auch Stale-Replay), widersprüchliche doppelte Story-Thread-Kennung und gleicher Text-Identifier in voneinander unabhängigen Thread-/NPC-Namespaces. Der Held sowie die ursprünglichen bestätigten Daten bleiben bei Ablehnung unverändert.

## Abnahme und Grenzen
Die eigene **volle** [GitHub-CI des PR #168](https://github.com/ManuEtt/Dnd/pull/168/checks) muss Dart-Format, Flutter-Analyse/Vollsuite, Python-/Backendtests, Android-Debug, native Tests und Alpha-Artefakte auf **dem letzten SHA** erfolgreich abschließen. Basis-PR #165 ist grün ([CI #40170005782](https://github.com/ManuEtt/Dnd/actions/runs/40170005782)), beweist aber nicht dieses neue Paket.

Dies ist eine **spezifische lokale KI-Eingangsprüfung**, **keine** vollständige Migration des globalen Campaign-Schemas; die mögliche Alt-NPC-Duplikation wird weder gelöscht noch stillschweigend umgeschrieben. Andere Campaign-Importpfade bleiben unverändert und können in einem gesonderten, koordinierten Integrationspaket behandelt werden.

Keine App-Versionserhöhung (0.8.38+88), keine SQLite-2-/JSON-1-Migration, keine zusätzliche D&D-SRD-5.2.1-Abdeckung, keine Änderungen an KI-Providerkosten oder Kampfregeln. Echtgerät, historischer persönlicher Spielstand und produktive Signierung nicht geprüft.

## Integration
Branch `fix/local-ai-duplicate-npc-ids-20261025` basiert auf dem grünen PR #165; #165 wiederum auf #164. Der Backend-Schutz aus #167 ist unabhängig. Review der Stacks in der richtigen Reihenfolge und vor jedem Wechsel der Basis eine erneute vollständige CI. Keine Änderungen an `main` oder fremden PRs.
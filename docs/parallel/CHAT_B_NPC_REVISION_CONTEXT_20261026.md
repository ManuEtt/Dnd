# Chat B – NPC-Identität mit Kampagnenrevision (26.10.2026)

## Integrationsbasis und Parallelkoordination
- Basis-`main`: `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`.
- Branch: `feat/chat-b/npc-revision-context-20261026`.
- Zu Entwicklungsbeginn offene PRs #178, #179, #180, #181, #184, #187, #188–#195. Gerade #181 verändert den `story_api.dart`-Export, #187/#194 den KI-`game_controller.dart` und #193 das Backend-`app.ts`; alle bleiben absichtlich unberührt.
- PR #193 auf `bdd95cac4006a0f575d96fef614091464c0e748e`: vollständige GitHub Actions #40234301318 `success`, **weiterhin offen, nicht gemergt**.
- Eigenes neues Fachpaket ausschließlich in zwei bisher freien Pfaden unter `app/lib/story/` und `app/test/`. Gemeinsam genutzte README-/Checkpoint-Ergänzungen sind vor einem Merge mit Chat D zusammenzuführen.

## Problem und Abgrenzung
Die bisherige Übertragung an den optionalen Erzähler nutzt markierte Erinnerungsstrings, kann jedoch nicht zuverlässig zwei gleichnamige NPCs unterscheiden. Außerdem fehlt eine revisionengebundene, ID-basierte lokale Auswahl vor Aufbau eines zukünftigen strukturierten KI-Requests.

## Implementiert
- `app/lib/story/npc_identity_memory.dart`: `NpcIdentityMemory.read` verlangt genaue `npcId`, erwartete `campaign.revision` und ein Limit von 1–20. Gleiche Anzeigenamen sind zulässig, gleiche IDs nicht.
- Die unveränderliche `NpcIdentityContext`-Projektion enthält Kampagnenkennung, Revision, NPC-ID, Anzeigename, Lebens- und Beziehungsstatus und ausschließlich die zugehörigen bestätigten `NpcRelationshipNote`-Einträge.
- Deterministische Reihenfolge: neuestes `recordedAt` zuerst, bei Gleichstand zuletzt protokollierte Notiz zuerst.
- `NpcIdentityMemory.requireCurrent` lehnt fremde Kampagnen, geänderte Revisionen und auch widersprechende gleichrevisionierte Daten ab. Kein stilles Neuladen veralteter Werte.
- `toContextMap` erzeugt einen ID-haltigen strukturierten **lokalen** Kontext, ohne eine neue externe API oder einen Provideraufruf vorzutäuschen.
- `app/test/npc_identity_memory_test.dart`: sechs Tests zu gleichnamigen Figuren, JSON-Roundtrip, Sortierung, Revisionen/Kampagnenwechsel, Eingabegrenzen, Unveränderlichkeit und alten JSON-Ständen.

## Akzeptanzkriterien
1. Bei gleichem Namen und verschiedenen IDs dürfen die Fakten niemals zwischen NPCs vermischt werden.
2. Veraltete Revisionen und widersprüchliche, scheinbar gleichrevisionierte Snapshots müssen scheitern.
3. Ohne bestätigte Notizen wird eine leere Chronik geliefert; Alt-JSON ohne Notizfeld funktioniert.
4. Der Inhalt bleibt schreibgeschützt. HP, Quest-, Regel- und sonstige Kampagnenzustände bleiben unverändert.
5. Kein Schema-/Versionswechsel oder fiktiv als ausgeführt gemeldeter KI-Provider-Test.

## Prüfstand
- Fachcode und sechs Flutter-Regressionsfälle geschrieben und auf GitHub gesichert.
- Hier steht kein lokales Dart-/Flutter-SDK zur Verfügung; verbindliche Abnahme über GitHub-CI des **finalen** PR-HEAD.
- Noch nicht getestet: echte Geräteinstallation, KI-Provider-Integration, Release-Signierung und produktive Datenmigration.

## Migration, Grenzen, nächster Schritt
- Persistenz bleibt SQLite 2 / Kampagnen-JSON 1. Keine Datenbank- oder API-Migration.
- Die aktuelle Backendroute erwartet `memories: string[]` und unterstützt die Struktur von `toContextMap` noch **nicht**. Diese Daten dürfen daher derzeit nicht unvalidiert an den Backendprovider gesendet werden.
- Das Paket ist die unabhängige, lokal autoritative Quelle für ein zukünftiges ID- und revisionsgebundenes Protokoll. Noch kein automatischer Erzähler-Konsument.
- **Ein nächster Schritt nach CI und Integration der offenen PRs:** serverseitig ein optionales strukturiertes NPC-ID-/Revisionsprotokoll mit Mock-End-to-End-Prüfungen ergänzen und erst nach Freigabe vom lokal bestätigten Client befüllen.

# Chat-B-Integrationsprüfung – 30.10.2026

Stand: 21:27 UTC. Lokale Gruppenbasis ist `6465a4b2fc8d42ae7aab596ac26e85d61d2b8f49`.
Arbeitsbranch: `integrate/story-all-20261030`. Die Gesamtintegration,
Main-CI, Archivierung und Remote-Bereinigung erfolgen getrennt durch den
koordinierenden Integrationslauf zu Issue #425; dieser Bericht behauptet
keinen bereits erfolgten Main-Merge.

## Übernommene Historie

Alle sieben ursprünglichen Chat-B-Heads wurden mit regulären Merge-Commits
übernommen, ohne Force-Push oder Änderung der ursprünglichen Remote-Branches:

| Ursprungs-PR | Branchende | Ursprünglicher HEAD |
| --- | --- | --- |
| #398 | npc-context-control-sanitizing-20261030 | `92ddc263cc1ff56c01d8d62395454cf3f39323f6` |
| #431 | npc-context-immutable-restart-20261030 | `62485860893fe7717bdb46594f4d4bc803e33633` |
| #407 | npc-identity-bidi-context-20261030 | `8bf99dbef2fe92dd3419667dc9609aef44fe6d80` |
| #403 | npc-narrator-wire-bidi-20261030 | `38672252bb413e27838e35c9b412888ff33194b8` |
| #396 | safe-npc-identity-recall-20261030 | `755064d69e42f5d1080cd4a29ce270bf4fdd1d34` |
| #414 | story-entry-id-collision-20261030 | `1c4e7c32b1a5afae683a3dfb7e0d4b597072195f` |
| #424 | story-provider-unicode-guard-20261030 | `8e8e469a2b3cf97117e7427ed86f9181f2c1509a` |

Gruppen-Merge-HEAD vor der folgenden fachlichen Reparatur:
`df3a1c81f4cd06fcd9d88e09fdee923dec4a85ed`.
Jeder ursprüngliche HEAD ist nachweislich Vorfahre. Alle übernommenen App-/Backend-
Quell- und Testdateien waren an diesem Zwischenstand bytegleich zu ihrem
Ursprungsbranch (Git-Blob-SHA-Vergleich).

Es gab keine Quellkonflikte. Konflikte in README, zentralem Checkpoint und
Chat-B-Checkpoint wurden durch Vereinigung ausschließlich der kollidierenden
Dokumentationsabschnitte gelöst. Alle vorherigen Zeilen der drei Main-Dokumente
bleiben in unveränderter Reihenfolge erhalten. Historische Test- und PR-Angaben
dieser Abschnitte sind keine Abnahme des neuen Gesamtstands.

## Behobener Integrationsfehler

Die strukturierte NPC-Übertragung entfernt unsichtbare Richtungszeichen für
den Namensvergleich. Die lesbare NPC-Erinnerung und der Legacy-Erzähler ersetzten
dieselben Zeichen bisher durch Leerzeichen. Bei `Mira` und `Mi\u200era`
konnte deshalb der Legacy-Erzähler aus „Ich frage Mira“ unzulässig die erste
Identität ableiten, während die strukturierte Übertragung die Mehrdeutigkeit
korrekt erkannte.

`NpcContinuityReader` und `NpcNarratorMemory` entfernen Richtungszeichen jetzt
ebenfalls ausschließlich für den Identitätsvergleich. Tatsächliche Leerzeichen
bleiben bedeutungstragend. Sichtbare Kontexttexte bleiben von Steuerzeichen
bereinigt; der Kontinuitätsleser umfasst jetzt auch ALM/LRM/RLM. Explizite
ID-Auswahl, Originalnamen, Beziehungen, JSON und SQLite-Spielstände bleiben
unverändert. Keine neue Schema- oder API-Version und keine Regelzustandsänderung.

Der neue Test `npc_invisible_name_collision_integration_test.dart` vergleicht
alle drei NPC-Projektionen für zwölf Richtungszeichen innerhalb eines Namens,
prüft die explizite ID-Darstellung und unverändertes Kampagnen-JSON sowie einen
positiven Fall mit tatsächlich verschiedenem Namen `Mi ra`.

## Tatsächliche lokale Prüfungen

- Vor der Reparatur: neue Regression **1 bestanden / 12 fehlgeschlagen**;
  der falsche NPC-Kontext ist damit reproduziert.
- Nach Reparatur: **89/89 Flutter-Tests** in 15 gezielten Dateien bestanden,
  einschließlich aller sieben ursprünglichen neuen B-Testdateien,
  bestehender Story-/NPC-/Regelgrenztests und der 13 neuen Regressionen.
- `flutter analyze`: keine Befunde. Formatprüfung der Storymodule und neuen
  Regression bestanden; `check_domain_boundaries.py` bestanden.
- Backend: `npm ci`, Typecheck und Build bestanden, **75/75 Tests** bestanden.
- Vollständige kombinierte Flutter-/Python-/Android-Prüfung, PR-CI,
  Main-CI und Geräteabnahme sind hier **nicht** ausgeführt beziehungsweise
  noch nicht nachgewiesen; sie gehören zum koordinierenden Gesamtlauf.

Externe lokale Belege liegen unter
`/workspace/validation/20261030-migration-story-*.log` und
`20261030-migration-story-source-blobs.json`; diese Workspacepfade sind keine
öffentlichen Downloads. Nächster Schritt ist die reguläre Übernahme dieses
Gruppenbranches in den Gesamtintegrationsbranch und dessen vollständige Prüfung.

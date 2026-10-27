# Chat B – Sitzungsgrenze im Story-Journal-Replay (27.10.2026)

## Ausgangslage und Abgrenzung

Ausgangs-main: `96001353f2b90f293fbdade934e78b7b8281e965`.
Branch: `fix/chat-b/story-replay-session-identity-20261027`.
Betroffen sind nur `app/lib/story/story_memory_engine.dart` und ein neuer Story-Regressionstest.
Die am Aufgabenbeginn offenen Chat-B-PRs #288, #290, #292, #300, #303–#306 und #309–#310
bearbeiten NPC-Auswahl, Outbox oder Erinnerungstransport, nicht die Replay-Funktion.
PR #175 ist bereits integriert. Gemeinsame README-/Checkpoint-Fassungen muss Chat D
bei der späteren Integration additiv konsolidieren.

## Problem

`MemoryEngine.replay` prüfte die Kampagnen-ID sowie die Revisionsfolge, aber
nicht, ob ein neu eingespieltes Journal-Ereignis zur aktuell wiederhergestellten
Sitzung gehört. Ein syntaktisch gültiger `stateAfter`-Checkpoint durfte zudem
eine andere `sessionId` als sein eigenes Ereignis tragen.

## Verhalten und Abnahme

1. Neue Journalereignisse mit fremder `sessionId` werden vor Übernahme verworfen;
   das gilt auch für ältere Ereignisformate ohne `stateAfter`.
2. Ein Checkpoint mit einer vom Ereignis abweichenden Sitzungs-ID wird verworfen.
3. Exakt identische, **bereits bestätigte** Ereignisse bleiben idempotent,
   auch wenn die aktuell geladene Kampagne mittlerweile eine andere Sitzung hat.
4. Gültige Wiederherstellung liefert weiterhin denselben bestätigten Zustand
   einschließlich Helden-/Regelzustand, Nachrichten, Ereignissen und Revision.
5. Fehler verändern weder Seed-Kampagne noch Input-Ereignisse.

## Tests und Kompatibilität

Neuer Test: `app/test/story_replay_session_boundary_test.dart`.
Vier positive/negative Regressionen zu normalem Replay, fremdem Ereignis
(mit und ohne Checkpoint), gefälschtem Sitzungswechsel und historischem
Idempotenzverhalten.

Keine Änderung an öffentlichem API, Erzählanbieter, Kampf- oder Regelengine,
Controller, SQLite-Schema, Kampagnen-JSON, Exportversion und App-Version.
Keine kostenpflichtigen KI-Requests. Weiterhin keine allgemeine Eventsignatur
oder externe Exactly-once-Garantie.

## Auszuführende Abnahme

```bash
python3 scripts/verify_project.py
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py --json
python3 -m unittest discover -s scripts/tests -v
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/story_replay_session_boundary_test.dart
flutter test
flutter build apk --debug
```

Backend-Checks und Android-Geräteabnahme getrennt protokollieren.
Vor Merge finale PR-CI auf genauem Branch-Commit prüfen. Kein Auto-Merge.

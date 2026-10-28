# Chat A – SRD-Weitsprung: Kampfübergang vorbereiten (27.10.2026)

## Koordination und Basis

- Dieses Paket ist **gestapelt** auf [PR #284](https://github.com/ManuEtt/Dnd/pull/284), HEAD `4e15ba643a22b94e9ec3ba7da72e8330a0b0e56c`; #284 selbst basiert auf `main` `e7736bfc99427bfa6a1d0fd3ff887252c75c9413`.
- Branch: `feat/chat-a/long-jump-encounter-plan-20261027`; **PR-Zielbranch ist absichtlich der Branch von #284**, nicht `main`. Erst #284 abnehmen, dann diesen Folge-PR integrieren.
- Gemeinsame noch offene PRs #280/#278/#276 verändern u. a. `game_engine.dart`, `game_controller.dart` und Terrainanbindungen. Diese Dateien bleiben hier unangetastet. Auch keine Korrektur bestehender Reviews, Datenbanktabellen oder App UI.
- Regelbasis: Wizards of the Coast, SRD 5.2.1, *Rules Glossary – Long Jump*, Druckseiten 184–185, CC BY 4.0; [offizielle PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf).

## IMPLEMENTIERT

- `app/lib/domain/srd_long_jump_encounter_rules.dart` führt `SrdLongJumpRules.preflight` mit den **konkreten**, bestätigten Charakter- und Kampfdaten zusammen.
- Verpflichtende Prüfung: Kampagnen-ID, Kampf-ID, erwartete Revision, laufender eigener Kampfzug, nicht beendeter Kampf, kein offener Wurf/Todeswurf/Schildtreffer/Gelegenheitsangriff.
- Gesperrt bei `liegend`, Bewegungsverbot oder Tempo 0, ungeklärtem Sprungweitenbonus und nicht bereits bezahltem Anlauf. Die Stärke stammt ausschließlich aus dem tatsächlichen Charakterwert; keine KI- oder Dialogbehauptung ersetzt ihn.
- Zentimetergenaue SRD-Vorprüfung und sichere Brücke ins bestehende `Encounter.remainingMovementDecimeters`-Modell. **Nicht durch 10 teilbare Zentimeter** werden zurückgewiesen, damit 225 cm (7,5 Fuß) nicht durch Rundung stillschweigend verfälscht werden. Der Anlauf muss bereits verbucht sein und wird nicht nochmals berechnet.
- Erfolgreiche Vorprüfung liefert `SrdLongJumpEncounterPlan`: eine **unverbindliche** `projectedCampaign`, den dokumentierten Bewegungsverbrauch und ein Flag für neu hinzukommendes `liegend`; Bewegung verliert bestätigte Deckung; Angriffsaktion/Bonusaktion/Reaktion bleiben erhalten.
- Schwieriges Landegelände mit bestätigter gescheiterter SG-10-Akrobatik führt ausschließlich in der Projektion zur **manuellen** `liegend`-Bedingung. Andere Zustandsquellen werden nicht gelöscht.
- Ausstehende Probe und nicht überwundenes Hindernis blockieren den Zustandsentwurf; keine Annahme vom Erzähler oder aus einem alten Kampagnen-Checkpoint.

## GETESTET / AKZEPTANZ

- `app/test/srd_long_jump_encounter_rules_test.dart`: positive Kampfbuchung in Dezimetern; Nichtverbrauch der Angriffsressourcen; Prone bei Landefehler und Erfolgsfall; fehlende oder gescheiterte DC-10-Prüfung; fremder Kampf, fremde Kampagne, fremde Revision, fremder Zug und beendeter Kampf; offene Regelaktionen; `liegend`/`gepackt`/Tempo 0 und nicht geklärte Sprungboni; bereits bezahlter Anlauf; exakte 9/10-Fuß-Grenze; halbe Fußstrecke; negatives/inkonsistentes Bewegungsbudget; Modell-JSON-Roundtrip; Schutz der unveränderten Eingabe.
- Testläufe sind **nur dann als bestanden** zu bezeichnen, wenn die GitHub-CI für die *abschließende Branch-SHA* erfolgreich ist. Ein zuvor erfolgreicher CI-Lauf von #284 deckt dieses neue Paket nicht ab.
- Kontrollbefehle:

```sh
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_long_jump_rules_test.dart
flutter test test/srd_long_jump_encounter_rules_test.dart
flutter test
flutter build apk --debug
```

## NICHT IMPLEMENTIERT / BLOCKIERT

- **Keine echte Aktion im `GameEngine`, kein Aufruf im `GameController`, keine Transaktion im SQLite-Repository, keine Ereignis-/Revisionsinkrementierung.** Die Projektion ist weder Commit noch `GameUpdate`, und das bloße `Campaign.fromJson` ist kein DB-Neustarttest. `prepare` darf keine Doppelevents/Idempotenz suggerieren. Ohne Controller-/Repository-Transaktion darf keine UI diese Projektion dauerhaft speichern.
- Ausdrückliche Bestätigung, dass der unmittelbar vorangehende Anlauf **tatsächlich durch dieselbe aktuelle Bewegungsaktion bereits bezahlt** wurde, muss die spätere zentrale Engine anhand ihres Buchungsjournals nachweisen. Das neue Bool-Flag allein ist noch **kein** manipulationssicherer Beweis.
- Attributeffekte/Sonderregeln wie Sprungweiteverdoppelung sowie die dauerhafte Speicherung echter 15-cm-Reste benötigen ein gesondertes, kompatibles Regel- bzw. Datenmodell. Keine fehlerhafte automatische Rundung.
- Keine SQLite-/Kampagnen-JSON-Migration (Version 2 / 1), keine App-Versionsänderung (0.8.42+92) und kein Android-Gerätetest.

## Genau ein nächster Schritt

**Nach der Integration des unabhängigen Regel-PRs #284 und nach Abstimmung mit dem Gelände-Integrations-PR #280** den Projektionstyp an die autoritative `GameEngine`-/`GameController`- und SQLite-Transaktion anschließen. Dabei Tests für revisionssicheren, eindeutigen Event-Commit, persistierte Landebedingung, bereits verbuchten Anlauf, DB-Rollback beim Event-Fehler und Restart auf echtem Spielstand hinzufügen.

# Chat A – SRD-5.2.1-Weitsprung: autoritativer Kampf-Commit (27.10.2026)

## Ausgangslage, Koordination und Quellgrundlage

- **Neuer unabhängiger Integrationsbranch direkt von `main`**: `feat/chat-a/long-jump-atomic-integration-20261027` auf `2421fcd18f4d980f31a71ec9d60e80a53b53e45b`.
- Gelände-Integration [#280](https://github.com/ManuEtt/Dnd/pull/280) ist bereits **in main** und wird dadurch nicht überschrieben. Die Quell-PRs [#284](https://github.com/ManuEtt/Dnd/pull/284) (Long-Jump-Preflight) und [#285](https://github.com/ManuEtt/Dnd/pull/285) (read-only Encounter-Projektion) bleiben offen, damit ihre geprüften Inhalte nachvollziehbar sind; dieser Integrations-PR importiert genau diese vier Fach-/Testdateien auf den aktualisierten main-Stand und fügt die echte Speicherung hinzu. **Vor dem Mergen prüfen, dass die früheren PRs nicht doppelt integriert werden.**
- Verbindliche Regelquelle: WotC SRD 5.2.1, *Rules Glossary – Long Jump*, Druckseiten 184–185; CC BY 4.0, [amtliche PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf).

## IMPLEMENTIERT

- `app/lib/domain/srd_long_jump_rules.dart`: reine bestätigte Sprungweitengrenzen, Zentimeterbewegung, Landung in schwierigem Gelände/Akrobatik SG 10 und niedriges Hindernis/Athletik SG 10.
- `app/lib/domain/srd_long_jump_encounter_rules.dart`: prüft Kampagnen-/Begegnungsrevision, aktiven eigenen Zug, offenen Wurf, Bedingungen, Bewegungsreste und nicht abgebildete Sprungboni; bereitet eine unverbindliche Bewegung/Prone-Projektion vor.
- **`GameEngine.confirmLongJump`**: erfordert explizite Bestätigung, eindeutige Handlungskennung und für vollen Anlauf **das unmittelbar vorausgehende bestätigte `combat.moved`-Ereignis** derselben Revision, desselben Kampfes und desselben Helden mit mindestens 3 m Bewegung. Die bisherige Behauptung `runUpAlreadySpentConfirmed` alleine ist nicht mehr ausreichend. Diese Anlaufprüfung ist absichtlich streng: nur `0` oder `10` Fuß statt eines unbewiesenen 9-Fuß-Anlaufs. Weder der Text des KI-Erzählers noch eine freie boolesche Behauptung erzeugt den Anlauf.
- Spielzustand wird einmal in `_commit` als `combat.longJumpConfirmed` protokolliert: verbleibende Bewegung, `liegend` bei bestätigtem misslungenem Akrobatikwurf, vorherige Deckung aufgehoben; Revisionsfortschritt und Replay-`stateAfter` konsistent. Eine Kampfaktion/Bonusaktion/Reaktion wird nicht verwendet.
- **`GameController.confirmLongJump`**: vor Ausführung Vergleich des gespeicherten `Campaign`-Stands und der erwarteten Revision; nach erfolgreicher Ausführung eine **atomare** `SqliteCampaignRepository.saveCampaign`-Transaktion mit Ereignis. Bei wiederholter Anfrage-ID wird das Ereignis mit allen Parametern verglichen und der gespeicherte Endzustand ohne zweite Bewegung übernommen; eine Kennung mit unterschiedlichen Fakten wird abgelehnt, einschließlich übernommener Kennungen anderer Aktionstypen. Nach konkurrierender Revision wird nur ein nachweislich identischer Request restauriert.
- Alle Änderungen im vorhandenen SQLite-2-/JSON-1-Modell, **keine neue Tabelle** und keine App-Versionserhöhung (0.8.42+92).
- Neue End-to-End-Fixture `app/test/srd_long_jump_atomic_storage_test.dart`: echter Laufbewegungs-Receipt vor Sprung, genau ein Event, Revisionsfortschritt, verlorene ACK-Antwort im laufenden Controller und nach SQLite-Neustart, veraltete Revision, Kollision einer Request-ID, Landung mit `liegend`, verweigerter oder fehlender Anlauf, offene D20-Probe, unrepresentierbare 225 cm, Rollback per SQL-Trigger beim Event-Insert und optionale Hindernisprobe SG 10.

## Teststatus und Prüfung

```sh
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_long_jump_rules_test.dart
flutter test test/srd_long_jump_encounter_rules_test.dart
flutter test test/srd_long_jump_atomic_storage_test.dart
flutter test
flutter build apk --debug
```

Die endgültige GitHub-Actions-CI auf **genau dem PR-HEAD** ist als Testbeleg nötig; eine frühe fehlgeschlagene Dart-Formatprüfung wird nicht als bestandener Test ausgegeben. Echte Android-Gerätetests, Signierung und TalkBack-Abnahme sind davon getrennt.

## Grenzen / noch nicht implementiert

- Es gibt **noch keinen Android-Dialog/Quick-Action**, um Spielleitungsentscheidungen und bestätigte Proben bequem und zugänglich einzugeben. Der Controller ist programmatisch erreichbar und wird durch Tests angesprochen.
- Von 15 cm abweichende Bewegungsreste (`225 cm` bei ungerader Stärke) bleiben gesperrt, da `Encounter` derzeit nur 10-cm-Schritte persistiert. Keine Rundung, keine Datenmigration.
- Die Würfel-Gesamtergebnisse werden als *ausdrücklich bestätigte* Eingaben des Spielers übernommen, nicht als signierte, verifizierte Würfel-Receipts; die UI darf keine KI-behaupteten Ergebnisse übernehmen.
- Der unmittelbar vorangehende normale Fußweg ist nur im vorhandenen `combat.moved`-Format mit ganzen Metern beweisbar; komplexere Zwischenbewegungen, andere Bewegungstypen und spezielle Sprungboni erfordern eigene geprüfte Quellen.
- Das Requirements-Register `COMBAT-TERRAIN-MAP` bleibt unvollständig, denn dieses Paket ist keine Abnahme der vollständigen SRD-Bewegungsautomatik.

## Genau ein nächster Schritt

Nach grüner CI und konfliktfreier Integration auf main: **ein zugänglicher, deutscher Weitsprung-Dialog** mit getrennter Anlauf-, Terrain-, Hindernis- und Probe-Bestätigung, der den Controller aufruft und ausstehende SG-Würfe statt stiller Erfolge darstellt. Dazu Widgettests und realer Android-Gerätetest.

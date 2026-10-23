# Bestätigte Parallelaktionen: Revision-Race-Absicherung

Stand: 23.10.2026. Reine Zuverlässigkeitsanforderung; keine neue SRD-Regel.

## Problem

Zwischen dem ersten SQLite-Read in `GameController.sendAction` und dem anschließenden transaktionalen Commit kann ein zweiter Controller dieselbe `requestId` bereits erfolgreich bestätigen. Vorher sah der verspätete Controller anschließend nur einen Revisionskonflikt. Die UI-Outbox blieb dann trotz bestätigter Spielerhandlung offen.

## IMPLEMENTIERT

- Ein `CampaignConflictException` am Ende einer mit Request-ID versehenen `sendAction` führt zu einem **einmaligen Read des bestätigten Spielstands**; es gibt **keine zweite Engine-Ausführung, keinen zweiten Wurf und keinen weiteren Aufruf des externen Erzählers** durch diesen Wiederabgleich.
- Ist die exakte Kombination aus `actionRequestId` und bereinigtem Text im bestätigten Journal, wird nur dieser gespeicherte Snapshot neu geladen und als erfolgreich bestätigt.
- Dieselbe ID mit abweichendem Text wird als Formatfehler abgelehnt; ein konkurrierender Commit mit anderer oder fehlender ID bleibt ein echter Revisionskonflikt.
- Der Abgleich gilt nur für den explizit geprüften SQLite-Revisionskonflikt. Andere Speicherfehler werden nicht verschluckt, alle Legacy-Aufrufe ohne ID bleiben unverändert.
- Keine SQLite-Schemamigration; alle bestehenden Event-, Snapshot- und Archivgrenzen bleiben bestehen.

## Tests

`app/test/controller_integration_test.dart`: Drei deterministische SQLite-Race-Szenarien mit zwei Controllern und einer Commit-Barriere: gleiche ID und gleicher Text, gleiche ID mit abweichendem Text, unterschiedliche ID. Die Tests vergleichen die bestätigte Revision und kontrollieren, dass der Schlüssel `brass-key` und das Ereignis nicht doppelt gespeichert werden.

Die endgültige Bewertung erfolgt erst nach erfolgreicher CI des Pull-Request-HEAD (Analyse, Flutter-Tests, Backend, Android Debug).

## Grenzen

- Zwei parallel gestartete Aufrufe können **vor dem Commit** jeweils bereits einen externen KI-Anbieter angefragt haben. Anbieterweite Kosten-Idempotenz braucht einen eigenständigen serverseitigen Request-Mechanismus.
- Ein gemeinsames SQLite-Repository mit konkurrierenden App-Einstellungen benötigt weiterhin eine transaktionale Outbox-Strategie; der hier behobene Race betrifft das atomare Kampagnenrevision-Speichern.
- Der Schutz betrifft `sendAction` mit `requestId`, nicht alle Würfel-, Inventar- und Kampfrunden-Endpunkte.

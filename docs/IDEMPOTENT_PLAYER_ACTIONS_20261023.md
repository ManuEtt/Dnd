# Würfelraunen – Idempotente Spielerhandlungen (23.10.2026)

## Ausgangspunkt

- Aktuelles `main` zum Beginn: `07cab7bc302946b1a0214b35ca1a566749307ff3` (PR #127 integriert).
- Separater, weiterhin offener UI-PR #128 bleibt unangetastet.
- Integrationstrack, keine neuen SRD-Regeln, kein neues SQLite-Schema, keine Änderungen an eigenen und importierten Spielständen.

## IMPLEMENTIERT

- `GameController.sendAction(text, requestId: id)` akzeptiert optional eine stabile Kennung pro vom Spieler bestätigter Eingabe. Der vorhandene API-Aufruf ohne Kennung bleibt kompatibel.
- Bei Kennung wird **vor** `GameEngine.act`, Würfeln oder externem Erzähler der aktuelle Spielstand aus der Repositoryquelle geladen; im bestätigten Ereignisprotokoll gespeicherte `actionRequestId` + `actionRequestText` kennzeichnen bereits vollzogene Befehle. Ein wiederholter identischer Befehl aktualisiert nur den sichtbaren bestätigten Snapshot, erzeugt aber **keinen** zweiten Wurf, keine zweite Belohnung und keinen erneuten Provideraufruf.
- Eine Kennung für einen abweichenden Text wird abgelehnt. Ungültige Kennungen ebenso. Neuer, konkurrierender Spielstand ohne die Kennung erzeugt einen Revisionskonflikt, statt den neueren Stand zu überschreiben.
- Die Kennung wird im vorhandenen ersten Ereignis des `GameUpdate` als zusätzliche Audit-Metadaten hinterlegt. `SqliteCampaignRepository.saveCampaign` persistiert Event, Revision, Charakterarchiv und Snapshot wie bisher in **derselben Transaktion**. Kein zusätzliches Event, keine zweite Revision, keine Regel- oder Storyfeld-Mutation.
- Ein vom Repository bestätigter, aber gegenüber dem Client fälschlich als fehlgeschlagen gemeldeter Commit kann durch dieselbe Kennung nach einem erneuten Versuch wiedergefunden werden. Bereits fehlerhaft abgelehnte Commits lassen sich mit derselben Kennung neu ausführen.

## Testfälle

In `app/test/controller_integration_test.dart` ergänzt:
1. Erfolgreicher SQLite-Commit mit simulierter verlorener Rückmeldung: einmaliger Schlüsselgewinn, Replay ohne Revision/Inventaränderung.
2. Neuer Controller + tatsächliches SQLite-Reopen: wiederholter Befehl mit derselben ID erzeugt kein neues Event. Eine neue ID ist dagegen eine neue Handlung.
3. Gescheiterter Commit verbraucht die ID nicht; der anschließende erfolgreiche Versuch wird genau einmal bestätigt.
4. Ungültige IDs, ID-Konflikt mit anderem Text sowie unveränderte alte Aufrufe ohne ID.

Vor Merge in CI auszuführen: Formatierung, `flutter analyze`, `flutter test`, Android-Debug-Build und native Tests. Ein erfolgreicher älterer Lauf ersetzt nicht die CI des aktuellen Commits.

## Verbleibende Grenzen / nächste Etappe

- **Noch nicht UI-verkabelt:** Die vorhandenen Texteingaben, Sprachaktionen und Schnellaktionen erzeugen bisher noch keine dauerhaft gespeicherten `requestId`-Werte. Das Controller-Verhalten schützt nur Aufrufe, die eine stabile ID tatsächlich mitgeben.
- Für automatische Wiederaufnahme nach App-Absturz benötigt die UI eine vor dem Versenden lokal gespeicherte Outbox mit derselben ID und dem unveränderlichen Text; diese muss bewusst mit PR #128 und dessen `_send({quickAction})` integriert werden. Wiederholte kostenpflichtige Backendanfragen vor erstem bestätigtem Commit benötigen eine separate serverseitige Idempotenzstrategie.
- Weitere mechanische Controller-Endpunkte (`resolveRoll`, `acceptAdventure`, Inventar-/Zauberbestätigungen usw.) benötigen später eigene typisierte Befehlskennungen und Tests. Die hier implementierte Garantie gilt **nur** für `sendAction` mit expliziter `requestId`.
- Android-Grafik, kleine Viewports, Touch/IME, Screenshotabnahme und wirkliche Geräteinstallation bleiben separat abzuprüfen. Es wurde kein neues Bild und keine neue SRD-Regel implementiert.

**Stabile interne Anforderung:** `WR-INT-REQUEST-001`. Keine offizielle SRD-Stelle, weil dies eine reine Zuverlässigkeitsanforderung des Produkts und keine Spielregel ist.

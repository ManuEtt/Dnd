# Erzählkontinuität: abgeschlossene Handlungsstränge bleiben abgeschlossen

Stand 24.10.2026 – [PR #161](https://github.com/ManuEtt/Dnd/pull/161)

## Reproduzierbares Problem

Der Backend-Endpunkt `/v1/story/advance` akzeptierte in `parseStoryTurn` jede bekannte Thread-ID mit einem der Werte `open`, `resolved` und `abandoned`, ohne den gespeicherten Vorzustand zu beachten. Eine generierte Erzählerantwort konnte daher einen vom Spieler bereits beendeten oder aufgegebenen Handlungsstrang wieder auf `open` setzen. Der Client übernimmt zulässige rein narrative `threadUpdates` später in die Kampagnenerinnerung. Das betrifft erzählerische Kontinuität, **keine** SRD-Regelmechanik.

## Begrenzt behobene Lücke

- `backend/src/story.ts` vergleicht vor der Freigabe jeden Update-Vorschlag mit dem übermittelten gespeicherten Threadstatus.
- `open` darf wie bisher eine narrative Fortschreibung nach `open`, `resolved` oder `abandoned` erhalten.
- `resolved` und `abandoned` dürfen von der KI nur mit **demselben** Status erneut erwähnt werden. Ein unbeauftragtes Wiederöffnen oder Umklassifizieren wird als `closed_story_thread` zurückgewiesen.
- Ausschließlich eine bereits **manuell** vorgenommene und gespeicherte Wiederöffnung im lokalen Editor, die als `status=open` im bestätigten Request ankommt, ermöglicht weitere automatische Updates. Kein neuer UI-Knopf und keine KI-Sonderrechte.
- Der Endpunkt gibt bei unzulässiger Anbieterantwort den bestehenden generischen HTTP-502-`provider_unavailable`-Fehler zurück; private provider- und Story-Inhalte werden nicht im Response ausgegeben.
- `stateChanges: []`, lokale Regel-/Würfel-/TP-/Quest-Autorität, Spielstandsformate (SQLite 2, Kampagnen-JSON 1), Android-UI und App-Version 0.8.38+88 bleiben unverändert.

## Prüfkriterien

`backend/test/story.test.ts` umfasst beide abgeschlossenen Zustände, unzulässige Rückkehr nach `open`, verbotene Statusumschreibung, erlaubte Notiz mit unverändertem Terminalstatus, Wiederöffnung erst nach manuell geändertem bestätigtem Input, Mock-Auswahl offener Handlungsstränge und HTTP-502 ohne Durchreichen privater Anbietertexte. Kein echter KI-Aufruf.

Lokale Befehle bei vorhandener Umgebung:

```bash
cd backend
npm ci
npm run typecheck
npm run build
npm test
```

Zusätzlich Repository-Gates über `bash scripts/check.sh`, Dart-Formatter, Flutter-Analyse und vollständige Android-GitHub-CI für den **finalen PR-HEAD** prüfen. Bereits grüne PRs #159/#160 sind **kein** Nachweis für PR #161.

## Abgrenzung und nächster Schritt

Die lokale manuelle Threadverwaltung (`StoryCampaignEngine.saveStoryThread`) wird nicht verändert. Eine weitere Variante mit ausführlich auditiertem Spielerbeschluss zum Öffnen eines zuvor abgeschlossenen Strangs ist ein separates zukünftiges Produktpaket. Dieser PR ist ausschließlich eine **fail-closed**-Sicherung der Backend-Grenze. Nach grüner CI Review und sichere Integration unter Abgleich mit dem aktuellen `main`.

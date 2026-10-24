# Rate-Limiter: aktives Anfragekontingent bei voller Kapazität bewahren

Stand 24.10.2026, [PR #162](https://github.com/ManuEtt/Dnd/pull/162)

## Ausgangsfehler

Der bisherige `WindowLimiter.take(key,now,windowMs,max)` begrenzte die Zahl gespeicherter Schlüssel mit `maxEntries=10000`. Bei voller Kapazität wurde bislang der älteste Map-Eintrag gelöscht, **auch wenn dessen Zeitfenster noch lief**. Ein neuer, wechselnder Schlüssel konnte dadurch für andere aktive Schlüssel gespeicherte verbrauchte Kontingente entfernen und beim nächsten Aufruf erneut freigeben.

Dies ist eine **backendseitige Sicherheits-/Belastbarkeitskorrektur**, keine SRD-5.2.1-Regeländerung. Eine tatsächliche Ausnutzung wurde nicht beobachtet; der Fehler ist am Quellcode und durch deterministische Tests nachvollziehbar.

## Gewählte Abhilfe

- Bei der Neuanlage wird, sofern die Map voll ist, jeder abgelaufene Eintrag (oder bei zurückspringender Zeit ein zukünftig gestarteter Eintrag) abgeräumt.
- Bleiben alle Plätze mit aktiven Fenstern belegt, wird der neue Schlüssel abgelehnt (`false`, beim HTTP-Endpunkt `429`). **Kein aktiver Eintrag wird verdrängt**.
- Bereits aktive Schlüssel erhalten bei Erreichen der Map-Grenze keine zusätzliche Quote. Bestehende Zeitgrenzen und `Retry-After`-Werte bleiben unverändert.
- Ein vollständiger Map-Sweep erfolgt nur bei voller Kapazität und ist durch `maxEntries` beschränkt; gegenüber dem vorherigen Verhalten wird die Kapazitätsüberschreitung konservativ behandelt.
- Backend-Prozessneustart setzt die bestehenden In-Memory-Zähler wie bisher zurück. Das ist **keine** verteilte globale Rate-Limit-Garantie; bei mehrfachen Instanzen ist ein externer gemeinsamer Speicher erforderlich.

## Tests und Abnahme

`backend/test/backend.test.ts` enthält jetzt zwei Regressionen für: wiederholte Anfragen mit rotierenden Schlüsseln, Erhalt bereits verbrauchter aktiver Kontingente, Wiederfreigabe exakt an der Zeitgrenze, selektives Entfernen abgelaufener Einträge und Rücksprünge der simulierten Uhr.

```bash
cd backend
npm ci
npm run typecheck
npm run build
npm test
```

Zusätzlich gelten die unveränderten Python-, Flutter-/Dart-, SQLite- und Android-Gates in `.github/workflows/android-build.yml`. Erfolg wird **nur** für einen tatsächlich abgeschlossenen GitHub-Actions-Workflow mit dem jeweiligen SHA gemeldet: [Checks PR #162](https://github.com/ManuEtt/Dnd/pull/162/checks).

## Unveränderte Grenzen

Weder KI noch Backend erhalten neue autoritative Rechte über Spielstände. Keine Änderungen an `main`, Android-App-Version 0.8.38+88, SQLite 2, Export-JSON 1, JSON/API-Strukturen oder SRD-Regelregister. Parallele PRs #159 (Sending), #160 (Schurke) und #161 (Story-Endzustände) bleiben unberührt. Gerätetest und produktive Signierung weiterhin separat offen.

**Genau ein nächster Schritt:** Vollständige CI des finalen PR-#162-HEAD inklusive Backend-/Flutter-/Android-Abnahme prüfen, gegebenenfalls Fehler korrigieren und erst danach PR zur Review freigeben.

# Gefüllte SQLite-Altspielstände sicher von Schema 1 auf 2 migrieren

**Testpaket vom 23.10.2026 · Würfelraunen 0.8.33+83 · CI-Abnahme ausstehend**

Die bisherigen Tests der Outbox-Migration legten nur eine ältere `settings`-
Tabelle mit ausstehenden Aktionen an. Dieses zusätzliche Paket prüft auch
**Kampagnen, Revisionshistorie, bestätigte Ereignisse, Charakterarchiv,
Einstellungen und PlayerActionOutbox** zusammen.

## Abnahmekriterien

- Der Test erzeugt über `GameController` und das echte Repository einen
  vollständig gespeicherten Spielstand mit bestätigter Spielhandlung.
- Anschließend wird der genaue strukturelle Unterschied des Altstandes
  hergestellt: `pending_player_actions` entfernen, SQLite-`user_version`
  auf 1 setzen. Die übrigen Tabellen und Datensätze bleiben unangetastet.
- Nach Öffnen über das aktuelle Repository bleibt der vollständige
  Kampagnensnapshot identisch. Revisionen 0 und 1, Ereignisse, Charakterarchiv
  und andere Einstellungen bleiben verfügbar. Die ursprüngliche Request-ID
  wird unverändert in die neue SQLite-Outbox übernommen.
- Erneutes Öffnen führt zu keiner zweiten Migration; JSON-Kampagnenexport
  bleibt `schemaVersion=1`.
- Bei einer beschädigten alten ausstehenden Aktion wird die gesamte Migration
  abgebrochen: SQLite bleibt Version 1, die neu angelegte Outbox-Tabelle ist
  wieder verschwunden und alle bestehenden Kampagnen-/Ereignis-/Archivdaten
  sind weiterhin vorhanden. Nach expliziter Korrektur kann die Migration
  erfolgreich nachgeholt werden.

## Test und Grenzen

```bash
cd app
flutter test test/populated_legacy_upgrade_test.dart
flutter analyze
flutter test
flutter build apk --debug
```

Die komplette GitHub-Actions-Pipeline ist zusätzlich erforderlich. **Das
Paket simuliert die alte Datenbankstruktur programmgesteuert**, es führt noch
keine echte Installation oder App-Aktualisierung auf einem Android-Gerät aus.
Vor Updates produktiver Geräte bleibt eine separate gesicherte Geräteprüfung
einschließlich Rückspielung eines Altspielstands erforderlich.

Keine neue SQLite-Migration, kein neues JSON-Format und keine D&D-Regel-
oder Storyänderungen werden in diesem Paket eingeführt.

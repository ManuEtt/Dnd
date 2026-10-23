# Bestandsmigration SQLite 1 → 2: gefüllte Spielstände

Stand: 23.10.2026 · Test-PR auf `main` `4061d651` · App bleibt `0.8.33+83`.

## Problem und Prüfumfang

Bislang getestet: Umzug älterer `pendingPlayerActionsV1`-Einträge aus
`settings` in die neue Tabelle `pending_player_actions`. Der zuvor
erfolgreich geprüfte PR #137 wurde **ohne Merge geschlossen**, weshalb seine
Prüfung einer **gefüllten** Datenbank auf `main` fehlt.

`app/test/populated_legacy_upgrade_test.dart` erstellt eine real gespeicherte
Demo-Kampagne mit bestätigter Handlung, Revisionshistorie, Ereignisjournal,
Heldenarchiv, Präferenzen und ausstehender Aktion. Der Test stellt anschließend
ohne Datenverlust die **alte** Struktur nach: Tabelle
`pending_player_actions` löschen und `user_version=1` setzen. Das echte
Öffnen des Repositorys führt dann die vorhandene Schema-2-Migration aus.

## Akzeptanzfälle

1. Identischer Kampagnensnapshot samt Ereignissen, Revisionen 0/1,
   Heldenarchiv und Inventar vor/nach der Migration.
2. Alle unabhängigen Einstellungen bleiben erhalten; die neue Outbox
   enthält dieselbe Request-ID und denselben Text; nach Neustart unverändert.
3. Der Kampagnen-JSON-Export bleibt weiterhin `schemaVersion=1`.
4. Fehlerhafte Legacy-Aktion: Migration schlägt fehl und hinterlässt
   **vollständige alte** Datenbank inkl. Version 1 und ursprünglichem
   Settings-JSON; kontrollierte Reparatur erlaubt erneute Migration.
5. Zwei alte Handlungen mit **derselben Request-ID**: Eindeutigkeitskonflikt
   muss vollständig zurückrollen, statt nur einzelne Aktionen zu verlieren.

## Nachweise und Grenzen

Der frühere Code für Fälle 1–4 bestand die vollständige
[GitHub-CI #39964813706](https://github.com/ManuEtt/Dnd/actions/runs/39964813706)
auf PR #137. Dies ist **kein** Testnachweis für den neu hinzugefügten Fall 5
oder diesen neuen Branch. Der aktuelle PR muss separat Flutter-Analyse,
vollständige Flutter-Suite, Backend, Android-Build und native Tests bestehen.

```bash
cd app
flutter test test/populated_legacy_upgrade_test.dart
flutter test
flutter analyze
flutter build apk --debug
```

Es werden nur temporäre Testdaten benutzt. Noch ausstehend: Installation und
Migration einer tatsächlich auf Android installierten alten App mit lokalem
Spielstand, Backup vor dem Upgrade und vollständiger Restore-Test. Es wird
weder das SQLite-Schema (bleibt 2) noch das Kampagnen-JSON-Format (bleibt 1)
verändert; keine Regel-, Story- oder KI-Provider-Änderung.

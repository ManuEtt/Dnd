# Dart-CI-Formatfehler reparieren – Würfelraunen

**Basis:** GitHub `ManuEtt/Dnd`, `main`, Commit `252c6a6138da438617c560c1ae51a0fd08973b5a`, Version `0.8.1+51`.

## Gesicherte Ursache

GitHub Actions, Lauf [39130795941](https://github.com/ManuEtt/Dnd/actions/runs/39130795941),
verweigert den Build im Schritt `Dart-Formatierung prüfen`, da der offizielle Formatter
**fünf** Dateien ändern würde:

- `app/lib/ui/equipment_catalog_dialog.dart`
- `app/lib/ui/equipment_fields.dart`
- `app/test/domain_game_test.dart`
- `app/test/equipment_fields_test.dart`
- `app/test/ui_backup_test.dart`

Alle vorgelagerten Backend-Tests waren erfolgreich. Flutter-Analyse, Flutter-Tests und Android-Build
wurden nicht ausgeführt. Daher sind weitere Probleme nach der Formatkorrektur möglich.

## Empfohlen: GitHub ohne lokales Flutter-SDK

1. Übernehme **nur** die beiden neuen Dateien `.github/workflows/dart-format-reparieren.yml`
   und `scripts/fix_dart_format.sh` in das GitHub-Repository. Dazu das ZIP entpacken;
   auf GitHub `Add file` > `Upload files` wählen, oder für versteckte `.github`-Ordner
   über `Add file` > `Create new file` den Pfad exakt eintragen.
2. Öffne `https://github.com/ManuEtt/Dnd/actions`.
3. Wähle links **Dart-Formatierung reparieren** > **Run workflow** > `main`.
4. Die Action benutzt **Flutter 3.35.7** und führt `dart format lib test` sowie die
   bestehende strenge Formatprüfung aus. Anschließend erstellt sie nach Möglichkeit einen
   neuen Branch und einen Pull Request. Sie verändert `main` nicht direkt.
5. Öffne den Pull Request, prüfe das Ergebnis der regulären Android-CI und merge erst
   bei erfolgreicher Prüfung.
6. Falls GitHub Actions keine Schreibrechte hat, lade bei diesem Lauf unter **Artifacts**
   `wuerfelraunen-dart-format-reparatur-...` herunter. Es enthält den genauen Patch,
   die fünf formatierten Quelldateien mit ihren Pfaden und eine SHA256-Prüfsumme.
   Übertrage dann die Dateien in einen neuen Branch und erstelle einen PR.

Falls der Workflow sich trotz `permissions` nicht pushen kann, in GitHub unter
**Settings > Actions > General > Workflow permissions** `Read and write permissions`
aktivieren (sofern von deinem Kontotyp/der Organisation erlaubt) **oder** den
Artefakt-Patch manuell übernehmen.

## Lokal, falls Flutter/Dart SDK vorhanden

```bash
bash scripts/fix_dart_format.sh
cd app
flutter analyze
flutter test
```

Erst nach tatsächlichem Durchlauf über einen erfolgreichen Android-GitHub-Workflow gilt
auch der Android-Build als geprüft.

## Status dieses Downloads

Dies ist der **vollständige, unverändert aus dem neuesten GitHub-Checkpoint bezogene
Projektstand** mit einer neuen **gezielten Format-Reparaturmöglichkeit**, nicht die
bereits vom Dart-Formatter behandelte finale Quellversion: In der Umgebung dieses
Downloads ist das Dart-SDK nicht installiert, und der verbundene GitHub-Schreibzugriff
liefert HTTP 403. Deshalb weder Erfolg der Formatprüfung noch Reparatur im Remote-Repository behaupten.

Die bestehende `.github/workflows/android-build.yml` bleibt absichtlich unverändert.

# Import und Tests – Würfelraunen 0.6.5+35

**Basis-Commit:** `49c8c39af045c6d0e3a78eba23e95383c3c31a84` (`ManuEtt/Dnd`, `main`).
**Status:** Quellcode-Iteration ohne Flutter-/APK-Abnahme. Android-Paket-ID und Savegame-Schema wurden nicht verändert.

## Vollständiges ZIP

Das ZIP enthält alle Projektdateien unmittelbar in der Archivwurzel, insbesondere `app/`, `backend/`, `.github/`, `scripts/`, Assets und Dokumentation. In ein neues Verzeichnis auspacken, `app/` als Flutter-Projekt öffnen. Für bestehende Git-Repositories nicht blind alles überschreiben: zuerst den Unterschied zum Basis-Commit prüfen.

## Gezielter Patch statt Vollimport (empfohlen)

Der separat bereitgestellte Patch ist exakt gegen das Basis-Commit erstellt. Im vorhandenen Git-Checkout:

```bash
git switch main
git pull --ff-only
git switch -c feature/srd-damage-rules-ci-fix-20261016
git apply --check Dnd_Wuerfelraunen_0.6.5_35_Aenderungen.patch
git apply Dnd_Wuerfelraunen_0.6.5_35_Aenderungen.patch
python3 scripts/verify_project.py .
python3 -m unittest discover -s scripts/tests -v
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Falls `git apply --check` fehlschlägt, wurde `main` wahrscheinlich inzwischen geändert. **Dann nicht automatisch forcieren:** Unterschiede prüfen und einen manuellen Merge durchführen. Bei grünem CI einen Pull Request erstellen. Die Android-Action baut die APK erst nach bestandenen Tests.

## Umfang

- Widgettestfehler (`9 m` statt `9.0 m`) korrigiert.
- Konzentrations-SG auf 30 gedeckelt.
- SRD-Regellogik für 13 Schadensarten, Resistenz, Anfälligkeit, Immunität und Nicht-Stapelung als wiederverwendbare Domain-Komponente ergänzt.
- `app/test/damage_rules_test.dart` und zusätzliche Regressionen ergänzt.

**Grenzen:** Es ist noch kein allgemeines Monster-/Zauber-Defensivprofil im Spielzustand hinterlegt. Eine automatische Anwendung in allen Kampfarten wird daher nicht behauptet. Der Code wurde nicht nach GitHub gepusht; GitHub meldete für die Branch-Anlage HTTP 403.

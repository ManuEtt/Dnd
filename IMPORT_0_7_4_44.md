# Import der Entwicklungsversion 0.7.4+44

**Ausgangsbasis für den Patch:** das vollständige Projektpaket `0.7.3+43`, nicht direkt der unveränderte GitHub-Stand `0.7.2+42`. Das neue Vollprojekt-ZIP ist selbstständig und benötigt keinen Patch.

## Import

Vollprojekt-ZIP entpacken: `app/`, `backend/`, `.github/` und `README.md` liegen direkt im Root. Bestehende Benutzer-Spielstände vorher über die App sichern. In GitHub entweder die fehlenden Projektänderungen zusammenführen oder einen neuen Branch anlegen; vorhandene unabhängige Änderungen nicht blind überschreiben.

Ein Patch lässt sich mit `git apply --check Dnd_Wuerfelraunen_0.7.4_44_Aenderungen.patch` im Root von **0.7.3+43** prüfen, anschließend mit `git apply ...` anwenden.

## Tests vor einer Veröffentlichung

```bash
python3 scripts/verify_project.py .
python3 -m unittest discover -s scripts/tests -v
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Die Flutter-/Android-Schritte konnten in dieser Umgebung nicht ausgeführt werden. Die erzeugte ZIP ist ein **Quellprojekt**, keine verifizierte APK. Sie implementiert einen zusätzlichen, klar begrenzten Satz von Regelmechaniken; nicht die vollständige SRD-Engine.

Die Liste der Änderungen, Grenzen und deutschen Befehle steht unter `docs/CLASS_ACTIONS_AND_SAVES_0_7_4.md`.

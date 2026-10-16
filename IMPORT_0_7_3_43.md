# Import: Würfelraunen 0.7.3+43

**Ausgangsbasis:** `ManuEtt/Dnd` Commit `91ffddd246a3aa07780bf1bbafa9ce2c17726e21`, Version `0.7.2+42`.

**Vollständiges Archiv:** Die ZIP enthält das Projekt ab Wurzelordner, einschließlich Android, Flutter, Backend, Quellen und `.github/workflows/android-build.yml` (keine Codex-Entwicklungs-Action). In ein frisches Verzeichnis entpacken und als Projekt öffnen.

**Patch:** Das Änderungs-Patch ist nur gegen den angegebenen Ausgangsstand gedacht. In einem Klon auf genau diesem Commit ausführen: `git apply --check ../Dnd_Wuerfelraunen_0.7.3_43_Aenderungen.patch` und nach erfolgreicher Prüfung `git apply ../Dnd_Wuerfelraunen_0.7.3_43_Aenderungen.patch`. Bereits geänderte Dateien zuvor abgleichen. Kein Force-Push.

**Neu:** Ausführbare Mönchs-Selbstwiederherstellung (Stufe 10), Rettungswurfübung aller sechs Attribute ab Mönchsstufe 14, CI-Korrektur von nullable Kampfkunstattributen und Regressionstests.

**Validierung vor Installationsfreigabe:**

```
python3 scripts/verify_project.py .
python3 -m unittest discover -s scripts/tests -v
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Die letzten drei Kommandos sind hier nicht ausgeführt worden, daher wird keine installierbare APK behauptet. Das Speicherschema bleibt 1; ältere Spielstände ohne das optionale Feld bleiben ladbar.

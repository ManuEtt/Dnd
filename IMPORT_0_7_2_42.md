# Import Würfelraunen 0.7.2+42

Basis-Commit: `73c5bfe5f39b5f3189eec5dc5aeeebe5fc083fa2`, Version 0.7.1+41.

1. Das gesamte ZIP in ein leeres Projektverzeichnis entpacken oder den Patch mit `git apply --check` und `git apply` gegen obigen Commit einspielen.
2. `python3 scripts/verify_project.py .` sowie `python3 -m unittest discover -s scripts/tests -v` ausführen.
3. Im Ordner `app`: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug`.
4. Nach erfolgreicher CI die neue Android-Version bereitstellen.

Die Projektdateien behalten die bestehende Verzeichnisstruktur; alte Schema-1-Speicherstände ohne `temporaryHitPoints` bleiben kompatibel.

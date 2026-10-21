# Android-SDK-Installation in CI: Wiederholungslogik

## Anlass

Beim GitHub-Actions-Lauf #39652374316 (Branch von PR #99) wurden Backend, Dart-Formatierung, Flutter-Analyse und die vollständige Flutter-Testsuite erfolgreich abgeschlossen. Die Installation der Android-Buildwerkzeuge scheiterte dagegen bei `ndk;27.0.12077973` mit `Error on ZipFile unknown archive`: ein beschädigtes oder unvollständiges SDK-Downloadarchiv auf dem Runner.

## Änderung

Der Schritt `Android-Plattformen und Buildwerkzeuge installieren` führt nun `scripts/install_android_sdk_packages.sh` aus.

- Bis zu drei Versuche mit begrenzter Wartezeit, bei Erfolg sofortiger Abbruch.
- Gleichbleibende Android-Plattformen 34, 35 und 36, Build-Tools 35.0.0, NDK 27.0.12077973, CMake 3.22.1.
- Nach einem gescheiterten Versuch werden ausschließlich temporäre SDK-Downloads und das partielle NDK-Verzeichnis im aktiven SDK-Root entfernt.
- Nach drei Fehlschlägen bricht die CI eindeutig mit Fehler ab; kein falsches Erfolgssignal.
- Sicherheitsprüfung des SDK-Root-Pfads verhindert Löschung bei leerem, relativem oder Root-Verzeichnis.

## Tests

`python3 -m unittest discover -s scripts/tests -v` prüft über einen lokalen Mock von `sdkmanager` den erfolgreichen zweiten Versuch, die feste Obergrenze der Wiederholungen, Bereinigung der temporären Downloads und die Pfadvalidierung.

Die Änderung betrifft ausschließlich die CI-Buildumgebung und verändert keine D&D-Regeln, Android-App-Funktionen oder App-Buildparameter.

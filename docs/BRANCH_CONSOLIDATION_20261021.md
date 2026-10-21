# Konsolidierung der Entwicklungsbranches – 21.10.2026

## Ergebnis der Bestandsaufnahme

Vor der Bereinigung zeigt GitHub genau acht Branches: `main` und die sieben
im Cleanup-Skript einzeln mit SHA festgehaltenen Alt-Branches.
Der geprüfte `main`-Commit war
`cab20cf3f299c7dc18da121f3c2c16bfb382548b`.

* PR #85 und #88 haben die beiden SRD-Funktionsbranches direkt nach `main`
  integriert; ihr GitHub-Vergleich ergibt jeweils `ahead_by=0`.
* PR #90 wurde gemergt. Der komplette Datei-Baum von
  `integration/rabenwacht-story-current-main-20261021` ist SHA-für-SHA
  identisch mit dem geprüften `main`-Baum (524 Dateien).
* Die drei früheren Kapitelbranches enthalten ältere Zwischenstände derselben
  Fortsetzung. Ihre neuen Akt-VIII-, Epilog- und Brief-von-Morgen-Dateien
  samt Tests sind auf `main` mit identischem Blob-SHA vorhanden.
* `integration/rabenwacht-acht-epilog-brief-20261021` war ein älterer
  Integrationsversuch (#89, nicht gemergt). Die Rabenwacht-Dateien sind im
  neueren PR #90 enthalten; die Abweichungen stammen aus zwischenzeitlichen
  SRD/UI-Änderungen und Status-Dokumentation.

## Sicherung gegen Datenverlust

Die Einmal-Aktion vergleicht alle alten Datei-Blobs mit dem aktuellen `main`
und toleriert nur vorher explizit geprüfte Pfade, deren Inhalt durch spätere
Regel-/UI- oder Story-Integration überholt wurde. Außerdem prüft sie sieben
konkrete Story-Code-/Test-Blob-SHAs von `main`.

Jede Löschung setzt voraus: exakte ursprüngliche Branch-SHA,
nicht geschützt, unverändertes `main`, bestätigte Geschichte oder
Dateiabdeckung, und unmittelbar vor dem API-Aufruf erneut identische
Branch-SHA. `main` selbst wird niemals gelöscht. Der Maintenance-Branch
wird nur gelöscht, falls auch er vollständig in `main` enthalten ist.

Die vorab bereits erfolgreiche GitHub-Actions-Pipeline für `main`
umfasst Dart-Formatierung, Flutter-Analyse/-Tests, Backend-Tests und
Android-APK-Build. Ein Realgerätetest ist dadurch **nicht** bestätigt.
Der neue Cleanup-PR ändert **keinen App- oder Backend-Quellcode**;
er ergänzt nur diesen Nachweis, die Safety-Tests und den Workflow.

Nach erfolgreichem Cleanup kann der einmalige Workflow in einem
separaten Folgeschritt entfernt werden. Er löscht keine unbekannten Branches.

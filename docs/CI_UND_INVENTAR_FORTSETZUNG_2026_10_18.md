# Würfelraunen – CI- und Inventarkorrekturen (18.10.2026)

**Remote-Basis:** `ManuEtt/Dnd`, Branch `main`, Commit `58c6fd155ff88517c8764fe7525c35a3e6228d92`.
**Lokaler Stand:** Noch NICHT auf GitHub übertragen, Android-Build NICHT bestätigt.

## Änderungen

1. Die im vorherigen Paket nachweislich fehlerhafte Dart-Formatierung von fünf Dateien wird durch die **originalen vom offiziellen Dart-Formatter im GitHub-Actions-Lauf 39133071528 erzeugten Fassungen** ersetzt. Der damalige zweite Formatlauf ergab 0 Änderungen. Neue Dart-Codeänderungen danach benötigen einen erneuten Formatlauf.
2. Die einmalige Formatier-Action enthält keine verbotene Nennung des Entwicklungsagenten mehr. Ein Python-Repositorytest hatte zuvor deshalb versagt.
3. `InventoryItem.copyWith()` ermöglicht das Aktualisieren der Stückzahl, ohne `catalogId`, ID, Name und Beschreibung zu verlieren.
4. Der reale Heiltrankverbrauch benutzt `e.copyWith(quantity: e.quantity - 1)` statt einen Eintrag zu konstruieren, der die Katalogreferenz verliert.
5. Zusätzlicher Domain-Regressionstest prüft einen Stapel von zwei kataloggebundenen Tränken und den JSON-Roundtrip nach einer Entnahme.
6. Zusätzlicher Widget-Regressionstest prüft, dass die fixierte Schnellaktionsleiste nur auf der Abenteuerseite und nicht auf Start, Helden, Tagebuch oder Optionen erscheint.

## Tatsächlich ausgeführte Prüfungen

- `python3 scripts/verify_project.py`: bestanden.
- `python3 -m unittest discover -s scripts/tests -q`: 60 Tests bestanden.
- Der neue Flutter-/Dart-Code konnte mangels installiertem Flutter-/Dart-SDK in dieser Umgebung **nicht** kompiliert, analysiert, formatiert oder per Flutter-Tests ausgeführt werden.
- Die vollständige Android-CI muss nach Übernahme auf GitHub laufen.

## Übernahme und nächste Prüfung

Option A: Projekt-ZIP in einen **neuen Arbeits-Branch** auf Basis des genannten Commits entpacken und Dateien übernehmen, anschließend `git diff` kontrollieren. Nicht unkontrolliert neuere Commits auf `main` überschreiben.

Option B: beigefügten Patch auf einem frischen Klon dieses Commits mit `git apply --check PATCHNAME` prüfen und mit `git apply PATCHNAME` anwenden.

**Nach dem Import in einer Flutter-Entwicklungsumgebung:**

```bash
cd app
dart format lib test
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Danach in einem separaten Commit auf Branch pushen, Pull Request erstellen und Build prüfen.
Die Version bleibt vorerst `0.8.1+51`, weil ein erfolgreicher Android-Build für diese Erweiterung fehlt.

## Noch offen

- Komplett typisiertes Inventar-Modell einschließlich individueller Waffen-/Rüstungs-/Magie-Werte mit Editor, Persistenz, Effekten und Migrationen.
- Vollständige Umsetzung des neuen Fantasy-Designs.
- Weitere D&D-SRD-Regelautomation und reale Android-Geräteabnahme.

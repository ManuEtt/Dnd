# Qualitätscheckpoint – 2026-11-12

- **Ausgangs-main:** `32d1ffac6f022af65550cd02895e9915816e0f34`
- **Branch:** `fix/chat-d/boundary-symlink-roots-20261112`
- **Codecommit:** `ee575a45241230a4d9799654b20657846b8f983a`
- **Problem:** Symbolische Links an vier Verzeichnisebenen und Dart-`part`-/`part of`-Direktiven müssen gegen Modulgrenzen abgesichert bleiben.
- **Änderung:** Sieben isolierte Python-Regressionstests in `scripts/tests/test_domain_boundary_roots.py`; bestehende Produktionslogik unverändert.
- **Akzeptanzkriterien:** Verknüpfte App-, Lib-, Story- und Unterverzeichnisse werden abgewiesen; Cross-Module-`part of` wird abgewiesen; gleiches Modul bleibt erlaubt.
- **Tests:** Bei Veröffentlichung noch nicht ausgeführt; CI-Status separat prüfen. Keine grüne CI vorwegnehmen.
- **Spielstände / Migrationen:** Keine Änderungen.
- **Zentrale Dokumentation:** README und gemeinsam genutzter Checkpoint bewusst unverändert, um parallele append-only-Nachträge nicht zu überschreiben.
- **Nächster Schritt:** Pull-Request-CI vollständig prüfen und bei Fehlschlag denselben Branch korrigieren.

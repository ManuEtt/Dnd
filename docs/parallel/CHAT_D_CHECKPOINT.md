# CHAT D – Inkrement D-002: rekursiver Architekturgrenzen-Check

**Datum:** 25.10.2026

## GitHub-Stand und Zuständigkeit

- **Ausgangs-main-SHA:** `fb788a980b8ee9eb60439c249f3e1f5092a9f188` (PR #176 gemergt).
- **Eigener Branch:** `fix/chat-d/nested-boundary-scan-20261025`.
- **Technischer Commit:** `5d8a60d1133b7bb907597177395cb766bfd9c13e` (vor Dokumentation).
- **PR:** wird nach Veröffentlichung dieser Notizen erstellt; URL im PR-Beschreibungseintrag nachprüfen.
- **Parallel:** Chat D PR #177 (CI-Qualitätsgates), Chat C #178 (NPC), Chat B #179 (Erinnerungen), Chat A #180 (Zauberdauern).
- **Pfadabgleich:** Diese Arbeit ändert ausschließlich den Architekturprüfer, seinen neuen Python-Test sowie die ausdrücklich vereinbarten gemeinsam verwalteten README-/Checkpoint-Dokumente. Andere PRs bearbeiten nicht den Prüfer oder den neuen Test. Zentrale Dokumentation beim Integrationsschritt additiv erhalten.

## Ausgangsproblem

`scripts/check_domain_boundaries.py` nutzt `glob("*.dart")` und übersieht Dart-Dateien in Unterverzeichnissen von `app/lib/story/` bzw. `app/lib/domain/`. Außerdem kann `check_imports` bisher nur wörtlich geschriebene relative Imports wie `../story/` beziehungsweise `../domain/` zuverlässig beurteilen. Verschachtelte Pfade (`../../story/`) und äquivalente `./../`-Schreibweisen umgehen dadurch die Architekturgrenze.

## Implementiert

- Rekursives `rglob("*.dart")` in den zwei überwachten Bereichen.
- Pfadauflösung mit `posixpath.normpath` vor der Prüfung gegen die unveränderte Modulzugehörigkeit; die expliziten Legacy-Adapter bleiben zugelassen.
- Erlaubte gemeinsame Story-Datenmodelle anhand ihres kanonischen Dateiziels identifizieren, damit legitime verschachtelte Module funktionsfähig bleiben.
- Sechs neue positive/negative Python-Regressionstests in `scripts/tests/test_nested_domain_boundaries.py`.

## Geänderte Dateien

`scripts/check_domain_boundaries.py`, `scripts/tests/test_nested_domain_boundaries.py`, `docs/parallel/CHAT_D_CHECKPOINT.md` auf diesem Branch, `README.md`, `docs/CODEX_CHECKPOINT.md`.

## Tests und CI-Ergebnisse

- **GETESTET:** Sechs neue Python-Unit-Tests mit dem vorgeschlagenen Prüfer in einer isolierten lokalen Projektstruktur: **6 bestanden, 0 fehlgeschlagen**. Positive Fälle: erlaubte verschachtelte Story-/Modell-Imports; negative Fälle: verbotene verschachtelte Regel-/Story-Imports, Alias-Pfade und rekursive Unterordnerprüfung.
- **NICHT GETESTET:** Alle vorhandenen Python-, Flutter-, Node-/Backend-, Android- und JVM-Prüfungen gegen den vollständigen Checkout; die GitHub-Actions-Abnahme des aktuellen Branch-Commits. Eine abweichende CI-Basis oder einen alten grünen Lauf nicht auf diese Änderung übertragen.
- **BLOCKIERT:** Vollständiger Projekt-Checkout ist hier nicht lokal verfügbar, Flutter- und Android-SDK fehlen. GitHub Actions ist für die vollständige Abnahme zuständig.

## Spielstand-/Lizenzfolgen und offene Aufgaben

Keine Änderung an Domain- oder Story-Dart-Dateien, SQLite, JSON, SRD-Regelinhalten, Assets oder Lizenztexten; keine Migration. Hauptwirkung ist die zukünftige Ablehnung unzulässiger Modul-Imports auch bei Unterordnern.

## Genau ein nächster Schritt

Den **vollständigen CI-Lauf auf dem finalen D-002-Commit** (inkl. Python-Suite, zwei Architekturprüfern, Flutter/Android und APK-Artefakten) erfolgreich nachweisen und den PR erst nach konfliktfreier README-/Checkpoint-Konsolidierung gegen den dann aktuellen Main zur Integration freigeben.

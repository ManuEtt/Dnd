# CHAT D – Qualität, Speicherung und Integration

## Inkrement 2026-10-25: Regel-/Story-Grenzen und SRD-Register als CI-Gates

- **Ausgangs-main-SHA:** `5c1499a9342449050bb946542659b221ac2653da` (PR #175 bereits gemergt).
- **Eigener Branch:** `fix/chat-d/ci-rule-quality-gates-20261025`.
- **Code-/Test-Commit:** `40bb07cd98f4e8ed65ea373acc913d016f60d4b6` (vor den späteren Dokumentations-Commits).
- **Pull Request:** [#177](https://github.com/ManuEtt/Dnd/pull/177), zunächst Draft, gegen `main`.
- **Parallel laufender PR:** [#176](https://github.com/ManuEtt/Dnd/pull/176) betrifft Gelegenheitsreaktionen und unter anderem die zentralen Dokumentationsdateien. Keine gemeinsam bearbeiteten **technischen** Dateipfade; Dokumentationskonflikte vor einem Merge manuell konsolidieren.

### Ausgangsproblem

Das Repository schreibt `scripts/check_domain_boundaries.py` und `scripts/srd_coverage.py --json` als Prüfungen vor, führt beide aber bislang weder in `scripts/check.sh` noch als eigene CI-Schritte aus. Eine grüne Android-CI konnte daher diese beiden Vertragseigenschaften nicht belegen.

### Implementiert

- `.github/workflows/android-build.yml`: zwei verpflichtende Schritte vor der Python-Unittestsuite.
- `scripts/check.sh`: dieselben Schritte mit `set -euo pipefail`; fehlschlagende Prüfungen stoppen die Folgearbeit.
- `scripts/tests/test_ci_rule_quality_gates.py`: vier Testfälle inklusive positiver und negativer Konfigurationsprüfung.

### Geänderte Dateien

`.github/workflows/android-build.yml`, `scripts/check.sh`, `scripts/tests/test_ci_rule_quality_gates.py`, `docs/parallel/CHAT_D_CHECKPOINT.md`, `docs/CODEX_CHECKPOINT.md`, `README.md`.

### Tatsächliche Prüfungen und CI

- **GETESTET:** 4 neue Python-Unittests mit Python 3 in einem lokalen, isolierten Mini-Projekt mit repräsentativen Konfigurationen bestanden; danach die drei geänderten technischen Dateien in GitHub erneut abgerufen und die aktiven Befehle geprüft.
- **NICHT GETESTET:** alle Python-Tests gegen den vollständigen Repository-Checkout; die zwei Prüfskripte gegen die tatsächlichen SRD-/Dart-Dateien; Flutter-/Dart-/npm-/Android-Tests lokal. Keine vollständige CI-Abnahme oder APK dieses Inkrements behaupten, bis ein zugehöriger Actions-Lauf mit passendem Commit tatsächlich erfolgreich abgeschlossen ist.
- **CI:** Zum Anlegen des Checkpoints noch offen. Erneut den endgültigen PR-HEAD und zugehörige GitHub Actions kontrollieren.

### Migrationen, Risiken und bekannte Fehler

Keine Änderung am SQLite-Schema, an JSON-Sicherungen, Regeln, UI oder Backend; **keine Migration**. Die strengeren Gates können echte bestehende Integrationsfehler sichtbar machen, die bisher nicht geprüft wurden. Das offene SRD-Inventar soll weiterhin unvollständig bleiben dürfen: daher bewusst **kein** `--require-complete-inventory` und keine behauptete globale SRD-Fertigstellungsquote. README-/Zentralcheckpoint-Konflikte mit PR #176 erst beim koordinierten Integrationsschritt auflösen.

### Nächster konkreter Schritt

PR #177 nach Abschluss der GitHub-Actions-Läufe auf dem **finalen** Commit prüfen; Akzeptanz: neue Gates, reguläre Python-/Backend-/Flutter-Jobs und Android-Artefakte erfolgreich, PR ohne Überschreiben paralleler Dokumentation konfliktfrei integrierbar. Keine automatische Zusammenführung oder Branchlöschung.

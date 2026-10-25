# CHAT D – Qualität und Integration: laufender Stand

## D-002-Abgleich nach vollständiger Integration von PR #177

Neuer Ausgangs- und gemeinsamer Main-Stand: `97a06118f17d71cc77be2cb15a2fc9a53db20ee0`. Der vollständig geprüfte [PR #177](https://github.com/ManuEtt/Dnd/pull/177) ist integriert (regulärer Merge; keine Fremd-PRs verändert). D-002 übernimmt die neue Architektur-/SRD-CI-Absicherung unverändert. Der vorherige D-002-Branch-HEAD `88455ce02a8467d8666f172890339815a2c8a863` und sein Main-Vorfahr werden in einem nicht-erzwingenden Merge zusammengeführt. Für die vollständige Abnahme des neuen Head ist eine weitere CI erforderlich. Die darunter dokumentierten ursprünglichen Basis-/PR-Statusangaben bleiben als historische Belege erhalten.

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

---

# CHAT D – Qualität, Speicherung und Integration

## Main-Synchronisierung nach PR #176 – 25.10.2026

Main `fb788a980b8ee9eb60439c249f3e1f5092a9f188` enthält jetzt PR #176 (persistente Bewegungsunterbrechung). Der bisherige PR-D-Basisstand war `5c1499a9342449050bb946542659b221ac2653da`. Die geänderten technischen Pfade von Chat D überlappen weder mit #176 noch mit den offenen PRs #178–#180; README und zentraler Checkpoint wurden additiv anhand des neuen Main-Inhalts zusammengeführt. Frühere, inzwischen veraltete Angaben zur PR-176-Offenheit unten sind historisch.

Beobachtete CI [#40217436454](https://github.com/ManuEtt/Dnd/actions/runs/40217436454) für den **vorherigen** HEAD `1fdd3c0`: Architekturgrenze, SRD-Register, Python-Unit-Tests, Backend-Tests, Flutter-Analyse und Flutter-Tests erfolgreich, Android-Build zur Abfrage noch laufend. Für den neuen Kombinations-HEAD ist eine eigenständige finale CI nötig. Keine Fremd-PRs automatisch gemergt, keine Datenmigration.

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

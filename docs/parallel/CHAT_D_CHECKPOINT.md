# Chat D – D-003: Eindeutige, sichere APK-ZIP-Einträge

- **Datum / Zuständigkeit:** 25.10.2026 / Chat D Qualität, Speicherung, Integration.
- **Ausgangs-main-SHA:** `97a06118f17d71cc77be2cb15a2fc9a53db20ee0` (PR #177 integriert, PR #182 noch separat in Abnahme).
- **Branch:** `fix/chat-d/apk-zip-validation-20261025`.
- **Code-/Test-Commit:** `91c1911efcf39cc4a7708603e89a47c56c16cf32`.
- **Pull Request:** wird anschließend gegen `main` angelegt; PR und finale SHA dort überprüfen.
- **Offene parallele PRs:** Chat D #182 (anderer Prüfpfad), Chat A #180, Chat B #179/#181, Chat C #178; keine Regel-, Story-, Android-UI- oder Speicherdatei geändert.

## Ausgangsproblem

`validate_arm64_apk` in `scripts/prepare_alpha_release.py` prüfte native Komponenten und ZIP-CRC, akzeptierte jedoch doppelte Archivnamen und unsafe ZIP-Pfade. Zwei unterschiedlich enthaltene `lib/arm64-v8a/libapp.so`-Mitglieder erlauben beispielsweise eine mehrdeutige Prüfaussage. Unsichere Eintragsnamen oder symbolische Links gehören nicht in das Alpha-Paket.

## IMPLEMENTIERT

- Alle ZIP-Membernamen vor der Bestimmung erforderlicher Komponenten auf Eindeutigkeit prüfen.
- Absolute Pfade, Laufwerkspfade, Rückwärtsschrägstriche, leere/`.`/`..`-Segmente und Steuerzeichen abweisen.
- Symbolische ZIP-Links anhand der ZIP-Dateimodus-Metadaten ablehnen.
- Legitime Verzeichniseinträge mit abschließendem `/` weiterhin zulassen.
- Vier zusätzliche positive und negative Tests in `scripts/tests/test_prepare_alpha_release.py`.

## Geänderte Dateien

`scripts/prepare_alpha_release.py`, `scripts/tests/test_prepare_alpha_release.py`, `docs/parallel/CHAT_D_CHECKPOINT.md`, `docs/CODEX_CHECKPOINT.md`, `README.md`.

## Tests, CI, Spielstände

- **GETESTET:** GitHub-Connector hat beide veränderten Skript-/Testdateien auf dem Branch erneut gelesen; erwartete Korrektur ist dort vorhanden. Frühere Tests gelten nur für frühere Commits.
- **NICHT GETESTET:** Neue vier Regressionen und vollständige Repository-/Python-/Backend-/Flutter-/Android-CI dieses Commitstands sind noch abzunehmen. Aktive Push-CI: [#40220308644](https://github.com/ManuEtt/Dnd/actions/runs/40220308644). Keine grüne CI oder installierbare neue APK für diesen Commit behaupten.
- **Migration:** keine Änderungen an App- oder Backendcode, SQLite-Version, Datenformat, gespeicherten Spielständen oder SRD-Regeln. Keine Migration.
- **BLOCKIERT:** lokale vollständige Projekt-Toolchain/Checkout fehlen. Finale Actions-Läufe und Integration anderer Chats benötigen Koordination. README und zentraler Checkpoint können mit den anderen PRs kollidieren und müssen additiv zusammengeführt werden.

## Genau ein nächster Schritt

CI des finalen D-003-PR-Commitstands vollständig (inkl. Tests für den korrigierten Release-Paketpfad und erzeugte APK-Release-Artefakte) erfolgreich abnehmen, echten Main-/PR-Dateiabgleich wiederholen und erst danach integrationsbereit stellen. Keine fremden PRs mergen oder Branches löschen.

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

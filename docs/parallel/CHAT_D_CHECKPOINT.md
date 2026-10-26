# Chat D – Main-Synchronisierung D-005

## Aktualisierung nach Main-Merge #195 – 26.10.2026

Neue Basis `575a885bd34ecae2bd173dc183abf88a367a69af`; der D-005-Stand `95fcf11c828e28f2de358b31636e5dc9898edfb6` war auf `main` `5f9a01d` integriert und wird in einem weiteren regulären Merge-Commit mit neuem Main vereinigt. Die technischen Änderungen bleiben auf genau zwei Gradle-Prüfdateien begrenzt. GitHub CI auf dem **neuen** kombinierten Commit erneut nötig; frühere erfolgreiche CI-Läufe gelten nur für ältere Heads. Die aktuellen Main-Änderungen der anderen Chats (SRD-Zauberdauer, NPC-Erinnerung) bleiben erhalten.


---

# Chat D D-005 – Main-Rebase-freie Synchronisation (26.10.2026)

Der auf `87a0d4b7d62aaacf7aa99886c629d6aa5f17a119` vollständig CI-geprüfte D-005-PR #189 wurde mit dem aktuellen Main-HEAD `5f9a01dd73f68ad4f9e226f859a8ca87803b8337` (PR #185 integriert) per zusätzlichem Elterncommit synchronisiert, ohne Force-Push und ohne fremde technische Änderungen. Neue endgültige CI erforderlich; frühere Dokumentation erhalten.

---

# Chat D – D-005: Eindeutige Gradle-Distributionseinstellungen

## Ausgangslage und GitHub
- Datum: 25.10.2026.
- **Main zum Arbeitsbeginn:** `af70a48c84d83c133ced4200be04ca81a91abf1b` mit D-001 bis D-004 erfolgreich integriert.
- **Branch:** `fix/chat-d/gradle-properties-duplicate-guard-20261025`.
- **Fachlicher Umfang:** `scripts/verify_project.py` und `scripts/tests/test_verify_project.py`.
- **Andere PRs:** Chat A, B und C bearbeiten Regel-, Story- und UI-Module getrennt; gemeinsame README-/Checkpoint-Dateien additiv konsolidieren.
- **GitHub-PR:** wird nach Dokumentation als Draft angelegt und dort verlinkt.

## Ausgangsproblem

`verify_project` akzeptierte eine gültige `distributionUrl=` und eine gültige `distributionSha256Sum=`, obwohl in derselben Java-Properties-Datei weitere, abweichende Deklarationen desselben Schlüssels standen. Eine Laufzeit, die bei mehrfachen Keys den letzten Wert verwendet, kann dadurch etwas anderes benutzen als der Sicherheitsprüfer bestätigt hat.

## Implementiert

- `unique_gradle_property` durchsucht nicht auskommentierte Java-Properties-Zeilen und berücksichtigt `=`, `:` und Whitespace als übliche Separatoren.
- Wenn der jeweilige Schlüssel fehlt, doppelt vorkommt oder uneindeutig formuliert ist, liefert er keinen validierten Wert.
- Einmalige SHA-256-Prüfsumme muss weiterhin exakt 64 Hex-Zeichen enthalten; Download-URL muss weiterhin den bisherigen festgelegten HTTPS-/Gradle-Version-Regeln entsprechen.
- Sechs neue Regressionstests: doppelte URL, identischer doppelter Hash, gemischte Separatoren, Kommentar-Zeilen, legitime URL ohne Escape sowie zusätzlicher leerer URL-Schlüssel.
- Bestehende deutschsprachige Diagnosetexte bleiben erhalten; keine Werte oder Geheimnisse werden in Fehlermeldungen ausgegeben.

## GETESTET / NICHT GETESTET / BLOCKIERT

- **GETESTET:** Änderungen wurden nach GitHub-Push aus den beiden Branchdateien erneut eingelesen und auf korrekte Funktionszuordnung geprüft. Der URL-Ausdruck wurde zusätzlich isoliert mit legitimer, escaped HTTPS-URL sowie HTTP-Negativfall überprüft. **Das ist kein Nachweis einer vollständigen Repository-CI.**
- **NICHT GETESTET:** sämtliche Python-/Flutter-/Backend-/Android-Tests sowie APK-/Release-Builds für den finalen D-005-HEAD; Testlauf auf echten Android-Geräten.
- **BLOCKIERT:** Finale GitHub-Actions-Abnahme und eventuelle Änderungen im Hauptbranch. Keine lokale vollständige Flutter-/Android-Toolchain.
- **Sicherheit/Kompatibilität:** kein Eingriff in den echten Gradle-Wrapper, Android-Code, SQLite, Kampagnen-JSON, KI-Erzählung oder SRD-Regeln. Keine Datenmigration.

## Genau ein nächster Schritt

Finalen GitHub-CI-Lauf dieses PR-Commits prüfen und gegebenenfalls Testfehler im eigenen Branch korrigieren, anschließend neuen Main-HEAD und die gemeinsamen Dokumentationsdateien konfliktfrei synchronisieren und erst nach vollständiger Abnahme zur Integration freigeben.


---

# Chat D D-004 – Main-Synchronisierung nach PR #183

Neuer Basis-Main-HEAD `713b8cc2831f9d8039ef4e6ebf37c10682aec675` enthält D-001, D-002 und D-003. Branch D-004 wird per **normalem Merge-Commit ohne Force-Push** mit Main synchronisiert. Nur die zwei Python-Projektprüfer-/Testdateien werden aus D-004 übernommen; Dokumentation aus aktuellem Main bleibt erhalten und wird additiv ergänzt. Frühere Code-Tests/CIs auf `c7f2df12a9df474e6204ad1de4011f7c5b6e3e7f` sind keine finale Abnahme nach Synchronisierung. Offene PRs anderer Chats bleiben unverändert.

---

# Chat D – D-004: Gradle-Wrapper-JAR mit sicheren ZIP-Dateinamen prüfen

## Ausgangsstand

- **Datum:** 25.10.2026
- **Basis-main-SHA:** `45bea9c2a897275583bdbe32ed50afde5d0a76b0`.
- **Branch:** `fix/chat-d/gradle-wrapper-jar-safety-20261025`.
- **Technischer Commit:** `944762a8412ddd4eb5801d7832e424b238197deb` (vor Checkpoint-/README-Nachtrag).
- **PR:** auf eigenem Branch in GitHub zu erstellen.
- **Parallel:** Chat-D-PR #183 (Release-APK-Archivprüfung), andere Chat-PRs #178–#181, #184–#185.
- **Geänderte technische Dateien:** `scripts/verify_project.py`, `scripts/tests/test_verify_project.py`. Kein technischer Konflikt zu den offenen PR-Dateien bekannt.

## Ausgangsproblem und Akzeptanzkriterien

Die bestehende Gradle-Wrapper-Prüfung validiert die ZIP-CRC und das Java-Startklassen-Magic. Doppelte Dateinamen oder Pfad-Traversal und ZIP-Symlinks wurden dabei nicht abgewiesen. Akzeptiert bleiben legitime ZIP-Unterverzeichnisse und der bisher geprüfte Gradle-Wrapper. Erwartet wird ein abbrechender Projektcheck vor Android-SDK-/Gradle-Ausführung.

## Implementiert

- Frühzeitige Ablehnung doppelter ZIP-Mitglieder, bevor `GradleWrapperMain.class` gelesen wird.
- Normalisierte Pfad-Sicherheitsprüfung gegen absolute Namen, Traversal-/Punktsegmente, Rückwärtsschrägstriche, Steuerzeichen und Windows-Laufwerkspfade.
- ZIP-Symlink-Erkennung per `stat.S_ISLNK`.
- Vier neue Python-Regressionstests: doppelte Startklasse, sechs unsichere Namen, Symlink-Member, erlaubtes normales ZIP-Verzeichnis.
- Bestehende Fehlerausgabe bleibt ein sicherer deutschsprachiger Hinweis auf ein ungültiges Gradle-Wrapper-JAR; keine Secrets ausgegeben.

## Tests und Migrationsfolgen

- **GETESTET:** Nach dem Push beide technischen Branch-Dateien über GitHub gelesen und Korrektur-/Testmethoden nachgewiesen.
- **NICHT GETESTET:** Python-Unittests und vollständige neue GitHub-CI des finalen D-004-Commits, npm, Flutter, Android-Builds und native Tests. Keine grünen Testläufe behaupten, solange Actions sie nicht bestätigt.
- **BLOCKIERT:** Vollständige lokale Android-/Flutter-Toolchain/Repository-Checkout in der Chat-Umgebung fehlen.
- **Migration:** keine Änderung an Android-Gradle-Wrapper-JAR, app/, SQLite, JSON, Gameplay oder SRD-Regeln. Keine Spielstandmigration erforderlich.

## Genau ein nächster Schritt

Vollständige GitHub-CI auf dem **finalen** D-004-PR-Head kontrollieren; negative Testfälle und bisherige Wrapper-Kompatibilität bestätigen. Nach anschließendem Main-Abgleich die gemeinsamen Dokumentationsdateien mit PR #183 und anderen Chats additiv konsolidieren. Ohne vollständigen erfolgreichen Test- und Dateiabgleich kein Merge.


---

# CHAT D – Integrations-Update D-003 (25.10.2026)

D-001 PR #177 und D-002 PR #182 wurden nach vollständig erfolgreicher CI in `main` integriert. Neuer Main-HEAD `45bea9c2a897275583bdbe32ed50afde5d0a76b0`, alter D-003-HEAD `ae0efbe2d1da4284093433c0851b147f101e3301`. Der neue D-003-Commit führt beide Stände als regulären Merge zusammen und erhält alle technischen Dateien und bisherigen Checkpoints. D-003 umfasst ausschließlich APK-ZIP-Validierungsdateien plus ergänzende Dokumentation; keine Spielstände, Story oder Regeln betroffen. Der neue Commit braucht eine eigene vollständige CI; alte CI-Ergebnisse sind nicht übertragbar. PRs #178–#181 und #184 haben eigene technische Module und überlappende README-/Checkpoint-Dokumentation. Keine fremden Änderungen zusammenführen oder überschreiben.

---


## D-003 – vollständiges ursprüngliches Paketprotokoll

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

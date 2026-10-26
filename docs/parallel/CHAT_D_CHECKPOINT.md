# Chat D D-011 – Package-Import-Grenze schließen (26.10.2026)

- **Main-Basis:** `5e3116f9e3f8de0af6e8125a97b3962cb8910cdf`. **Branch:** `fix/chat-d/domain-package-uri-boundary-20261026`; Code-Commit `213b35df88aa61389caf038105d9d9e21641a2c1`, Test-Commit `44ca615064ffc9db2004310ff4c45205971e4d73`.
- **Problem:** `scripts/check_domain_boundaries.py` übersprang in `app/lib/domain/**` alle URIs mit Doppelpunkt. So blieb ein `package:lebendiger_spielleiter/story/...`-Import ohne Meldung, obwohl dieselbe Story-Datei via relativen Import gesperrt ist.
- **IMPLEMENTIERT:** Paket-URI des tatsächlichen Flutter-Pakets `lebendiger_spielleiter` zum kanonischen Repositorypfad auflösen; normale Paketpfade, `./`, `../` und doppelte Slashes der Story-Grenze unterwerfen. Fremdpakete, Dart-Standardbibliothek und Domänenimporte bleiben erlaubt.
- **TESTS:** Zusätzliche positive/negative Python-Regressionen für Import und Export, Umgehungsvarianten, legitime Pakete und den Paketnamen aus `app/pubspec.yaml`. Isolierter Python-Smoketest mit vergleichbarer Prüferlogik: fünf Tests erfolgreich; **vollständige Repository-Python-Suite, Flutter, Backend und Android/CI auf tatsächlichem Branch-HEAD noch zu verifizieren**.
- **Dateien:** `scripts/check_domain_boundaries.py`, `scripts/tests/test_domain_boundaries.py`, `docs/parallel/CHAT_D_CHECKPOINT.md`, `docs/CODEX_CHECKPOINT.md`, `README.md`.
- **Kompatibilität:** Keine Spielstands-, Schema-, Import-/Export-, Regel-, Story-, UI- oder App-Versionsänderung; SQLite 2 und Kampagnen-JSON 1 unverändert; keine Migration.
- **Koordination:** PR #243 integriert andere Arbeiten; auch PRs #241/#242/#236/#237/#239/#240 bleiben unberührt. Produktions- und Testpfade sind von allen zu Beginn geprüften offenen PRs unabhängig; zentrale Dokumentdateien können beim späteren Merge Konflikte erfordern.
- **BLOCKIERT/NICHT GETESTET:** Kein kompletter lokaler Git-Checkout wegen GitHub-DNS in der Containerumgebung; Flutter/Dart nicht installiert. Finale CI und APK auf exaktem Branch-HEAD ausstehend; kein Realgerät, keine produktive Signierung.
- **NÄCHSTER SCHRITT:** Eigene PR-CI auf endgültigem HEAD vollständig prüfen, dort aufgedeckte Fehler im eigenen Branch korrigieren und vor Integration aktuelle Main-/PR-Dateipfade abgleichen.

---

# Chat D D-009 – Quell-ZIP gegen nachträglichen Symlink-Austausch schützen (26.10.2026)

- **Ausgangs-`main`:** `42d14ad36cc947691f7e5a1e8647a43f5421b86e`, Push/PR-CI auf `main` vorher erfolgreich. **Branch:** `fix/chat-d/source-zip-symlink-swap-20261026`.
- **Problem:** `source_paths` sperrt symbolische Links beim Auflisten, aber bisher konnten Quelldateien oder Verzeichnis-Ahnen nach dem Scan und vor `path.open('rb')` durch Symlinks auf externe/private Dateien ersetzt werden. Die alte `stat`/`fstat`-Konsistenzprüfung schützt nicht, wenn der Austausch vor dem ersten `stat` stattfand.
- **IMPLEMENTIERT:** `read_verified_source(root, path)` liest unter POSIX über Verzeichnis-Dateideskriptoren und `O_DIRECTORY|O_NOFOLLOW` alle Elternkomponenten und `O_NOFOLLOW|O_NONBLOCK` die Quelldatei; Typprüfung auf reguläre Dateien und bestehender Dreifachvergleich (Lstat/Fstat/Lstat, Größe) bleiben fail-closed. Windows-/Non-POSIX-Fallback prüft Symlinks/Projektgrenze best-effort, ist aber **nicht** garantiert rennbedingungsfrei.
- **TESTS ERGÄNZT:** Drei Regressionen simulieren nach der Dateiauflistung ausgetauschte Dateisymlinks (inklusive Erhalt alter ZIP-/SHA256-Paare), ausgetauschte Verzeichnis-Symlinks und private externe Quellen. Der ältere `fstat`-Testmock enthält nun das beim Dateitypvergleich erforderliche `st_mode`.
- **GETESTET:** Neue und vorhandene Python-Tests wurden durch GitHub Actions auf frühen Commits gestartet. Erste zwei Push-CIs meldeten den **Mockfehler `AttributeError: Changed.st_mode`**, ohne dass der Symlink-Schutz entfernt wurde. Dieser Testmock ist in Commit `273c3c5d` korrigiert. Neuer Push-Run [#40358698621](https://github.com/ManuEtt/Dnd/actions/runs/40358698621) läuft; finale PR-/Push-CI nach diesem Dokumentationscommit **noch nicht vollständig bestätigt**.
- **NICHT GETESTET:** Reales Android-Gerät, Windows-Race-Sicherheit, vollständiger Flutter-/Backend-/Android-/Alpha-End-zu-Ende-Build auf finaler Branch-SHA.
- **BLOCKIERT:** endgültiger Actions-Lauf; weitere Merge-Konflikte, falls sich `main` parallel verschiebt.
- **KEINE MIGRATION:** SQLite-/JSON-Spielstände, SRD-Regeln, Story, Android-UI und App-Version unverändert. Nur Quellarchiv-Export und Python-Regressionen betroffen.
- **NOCH NICHT IMPLEMENTIERT:** Dieser Schutz härtet `package_project.py` auf POSIX ab; er ersetzt kein separates formales Hardening sämtlicher Dateilesewege von `create_checkpoint.file_manifest`.
- **NÄCHSTER SCHRITT:** finale CI auf exaktem PR-Head prüfen, bei Fehlern auf diesem Branch korrigieren, und erst nach aktuellem Main-/Datei-Abgleich integrieren. Fremde PRs #236/#237 nicht überschreiben.

---

## D-007 – zusätzliche CI-Blocker bereinigt

Der Python-/Checkpoint-Fix war auf dem ersten D-007-Commit erfolgreich; die reguläre CI stoppte danach an unabhängigen Dart-Problemen. Die frühere Eldritch-Test-Formatierung ist durch Main-PR #214 bereits korrigiert. Ein vorübergehender, inzwischen vollständig entfernter CI-Diagnoseschritt zeigte exakt den Format-Diff in `app/lib/story/npc_identity_story_payload.dart`: Dort ist jetzt `length == 0` verhaltensgleich als `isEmpty` geschrieben und ein langer `FormatException`-Aufruf entsprechend dem Dart-Formatter umgebrochen. Keine NPC-Identitäts-, Auswahl-, Speicher- oder Regelwirkung geändert. Die unveränderte Workflowdatei aus `main` wird explizit wiederhergestellt. Die erste diagnostisch instrumentierte CI zählt nicht als finale Abnahme; reguläre vollständige CI auf dem neuen Head abwarten.

# D-007 – Synchronisierung mit Hauptbranch (26.10.2026)

Main `d03faea7ce032e8918da2204228473bd9999932c` enthält zwischenzeitlich PR #214 (Eldritch-Cover). Der eigene D-007-Branch `8eaf1fc1787ccf80c4c676fec3df1ce91da16034` wurde regulär mit `main` als weiterem Parent zusammengeführt. Die beiden D-007-Python-Dateien bleiben die einzigen technischen Änderungen. Frühere grüne Python-Schritte und die rote Format-CI gelten nicht als Freigabe des neuen Merge-Commits; alle finalen Tests erneut prüfen. Aktuelle fremde README-/Checkpoint-Fortschritte sind additiv erhalten.

---

# Chat D D-007 – Ausführbare Skripte und atomare ZIP-Tests wiederherstellen

- **Datum:** 26.10.2026, **Main-Basis:** `e903ae38c6ae99abfa99a432e7f7777f0eee853f`, **Branch:** `fix/chat-d/restore-checkpoint-zip-executable-modes-20261026`.
- **Analyse:** Quell-ZIP nutzt inzwischen `writestr()` nach sicherem Dateiinhalt-/Statistikvergleich, was im Gegensatz zu `ZipFile.write()` keine Unix-Dateimodi übernimmt. `create_checkpoint.validate_archive` vergleicht diese Modi mit dem Manifest und hat deshalb in der Python-Gesamtsuite versagt. Zwei ältere Tests mockten `ZipFile.write`, das im Produktionspfad nicht mehr verwendet wird. Die erste CI auf dem anderen Paket D-008 bestätigte diese drei **bestehenden** Fehler; sie sind nicht durch dessen Gradle-Code verursacht.
- **IMPLEMENTIERT:** `scripts/package_project.py` setzt für `ZipInfo` die regulären Dateimodus-/Ausführungsbits via `stat.S_IFREG | stat.S_IMODE(before.st_mode)`, behält `ZIP_DEFLATED` und den zuvor verifizierten Dateidateninhalt. Kein Rückfall auf den TOCTOU-anfälligeren direkten `ZipFile.write()`-Pfad.
- **TESTS ERGÄNZT:** Neuer ZIP-Metadaten-Regressionsfall mit `0755` und `0644`; bestehende zwei Rollbacktests simulieren Schreibfehler nun in `ZipFile.writestr` und prüfen, dass bestehende ZIP-/SHA256-Dateien unangetastet bleiben.
- **GEPRÜFT:** Technische Dateien über den GitHub-Connector auf den Branch gepusht. Die vollständige neue CI auf dem endgültigen Commit noch nicht abschließend bestätigt.
- **NICHT GETESTET:** Android-Realgerät, manuelle Installation sowie finale vollständige Flutter-/Backend-/Android-/Alpha-CI des neuesten Branch-Stands.
- **BLOCKIERT:** CI-Freigabe und anschließend Konfliktvergleich mit dem dann aktuellen Main. Unabhängiger nächster D-008-Branch (Java-Properties-escapte Schlüssel) bleibt technisch separat.
- **PERSISTENZ:** SQLite, JSON, App-Version und Regel-/Storydateien unverändert. Keine Migration.
- **NOCH NICHT IMPLEMENTIERT:** Keine funktionalen Erweiterungen der Kampagne, Regelengine oder UI in diesem Qualitätspaket.
- **NÄCHSTER SCHRITT:** CI der finalen Branch-SHA vollständig prüfen, Fehler korrigieren, PR konfliktfrei nach `main` integrieren; danach D-008 auf diesen geprüften Main synchronisieren.

---
# Chat D – D-006 Main-Abgleich nach A/B-Integrationen, 26.10.2026

Alter CI-geprüfter D-006 HEAD `46b869eb27c23cd8b250e7747b86b0b54ad6eed1`; neuester Main-HEAD `f1f3e997bc8650a757d34234eff49d870dcf9369`, enthält SRD-Zauber- und NPC-Erinnerungsintegrationen. Nur `scripts/package_project.py` und zugehörige Tests aus D-006 übernommen, Main-Historie und Dateien vollständig erhalten. Neues finales CI erforderlich, kein Force-Push.

---

# Chat D – D-006: plattformübergreifend sichere Quell-ZIP-Namen

## GitHub und Scope

- **Datum:** 26.10.2026
- **Ausgangs-Main:** `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`, [Main-CI #40233719625](https://github.com/ManuEtt/Dnd/actions/runs/40233719625) erfolgreich.
- **Branch:** `fix/chat-d/portable-source-zip-paths-20261026`.
- **Technischer Commit:** `381d512d82fc9218c1d4769d25ec43629adc7012` (vor Dokumentation).
- **Vorgesehen:** eigener Draft-PR; finales CI-Ergebnis und URL im PR verifizieren.
- **Technische Pfade:** `scripts/package_project.py`, `scripts/tests/test_package_project.py`. Diese Pfade sind getrennt von PR #189 und den A/B/C-PRs.
- **Gemeinsam bearbeitete Dokumentation:** `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`; gegen neuen Main vor dem Merge additiv abgleichen.

## Problem

ZIP-Namen unterscheiden Groß- und Kleinschreibung. Windows sowie viele macOS-Volumes und Unicode-normalisierende Dateisysteme können `Card.png` und `card.PNG`, `Icons/` und `icons/` oder aus NFC/NFD zusammengesetzte Unicode-Namen beim Entpacken nicht eindeutig getrennt darstellen. Das bisherige Quellarchiv könnte daher beim Übertragen Dateien zusammenfallen lassen.

## IMPLEMENTIERT

- `validate_portable_source_paths(root, paths)` prüft alle für den Export zugelassenen relativen Datei- und Verzeichnisprefixe **bevor** die ZIP-Erstellung oder der Ersatz vorhandener Archive beginnt.
- Unicode-NFC plus `casefold()` kennzeichnen plattformübergreifende Dateinamenkollisionen, ohne rechtmäßige Großschreibung im ZIP zu verändern.
- Windows-unzulässige Zeichen, reservierte Namen, Steuerzeichen und abschließende Punkte/Leerzeichen werden vor dem Verpacken abgewiesen.
- **Sechs neue Tests:** Dateinamenskollision, Verzeichniskollision, Unicode-NFC/NFD-Kollision, unportable Windows-Namen, vollständige Bewahrung zuvor veröffentlichter ZIP-/SHA256-Paare bei Fehlprüfung, reguläre unterschiedliche Dateinamen.
- Normale ZIP-Ausgabe und bereits vorhandene Secrets-/SDK-Filter sind unverändert.

## Tests

- **GEPRÜFT:** über GitHub am Branch veröffentlichte Änderungen in den beiden technischen Dateien vorhanden; [Main-CI](https://github.com/ManuEtt/Dnd/actions/runs/40233719625) deckt lediglich die vorherige Basis ab.
- **NICHT GETESTET:** volle Python-/Flutter-/Android-/Backend-CI und ZIP-Artefakte des finalen D-006-Commits; außerdem reales Entpacken auf Windows/macOS.
- **BLOCKIERT:** unabhängige finale GitHub-Actions-Abnahme und GitHub-Main-Abgleich nach parallelen Merges.
- **PERSISTENZ/REGELN:** kein Datenbank- oder JSON-Eingriff, keine Android-App- oder SRD-Regeländerung, keine Migration.

## Genau ein nächster Schritt

Den **finalen** CI-Lauf für D-006 samt vollständiger Python-Regressionen und Alpha-Release-Quellarchiv abschließen, den aktuellen Main-Stand prüfen und Checkpoint-/README-Änderungen erst bei vollständiger Abnahme konfliktfrei zusammenführen.


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

---

# Chat D – D-006 Main-Abgleich nach A/B-Integrationen, 26.10.2026

Alter CI-geprüfter D-006 HEAD `46b869eb27c23cd8b250e7747b86b0b54ad6eed1`; neuester Main-HEAD `f1f3e997bc8650a757d34234eff49d870dcf9369`, enthält SRD-Zauber- und NPC-Erinnerungsintegrationen. Nur `scripts/package_project.py` und zugehörige Tests aus D-006 übernommen, Main-Historie und Dateien vollständig erhalten. Neues finales CI erforderlich, kein Force-Push.

---

# Chat D – D-006: plattformübergreifend sichere Quell-ZIP-Namen

## GitHub und Scope

- **Datum:** 26.10.2026
- **Ausgangs-Main:** `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`, [Main-CI #40233719625](https://github.com/ManuEtt/Dnd/actions/runs/40233719625) erfolgreich.
- **Branch:** `fix/chat-d/portable-source-zip-paths-20261026`.
- **Technischer Commit:** `381d512d82fc9218c1d4769d25ec43629adc7012` (vor Dokumentation).
- **Vorgesehen:** eigener Draft-PR; finales CI-Ergebnis und URL im PR verifizieren.
- **Technische Pfade:** `scripts/package_project.py`, `scripts/tests/test_package_project.py`. Diese Pfade sind getrennt von PR #189 und den A/B/C-PRs.
- **Gemeinsam bearbeitete Dokumentation:** `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`; gegen neuen Main vor dem Merge additiv abgleichen.

## Problem

ZIP-Namen unterscheiden Groß- und Kleinschreibung. Windows sowie viele macOS-Volumes und Unicode-normalisierende Dateisysteme können `Card.png` und `card.PNG`, `Icons/` und `icons/` oder aus NFC/NFD zusammengesetzte Unicode-Namen beim Entpacken nicht eindeutig getrennt darstellen. Das bisherige Quellarchiv könnte daher beim Übertragen Dateien zusammenfallen lassen.

## IMPLEMENTIERT

- `validate_portable_source_paths(root, paths)` prüft alle für den Export zugelassenen relativen Datei- und Verzeichnisprefixe **bevor** die ZIP-Erstellung oder der Ersatz vorhandener Archive beginnt.
- Unicode-NFC plus `casefold()` kennzeichnen plattformübergreifende Dateinamenkollisionen, ohne rechtmäßige Großschreibung im ZIP zu verändern.
- Windows-unzulässige Zeichen, reservierte Namen, Steuerzeichen und abschließende Punkte/Leerzeichen werden vor dem Verpacken abgewiesen.
- **Sechs neue Tests:** Dateinamenskollision, Verzeichniskollision, Unicode-NFC/NFD-Kollision, unportable Windows-Namen, vollständige Bewahrung zuvor veröffentlichter ZIP-/SHA256-Paare bei Fehlprüfung, reguläre unterschiedliche Dateinamen.
- Normale ZIP-Ausgabe und bereits vorhandene Secrets-/SDK-Filter sind unverändert.

## Tests

- **GEPRÜFT:** über GitHub am Branch veröffentlichte Änderungen in den beiden technischen Dateien vorhanden; [Main-CI](https://github.com/ManuEtt/Dnd/actions/runs/40233719625) deckt lediglich die vorherige Basis ab.
- **NICHT GETESTET:** volle Python-/Flutter-/Android-/Backend-CI und ZIP-Artefakte des finalen D-006-Commits; außerdem reales Entpacken auf Windows/macOS.
- **BLOCKIERT:** unabhängige finale GitHub-Actions-Abnahme und GitHub-Main-Abgleich nach parallelen Merges.
- **PERSISTENZ/REGELN:** kein Datenbank- oder JSON-Eingriff, keine Android-App- oder SRD-Regeländerung, keine Migration.

## Genau ein nächster Schritt

Den **finalen** CI-Lauf für D-006 samt vollständiger Python-Regressionen und Alpha-Release-Quellarchiv abschließen, den aktuellen Main-Stand prüfen und Checkpoint-/README-Änderungen erst bei vollständiger Abnahme konfliktfrei zusammenführen.


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

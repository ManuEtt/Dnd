# Chat D D-021 – Verifizierten Grafikimport gegen Symlink-Umleitung absichern (30.10.2026)

- **Ausgangs-Main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `fix/chat-d/fantasy-import-symlink-20261030`.
- **Code-Commit:** `e2d28c1e35be405a8e09cd86a0e6f249259f2799`.
- **Pull Request:** [#409](https://github.com/ManuEtt/Dnd/pull/409), initial Draft.
- **Ausgangsproblem:** `Path.exists()` liefert für einen hängenden Symlink `False`; `Path.write_bytes()` würde externe Zielpfade indirekt erzeugen. Auch symlink-basierte Assets-Verzeichnisse konnten den Import umleiten.
- **IMPLEMENTIERT:** `ensure_safe_destination` prüft den Projektzielordner und jeden Pfadbestandteil auf Symlinks, während der ZIP-Analyse und vor/nach dem Erstellen von Verzeichnissen; neue Dateien mit `open("xb")` exklusiv erzeugen statt Links zu folgen oder bestehende Dateien zu überschreiben.
- **Geänderte Dateien:** `scripts/import_complete_fantasy_assets.py`, `scripts/tests/test_import_complete_fantasy_assets.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Regressionen:** gültiger erstmaliger und idempotenter Import, symlink-basiertes Zielverzeichnis, dangling Symlink am Assetziel und Symlink als Projektziel; bisherige negative Daten-/Checksum-Tests bleiben.
- **GETESTET:** Code und Tests auf PR-Branch gesichert; vollständige CI auf finalem Head noch nicht als Erfolg verifiziert.
- **NICHT GETESTET:** vollständiger Python-/Backend-/Flutter-/Android-Durchlauf, APK-/Release-Paketierung und realer Gerätetest bis zur CI-Abnahme.
- **BLOCKIERT:** GitHub-DNS für lokalen Checkout; GitHub-Connector sowie Actions funktionieren.
- **Migrationen:** keine Änderungen an Spielständen, SQLite-/JSON-Dateiformaten oder App-/SRD-Version.
- **Koordination:** Dateipfade aller zum Start offenen PRs #387–#408 geprüft; keine technischen Überschneidungen, gemeinsame README und Checkpoints vor Merge verlustfrei konsolidieren. Keine fremden Branches verändert oder gelöscht.
- **Vorgänger:** PR #401 und #402 vollständig CI-grün und zur Review freigegeben. PR #406 zuletzt weiter im vollständigen Android-Build in Prüfung, kein automatischer Merge.
- **Nächster Schritt:** finalen GitHub-Actions-Lauf von #409 abnehmen, etwaige Fehler auf diesem Branch korrigieren und bei vollständigem Erfolg zur Review freigeben.

---

# Chat D D-022 – Fehlertoleranter SRD-Qualitätscheck (30.10.2026)

- **Ausgangs-Main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `fix/chat-d/srd-audit-malformed-records-20261030`.
- **Code-Commit:** `248500247eb98f1cbde46d29448a9ca3303878e3`.
- **Pull Request:** [#410](https://github.com/ManuEtt/Dnd/pull/410), initial Draft.
- **Ausgangsproblem:** Fehldatentypen in ansonsten gültigen SRD-Inventur-JSONs konnten beim Audit `TypeError` oder `KeyError` auslösen; Fehlerdiagnosen gingen verloren.
- **IMPLEMENTIERT:** sichere Enum-/Datentypprüfungen in `validate_matrix`/`validate_entities`, robustes Einlesen von Katalogreferenzen und Inventarlücken, Hash-/Duplikatchecks nur für gültige Metadaten; `main` bricht nach Validierungsfehlern vor der statistischen Auswertung mit Exitcode 1 ab.
- **Dateien:** `scripts/srd_coverage.py`, `scripts/tests/test_srd_requirements_matrix.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Tests:** vier neue negative Testmethoden für unhashbare Requirement-Felder, kaputte Katalogeinträge, Entity-Datentypen und Nicht-Objekt-Wurzeltypen. Positive Bestandsinventur bleibt unverändert.
- **GETESTET:** Implementierung und Regressionstests committed und in PR gesichert; vollständige CI noch nicht als grün belegt.
- **NICHT GETESTET:** finale Python-/Backend-/Flutter-/Android-/APK-Suite und Realgerät bis zur erfolgreichen GitHub-CI.
- **Migrationen:** keine; SRD-Quellen, Spielregeln, SQLite/JSON, Spielstände und Appversion unverändert.
- **Koordination:** alle 21 beim Start offenen PRs geprüft; keine Änderungen an den zwei technischen Skript-/Testdateien in fremden PRs. README und zentralen Checkpoint nur verlustfrei gemeinsam integrieren.
- **Vorarbeiten:** PRs #401, #402, #406 und #409 vollständig CI-erfolgreich und zur Review freigegeben; kein Merge in `main`.
- **Nächster Schritt:** endgültigen Actions-Lauf für #410 auf letztem SHA prüfen, Fehler auf dem eigenen Branch beheben und erst bei vollständigem Grün zur Review freigeben.

---

# Chat D – Integration von PR #358 nach Checkpoint-Fix #363 (29.10.2026)

## Integrationskandidat 29.10.2026 – Chat D

Zusammengeführte Fachpakete: [#378](https://github.com/ManuEtt/Dnd/pull/378), [#380](https://github.com/ManuEtt/Dnd/pull/380), [#381](https://github.com/ManuEtt/Dnd/pull/381), [#384](https://github.com/ManuEtt/Dnd/pull/384). Die ursprünglichen Branch-HEADs, PR-Beschreibungen, Tests, bekannte Grenzen und Statusmeldungen sind im [Integrationsjournal](INTEGRATION_20261029.md) mit Git-Historie dokumentiert. **Dieser Stand ist weder auf main integriert noch gemeinsam CI-abgenommen; Drafts sind nicht freigegeben.** Bisherige Checkpoint-Einträge bleiben erhalten.


- **Stand:** Alpha-Release-Lock in `scripts/prepare_alpha_release.py` (3 neue Tests), vorherige vollständige CI `40730971955` auf `1d7b1723` erfolgreich; kombinierter Head benötigt erneute CI.
- **Ausgangsbranch:** `fix/chat-d/alpha-release-version-lock-20261028`; **Integrationsbasis:** `b5f469f2163c1d60a63761e0a63434f4359e5e2a` enthält aktuelle Hauptbranch-Arbeit und PR #363. PR #358 bleibt bis gemeinsamer CI im Draft.
- **Risiko:** Lock-Verzeichnis bleibt nach hartem Crash fail-closed; gleichzeitige externe Runner und Geräteinstallation nicht geprüft. Keine SQLite-/JSON-Migration, bestehende Alpha-Artefakte unverändert.
- **Nächster Schritt:** vollständige GitHub Actions auf finalem Head, erst dann integrieren.

---

# Chat D D-017 – Sichere Checkpoint-Prüfsummenhistorie (28.10.2026)

- **Main-Basis:** `854ca85c0234c508f34f00cdbfbef2e10554ca13`; **Branch:** `fix/chat-d/checkpoint-history-safe-names-20261028`.
- **Problem:** Historische Checkpoint-Einträge wurden über `Path.is_file()` gesammelt (folgt Symlinks) und ihre Namen ohne Prüfungsnormalisierung in `SHA256SUMS.txt` geschrieben. Ein fremdes Ziel oder Zeilenumbruch kann so die Prüfsummenliste verfälschen bzw. einen externen Dateizugriff verursachen.
- **IMPLEMENTIERT:** `previous_checkpoint_files()` lässt ausschließlich sichere, reguläre historische Artefakte zu; invalides Inventar bricht vor dem Ersetzen der Version/Stable-Aliases ab.
- **Tests:** Drei neue negative Fälle (Symlink auf externe Datei, Zeilenumbruch, Verzeichnis mit ZIP-Endung) prüfen Ablehnung und unveränderte zuvor veröffentlichte Aliases. Alte positive Historienprüfung bleibt.
- **GETESTET:** Code-/Teständerungen über GitHub-Connector gesichert; tatsächliche Testausführung folgt über CI.
- **NICHT GETESTET:** Python-/Backend-/Flutter-/Android-Gesamtsuite und Realgerät.
- **BLOCKIERT:** Lokaler GitHub-DNS-Checkout und Flutter-/Dart-SDKs nicht vorhanden.
- **NOCH NICHT IMPLEMENTIERT:** Atomare Lock-/Race-Protektion für alle extern manipulierbaren Artefaktordner; diese Patch prüft Dateityp zum Auflistungszeitpunkt, keine No-Follow-Dateideskriptoren beim späteren Hashing.
- **Keine Migration:** Spielstands-/SQLite-/JSON-/Appversion unverändert.
- **Geänderte Dateien:** `scripts/create_checkpoint.py`, `scripts/tests/test_create_checkpoint.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Nächster Schritt:** finale CI/PR-Abnahme der drei Regressionen sowie normaler Android-Gates, bevor über einen Merge entschieden wird.

---

# Chat D D-016 – Dart-Teilbibliotheken und Story-/Regelgrenzen (28.10.2026)

- **Basis-`main`:** `ab8bef62039a2c4df04ee0cbecf0baebfefc8d78`; **Branch:** `fix/chat-d/dart-part-boundary-20261028`; **Codecommit:** `4690b591dbf3664824981bb4fec5844a48d8bfa2`; **Pull Request:** [#360](https://github.com/ManuEtt/Dnd/pull/360) (Draft).
- **Ausgangsproblem:** `check_domain_boundaries.py` erkannte `import`/`export`, aber nicht `part`/`part of`. So konnten Regel-/Storydateien unbemerkt als Bibliotheksteile referenziert werden.
- **IMPLEMENTIERT:** Der Prüfer liest beide URI-basierten Direktiven einschließlich Kommentare und verbietet grenzüberschreitende Teilbibliotheken auch für bisher zulässige Shared-Model-/Fassaden-Imports. Zulässige lokale Parts bleiben erlaubt.
- **Akzeptanzkriterien:** Domain→Story und Story→Domain per `part` und `part of` verboten; Package-Aliase/Whitelist umgehen die Sperre nicht; lokale Parts und erlaubter Model-Import funktionieren.
- **Regressionen:** Fünf neue Testmethoden in `scripts/tests/test_domain_boundaries.py` (positive und negative Fälle).
- **GETESTET:** Fünf Parser-Stichproben mit lokalem Python erfolgreich. Keine vollumfänglichen Repo-Testresultate behauptet.
- **NICHT GETESTET:** komplette Python-/Backend-Suite, Flutter-/Dart-Analyse und Tests, Android-Build/native Tests, vollständige CI auf finalem PR-HEAD, Realgerät.
- **BLOCKIERT:** kein GitHub-Checkout via lokalen DNS und kein Flutter-/Dart-SDK. GitHub Actions separat prüfen.
- **Kompatibilität und Migration:** App-/Story-/Domaincode, SQLite, Kampagnen-JSON und Versionsdaten unverändert; keine Migration.
- **Technische Dateien:** `scripts/check_domain_boundaries.py`, `scripts/tests/test_domain_boundaries.py`. Zusätzliche additive Dokumentation in README und zentralem/persönlichem Checkpoint.
- **Koordination:** offene PRs #353/#355/#356/#357/#358 technisch überschneidungsfrei. Gemeinsame README-/Checkpoint-Änderungen vor Merge verlustfrei abgleichen; keine fremden PRs automatisch mergen.
- **Nächster Schritt:** Finale PR-CI des aktuellen HEAD samt allen neuen Regressionen und Android-Build verifizieren und nur bei Erfolg zur Review freigeben.

---

# Chat D D-014 – Bedingte Dart-Imports/Exports an Architekturgrenzen (27.10.2026)

- **Basis-main:** `8239f5e71ec6b229a2a0883500adaf431bb70087`, Branch `fix/chat-d/conditional-dart-boundaries-20261027`.
- **Ausgangsproblem:** `scripts/check_domain_boundaries.py` prüfte bei `import` und `export` nur die erste URI. Dart bietet `if (dart.library.io)` / `if (dart.library.html)` bedingte Dateivarianten, die je nach Plattform die Story-/Regelgrenze unbemerkt hätten überschreiten können.
- **IMPLEMENTIERT:** Jede bedingte Datei-URI derselben Import-/Exportanweisung durchläuft dieselbe bestehende Story-/Regel- und Package-URI-Prüfung. Mehrere `if`-Alternativen, Zeilenumbrüche, Dart-Kommentare zwischen Direktivenbestandteilen und konfigurierte String-Vergleiche werden erfasst. Die eng erlaubten Story-Fassadenimports bleiben auf genau ihre bekannten relativen Pfade beschränkt. Framework-/Dart-Bibliotheken werden nach den vorhandenen Regeln behandelt.
- **TESTS:** Neun Python-Regressionen für Domain→Story (relative/package URI), mehrfach bedingten Export, unveränderte Whitelist, Story→Dart-Plattform, Vergleichsbedingung, erlaubte Alternativen, Kommentare/Text ohne Importwirkung sowie bedingte Imports/Exports mit echten Block-/Zeilenkommentaren. Isolierte Regex-Stichprobe lokal ausgeführt; komplette Repository-Python- und Android-CI auf dem finalen Commit noch ausstehend.
- **VERSIONEN:** Flutter-App, Backend, SRD-Regelcode, SQLite-Schema 2, Kampagnen-JSON-Schema 1 bleiben unverändert; keine Migration.
- **KOORDINATION:** Bei Paketbeginn offene PRs #287–#312 geprüft. #311 (anderes Chat-D-Paket) bearbeitet `scripts/prepare_alpha_release.py` und dessen Tests, nicht die zwei hier geänderten Prüfdateien. README/zentraler Checkpoint nur additiv ändern und bei späteren Merges konsolidieren. Fremde Branches und PRs nicht bearbeiten.
- **BLOCKIERT/UNGETESTET:** endgültige GitHub Actions auf PR-HEAD, echte Android-Installation und Integration nach Main. Externer Branch-Cleanup-Lauf auf Main war unabhängig hiervon fehlgeschlagen; kein Code dieses Pakets betroffen.
- **NÄCHSTER SCHRITT:** PR-CI auf exakter SHA prüfen; gegebenenfalls nur eigenen Branch reparieren, anschließend aktuelle Main- und PR-Änderungen vergleichen.

---

# Chat D D-013 – APK-ZIP-Bomb-Abwehr vor Alpha-Veröffentlichung (27.10.2026)

- **Ausgangs-main:** `f9b2f72a4bf8e4216bf8baac60c7f92c4a8a997f`, Branch `fix/chat-d/alpha-apk-zipbomb-guard-20261027`. Würfelraunen `0.8.42+92`, SQLite 2, Kampagnen-JSON 1 unverändert.
- **Problem:** `scripts/prepare_alpha_release.py:validate_arm64_apk` durchlief `ZipFile.testzip()` ohne vorgelagerte Größen-/Kompressionsbegrenzung. Dadurch hätte eine manipulierte APK mit vielen oder hochkomprimierten ZIP-Einträgen bei der Verifikation sehr viel Zeit/Ressourcen beanspruchen können.
- **IMPLEMENTIERT:** Fail-Closed-Limits: APK-Datei höchstens **512 MiB**, ZIP höchstens **20.000 Einträge**, Summe der angegebenen entpackten Größen höchstens **1 GiB**; Einträge ab **1 MiB** dürfen nicht mehr als **1000-fach** expandieren (laut ZIP-Zentralverzeichnis). Die Limits werden vor `testzip()` geprüft. Bisherige Erkennung von duplizierten/unsicheren Pfaden, Symlinks, CRC-Schäden und fehlenden oder leeren Android-ARM64-Pflichtbibliotheken bleibt bestehen.
- **REGRESSIONEN:** Vier negative Python-Fälle: auf Datenträger zu große APK (ZIP-Prüfer darf nicht geöffnet werden), hochkomprimierter Deflate-Eintrag, fiktive zu große entpackte Gesamtsumme, ZIP mit überzähliger Eintragsliste. Die drei letzten Tests verlangen Ablehnung vor `testzip()`. Normale bestehende positive Release-Tests bleiben unverändert.
- **Dateien:** `scripts/prepare_alpha_release.py`, `scripts/tests/test_prepare_alpha_release.py`, `docs/parallel/CHAT_D_CHECKPOINT.md`, `docs/CODEX_CHECKPOINT.md`, `README.md`. Codecommit `daea8b78d441b30c93fa8e825a5c2708ff104302`; Regressionen `912a662ed54dc8fa520a59d366bb4654a93c80ae`.
- **GETESTET:** Vorgänger-PR #258 vollständig erfolgreich [GitHub-CI #40391878647](https://github.com/ManuEtt/Dnd/actions/runs/40391878647), 36/36 Schritte; PR #258 wurde in Main gemergt. Das belegt **nicht** D-013.
- **NICHT GETESTET:** Neue Python-/Flutter-/Backend-/Android-/Alpha-CI auf finaler D-013-SHA, reale Android-Geräte, produktive APK-Signatur, alte Installationen. Kein lokaler vollständiger Checkout wegen GitHub-DNS-Ausfall.
- **BLOCKIERT:** CI des neuen PR-HEADs und Abgleich gegen inzwischen verändertes Main. Keine fremden PRs/Branches berührt oder automatisch gemergt.
- **KEINE MIGRATION:** Reine Alpha-Release-Prüfung, weder Spielregeln noch Story-/KI- oder SQLite-Code verändert; Schema 2 und Kampagnenformat 1 bleiben erhalten.
- **NÄCHSTER SCHRITT:** PR-CI auf exaktem Dokumentations-HEAD abnehmen, Fehler ggf. im eigenen Branch korrigieren, vor Freigabe neuen Main-HEAD und offene PRs erneut prüfen. Ein echter APK-Release ersetzt keine Geräteprüfung.

---

# Chat D D-014 – Störenden Alt-Workflow deaktivieren (28.10.2026)

- **Ausgangs-main-SHA:** `571edec9455fb32e4991432953c9a2479a6fffb2`.
- **Eigener Branch:** `fix/chat-d/disable-legacy-cleanup-20261028`.
- **PR:** [#329](https://github.com/ManuEtt/Dnd/pull/329) (reviewbereit).
- **Technische Commit-SHAs:** `45236f1b4d595303c19c1cf9e992ba36003026fc`, `c5b223389d75a9949a2bee13386d305bc586102e`; Dokumentation auf demselben Branch ergänzt.
- **Reproduzierter Befund:** Der alte Workflow [40589220593](https://github.com/ManuEtt/Dnd/actions/runs/40589220593) brach mit 404 bei `test/chat-b/story-12-memory-transport-20261027` ab. Der neue SHA-geprüfte Workflow [40589220368](https://github.com/ManuEtt/Dnd/actions/runs/40589220368) hatte diesen Branch nach Archivierung vorher gelöscht.
- **Implementiert:** Alter Workflow nur manuell und schreibgeschützt, ausschließlich informative Ausgabe, keine Branch-/Tag-Schreibzugriffe. Der aktive Nachfolger bleibt unverändert.
- **Geänderte Dateien:** `.github/workflows/retire-verified-branches-20261026.yml`, `scripts/tests/test_retired_cleanup_workflow.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **TESTS:** Drei neue Python-Tests (positiv, adversarial/negativ, Nachfolger); CI auf finalem SHA auf ursprünglichem CI-Commit grün, kombinierte CI neu gestartet, kein lokales Flutter-/Android-SDK.
- **Bekannte Einschränkungen:** Die aktuelle automatische Bereinigung im neueren Workflow ist ein eigenständiger Arbeitsbereich; keine Änderung oder Abnahme ihrer vollständigen Nebenläufigkeitsgarantien. Realgerät/Produktionssignierung nicht getestet.
- **Migration:** Keine, SQLite 2/JSON 1 unverändert.
- **Nächster Schritt:** Finale Python/Backend/Flutter/Android-CI für PR #329 nachweisen, bei Fehlern den eigenen Branch korrigieren und Review erst nach Erfolg anbieten.

---

# Chat D D-013 – Symlink-Sperre bei der Projektübertragungsprüfung (27.10.2026)

- **Ausgangs-main-SHA:** `ff245cc253194cd0858385d535ae7b2c9132bb06`.
- **Branch:** `fix/chat-d/verify-project-symlink-20261027`.
- **Technische Commits:** `4a81596a1bc2b729fe2c8cc739f7a201220f92f6`, `9c910244117ec4f7b3ea6149fedf5e78b279568a`; Dokumentationsstand folgt auf demselben PR-Branch.
- **Pull Request:** [#321](https://github.com/ManuEtt/Dnd/pull/321) (Draft, nicht mergen vor Prüfung).
- **Ausgangsproblem:** `scripts/verify_project.py` akzeptierte vorhandene, nichtleere Pflichtdateien trotz Symlink und konnte bei Backend-JSON/Wrapper-Inhalt auf Dateien außerhalb des hochgeladenen Baums folgen.
- **Implementiert:** Linkprüfung sämtlicher Dateipfad-Komponenten und Skip nachgelagerter Inhaltsprüfungen für Links, ohne Ausgabe von Zielpfaden.
- **Geänderte Dateien:** `scripts/verify_project.py`, `scripts/tests/test_verify_project.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Tests:** Vier neue Regressionstests einschließlich positiver Bestandstest; Ausführung und finale CI **noch nicht nachgewiesen**. Kein lokaler vollständiger Checkout und kein Flutter-/Dart-SDK.
- **CI-Ergebnis:** Neu ausgelöste GitHub-Actions-Läufe auf finale PR-SHA prüfen, Status zum Dokumentationszeitpunkt ausstehend.
- **Bekannte Grenze:** Vorprüfung nicht race-/TOCTOU-sicher bei konkurrierendem Umtausch einer regulären Datei in einen Link.
- **Migration:** Keine. SQLite 2, JSON 1, Produktcode und App-Version unverändert.
- **Nächster konkreter Schritt:** Den Python-Test-Gate und Android-Workflow auf finalem PR-Commit nachweisen, Fehler im selben Branch beheben.

---

# Chat D D-012 – ZIP-Bomb-Schutz bei Gradle-Wrapper-Vorprüfung (26.10.2026)

- **Ausgangs-main:** `67f146e690306b13d490bd8e7fd5636bb187c77e`. **Arbeitsbranch:** `fix/chat-d/gradle-jar-zip-bomb-guard-20261026`. Implementierung `77a431955351e30a1dcf54e0dea7f8ba7b7b497a`, Regressionstests `86634965c6784994ecb731c4bacab476a9f50ffa`.
- **Ausgangsproblem:** `scripts/verify_project.py` prüft die JAR per `ZipFile.testzip()` und lädt danach die Startklasse; ein hochkomprimiertes manipuliertes JAR konnte ohne Begrenzung der Gesamtauspackgröße oder Eintragsanzahl CPU-/Speicheraufwand verursachen.
- **IMPLEMENTIERT:** Vor dem ersten CRC-Lesen maximal 16 MiB komprimierte JAR-Dateigröße, 16 MiB Summe entpackter Einträge und 512 ZIP-Mitglieder verlangen. Bestehende ZIP-Pfad-, Duplikat-, Symlink-, CRC- und Java-Bytecode-Kontrollen bleiben aktiv; bei Überschreitung gilt weiterhin dieselbe knappe Benutzerfehlermeldung ohne Dateiinhalte.
- **TESTS ERGÄNZT:** Zu große JAR-Datei vor ZIP-Öffnung; Deflate-ZIP-Bomb-Regression mit Mock, der einen unerwarteten `testzip()`-Aufruf erkennen würde; ZIP mit zu vielen Einträgen; positiver Test gegen unverändertes originales Gradle-Wrapper-JAR. Bestehende Upload-/Kopiertests weiter aktiv.
- **TESTSTATUS:** GitHub-CI für diesen Branch ist gestartet/noch auf dem exakten finalen HEAD zu verifizieren. Keine lokalen Vollprojekttests, da der Container das GitHub-Repository nicht per DNS auschecken kann. Früheres erfolgreiches GitHub-CI von PR #246 gehört zu D-011, nicht zu diesem Paket.
- **KOMPATIBILITÄT:** Nur `scripts/verify_project.py` und `scripts/tests/test_verify_project.py` verändert (außer Statusdokumenten). Weder Flutter-/Backend-Produktcode noch SRD-/Storymechanik, App-Version, SQLite 2 oder Kampagnen-JSON 1 geändert. Keine Migration.
- **KOORDINATION:** Vor Beginn alle offenen PRs #244–#254 geprüft; keine davon ändert die genannten zwei Python-Dateien. PR #250 übernimmt die technischen Dateien aus PR #246 bytegleich; kein paralleler Eingriff dort. `README.md`/`docs/CODEX_CHECKPOINT.md` nur additiv, spätere Integration durch Chat D konfliktbewusst.
- **NICHT GETESTET:** Finales CI/Android-APK auf Dokumentations-HEAD, reales Android-Gerät, produktive Signatur, historische Upgradepfade.
- **NÄCHSTER SCHRITT:** Exakte PR-HEAD-CI vollständig prüfen, bei Fehlern Korrekturen nur auf diesem Branch vornehmen, vor Merge erneut Main/PR-Konflikte und gemeinsame Dokumente vergleichen.

---

# Chat D D-010 – symlinksichere Checkpoint-Dateimanifeste (26.10.2026)

- **Basis-`main`:** `5e3116f9e3f8de0af6e8125a97b3962cb8910cdf`, PR #238 für Quell-ZIP sicher integriert. **Branch:** `fix/chat-d/checkpoint-manifest-nofollow-20261026`.
- **Ausgangsproblem:** `create_checkpoint.file_manifest` verwendete nach `source_paths` eine ungeschützte `sha256(path)`-Leseoperation und wiederholte `path.stat()`-Aufrufe. Ein nach der Auflistung vertauschter Datei- oder Ordner-Symlink konnte dabei auf fremde Daten zeigen, obwohl die ZIP-Paketierung seit D-009 auf POSIX dagegen gehärtet ist.
- **IMPLEMENTIERT:** Manifest liest durch `package_project.read_verified_source(root, path)` mit POSIX-Dateideskriptoren und `O_NOFOLLOW` bzw. Best-Effort-Fallback auf anderen Plattformen; SHA-256, Größe und Ausführbarkeit stammen aus **demselben geprüften Dateiinhalt und fstat/lstat** statt mehreren möglicherweise unterschiedlichen Dateizugriffen.
- **TESTS ERGÄNZT:** Drei konkrete negative Regressionen gegen nach Scan ausgetauschte Datei-/Elternordner-Symlinks sowie Erhalt zuvor gesicherter ZIP-, Patch-, Manifest- und Prüfsummenartefakte bei Fehlschlag. Bestehende normale Checkpoint-Roundtrip- und Unix-Modus-Tests bleiben aktiv.
- **GETESTET:** Branch-Code und Tests über GitHub gespeichert; die volle GitHub-CI auf dem finalen Stand ist noch **nicht** abgenommen. Eine erfolgreiche Basis-Main-CI beweist diesen neuen Branch nicht.
- **NICHT GETESTET:** vollständige neue Python-/Backend-/Flutter-/Android-/Alpha-CI auf finaler SHA, Android-/Windows-Realgerät, nicht-POSIX-Race-Sicherheit.
- **BLOCKIERT:** endgültige CI und erneuter Main-/PR-Dateiabgleich nach eventuellen parallelen Merges. PRs #236/#237/#239 anderer Chats bleiben unverändert.
- **KEINE MIGRATION:** App, SQLite, JSON, Regelengine, Story, Versionscode und gespeicherte Spielstände unverändert. Nur Checkpoint-Erstellung/Tests.
- **NÄCHSTER SCHRITT:** Finale CI und Checkpoint-Artefakte des tatsächlichen PR-HEAD kontrollieren, mögliche Fehler auf eigenem Branch beheben, nach konfliktfreier Synchronisierung integrieren.

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


# Chat D D-015 – Schutz vor Löschen geschützter PR-Branches (28.10.2026)

- **Ausgangs-main-SHA:** `bf5999e98335c1da94b1eafbf2fc8088b392b6ef`.
- **Arbeitsbranch:** `fix/chat-d/cleanup-protected-head-20261028`.
- **PR:** [#335](https://github.com/ManuEtt/Dnd/pull/335) (gestapelt auf PR #337, finale kombinierte CI offen).
- **Technische Commits:** `f6a541f886e65d4cf623e6e3b961256955fbf88c`, `0ce8be9028ece58618d8c7f33e3768d0cbe4c9a7`; Dokumentation auf demselben Branch.
- **Ausgangsproblem:** Die über GitHub gelieferte Branch-Protected-Eigenschaft wurde beim aktiven Cleanup vor dem Archivierungs-/Löschpfad nicht ausdrücklich berücksichtigt.
- **Implementiert:** Guard `branch.protected || protectedNames.has(name)` vor der weiteren Prüfung; geschützte Referenzen können keine Löschaktion auslösen.
- **Geänderte Dateien:** `.github/workflows/cleanup-merged-safe-20261027.yml`, `scripts/tests/test_safe_cleanup_protected_branch.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Tests:** Drei Python-Unittest-Methoden (reguläre Guard-Position, negative Fälle, unveränderte weitere Gates). Ausführung/CI auf ursprünglichem Commit erfolgreich, kombinierte CI noch ausstehend, physischer Gerätetest offen.
- **CI-Ergebnis:** Ausstehend auf finalem Commit. Keine bereits grüne fremde CI als Nachweis verwendet.
- **Risiken:** Snapshot der Schutzflags ist keine atomare Referenzsperre. Bei zwischenzeitlich neu gesetztem Schutz verweigert GitHub selbst die Löschung; keine endgültige Race-Freiheit behauptet.
- **Migration:** Keine, SQLite 2/JSON 1 und App-Version unverändert.
- **Nächster konkreter Schritt:** Finalen PR-Workflow kontrollieren und fehlerfreie Regressionstests bestätigen; bei Rot korrigieren.

---

- **Koordination am 28.10.2026:** Auf PR #337 `maintenance/cleanup-ancestor-branches-20261028` gestapelt; dessen geänderte Trigger und sichere Git-Ancestry-Gates bleiben erhalten. Die Prüfung in `test_safe_cleanup_protected_branch.py` wurde an `#337` angepasst, ohne dessen Testdatei zu überschreiben.


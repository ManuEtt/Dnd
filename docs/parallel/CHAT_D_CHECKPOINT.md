# CHAT D – UTF-8-Byteobergrenze für JSON-Spielstandimport (02.11.2026)

- **Ausgangs-main-SHA:** `84437e4e92d735e179bb2585427b46a10451951d`.
- **Eigener Branch:** `fix/chat-d/utf8-import-size-limit-20261102`.
- **Code-/Testcommit:** `f3359b826f65027979b6e9af09640ff304a1188f`.
- **Pull Request:** [#502](https://github.com/ManuEtt/Dnd/pull/502).
- **Ausgangsproblem:** Eine 10-MiB-Importgrenze wurde allein über
  `String.length` (UTF-16-Codeeinheiten) geprüft. Mehrbyteige Unicodezeichen
  können die tatsächlich importierte UTF-8-Datei größer machen.
- **IMPLEMENTIERT:** tatsächliche UTF-8-Bytezählung mit einem vorgelagerten
  billigen Zeichenlängenfilter; frühzeitige `InvalidSaveException` vor
  JSON-Parsing/SQLite-Transaktion; bisherige Fehlermeldung bleibt bestehen.
- **Geänderte Dateien:** `app/lib/data/sqlite_campaign_repository.dart`,
  `app/test/storage_repository_test.dart`, `README.md`,
  `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Akzeptanz:** 10-MiB-UTF-8-Grenze gilt auch für mehrbyteiges JSON,
  bestehender Spielstand/Revision bleiben nach Ablehnung unverändert;
  valide Unicodeimporte werden akzeptiert.
- **Regressionen hinzugefügt:** zwei SQLite-FFI-Tests mit übergroßer
  Unicode-Szene sowie legalen Umlauten/Emoji und persistiertem Roundtrip.
- **GETESTET:** GitHub-Schreibzugriff, isolierter Branch und PR-Erstellung
  tatsächlich erfolgreich. Kein Testlauf wurde lokal behauptet.
- **NICHT GETESTET:** finale Python-/Backend-/Flutter-/Android-CI, realer
  Android-Backup-Picker; Flutter-/Dart-SDK in dieser Sitzung nicht vorhanden.
- **BLOCKIERT:** keine lokale Flutter-Toolchain, kein Netzwerk-Git-Clone;
  GitHub Actions muss den vollständigen PR-HEAD prüfen.
- **Migrationen:** keine. SQLite-Version 3, äußeres JSON-Schema 1,
  vorhandene Spielstände, Version, Controller und Exportformat unverändert.
- **Konfliktkoordination:** keine überschneidenden offenen Fachdateipfade;
  zentrale Dokumente können beim Zusammenführen andere Statusnachträge
  enthalten, daher ausschließlich additiv konsolidieren.
- **Nächster konkreter Schritt:** PR #502-CI auf dem finalen Head prüfen;
  bei Rot Formatierung/Ursache im selben Branch reparieren, bei Grün
  unabhängigen Integrationsreview veranlassen.

---

# CHAT D – Android-Backupdateinamen: Unicode-Zeilenumbruch sperren (31.10.2026)

- **Ausgangs-main-SHA:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Eigener Branch:** `fix/chat-d/backup-unicode-separators-20261031`.
- **Codecommits:** `147b86ad80ed32b1bdcddd940dbc492312db7909` und `3a32be9c74d79a141602f4461db4714d38902a0c`.
- **Pull Request:** [#449](https://github.com/ManuEtt/Dnd/pull/449), Draft bis vollständiger CI.
- **Ausgangsproblem:** `JsonBackupIo.isSafeName` erlaubt U+2028/U+2029, weil Unicode `LINE_SEPARATOR` und `PARAGRAPH_SEPARATOR` weder ISO-Steuerzeichen noch `FORMAT` sind. Der native SAF-Picker soll keine optisch mehrzeiligen Dateinamen erhalten.
- **IMPLEMENTIERT:** Die Codepoint-Schleife verbietet `Zl`/`Zp` explizit; bisheriger Unicode-FORMAT-/Surrogatschutz bleibt unverändert. Positive und negative Regressionstests schützen internationale, normal sichtbare Namen.
- **Geänderte Dateien:** `app/android/app/src/main/kotlin/de/aetheria/lebendiger_spielleiter/JsonBackupIo.kt`, `app/android/app/src/test/kotlin/de/aetheria/lebendiger_spielleiter/JsonBackupIoTest.kt`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Akzeptanz:** U+2028/U+2029 sicher abgewiesen; U+0085 weiterhin abgewiesen; gewöhnliche Leerzeichen, Umlaute, Emoji und kombinierte Unicodezeichen weiterhin erlaubt. End-to-End-/native Tests auf dem finalen HEAD ohne Regression.
- **GETESTET:** technische Änderung und Testfälle in GitHub gesichert; tatsächliche CI auf finalem Dokumentations-Commit zum Dokumentationszeitpunkt ausstehend.
- **NICHT GETESTET:** finale Remote-Python-/Backend-/Flutter-/JVM-/Android-Builds und echter SAF-Dialog auf Gerät.
- **Bekannte Grenzen:** Unicode-Homoglyphen und providerabhängige Umbenennungen werden durch diese kleine Änderung nicht allgemein gelöst.
- **Kompatibilität:** keine Migration; unveränderte bestehende SQLite-/JSON-Spielstände, Version, Berechtigungen und übrige Komponenten.
- **Koordination:** bei Beginn ausschließlich #446, #447 und #448 offen; keine Fachdateien in deren PRs betroffen. README/zentralen Checkpoint vor Zusammenführung additiv konsolidieren.
- **Genau ein nächster Schritt:** vollständige CI auf dem finalen PR-HEAD prüfen; erst dann Review- und Mergeentscheidung.

---

# CHAT D – D-Backup-Dateinamen: Unicode-Formatzeichen sperren (30.10.2026)

- **Ausgangs-main-SHA:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `fix/chat-d/backup-filename-format-20261030`.
- **Implementierungs-Commits:** `554774752a0d7c63da21d014f57065fc4ba9793d`, `4f26cdd51ad0e0a40a609b9e70f7a7e05e2f4f4f`; aktueller dokumentierter Branch-HEAD ist im PR einzusehen.
- **Pull Request:** [#421](https://github.com/ManuEtt/Dnd/pull/421) (nach grüner CI zur Review freigegeben).
- **Ausgangsproblem:** Native `JsonBackupIo.isSafeName` akzeptierte bislang unsichtbare Unicode-FORMAT-Codepoints und verwaiste UTF-16-Surrogate. Daraus konnten mehrdeutig angezeigte Backup-Dateinamen entstehen.
- **IMPLEMENTIERT:** Native Dateinamenprüfung weist Formatzeichen (einschließlich Bidi-Overrides/-Isolates, Zero-Width-Zeichen, Unicode-Tags) und unpaarige Surrogate ab; sichtbares Unicode einschließlich Umlauten, Emoji und kombinierenden Zeichen bleibt zulässig.
- **Betroffene Dateien:** `app/android/app/src/main/kotlin/de/aetheria/lebendiger_spielleiter/JsonBackupIo.kt`, `app/android/app/src/test/kotlin/de/aetheria/lebendiger_spielleiter/JsonBackupIoTest.kt`, `README.md`, `docs/CODEX_CHECKPOINT.md`, diese Checkpointdatei.
- **Tests/CI bei Dokumentation:** Vollständige GitHub-CI [#41119725865](https://github.com/ManuEtt/Dnd/actions/runs/41119725865) auf `da12ce1` erfolgreich; dabei Python-/Backend-/Flutter-/native Gradle-Tests und APK-Builds erfolgreich. Erneute CI nach main-Integration erforderlich, Android-SAF-Realgerät weiterhin ungetestet.
- **Akzeptanz:** Pfad-/Steuerzeichen bleiben verboten; beliebige FORMAT-Codepoints oder einzelne Surrogate werden abgelehnt; bekannte sichtbare Namen bleiben zulässig; die bestehende Gesamtsuite bleibt grün.
- **Migration/Kompatibilität:** keine Änderung an SQLite, JSON, Spielstandsdateien, App-Version, Regeln, Story, Android-Berechtigungen oder Picker-Ablauf.
- **Bekannte Grenzen:** Keine Garantien gegenüber UI-Spoofing durch andere Unicode-Buchstabenähnlichkeiten (Homoglyphen). Ein echter Android-SAF-Gerätetest bleibt notwendig. Parallele README-/Checkpoint-Einträge vor Integration verlustfrei konsolidieren.
- **Nächster konkreter Schritt:** finale CI und die 12+ nativen `JsonBackupIoTest`-Fälle auf PR #421 vollständig prüfen, anschließend Abnahme/Integration nur bei nachgewiesen grünem HEAD und Review.

---

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

# Chat D D-018 – Modulwurzeln fail-closed prüfen (30.10.2026)

- **Ausgangs-Main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `fix/chat-d/boundary-module-presence-20261030`.
- **Code-Commit:** `8a14e706deeceff2fc5709cfdc928e5e25c3115b`.
- **Pull Request:** [#401](https://github.com/ManuEtt/Dnd/pull/401), Draft.
- **Problem:** `check_repository()` brach nur bei fehlendem Story-Ordner ab; ein fehlender Domain-Ordner, eine Datei statt Modulverzeichnis oder symlink-basierte Modulwurzel konnte den Importgrenzen-Prüfauftrag umgehen oder entwerten.
- **IMPLEMENTIERT:** Beide Modulwurzeln müssen echte, nicht-symlinked Verzeichnisse sein; sonst Rückgabe von Fehlern und kein erfolgreiches `OK`. Danach unveränderte rekursive Import- und Whitelist-Prüfung.
- **Geänderte Dateien:** `scripts/check_domain_boundaries.py`, `scripts/tests/test_domain_boundaries.py`, `scripts/tests/test_nested_domain_boundaries.py`, dazu additive Einträge in `README.md`, `docs/CODEX_CHECKPOINT.md` und diesem Checkpoint.
- **Regressionen:** beide Modulwurzeln fehlen; nur Domain fehlt; reguläre Datei statt Story-Verzeichnis; Story-Modul als Symlink; gültige Modulverzeichnisse; gültige verschachtelte Story-Imports mit vollständiger Fixture.
- **GETESTET:** zum Zeitpunkt dieses Checkpoints keine tatsächliche vollständige Testausführung. Der Workflow wurde über Skriptpfadänderungen ausgelöst; finale Ergebnisse gesondert prüfen.
- **NICHT GETESTET:** vollständige Python-, Backend-, Flutter-, Android-CI/Debug-APK, native Tests und Realgerät; keine grünen Resultate unterstellen.
- **BLOCKIERT:** GitHub-DNS-Checkout im lokalen Container fehlgeschlagen; Flutter und Dart lokal nicht verfügbar.
- **Migrationen:** keine; unveränderte SQLite-/JSON-Spielstände und Appversion.
- **Koordination:** offene PRs #387–#399 ändern nicht die drei technischen Dateien dieses Pakets; gemeinsame README-/Checkpoint-Zeilen vor späterer Integration additiv bewahren.
- **Nächster konkreter Schritt:** finale GitHub-Actions-CI auf dem Dokumentations-HEAD verifizieren, dann bei grüner Gesamt-CI und konfliktfreier Abnahme Draft prüfen und gegebenenfalls zur Review freigeben. Keine fremden PRs automatisch mergen.

---

# Chat D D-019 – Vollständig installiertes Android-NDK bei Retry bewahren (30.10.2026)

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Arbeitsbranch:** `fix/chat-d/preserve-installed-ndk-20261030`.
- **Code-Commit:** `0999d7a44d75233a6091b0808b9ab60c740e5412`.
- **Pull Request:** [#402](https://github.com/ManuEtt/Dnd/pull/402), bis zur finalen CI im Draft.
- **Problem:** Ein fehlgeschlagenes SDK-Installationskommando löschte vor jedem weiteren Versuch auch ein bereits installiertes `ndk;27.0.12077973`, obwohl der Fehler durch andere Pakete verursacht sein konnte.
- **IMPLEMENTIERT:** Vor dem NDK-Cleanup auf `source.properties` prüfen; ohne Marker unvollständiges NDK entfernen, mit Marker Daten bewahren. Download-Staging und Android-Cache wie bisher bereinigen.
- **Dateien:** `scripts/install_android_sdk_packages.sh`, `scripts/tests/test_install_android_sdk_packages.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Akzeptanz:** Zwei zusätzliche Fälle (vorinstalliertes NDK, transient/dauerhaft gescheiterter `sdkmanager`) müssen NDK bewahren; bestehende Fälle müssen unvollständiges NDK entfernen, Cache bereinigen, Retry/Fehlercodes erhalten.
- **GETESTET:** Code und Tests in GitHub gesichert; kein lokaler Gesamttest bestätigt.
- **NICHT GETESTET:** CI auf finalem Commit, vollständiges Backend/Flutter/Android, APK, natives Gradle und Realgerät.
- **BLOCKIERT:** GitHub-DNS nicht im lokalen Container auflösbar; lokale Toolchain/Checkout fehlen.
- **Migrationen:** keine; SQLite-/JSON-Version, Spielstände, Regel-/Storymodule und Appversion unverändert.
- **Koordination:** bei Start alle offenen PRs #387–#401 geprüft, technische Dateipfade überschneidungsfrei; gemeinsam genutzte README-/Checkpoint-Dateien vor Integration verlustfrei konsolidieren.
- **Vorgänger PR #401:** Code-/Doku-Commit `0544c238c39da11b4f18e77a70c1cb0af10b4bbd` vollständig erfolgreich in [Actions #41007222064](https://github.com/ManuEtt/Dnd/actions/runs/41007222064), zur Review bereit, nicht gemergt.
- **Nächster Schritt:** finale CI von #402 auf exakt dem letzten Commit abnehmen und nur bei vollständigem Erfolg zur Review freigeben. Kein automatischer Merge fremder oder ungeprüfter PRs.

---

# Chat D D-020 – Quell-ZIP-Exklusivsperre auf aktuellen Main integriert (29.10.2026)

- **Basis:** `55fe44475a113943c6310ec16a8ffb481185f4e9`,
  bestehender PR-Head `5d5d615d9fc6b8c5152cc5fae1cb1725f1fc4758`.
- **IMPLEMENTIERT:** exklusives Ausgabe-Lock umfasst ZIP- und
  Prüfsummenveröffentlichung sowie Rollback; konkurrierende Ausgaben
  blockieren fail-closed. Drei neue Regressionen.
- **GETESTET:** ursprünglicher PR-Head in
  [CI #40918352502](https://github.com/ManuEtt/Dnd/actions/runs/40918352502)
  mit **36/36** Schritten erfolgreich.
- **OFFEN:** kombinierte CI nach dokumentationstreuer Main-Aufnahme;
  reale Mehrprozess-Runner, Windows, Android-Gerät.
- **KOMPATIBILITÄT:** kein Produkt-/Speicher-/Schemawechsel.
- **STATUS:** [PR #391](https://github.com/ManuEtt/Dnd/pull/391)
  reviewbereit; kein automatischer Produkt-Merge.

---

# Chat D D-020 – Unix-Typkontrolle für Alpha-APKs (30.10.2026)

- **Ausgangs-Main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `fix/chat-d/apk-entry-types-20261030`.
- **Code-Commit:** `df45e36d78f2fba2372df4fec462a6df6eb5f7a6`.
- **Pull Request:** [#406](https://github.com/ManuEtt/Dnd/pull/406), Draft bis finaler CI.
- **Ausgangsproblem:** CRC-valide ZIP-Einträge können Unix-FIFOs, Devices, Sockets oder eine Verzeichnisdatei mit Dateinamen wie `libapp.so` deklarieren. Die Alpha-APK-Prüfung sperrte bisher nur Symlinks und unsichere Namen.
- **IMPLEMENTIERT:** Unix-ZIP-Modustypen nur als reguläre Datei, Verzeichnis oder ohne bekannten Typ akzeptieren; Typ-/Namens-Widersprüche abweisen. Bestehende Symlink-Prüfung unverändert.
- **Geänderte Dateien:** `scripts/prepare_alpha_release.py`, `scripts/tests/test_prepare_alpha_release.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Regressionen:** vier unzulässige Unix-Sonderdateitypen; Verzeichnis statt Pflichtbibliothek; gültige Unix-Regulärdatei plus Verzeichnis; bestehende APK-Symlink-/ZIP-/Archivtests.
- **GETESTET:** Implementierung und Tests auf GitHub gesichert; vollständige CI noch nicht als erfolgreich bestätigt.
- **NICHT GETESTET:** Python-/Backend-/Flutter-/Android-Gesamtsuite auf finalem Commit und Gerätetest.
- **BLOCKIERT:** lokaler GitHub-Checkout wegen DNS nicht möglich. GitHub Actions verfügbar.
- **Migrationen:** keine; alle vorhandenen Spielstände, SQLite- und JSON-Formate unverändert.
- **Koordination:** zum Start alle PRs bis #405 geprüft; keine betroffene technische Datei bereits durch fremde PRs in Arbeit. Gemeinsame README-/Checkpoint-Änderungen später verlustfrei konsolidieren. Keine automatischen Merges/Löschungen.
- **Vorarbeiten:** #401 und #402 auf jeweiligem finalem Commit erfolgreich per GitHub Actions geprüft und zur Review freigegeben; weiterhin nicht in `main` integriert.
- **Nächster Schritt:** komplette PR-CI #406 am finalen Head verifizieren, Fehler auf demselben Branch reparieren und bei Grün zur Review freigeben. Keine produktive Signatur oder echten Gerätetests behaupten.
# Chat D D-023 – Remote-Backend PUBLIC_ORIGIN strikt prüfen (30.10.2026)

- **Ausgangs-Main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `fix/chat-d/backend-public-origin-20261030`.
- **Code-Commit:** `7ffa749d8be11ff9a518faaf8a65fc86f940dad1`.
- **Pull Request:** [#411](https://github.com/ManuEtt/Dnd/pull/411), zunächst Draft.
- **Problem:** `PUBLIC_ORIGIN` akzeptierte HTTPS-Adressen mit Pfad, Query oder Fragment, obwohl nur ein reiner Serverursprung vorgesehen ist.
- **IMPLEMENTIERT:** HTTPS-/Credentials-Checks um `pathname === '/'`, leeren `search` und leeren `hash` erweitern. Bestehende erlaubte Ursprünge mit optionalem Port erhalten.
- **Dateien:** `backend/src/config.ts`, `backend/test/backend.test.ts`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Regressionen:** gültige Ursprünge mit/ohne Schrägstrich und mit Port; ungültige Pfade, Query, Fragmente, Benutzerinformationen und HTTP.
- **GETESTET:** Code, Regressionstests und Checkpoints auf PR-Branch gesichert; CI auf finalem Head noch nicht abgeschlossen.
- **NICHT GETESTET:** finale Backend-/Flutter-/Android-Gesamtsuite und realer Reverse-Proxy-/Gerätetest.
- **BLOCKIERT:** lokaler GitHub-Checkout wegen DNS nicht möglich; GitHub-Connector und Actions sind verfügbar.
- **Migrationen:** keine; Spielstände und SQLite-/JSON-Dateien bleiben erhalten, kein SRD-/Appversionswechsel.
- **Koordination:** alle offenen PR-Dateipfade geprüft und keine technischen Überschneidungen; README/zentralen Checkpoint vor Merge verlustfrei konsolidieren. Keine fremden Branches verändert.
- **Vorgänger:** #401, #402, #406, #409 vollständig CI-grün und zur Review freigegeben. #410 beim letzten Abruf im Android-CI-Lauf, kein automatischer Merge.
- **Nächster Schritt:** finale GitHub-Actions-Abnahme für #411; Fehler auf eigenem Branch korrigieren, danach zur Review freigeben, keine ungeprüfte Integration.
# Chat D D-019 – Ressourcenbegrenzung in der Projektvorprüfung (29.10.2026)

- **Main-SHA bei Beginn:** `fde0ef6ed8b419d6a31c701a03aa05d61994c352`.
- **Eigener Branch:** `fix/chat-d/bounded-metadata-preflight-20261029`.
- **Code-Commits:** `76ffccf718ffd0f807c0b8a90d0545b4f2308a50`,
  `d32e318c6f00782ccbd4deed64a4999235ec02df`.
- **Ausgangsproblem:** Metadaten-JSON, Gradle-Properties und `gradlew`
  wurden im Vorabprüfer unabhängig von tatsächlicher Dateigröße ganz
  eingelesen. Beschädigte, extrem große Uploads konnten Ressourcen
  verschwenden, ehe Flutter/Android-Tests beginnen.
- **IMPLEMENTIERT:** `_read_bounded_utf8` begrenzt den tatsächlichen
  Leseumfang auf höchstens Limit+1 Byte für JSON (16 MiB) und Properties
  (64 KiB); kein nur auf `stat` basierender Schutz. Das Launcher-Shebang
  wird per `readline(4097)` mit LF- und CRLF-Prüfung geprüft.
  Bestehende Datenformate und normale Projektdateien unverändert.
- **Dateien:** `scripts/verify_project.py`,
  `scripts/tests/test_verify_project.py`, `README.md`,
  `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Akzeptanzkriterien:** beide übergroßen JSON-Dateien abweisen;
  übergroße Properties abweisen; ein gültiges kurzes Launcher-Shebang
  bei 64-MiB-Testdatei ohne `Path.read_bytes()` verarbeiten; zu langes
  Shebang abweisen; ursprüngliche Positiv- und Negativtests bestehen.
- **GETESTET:** vorherige Main-CI
  [#40867945743](https://github.com/ManuEtt/Dnd/actions/runs/40867945743)
  erfolgreich, **nicht** diese Änderungen. Zu Beginn keine offenen PRs.
- **NICHT GETESTET:** neue vollständige CI, Backend, Flutter, Android,
  natives APK-Packaging und Realgerät auf diesem Branch.
- **BLOCKIERT:** vollständiger lokaler Checkout durch GitHub-DNS
  nicht verfügbar; Flutter-/Dart-SDK nicht installiert.
- **Grenze:** keine neue racefreie Verifikation gegen während der
  Prüfung ausgetauschte Symlinks oder Dateien; nur Lesegrößen-Begrenzung.
- **Kompatibilität:** keine SQLite-/JSON-/Schema-/Versionsmigration.
- **Nächster Schritt:** CI auf finalem PR-Commit abnehmen; danach
  aktuelle Main-/PR-Dateien vor Review und Integration erneut prüfen.
# Chat D D-021 – Checkpoint-Veröffentlichung exklusiv sperren (29.10.2026)

- **Basis-Main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `fix/chat-d/checkpoint-publish-lock-20261029`.
- **Code-Commit:** `cc2c557ea6f3eedb1e2aacf0fa761f70574528a2`.
- **Problem:** Parallele `create_checkpoint`-Aufrufe auf dasselbe
  Verzeichnis konnten das versionierte Checkpoint-Set und seine stabilen
  `Wuerfelraunen_LATEST_Vollprojekt.zip`- bzw. `SHA256SUMS.txt`-
  Aliase gegenseitig überschreiben.
- **IMPLEMENTIERT:** Mit `mkdir` atomar beanspruchtes
  `.checkpoint.lock` über temporäre Erzeugung, Prüfung,
  historische Dateihashes, veröffentlichte Versionen und beide Aliase.
  Zweiter Lauf scheitert fail-closed, ohne fremde Sperren oder bereits
  veröffentlichte Dateien anzufassen. Eigener Lock wird in `finally`
  freigegeben; harte Crash-Sperren bleiben zur manuellen Prüfung.
- **Technische Dateien:** `scripts/create_checkpoint.py`,
  `scripts/tests/test_create_checkpoint.py`.
- **Dokumentation:** `README.md`, `docs/CODEX_CHECKPOINT.md`,
  `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Tests:** Drei neue Regressionen (vorhandenes Lock,
  konkurrierender Aufruf vor ZIP-Veröffentlichung, `KeyboardInterrupt`
  und sicherer Retry). Bestehende Manifest-/Git-Patch-/Symlink-/
  Integritätstests bleiben aktiv.
- **GETESTET:** vorherige Main-CI, **nicht** die neue Branch-CI.
- **NICHT GETESTET:** neuer vollständiger CI-Run, Windows,
  externe Mehrprozess-Rennen, Realgerät.
- **KOMPATIBILITÄT:** keinerlei Änderung an Spielständen,
  Regelsystem, Datenbank, JSON oder App-Version.
- **KOORDINATION:** PRs #387, #388, #389, #391, #392 und #394
  vor Paketstart überprüft; keine technischen Dateiüberschneidungen.
  README und zentraler Checkpoint beim späteren Merge additiv bewahren.
- **NÄCHSTER SCHRITT:** CI auswerten, neue PRs prüfen, Review-Freigabe.
# Chat D D-024 – Fantasy-Button-Generierung sicher veröffentlichen (30.10.2026)

- **Ausgangs-Main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `fix/chat-d/fantasy-button-output-safety-20261030`.
- **Code-Commit:** `69d691a58fb12dfc850920d2c1e0f7960c4084de`.
- **Pull Request:** [#412](https://github.com/ManuEtt/Dnd/pull/412), Draft bis abschließender CI.
- **Ausgangsproblem:** `Path.write_bytes()` konnte eine vorhandene Button-PNG durch einen abgebrochenen Schreibvorgang beschädigen oder über vorhandene Symlinks in fremde Verzeichnisse schreiben; auch `mkdir(parents=True)` konnte über Symlink-Vorfahren umgeleitet werden.
- **IMPLEMENTIERT:** bekannten Symlinks an allen vorhandenen Ausgabepfad-Komponenten, direkt vor/nach `mkdir` und vor der Veröffentlichung ausweichen; nur reguläre Ausgabedateien zulassen. Vollständig generierte PNGs temporär speichern und per `os.replace` atomar veröffentlichen, Staging stets aufräumen; Dateimodus bestehender PNGs erhalten.
- **Geänderte Dateien:** `scripts/generate_fantasy_buttons.py`, `scripts/tests/test_generate_fantasy_buttons.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Akzeptanz/Regressionen:** bestehende 30-PNG-/Reproduzierbarkeitstests sowie fünf neue Tests gegen verlinktes Zielverzeichnis, verlinkten Vorfahr, PNG-Symlink, fehlgeschlagenen atomaren Publish und nicht-reguläre Ausgabedatei.
- **GETESTET:** Branch-Commit und PR angelegt; vollständiger CI-Lauf auf finalem Commit noch nicht als Erfolg bestätigt.
- **NICHT GETESTET:** finale Python-/Backend-/Flutter-/Android-/APK-/Release-Kette, Realgerät.
- **BLOCKIERT:** GitHub-DNS für lokalen Checkout; CI über GitHub Actions verfügbar.
- **Migrationen:** keine; kein Einfluss auf Spielstände, SQLite/JSON, SRD/Story oder Appversion.
- **Koordination:** alle offenen PRs bis #411 überprüft, keine technischen Dateipfad-Überschneidungen. Gemeinsam verwendete README-/Checkpoint-Dateien erst bei Integration additiv abgleichen; keine fremden Branches verändert, kein Merge.
- **Vorgänger:** #401, #402, #406, #409 und #410 vollständig CI-grün und zur Review freigegeben; #411 beim letzten Abruf noch im Android-Build.
- **Nächster Schritt:** CI für finalen #412-Commit vollständig abnehmen; bei Fehlern auf eigenem Branch korrigieren, andernfalls PR zur Review freigeben.

---

# Chat D – Integration von PR #358 nach Checkpoint-Fix #363 (29.10.2026)

# Chat D D-018 – Main-/Referenzabgleich bei Branch-Bereinigung (30.10.2026)

- **Ausgangs-main-SHA:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Eigener Branch:** `fix/chat-d/retire-main-recheck-20261030`.
- **Code-/Testcommit:** `b33ef1597630d2e6e896a97072a22da0b2101782`;
  **Pull Request:** [#419](https://github.com/ManuEtt/Dnd/pull/419), Draft.
- **Ausgangsproblem:** Das historische, allowlistbasierte Cleanup prüfte den
  `main`-SHA nur beim Start und behauptete nach DELETE ohne GET-Ergebnis
  eine erfolgreiche Entfernung.
- **IMPLEMENTIERT:** Erneute `main`-Konsistenz-, Branchschutz- und
  Compare-Prüfung unmittelbar vor tatsächlichem DELETE; danach
  branchspezifisches GET mit Fehler bei noch vorhandener Referenz.
- **Betroffene Dateien:** `scripts/retire_merged_branches.py`,
  `scripts/tests/test_retire_merged_branches_execution.py`,
  `README.md`, `docs/CODEX_CHECKPOINT.md`,
  `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Regressionen:** sechs neue vollständig gemockte Positive-/Negative-Tests
  (Löschung, geänderter main, Protection, Divergenz, wirkungsloser DELETE,
  Standard-Dry-Run). **Noch kein Test als erfolgreich ausgeführt belegt.**
- **CI:** finale GitHub Actions noch auf PR-HEAD zu verifizieren.
- **BLOCKIERT:** Lokaler Repository-Checkout per DNS und Flutter-/Dart-SDK.
- **Migration:** keine; keine Flutter-/Backend-Produkt- oder
  SQLite-/JSON-Spielstandsänderung. Keine echten Branchlöschungen.
- **Grenze:** nur Vorab-Race-Reduktion, kein atomarer DELETE-Lease.
- **Koordination:** 30 anfänglich offene PRs abgeglichen; beide
  Python-Fachdateien waren unbelegt. README-/Checkpoint-Dokumentation
  vor Integration mit den anderen Chats additiv zusammenführen.
- **Nächster Schritt:** vollständigen Test-/Actions-Status des finalen
  PR-Commits prüfen und bei Fehlschlag gezielt korrigieren.

---


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


## Chat D D-018 – SQLite-Outbox-Aufträge beim direkten Speichern validieren (30.10.2026)

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9` (Alpha 0.8.48+98). **Branch:** `fix/chat-d/pending-action-sqlite-validation-20261030`. **Technischer Commit:** `099a115b77af967483e9375a3fad9bed0cd1dd2b`. **PR:** [#397](https://github.com/ManuEtt/Dnd/pull/397), Draft.
- **Ausgangsproblem:** Direkte Aufrufe von `SqliteCampaignRepository.stagePendingAction` konnten leere, überlange oder ungültige Auftragsdaten dauerhaft speichern. Die spätere `PlayerActionOutbox.pendingFor`-Decodierung akzeptiert diese Daten nicht. Ein anschließender Neustart konnte damit an einem nicht wiederherstellbaren ausstehenden Auftrag hängen bleiben.
- **IMPLEMENTIERT:** Vor jedem SQLite-Schreibzugriff dieselben Längen-/Request-ID-Schranken wie bei der Outbox: Kampagnen-ID nicht leer, bis 128 Zeichen, ohne Steuerzeichen; Request-ID 1–128 ASCII-Buchstaben, Ziffern, Unterstrich oder Bindestrich; Handlung nicht blank und höchstens 4000 Zeichen. NPC-Identität, Revisionsbindung und atomare Duplikatsperre bleiben unverändert.
- **Neue Regressionen:** `app/test/pending_action_sqlite_validation_test.dart` prüft ungültige IDs, Steuerzeichen, Texte, Grenzwerte und den unveränderten Zustand bei Ablehnung; gültiges Staging, SQLite-Neustart, Outbox-Decodierung inklusive NPC-Auswahl sowie genaues Entfernen und Request-ID-Konflikt.
- **Geänderte Dateien:** `app/lib/data/sqlite_campaign_repository.dart`, `app/test/pending_action_sqlite_validation_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **GETESTET:** Technischen Code-Diff gegen main erneut geprüft (13 zusätzliche Produktionszeilen, keine entfernten Zeilen); GitHub-Branch und Draft-PR existieren. **Die neuen Flutter-Tests sind zum Zeitpunkt dieser Dokumentation noch nicht als erfolgreich ausgeführt bestätigt.**
- **NICHT GETESTET:** Vollständige finale GitHub Actions auf finalem Dokumentations-Commit, Dart-Format und Analyse, Flutter-Suite, Backend/Python, Android-Build/native Tests, reales Android-Gerät. Lokaler GitHub-Checkout scheitert an DNS; Flutter/Dart fehlen.
- **BLOCKIERT:** Finaler CI-Nachweis und manueller Main-/PR-Abgleich vor Integration. Offene fachliche PRs #387, #388, #392, #394 sowie Chat-D-PRs #389, #391, #395 ändern keine der beiden technischen Dateien. Gemeinsame Dokumentation vor Merge additiv konsolidieren.
- **Migration:** Keine. SQLite-Schema 3, Kampagnen-JSON 1, bestehende Spielstände, Appversion und fachliche Regeln unverändert. Historische ausstehende Aktionen werden nicht mutiert.
- **Nächster Schritt:** Finale `flutter test test/pending_action_sqlite_validation_test.dart` und vollständige GitHub-Actions-Pipeline auf dem tatsächlichen PR-HEAD verifizieren; erst danach Review-/Integrationsfreigabe erwägen.

---

---

# Chat D – D-025: Unicode-sichere Quellcode-ZIP-Pfade (31.10.2026)

- **Ausgangs-Main-SHA:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Branch:** `fix/chat-d/archive-unicode-controls-20261031`.
- **Code-/Test-Commit:** `59757423be3bbd47be9a39a1a187a1cb3baee71e`;
  endgültigen Branch-HEAD und CI nach Dokumentationscommit im PR prüfen.
- **PR:** https://github.com/ManuEtt/Dnd/pull/451 (Draft).
- **Problem:** Source-ZIP-Path-Validator erlaubte C1-Steuerzeichen,
  Zero-Width-/Bidi-Formatzeichen, Zl/Zp-Trennzeichen und isolierte Surrogate.
  Dies kann irreführende oder nicht portable ZIP-Namen erzeugen.
- **IMPLEMENTIERT:** `scripts/package_project.py` verwirft in
  `validate_portable_source_paths` zusätzlich Kategorie Cc/Cf/Cs/Zl/Zp,
  bewahrt gültige sichtbare Unicode-Zeichen einschließlich kombinierender
  Akzente und Emoji, und lässt den bestehenden atomaren Export unberührt.
- **Tests ergänzt:** `scripts/tests/test_package_project.py` enthält
  vier Regressionen für Steuer-/Formatzeichen, Verzeichnisse/Surrogate,
  gültige Unicode-Dateinamen und Erhalt früherer ZIP/SHA256-Ausgaben.
- **Geänderte Dateien:** `scripts/package_project.py`,
  `scripts/tests/test_package_project.py`, `README.md`,
  `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **GETESTET:** neue Tests geschrieben, noch nicht als bestanden ausgewiesen.
- **NICHT GETESTET:** Python-Gesamtsuite, Backend/Flutter/Android/APK und
  finale Actions auf PR-HEAD; kein reales Android-Gerät.
- **BLOCKIERT:** lokaler Checkout DNS `github.com` nicht auflösbar;
  Flutter/Dart nicht vorhanden. GitHub-CI muss die Ausführung bestätigen.
- **Migrationen:** keine. SQLite 3, äußeres JSON 1, Spielstände und API
  bleiben unverändert.
- **Koordination:** #449 betrifft native Kotlin-Dateinamen; dieses Paket
  ausschließlich Quellarchiv-Python. #446–#448 betreffen andere Codepfade.
  Dokumentationskonflikte in README/CODEX/CHAT_D nur additiv integrieren.
- **Nächster konkreter Schritt:** finale PR-#451-CI prüfen; bei Fehlern
  denselben Branch korrigieren, erst danach Review-/Merge-Freigabe erwägen.


---

# CHAT D – D-026: Unicode-Kontrollzeichen in APK-Archiven sperren (01.11.2026)

- **Ausgangs-main-SHA:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Branch:** `fix/chat-d/apk-unicode-entry-names-20261101`; **PR:** https://github.com/ManuEtt/Dnd/pull/460.
- **Code-Commit:** `1b5928ded1bd14fbe204b0bd82b725dc40b08a93`.
- **Test-Commit:** `14431b670ae4a6cd0c8b87d6d98d2d6be7d8ce88`.
- **Problem:** Der APK-Release-Validator akzeptierte Unicode C1, unsichtbare
  Format- und Bidi-Zeichen, Zeilen-/Absatztrennzeichen und Surrogat-Metadaten.
  CRC-gültige Einträge konnten dadurch irreführende ZIP-Namen tragen.
- **Implementiert:** Der Validator verweigert alle ZIP-Mitgliedsnamen
  mit Unicode-Kategorie `Cc/Cf/Cs/Zl/Zp` vor Dekomprimierung und Publikation.
  Bestehende Pfad-, Größen-, Dateityp- und Symlink-Sperren bleiben erhalten.
- **Dateien:** `scripts/prepare_alpha_release.py`,
  `scripts/tests/test_prepare_alpha_release.py`, `README.md`,
  `docs/CODEX_CHECKPOINT.md` und diese persönliche Checkpointdatei.
- **Tests:** fünf neue Python-Methoden für C1/Bidi/Zero-Width/Separator,
  Verzeichnis-Trenner, Surrogat-Metadaten, sichtbare Unicode-Namen und
  Schutz früherer Release-Artefakte.
- **GETESTET:** nur Testcode erstellt; finaler GitHub-CI-Nachweis steht aus.
- **NICHT GETESTET:** komplette Python-/Backend-/Flutter-/native Gradle-
  Testreihen und APKs auf endgültigem PR-HEAD; Realgerät/TalkBack.
- **BLOCKIERT:** GitHub-Checkout lokal DNS-Fehler, Flutter/Dart fehlen;
  PR-CI muss vollständige Ergebnisse liefern.
- **Koordination:** Beim Start wurden alle offenen PRs #446–#458 geprüft,
  keine Überschneidung bei den beiden Python-Technikdateien. README und
  zentraler Checkpoint erfordern verlustfreies Zusammenführen.
  Keine fremden PRs/Branches geändert oder gemergt.
- **Migrationsfolgen:** keine; SQLite 3, JSON 1 und ältere Spielstände bleiben
  unverändert. Kein Versionssprung, keine neue Android-Berechtigung.
- **Nächster konkreter Schritt:** PR-#460-CI auf dem finalen Commit auswerten;
  Konfliktprüfung vor Integration wiederholen, kein ungeprüfter Merge.


---

# CHAT D – D-027: Gradle-Wrapper-JAR Unicode-Kontrollzeichen (01.11.2026)

- **Ausgangs-main-SHA:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Branch:** `fix/chat-d/gradle-wrapper-unicode-entries-20261101`.
- **Code-Commit:** `2616c50fff45e64f9d577b3d3bf93d0dab5ad9ca`.
- **Test-Commit:** `5188d18ec791803ff79b21e91c00da230c344cc6`.
- **Pull Request:** https://github.com/ManuEtt/Dnd/pull/462 (Draft).
- **Ausgangsproblem:** Der Prüfpfad für
  `app/android/gradle/wrapper/gradle-wrapper.jar` lehnte ASCII C0/DEL,
  ZIP-Traversal, Duplikate, Symlinks und manipulierte CRCs bereits ab,
  aber nicht alle unsichtbaren Unicode-Formate und Separatoren.
- **IMPLEMENTIERT:** `scripts/verify_project.py` sperrt ZIP-Eintragsnamen
  der Unicode-Kategorien `Cc/Cf/Cs/Zl/Zp`, vor CRC-Dekomprimierung.
  Bestehende JAR-Binärdatei, Größenlimits und sichere ASCII-Pfade bleiben
  unverändert.
- **Geänderte Dateien:** `scripts/verify_project.py`,
  `scripts/tests/test_verify_project.py`, `README.md`,
  `docs/CODEX_CHECKPOINT.md` und diese Datei.
- **Regressionen:** `test_wrapper_rejects_invisible_unicode_names_before_crc`,
  `test_wrapper_rejects_unicode_separator_in_directory`,
  `test_wrapper_rejects_surrogate_member_metadata_before_crc`,
  `test_visible_unicode_wrapper_members_remain_allowed`.
- **GETESTET:** noch keine vollständige CI auf finalem PR-HEAD; diese
  Rubrik wird erst nach tatsächlich beobachtetem GitHub-Lauf aktualisiert.
- **NICHT GETESTET:** Python-Gesamtsuite, Backend, Flutter-Analyse/Tests,
  nativer Android-Test, APKs und reales Smartphone auf finalem Commit.
- **BLOCKIERT:** CI-Abnahme vor Freigabe sowie konfliktfreie Dokumentations-
  konsolidierung. GitHub-Checkout im Container durch DNS blockiert;
  Flutter/Dart-SDK lokal nicht verfügbar.
- **Migration:** keine. SQLite-Schema 3 / äußeres JSON 1 / vorhandene
  Spielstände bleiben unverändert, keine Version-/Berechtigungsänderung.
- **Parallele Koordination:** Vor Beginn alle offenen PRs #446–#461
  auf die beiden Python-Zieldateien geprüft; keine Überschneidung.
  Andere Branches, PRs und `main` nicht verändert.
- **Nächster konkreter Schritt:** finale CI am PR-HEAD prüfen; danach
  mit aktuellem Main und offenen PRs erneut Konflikte abgleichen.

---

# CHAT D – D-028: gemeinsame ZIP-Unicode-Schutzintegration (01.11.2026)

- **Ausgangs-main-SHA:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Eigener Branch:** `chore/chat-d/integrate-unicode-zip-guards-20261101`.
- **Quellen und finale geprüfte Head-SHAs:**
  - PR #451: `33463cc1c8719bbfb5aa0139497ca3a0a45c1cd0`;
    CI https://github.com/ManuEtt/Dnd/actions/runs/41244456398 erfolgreich.
  - PR #460: `d9fe14ac21d6f1ad2944ab77c7b35a8ec2d0bfeb`;
    CI https://github.com/ManuEtt/Dnd/actions/runs/41282041207 erfolgreich.
  - PR #462: `afe9853e14eb49b7e997a2c6400608361f99c210`;
    CI https://github.com/ManuEtt/Dnd/actions/runs/41312267140 erfolgreich.
- **Scope:** `scripts/package_project.py`,
  `scripts/tests/test_package_project.py`,
  `scripts/prepare_alpha_release.py`,
  `scripts/tests/test_prepare_alpha_release.py`,
  `scripts/verify_project.py`,
  `scripts/tests/test_verify_project.py` plus die drei
  gemeinsam genutzten Dokumentationen.
- **IMPLEMENTIERT:** Genau sechs fachliche Git-Blobs aus finalen
  Quellen ohne Quellcodeänderung übernommen; README/CODEX_CHECKPOINT
  und CHAT_D_CHECKPOINT mit allen drei kompletten Quellnachträgen und
  diesem aktualisierten Status additiv vereint.
- **GETESTET:** alle drei Quell-PRs auf finalem Commit vollständig
  erfolgreich (Python/Backend/Flutter/native Android/Alpha-APKs).
- **NICHT GETESTET:** kombinierte Integrations-CI auf neuem HEAD,
  Realgerät, Android-SAF/Dateipicker/TalkBack.
- **BLOCKIERT:** vollständige gemeinsame GitHub Actions und neue
  Main-/PR-/Dateikonfliktprüfung vor Merge.
- **Parallelität:** #454 enthält disjunkte Fachdateien, berührt aber
  dieselben Dokumentationsdateien. Keine automatische Zusammenführung
  mit dessen älterer README/Checkpoint-Version. Alle anderen aktiven
  Fach-PRs unberührt lassen.
- **Migration:** keine, SQLite-Schema 3 und JSON-Außenformat 1 bleiben
  unverändert; keine App-Version-/Berechtigungsänderung.
- **Nächster konkreter Schritt:** CI auf dem Integrations-HEAD
  vollständig abnehmen; danach PR-Rebase/Integration mit geprüften
  gemeinsamen Dokumentationsinhalten koordinieren, keine Altbranches
  ohne Archivsicherung löschen.

---

# CHAT D – D-029: sieben geprüfte Pakete gemeinsam integrieren (02.11.2026)

- **Main-Basis:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Integrationsbranch:** `chore/chat-d/integrate-verified-ad-and-zip-guards-20261102`.
- **Quell-Integrationen:** #454 (A/B/C/D #446–#449;
  Head `6e55749aebdc5dbf8324ef6865d07973f5d5d52e`;
  CI #41244568578 erfolgreich);
  #466 (D #451/#460/#462;
  Head `1698fb37fac0696a5bde572959dd6f7ff3c3dd14`;
  CI #41323233143 erfolgreich).
- **IMPLEMENTIERT:** Disjunkte Fachdateien und zugehörige Tests
  der beiden vollständigen Vorintegrationen ohne jede neue
  Fachcodeänderung zusammengeführt. Original-Blob-SHAs
  unverändert übernommen, Quell-Commits als Eltern in der
  Integrationshistorie bewahrt.
- **Dateien:** 18 nicht gemeinsame Originaldateien einschließlich
  Fachcode, Tests und A/B/C-Checkpoints; dazu README,
  docs/CODEX_CHECKPOINT.md, docs/parallel/CHAT_D_CHECKPOINT.md
  mit vollständig erhaltenen Originalabschnitten beider Quellen
  und neuem Abnahmestatus.
- **GETESTET:** beide Vorintegrationen mit vollständiger GitHub-
  CI auf ihren endgültigen Head-SHAs; disjunkte Fachdateien,
  vollständige Quell-Blob-SHAs und Dokumentationshistorie geprüft.
- **NICHT GETESTET:** neue gemeinsame GitHub-CI dieses Branchs
  auf dem finalen Integrations-HEAD; keine reale Geräte-/SAF-
  oder TalkBack-Abnahme.
- **BLOCKIERT:** Abschluss der vollständigen kombinierten
  Python-/Backend-/Flutter-/Android-/APK-CI und Kontrolle neuer
  Main-/PR-Änderungen vor Integration.
- **Parallelität:** neue A-/B-/C-PRs wurden auf Fachpfade geprüft.
  Gleiche README-/CODEX-Dateien additiv zusammengeführt; andere
  parallele fachliche PRs und ihre Branches nicht verändert.
- **Migrationen:** keine zusätzlichen Änderungen an Datenbank,
  JSON-/Spielstandsformat, Versionsnummer und Android-Berechtigungen.
- **Nächster konkreter Schritt:** vollständige CI des neuen
  Gesamtintegrations-PRs auf finalem HEAD abnehmen und
  aktuellen PR-/Main-Stand erneut prüfen, bevor Merge/Altbranch-
  Bereinigung überhaupt erwogen wird.

---

# CHAT D – D-030: Unix-Member-Typen im Gradle-Wrapper-JAR absichern (02.11.2026)

- **Ausgangs-main-SHA:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`.
- **Eigener Branch:** `fix/chat-d/wrapper-jar-member-types-20261102`.
- **Code-Commit:** `778873d148e5170482b721a3f93b11ce93bcb41c`.
- **Test-Commit:** `b150cbb701912a616c3db497c128981768dd5e51`.
- **Problem:** Der Gradle-Wrapper-JAR-Prüfer vertraute
  nach korrekten ZIP-Namen, Symlinkschutz und CRC auf
  Eintragsinhalte; als Unix-FIFO/Gerät/Socket getarnte oder
  widersprüchlich Datei-/Verzeichnis-getypte Einträge wurden
  nicht vor dem Entpacken abgelehnt.
- **IMPLEMENTIERT:** In `scripts/verify_project.py` werden Unix-
  `S_IFMT`-Typen und Namens-/Typkonformität geprüft.
  `stat.S_IFREG`, `stat.S_IFDIR` sowie untypisierte Einträge
  bleiben erlaubt, Unix-Symlinks und Sondertypen nicht.
  Bestehender Quellcode unverändert außerhalb der Python-Prüfung.
- **DATEIEN:** `scripts/verify_project.py`,
  `scripts/tests/test_verify_project.py`, `README.md`,
  `docs/CODEX_CHECKPOINT.md` und dieser Checkpoint.
- **REGRESSIONEN:** Vier neue Unit-Testmethoden prüfen vier
  Unix-Spezialtypen, eine als Directory getarnte Startklasse,
  einen regulären Eintrag mit Directory-Pfad und den
  Positivfall mit regulären Unix-Klassendateien und Verzeichnissen.
  Die negativen Fälle sperren `ZipFile.testzip()` per Mock.
- **GETESTET:** nur bisheriges main@2e920f2 vollständig CI-grün.
- **NICHT GETESTET:** neuer PR-/finaler Commit, reale Geräteabnahme.
- **BLOCKIERT:** neue GitHub-CI und spätere Integration mit
  aktueller README/CODEX-Dokumentation aller offenen PRs.
- **Migrationen:** Keine. SQLite-/JSON-/Spielstände,
  Appversion, native Android-Rechte und Gradle-Binärdatei unverändert.
- **Koordination:** Bei Arbeitsbeginn alle 19 offenen PRs auf
  die beiden betroffenen technischen Pfade geprüft;
  keine Überschneidung. Andere Branches nicht verändert.
- **Nächster Schritt:** PR veröffentlichen, finalen HEAD testen,
  nach kompletter grüner CI zur Review freigeben.


---

# CHAT D – D-030: Casefold-/NFC-Kollisionen in Alpha-APKs (02.11.2026)

- **Basis-Main-SHA:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`.
- **Main-CI:** #41395163971 und #41396647217 erfolgreich.
- **Branch:** `fix/chat-d/apk-unicode-path-collisions-20261102`.
- **Pull Request:** https://github.com/ManuEtt/Dnd/pull/476 (Draft bis final-grüner CI).
- **Code-Commit:** `dc2055bfb4cad572b822672dd4f6dadd6bc3b3b3`.
- **Test-Commit:** `9de29379de5114cf6c1519e41123d60001853ab8`.
- **Problem:** Die Alpha-APK-ZIP-Prüfung lehnte exakte Duplikate
  und Unicode-Kontrollzeichen bereits ab, ließ aber zwei durch
  Unicode-NFC oder Casefold gleichwertige Eintrags-/Pfadpräfixe
  zu. Unterschiedliche ZIP-Schreibweisen könnten auf manchen
  Dateisystemen dieselbe extrahierte Ressource bezeichnen.
- **IMPLEMENTIERT:** `scripts/prepare_alpha_release.py`
  führt eine `canonical_prefixes`-Prüfung vor `testzip()` aus
  und weist Pfadkollisionen ohne Umbenennung ab.
- **Geänderte Fachdateien:** `scripts/prepare_alpha_release.py`,
  `scripts/tests/test_prepare_alpha_release.py`.
- **Tests:** Casefold-Kollisionen einschließlich `straße/strasse`,
  Unicode-NFC (`café/cafe + kombinierender Akzent`),
  ungleich geschriebene implizite Verzeichnisse, gültige
  internationale Namen sowie frühere Release-Dateien bei Fehler.
- **GETESTET:** erfolgreiche Baseline-Main-CI auf Ausgangs-Commit.
  Keine finale Branch-CI dieser Implementierung als bestanden behaupten.
- **NICHT GETESTET:** Python-Gesamtsuite, Flutter, native Android-Tests,
  APK-Build, realer SAF-/TalkBack-Gerätetest auf finalem Branch-SHA.
- **BLOCKIERT:** vollständige PR-CI und noch ausstehender erneuter
  PR-/Konfliktvergleich vor Integrationsfreigabe.
- **Koordination:** 19 offene PRs #450–#474 vor Bearbeitung geprüft;
  keine Änderung der technischen Python-Zieldateien. Gemeinsame
  README/CODEX-Ergänzungen nur additiv mergen.
- **Migration:** keine; unveränderte SQLite-/JSON-/Spielstände,
  App-Version, Android-Berechtigungen, Regel- und Storymodule.
- **Nächster konkreter Schritt:** finalen PR-HEAD und GitHub-Actions
  kontrollieren; bei Defekt denselben Branch korrigieren und
  vor Merge erneut Main-/PR-Stand abgleichen.

---

# CHAT D – D-031: gemeinsame Gradle-/APK-Sicherheitsintegration (02.11.2026)

- **Ausgangs-main-SHA:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`,
  CI #41395163971 und #41396647217 erfolgreich.
- **Neuer Branch:** `chore/chat-d/integrate-apk-wrapper-guards-20261102`.
- **Quell-PR #475:** Head `3c8bc937358c4a95e4fd75094c0e038b5638c379`;
  Unix-Spezialdateitypen und Dateityp/Namen-Widersprüche im
  Gradle-Wrapper-JAR frühzeitig abweisen, vier neue Python-Tests.
- **Quell-PR #476:** Head `cf12727bcaf493f5fb03775b67dbd423bd56618c`;
  Casefold-/NFC-Kollisionen bei APK-ZIP-Datei- und impliziten
  Verzeichnisnamen frühzeitig abweisen, fünf neue Python-Tests.
- **IMPLEMENTIERT:** genau vier fachliche Python-Code-/Test-Blobs
  aus den Quell-PRs 1:1 und beide jeweiligen D-030-/README-/
  CODEX-Nachträge vollständig und additiv übernommen. Die beiden
  historischen D-030-Überschriften bleiben bewusst unverändert;
  dieser neue Abschnitt ordnet sie unter D-031 ein.
- **GETESTET:** bereits positive Python-Paket-/Strukturtests,
  Backend-Tests, Flutter-Analyse und gezielte Flutter-Dialogtests
  auf beiden Quell-Branches.
- **NICHT GETESTET:** vollständige Einzel-CI auf den finalen
  Quell-Commits und neu anzustoßende gemeinsame CI auf dem
  Integrations-HEAD, reale Android-/SAF-/TalkBack-Abnahme.
- **BLOCKIERT:** grüne Endabnahme aller drei finalen CI-Läufe
  und abschließende Dateikonfliktprüfung unmittelbar vor Merge.
- **Parallelität:** Vier Fachdateien ohne Überschneidung; offene
  A/B/C-PRs ändern nur andere Fachmodule, aber teilweise gemeinsame
  README-/CODEX-Checkpoints. Keine fremden PRs oder Branches geändert.
- **Migration:** keine. SQLite-Schema, Kampagnen-JSON, Spielstände,
  App-Version und Berechtigungen bleiben unverändert.
- **Nächster konkreter Schritt:** endgültige CI von #475/#476
  überprüfen, dann Integrations-CI auf finalem HEAD abschließen;
  erst danach Review-Freigabe und erneute Main-/PR-Statusprüfung.

---

# CHAT D – D-032: Gradle-Wrapper-JAR gegen Unicode-Pfadkollisionen absichern (02.11.2026)

- **Ausgangs-main:** `885580202caeafc9787538b6dc1c833b3190a529`.
- **Integration #480:** Erfolgreich gemergt; ursprüngliche Quell- und
  Integrations-CI vollständig grün. Neue Main-CI #41401319969 war
  bei Beginn dieses Folgepakets noch in Arbeit.
- **Branch:** `fix/chat-d/wrapper-jar-unicode-collisions-20261102`.
- **Code-Commit:** `4b3a75daf3c6f2191f9776e98ffdbc2a880b0280`.
- **Test-Commit:** `e86ce230f57d42ffa4c857dfb9842a5a5a5004b7`.
- **Problem:** Die Gradle-Wrapper-JAR-Prüfung sperrte bereits Traversal,
  Unicode-Steuerzeichen, Duplikate, Unix-Spezialtypen und manipulierte
  Wrapper-Startklassen. ZIP-Namen, die nur nach Unicode-NFC/`casefold()`
  kollidieren, konnten aber vor der Weitergabe noch bestehen.
- **IMPLEMENTIERT:** `scripts/verify_project.py` erkennt gleichwertige
  Dateinamen und implizite Verzeichnispräfixe vor `ZipFile.testzip()`.
  Die Originalnamen werden nicht umgeschrieben und das Wrapper-JAR
  weder umgepackt noch verändert.
- **Fünf Regressionstests:** `scripts/tests/test_verify_project.py`
  prüft ASCII-Casefold und ß/ss, NFC-Dateinamen, implizite
  Casefold-/NFC-Verzeichnisse und zulässige voneinander
  unterscheidbare internationale Pfade; in den vier Negativtests
  ist ZIP-Dekomprimierung ausdrücklich verboten.
- **GETESTET:** die vorherige Quell-/Kombinations-CI für #480
  am damals finalen Head vollständig erfolgreich.
- **NICHT GETESTET:** neue Python-Gesamtsuite, Flutter, Android/Gradle,
  Alpha-APK auf endgültigem Arbeits-HEAD; reale Android-Geräteabnahme.
- **BLOCKIERT:** neue vollständige CI auf dem finalen PR-HEAD und
  abschließender konfliktfreier Merge-Abgleich.
- **Parallelität:** alle bei Beginn 22 offenen PRs der anderen Chats
  auf technische Dateikollisionen geprüft; keine gefunden. Später
  neu entstandene PRs erneut prüfen. Gemeinsame README/CODEX-
  Checkpoints nur verlustfrei additiv integrieren.
- **Migration:** keine Datenbank-/JSON-/Save-/Versionsänderung;
  keine Änderung an Spielregeln, Story, UI oder Berechtigungen.
- **Nächster Schritt:** finalen PR-Head und Actions-CI abnehmen,
  bei Fehlern auf diesem Branch korrigieren, ohne andere Branches
  zu überschreiben oder zu löschen.


---

# CHAT D – D-033: Datei-/Verzeichnis-Kollisionen in APK und Wrapper-JAR (02.11.2026)

- **Basis-main:** `982cc1f548a309f8eb54cdb2ea37697267813389`, enthält
  vollständig CI-geprüftes Paket #482. Die neue Main-CI
  #41408485671 lief beim Start des Folgepakets noch.
- **Eigener Branch:** `fix/chat-d/zip-file-directory-conflicts-20261102`.
- **Problem:** ZIPs erlauben einen Eintrag wie `assets` (Datei) und
  gleichzeitig `assets/map.json` oder `assets/` (Verzeichnis).
  Bei Entpacken kann das zu Verzeichnis-/Dateikonflikten und
  unterschiedlichen Resultaten je Dateisystem führen.
- **IMPLEMENTIERT:** In `scripts/prepare_alpha_release.py`
  und `scripts/verify_project.py` erfassen zwei Mengen die
  kanonischen vollständigen Dateipfade und expliziten/impliziten
  Verzeichnispräfixe. Bei Schnittmenge wird schon bei ZIP-Metadaten,
  vor CRC-/Inhaltsprüfung, abgebrochen. Die vorhandene Casefold-/NFC-
  Prüfung bleibt bestehen; die originalen ZIP-Einträge bleiben unverändert.
- **Tests:** vier zusätzliche APK-Regressionen, darunter Reihenfolge,
  explizite Verzeichnisse und unbeschädigtes Vorrelease;
  drei zusätzliche Wrapper-JAR-Regressionen für Reihenfolge,
  explizite Verzeichnisse und reguläre Unterdateien.
  Negative Tests verbieten vorzeitiges `ZipFile.testzip()` per Mock.
- **GETESTET:** Vorpaket #482 vollständig CI-grün vor Merge;
  neues Paket selbst noch nicht final durch GitHub Actions abgenommen.
- **NICHT GETESTET:** vollständige neue Python-/Backend-/Flutter-/Android-
  Build- und Testfolge auf finalem PR-HEAD sowie reales Gerät.
- **BLOCKIERT:** erfolgreiche neue CI und letzte Main-/PR-Dateiprüfung.
- **Koordination:** 28 andere offene PRs ändern keine der vier
  technischen Python-Zieldateien. README/zentralen Checkpoint
  mit parallelen Entwicklungs-Chats verlustfrei additiv halten.
- **Migration:** keine SQLite-, JSON-, Speicherstand-, Versions-,
  Berechtigungs-, Story-, Regel- oder UI-Änderung.
- **Nächster Schritt:** finalen PR veröffentlichen, gesamten GitHub-CI-
  Lauf prüfen; nur erfolgreich abgenommene PRs integrieren,
  Branches bis zur sicheren Bereinigung behalten.

---

# CHAT D – D-034: Vier erfolgreich geprüfte A/B/C-Pakete integrieren (02.11.2026)

- **Basis-main:** `c33448780dfe8b453f7f1db9d28c1396822901a7`.
- **Arbeitsbranch:** `chore/chat-d/integrate-verified-abc-features-20261102`.
- **Vier original CI-grüne Quell-PRs:**
  - #485 Chat A Metamagie-Auswahlbeleg: `62e25c89eaa820f32f9b28cbf639245704850ae4`,
    GitHub CI #41402170368 `completed/success`, 36 Schritte.
  - #487 Chat A Null-TP-Kriechen/-Aufstehen: `964b0b07aab5b43bf5d90616dea483cbdc428d1a`,
    CI #41405378184 `completed/success`, 36 Schritte.
  - #488 Chat C Initiative-IME: `e89cc6250fd4e26467d411e68f8a05850ffb5df0`,
    CI #41405839209 `completed/success`, 36 Schritte.
  - #489 Chat B bestätigte NPC-Beziehungen: `b98ebb7d3310a5b5a3391e9b37266565ec29422b`,
    CI #41404718886 `completed/success`, 36 Schritte.
- **IMPLEMENTIERT:** Zehn fachliche Dart-Code-/Test-Blobs aus den Quell-PRs
  ohne Inhaltsänderung in einen gemeinsamen Integrationsbaum übertragen;
  außerdem neues SRD-Metamagie-Fachdokument.
- **Dokumentationsschutz:** README, CODEX sowie CHAT_A/CHAT_B/CHAT_C
  enthalten jede rein additive Einfügung der jeweiligen Quell-PRs, selbst
  wenn die Quelle sie in der Dokumentmitte eingefügt hat. D-CHECKPOINT
  erhält diesen zusätzlichen Fortschritt. Vorherige Main-Nachträge
  bleiben erhalten.
- **GETESTET:** vier Quell-PRs voll GitHub-CI-grün auf ihren genauen
  Commit-SHAs, keine Assertion über kombinierten Endstand.
- **NICHT GETESTET:** die neue vollständige Integrations-CI, reale
  Android-IME-/TalkBack-/SAF-Gerätetests.
- **BLOCKIERT:** Main-CI #41424171660 der vorgängigen #490-Integration
  beim Start noch in Arbeit und zukünftige Gesamt-CI auf finalem Integrations-HEAD.
- **Parallelität:** #481/#483 enthalten fachlich sich überschneidende
  manuelle Zugfolgedialog-Änderungen; beide ausgeschlossen und kommentiert.
  Andere offene A/B/C-PRs bleiben eigenständig; vor Merge erneut Main und
  offene PR-Dateien prüfen.
- **Migration:** keine durch die Integration, SQLite-/JSON-/Version/
  Android-Berechtigungen unverändert. Die fachliche Begrenzung von #485
  (Auswahlbeleg derzeit nicht im Helden-/SQLite-Modell persistiert) bleibt
  ausdrücklich erhalten.
- **Nächster Schritt:** technischen Baum und Docs auf finalen
  unveränderten Git-Blobs verifizieren, vollständige kombinierte CI
  starten und abnehmen; ohne deren Erfolg kein Merge/Branchlöschen.

---

# CHAT D – D-035: CI-grüne Regeln, UI und Story zusammenführen (02.11.2026)

- **Basis-main:** `01259cbc93810a159c9a0d79d6055572f0bde3f1`, zuvor #493 vollständig CI-grün auf Quell- und Integrations-HEAD gemergt.
- **Branch:** `chore/chat-d/integrate-validated-story-rules-ui-20261102`.
- **Vier getrennte vollständig geprüfte Pakete:**
  - #478 Distant-Touch-Metamagie, finaler Head `98b1931a97fc7f1411cf7899d8167f99d10df4d9`, CIs #41398490052 und #41398483892 grün.
  - #479 barrierefreier Dialog bestätigter Zauberwirkungen, finaler Head `77c9d38857be71e04a9e62c201d5922805c87fc0`, CI #41398989518 grün.
  - #486 kurze bestätigte NPC-Rückblicke, finaler Head `cb5c8dd25471ff7dc5046c04b6067b029180eca6`, CI #41402073724 grün.
  - #491 Zero-Width-Schutz für unbestätigte KI-Geschichten, finaler Head `db84bb72ac2a2f18498697b35406eee3110cc8e7`, CIs #41426189797 und #41426180554 grün.
- **Implementierung:** acht technische Dart-Code-/Test-Git-Blobs aus den vier geprüften Quellen ohne Inhaltsänderung übernommen und das separate Distant-Touch-Fachdokument aus #478 gesichert.
- **Dokumentation:** Die vollständigen rein additiven Quell-Einfügungen in README, CODEX, CHAT_A/B/C bleiben erhalten, zusammen mit allen vorherigen Main- und Chat-D-Nachträgen. Einfügungen aus älteren Basen wurden unverändert in gekennzeichneten Quellenabschnitten nachgetragen.
- **GETESTET:** vier eigenständige PR-CIs auf finalen Heads. **NICHT GETESTET:** kombinierte vollständige CI und reale Android-/TalkBack-/SAF-Abnahme.
- **BLOCKIERT:** vollständiger PR- und Push-CI-Abschluss auf endgültigem Integrations-HEAD, Main-Postmerge-CI nach #493, finale Main-/PR-Konfliktprüfung vor Merge.
- **Parallelität:** alle 23 zum Paketbeginn anderen offenen PRs auf die acht technischen Pfade geprüft, ohne Überschneidung. Die problematisch überlappenden #481/#483 im manuellen Zugfolgedialog bleiben ausdrücklich separat.
- **Fachliche Grenzen:** Metamagie-Auswahlbeleg aus #485 ist weiterhin nicht im Helden-/SQLite-Modell gespeichert. Kein automatisches Cast-Recht ableiten; kein zusätzlicher Schema-, Versions-, Spielstands- oder Berechtigungswechsel durch diese Integration.
- **Nächster Schritt:** neuen Integrationsbaum und Quell-Git-Blobs abgleichen; vollständige kombinierte CI starten und bis `completed/success` auf finalem Head abnehmen; erst danach Review/Merge.

---

## 02.11.2026 – Chat D: Materialinventar- und Kreaturendialog zusätzlich zu #495

- **Stack-Basis:** `4641abccd579ab4cec2acfe7cacd4aefb7d339a8` aus [PR #495](https://github.com/ManuEtt/Dnd/pull/495) mit vier anderen geprüften A/B/C-Paketen.
- **Quellen:** #474 (`10bcd7022e38dfcb737333b7da1c67fc839ff042`, CI 41396373761 erfolgreich), #469 (`87c7fe3b6597407fdb6489c1c29335a00a0ff321`, CI 41393278139 erfolgreich).
- **Originalblobs:** `app/lib/ui/srd_material_inventory_dialog.dart` + Test sowie `app/lib/ui/area_creature_registration_dialog.dart` + Test exakt aus der Quelle.
- **Doku:** README, CODEX und CHAT_C-Checkpoint ausschließlich additiv ergänzt; bestehende Inhalte aus #495 und #493 erhalten.
- **Historie:** sichere Original-Commit-Vorfahren und die vorläufigen Integrationsvarianten #494/#496 werden als Eltern archivierungsfähig gemacht, ohne deren fachliche Änderungen doppelt zu übernehmen.
- **Abnahme:** kombinierte CI dieses Heads, erfolgreicher Merge #495 und erfolgreiche folgende Main-CI erforderlich; keine migrations- oder versionsbezogenen Änderungen, kein Realgerät/TalkBack abgenommen.
- **Nächster Schritt:** nach #495 in main diesen PR abschließend prüfen, mergen und erst nach erfolgreicher Main-CI sichere Branchbereinigung kontrollieren.

---

## 02.11.2026 – Chat D: vier unabhängige, CI-grüne Barrierefreiheitsdialoge

- **Stack-Basis:** `be1be6aac0cd8d2b53e0a1219f43fee2fcb35400`, nach #495 und #497.
- **Quellen:** #465 Zustandsquellen-Dialog (CI 41323668152), #458 Mehrklassen-Dialog (CI 41282153192), #457 Magieinitiierten-Dialog (CI 41248140576) und #455 Hintergrundpaket-Dialog (CI 41246044715), jeweils `completed/success` auf Original-HEAD.
- **Implementiert:** vier exakt geprüfte Flutter-UI-Git-Blobs und vier unveränderte Widgettest-Blobs ohne gemeinsame produktive Fachdateien. README, zentraler und CHAT_C-Checkpoint additiv konsolidiert.
- **Regeln/Speicherung:** keine Domain-, Controller-, SQLite-, JSON-, Schema- oder Appversionsmigration; Dialoge bleiben unverbindlich, bis Anwender bestätigen.
- **Noch offen:** neue kombinierte CI auf diesem Integrations-HEAD und Main-CI nach sequenziellen Merges, tatsächliche Android-Hardware-/TalkBack-Abnahme.
- **Nächster Schritt:** nach Abnahme von #495 und #497 diesen Stack mit erneuter Konfliktprüfung mergen und nach erfolgreicher Main-CI Original-Branch-SHAs als Git-Tags archivieren, nicht vorher löschen.

---

## 02.11.2026 – Chat D: fünf zusätzliche getestete Zauber- und UI-Arbeitspakete

- **Stack-Basis:** `ad9d2e6ebf960dbbb643ec093396b4335afb4ebc`, nach #495, #497 und #498.
- **Quellen:** #472 Raster-Berührungsreichweite (41393551106 erfolgreich), #467 Vorbereitungs-/Austauschregeln (41323611885), #453 Mehrklassen-Slotalias (41244807154), #461 Mehrklassen-Zauberquellen (41282290565), #450 Schildreaktion-Dialog (41244483591). Alle auf dem jeweiligen finalen Quell-HEAD erfolgreich.
- **Fachdateien:** nur die Original-Git-Blobs in fünf getrennten Modulen sowie jeweils eigenständige Testdateien und quellgetreue SRD-Dokumente. Alle bestehenden Modulbasis-Dateien exakt unverändert zur Quellbasis geprüft; neue Dateien vor Integration nicht vorhanden. README/Checkpoints additiv.
- **Historienschutz:** Original-Quell-HEADs zusätzliche Git-Commit-Eltern; keine doppelte Übernahme, keine Force-Pushes, kein direkter Main-Commit.
- **Akzeptanz:** Vollständige kombinierte PR-CI vor jedem Merge, #495/#497/#498 vorher erfolgreich integrieren, Main-CI und danach SHA-gesicherte Branchbereinigung. Keine realen Android-/TalkBack-Tests, keine SQLite-/JSON-Schema-/Versionsmigration in diesem Paket.
- **Nächster Schritt:** nach erfolgreicher kompletter CI auf finalem Head und aller Vorgänger Stacked PR prüfen und mergen; dann noch verbliebene kollidierende PRs getrennt prüfen.

---

## Chat D – sichere Integration Zaubertrigger und NPC-Historie (02.11.2026)

- **Basis-main:** `516bc14e06cb02e7035a6adfb8e2d21e54253184`; **Integrationsbranch:** `chore/chat-d/integrate-trigger-npc-20261102`.
- **Quellen:** [PR #500](https://github.com/ManuEtt/Dnd/pull/500) Head `709b9fa8fa60a908ab8dcc2acda6a7a840cfa155` (vollständige Quell-CI erfolgreich) und [PR #501](https://github.com/ManuEtt/Dnd/pull/501) Head `c203e4fde2e2bb5c24d04eeac5f8e1de77e832ad` (zwei vollständige Quell-CIs erfolgreich).
- **Änderungen:** Unicode-Formatcodes in Zaubertriggern zurückweisen; revisionsgebundene NPC-Auswahl gegen Änderungen verdeckter eigener Notizen absichern. Beide Fachmodule lagen auf der Integrationsbasis auf den exakt gleichen Git-Blobs wie auf der geprüften Quelle `84437e4e`.
- **Regressionen:** Original-Code- und Testblobs der beiden finalen Heads unverändert übernommen; keine neuen oder gelöschten Spielstands-/SQLite-/JSON-Schemadaten.
- **Dokumentation:** Originale reine Hinzufügungen aus beiden PRs in README, zentralen CODEX- und individuellen A/B-Checkpoints additiv erhalten. Keine vorherige Main-Dokumentation entfernt.
- **Git-Historie:** Quell-Heads sind zusätzliche Eltern des Integrationscommits; keine Fremdbranches überschrieben oder gelöscht.
- **Freigabe:** Neue vollständige kombinierte GitHub-Actions-CI auf dem exakten Integrations-HEAD und neue Main-CI nach Merge noch erforderlich. Keine Realgerät-/TalkBack-/Altversions-Upgrade-Abnahme.

**Nächster Schritt:** Nach vollständig grüner kombinierter CI und aktuellem Main-/PR-Konfliktabgleich regulären Merge durchführen; danach Main-CI abnehmen.

---

## Chat D – zwei CI-grüne Android-Dialogpakete ohne Fachkollision (02.11.2026)

- **Stack-Basis:** PR #507, Commit `15dbf85f531b23102b4f055f116cb0832ba4ec0b`. Dies ist ein gestapelter Integrationsschritt, der erst nach #507 und grüner Main-CI gemergt werden darf.
- **Quellen:** [#492](https://github.com/ManuEtt/Dnd/pull/492) Head `104ad73947c439f96d19bcd8f738813e23041763` (zwei finale vollständige CI-Läufe erfolgreich); [#503](https://github.com/ManuEtt/Dnd/pull/503) Head `8ded6d3afc74a1d5cd6914956c8ed022c58a5d24` (zwei finale vollständige CI-Läufe erfolgreich).
- **Übernommen:** Zusatzkreaturenangriffs- und Sending-Dialog bei 200 % Schrift und geöffneter Android-Tastatur bedienen; Tests und produktive UI-Blobs exakt von den originalen finalen Heads übernommen.
- **Konfliktprüfung:** Beide produktiven UI-Blobs der Stack-Basis entsprechen exakt den ursprünglichen Quell-Basisblobs; keine Überschneidung der Fach-/Testdateien mit #507 oder untereinander. Gemeinsame README-/CODEX-/CHAT_C-Checkpoint-Diffs waren ausschließlich Einfügungen und wurden additiv erhalten; alte Dokumentation nicht gelöscht.
- **Historie:** Quell-HEADs als zusätzliche Git-Eltern des Integrationscommits bewahrt. Keine Domain-/Regel-/Spielstands-/SQLite-/JSON-/Versionsänderung. Kein Force-Push, keine Fremdbranchlöschung.
- **Offen:** Vollständige neue kombinierte PR-CI auf dem exakt finalen Integrations-HEAD, Vorgänger- und Main-CI, danach aktueller Main-/PR-Abgleich und regulärer Merge. Echte TalkBack-/IME-/Altversions-Geräteprüfung separat offen.

**Nächster Schritt:** Vollständige CI dieses Stacks abnehmen und erst nach Merge von #507 mit grüner Main-CI integrieren.


---

## Chat D – Alpha-Release-APK-Quelle ohne symbolische Verknüpfung (02.11.2026)

- **Ausgangs-main:** `a2f22eaceb344aaced12d0ad548b813aa44d544f` (nach der vollständigen Abnahme und Integration von #508).
- **Branch:** `fix/chat-d/alpha-apk-source-symlink-20261102`.
- **Pull Request:** [#514](https://github.com/ManuEtt/Dnd/pull/514), Draft bis finaler CI-Abnahme.
- **Implementierungs- und Regressionstest-Commits:** `15c75c8e137e9bf86538463a89db735fcc399571`, `9085c3a2ad0a7eca90f821f5c965c23f56e7c146`, `a9b1c76c5a4701937e3c56d06785edf02de77e2b` (Schutz des externen APK-Byteinhalts in Regression bestätigt).
- **Problem:** `prepare_release` rief `Path.resolve()` bereits vor der APK-Validierung auf und verdeckte dadurch einen verlinkten Eingabepfad. Eine gültige APK aus einem unerwarteten externen Dateipfad konnte so als Release-Quelle akzeptiert werden.
- **Lösung:** Originalpfad für die Prüfung erhalten; direkte und geerbte Symlinks vor dem Lesen ablehnen, nach der Quell-ZIP-Erzeugung erneut prüfen, ehe ein Release-APK-Ziel kopiert wird. Kein Zugriff auf das Ziel eines erkannten Linkpfads.
- **Geänderte Dateien:** `scripts/prepare_alpha_release.py`, `scripts/tests/test_prepare_alpha_release.py`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_D_CHECKPOINT.md`.
- **Tests:** vier neue Regressionen für gültige direkte APK-Quelle, verlinkte Quelldatei, verlinktes Elternverzeichnis, Quellpfad-Austausch nach Quellarchiv-Staging mit Rollback des Release-Verzeichnisses.
- **GETESTET:** Änderung und Testfälle in GitHub auf eigenem Branch gespeichert. Vollständige GitHub-Actions-Abnahme auf finalem HEAD steht aus.
- **NICHT GETESTET:** vollständige Python-/Backend-/Flutter-/Android-CI auf finalem HEAD und echter Geräte-Release-Installationspfad.
- **Spielstände/Migration:** kein Schema-/Versionswechsel, kein Eingriff in Flutter, Story, SRD oder gespeicherte Kampagnen.
- **Konfliktprüfung:** beim Beginn offene PRs #452–#512 ändern nicht die beiden Python-Fachdateien dieses Arbeitspakets. Gemeinsam genutzte Dokumentation vor Integration additiv bewahren. Keine fremden PRs oder Branches überschreiben.
- **Nächster Schritt:** finale vollständige CI prüfen; bei erfolgreichen Checks Review-Freigabe und spätere konfliktgeprüfte Integration.

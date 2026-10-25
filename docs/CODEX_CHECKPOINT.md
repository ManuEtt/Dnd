# CODEX-CHECKPOINT – Würfelraunen

Stand **2026-10-25T13:15:00+01:00 (Europe/Berlin)**. Neuer begrenzter Folgezyklus. Der Checkpoint von PR #170 und davor steht vollständig unter der Trennlinie; der tatsächliche Git- und CI-Stand wurde vor Änderungen erneut geprüft.

## Aktuelle Git-Lage

- **`main`-SHA:** `b60ffe7ff1aae502ea927cb77153b988be33e397`; App-Version aus `app/pubspec.yaml` **0.8.38+88**. Main wurde nicht verändert. Zu Beginn 13 offene PRs #159–#171; #171 konsolidiert bestehende Spiel-/Story-Branches und verändert den ZIP-Exporter nicht.
- Abhängige Basis: [PR #170](https://github.com/ManuEtt/Dnd/pull/170), Branch `fix/case-insensitive-secret-archive-filter-20261025`, HEAD **`daf6bd870b0582864beafe7497a75bd92011335e`**.
- **Neuer Branch:** `fix/atomic-source-archive-publication-20261025`, von exakt `daf6bd8` abgeleitet; **[PR #172](https://github.com/ManuEtt/Dnd/pull/172)** mit Zielbranch von PR #170. Code/Test nach Testkorrektur auf **`a1a8dd9802cd827b34580219c13c6764d9ff502f`**, darauffolgende README-/Changelog-/Status-/Checkpoint-Commits. Finalen HEAD unter [PR #172/commits](https://github.com/ManuEtt/Dnd/pull/172/commits) lesen; nicht behaupten, `main` enthalte schon die Änderungen.
- Letzter vollständig erfolgreicher GitHub-Basisworkflow: **[#40191043877](https://github.com/ManuEtt/Dnd/actions/runs/40191043877)** auf **`daf6bd870b0582864beafe7497a75bd92011335e`**, `completed/success`; letzter Main-Lauf [#40094794864](https://github.com/ManuEtt/Dnd/actions/runs/40094794864) auf `b60ffe7` `success`. Das ist **kein** Erfolgsnachweis für den neuen Code. Branch-PR-CI für [#172](https://github.com/ManuEtt/Dnd/pull/172/checks) am finalen HEAD erneut prüfen.

## IMPLEMENTIERT

- `scripts/package_project.py`: Vorhandene Ausgabearchive werden bei ZIP-Erstellung nicht mehr direkt geöffnet/überschrieben. Erstelle ZIP und Prüfsummendatei temporär im selben Zielverzeichnis, prüfe ZIP mit `testzip()`, berechne SHA256 und publiziere erst dann mit `os.replace`. Bei Ausnahme während der zweiten Ersetzung wird das zuvor gesicherte ZIP wiederhergestellt. Temporäres Verzeichnis wird per Kontextmanager aufgeräumt.
- `scripts/tests/test_package_project.py`: vier neue Regressionen für unversehrtes altes ZIP und alte Prüfsumme bei simuliertem Fehler, keinen halben neuen Export, Rollback bei Fehler der Prüfsummen-Ersetzung und normalen Ersatz beider Dateien. Alte Pakettests und Fallunterscheidungen aus PR #170 erhalten.
- `README.md`, `CHANGELOG.md`, `DEVELOPMENT_STATUS.md` und `docs/CODEX_CHECKPOINT.md` angepasst. Kein neuer SRD-Anforderungseintrag, keine Versionserhöhung, keine Änderungen an Flutter, KI, Story, Backend, SQLite-Schema 2, JSON-Spielständen 1 oder Lizenzen.

## GETESTET

- **Basis**: #170 vollständig grün auf `daf6bd8` in Actions #40191043877.
- **Neuer Code:** GitHub Actions auf `a1a8dd9` hat Projektstruktur-, Paket- und Python-Unit-Tests, Backend-Typprüfung/-Build/-Tests und die Flutter-Analyse sowie gezielte Flutter-Dialogtests erfolgreich abgeschlossen; spätere Schritte des PR-Laufs wurden durch neue Dokumentationscommits unterbrochen. Insbesondere alle neu hinzugefügten Python-Regressionen bei diesem Code-Commit bestanden.
- **Transparente Fehlerhistorie:** Actions [#40191974478](https://github.com/ManuEtt/Dnd/actions/runs/40191974478) auf `c30adee` schlug wegen des falsch escapten Test-Strings für den abschließenden Zeilenumbruch fehl. Fehlersuche aus Job-Log verifiziert. Der Fehler ist in `a1a8dd9` behoben; spätere Python-Prüfung grün.

## NICHT GETESTET

- Vollständige **finale** Android-/Flutter-/Backend-/Python-CI auf dem abschließenden Dokumentations-HEAD von PR #172, neue APK-/Artefakt-Checks und echte Geräteinstallation erst nach spezifischem Workflow-Nachweis. Stromverlust zwischen zwei Dateiersetzungen sowie konkurrierende Exporte sind ausdrücklich nicht abgedeckt; die beiden Dateien sind kein betriebssystemweit atomar ersetzbares Paar.

## BLOCKIERT

- Lokaler Repo-Klon über direkten Git-Zugriff scheitert in dieser Laufzeit mit `Could not resolve host: github.com`; Flutter-/Android-SDK nicht lokal vorhanden. Quelldateien wurden mit GitHub-Berechtigung direkt auf einem isolierten Branch gesichert, die unabhängigen Tests in GitHub Actions gestartet.

## NOCH NICHT IMPLEMENTIERT

- Echtes Crash-Consistent Zwei-Dateien-Commit für Stromausfall und parallele Schreiber. Vollständige SRD-5.2.1-Engine, generelle Mehrspieler-/Story-Funktionalität und produktive Android-Signierung sind weiterhin unabhängig offen.

## Genau ein nächster konkreter Schritt

**Nach vollständig grünem finalem CI-Lauf die Integration von #171 → #170 → #172 anhand der aktuellen Commits prüfen**, den gestapelten PR #172 nach Integration seiner Basis auf den neuen `main`-Stand umstellen und erst nach konfliktfreier Validierung und Review in `main` integrieren. Definition of Done: Main-HEAD und Merge-Basis nach jedem Schritt neu prüfen; keine doppelten Commit-Inhalte, alle ZIP-Schutztests in finaler CI grün, kein ungeprüfter Branch gelöscht und keine Spielstands-/Datenbankänderung. Befehle lokal bzw. CI: `python3 scripts/verify_project.py`, `python3 -m unittest discover -s scripts/tests -v`, `python3 scripts/check_domain_boundaries.py`, `bash scripts/check.sh`, `cd app && flutter build apk --debug`, `cd app/android && ./gradlew :app:testDebugUnitTest --no-daemon`.

Keine neue ZIP-/APK-SHA oder Realgerätetest in dieser Sitzung behauptet; vorhandene GitHub-Artefakte nur nach bestätigter finaler Actions-Abnahme verlinken.

### Änderungsprotokoll

- 25.10.2026: ZIP-Veröffentlichung gegen abgefangene Schreib-/Publikationsfehler abgesichert; vier Tests; Python-Zwischenfehler korrigiert; gestapelter PR #172 erstellt.

---

## Voriger Checkpoint: Sicherheits-PR #170

Stand **2026-10-25T12:56:12+01:00 (Europe/Berlin)**. Dies ist der aktuelle eigenständige Sicherheitszyklus; vorheriger Stand vom 24.10.2026 bleibt unten historisch erhalten.

## Git, Produkt und parallele Arbeit

- Hauptrepository `ManuEtt/Dnd`, `main`-Basis **`b60ffe7ff1aae502ea927cb77153b988be33e397`** (Merge #158). Version aus `app/pubspec.yaml`: **0.8.38+88**.
- Neuer Branch **`fix/case-insensitive-secret-archive-filter-20261025`**, [PR #170](https://github.com/ManuEtt/Dnd/pull/170). Implementierungs- und Test-Commit **`cf75153c583febb0bf0e248d2719d81810bbc167`**, nachfolgende Dokumentations-Commits auf demselben Branch; der tatsächlich letzte HEAD ist auf [PR #170/commits](https://github.com/ManuEtt/Dnd/pull/170/commits) einzusehen.
- Vor Beginn **elf offene PRs #159–#169** geprüft. #164 integriert den Vorschlag von #159–#163, #169 integriert #165/#167/#168; #160/#166 verändern Kampfregeln. Keine dieser Änderungen wird überschrieben oder nach `main` gemergt.
- Letzter vollständig bestätigter **main**-Workflow: [#40094794864](https://github.com/ManuEtt/Dnd/actions/runs/40094794864) für exakt **`b60ffe7`**, `completed/success`. Neue Branch-CI [#40190804413](https://github.com/ManuEtt/Dnd/actions/runs/40190804413) und PR-CI [#40190851746](https://github.com/ManuEtt/Dnd/actions/runs/40190851746) beim Erfassen **in Bearbeitung** auf `cf75153c`. Die Zwischen-Commit-CI #40190774551 war **abgebrochen**, kein grüner Nachweis.

## IMPLEMENTIERT

- `scripts/package_project.py`: schließt Namen und Verzeichnisbestandteile im ZIP-Export per `casefold()` aus; schützt damit vor abweichender Schreibweise von `.env*`, `.npmrc`, geheimen Dateien, Cache-Ordnern und SQLite-`-wal/-shm/-journal`-Dateien. Originalschreibweise der erlaubten Archiveinträge bleibt erhalten.
- `scripts/tests/test_package_project.py`: Regression mit wirklichem ZIP und gefährlichen gemischt geschriebenen Dateinamen; erlaubt harmlose `.ENV.EXAMPLE`-Vorlage und eine Grafik.
- `README.md`, `CHANGELOG.md`, `DEVELOPMENT_STATUS.md`, dieser Checkpoint: Übergabe. Keine SRD-Requirement-ID neu als `tested` markiert: ausschließlich Exportwerkzeug, keine Regeländerung.
- Keine Änderung an GameEngine, KI/Story, Backend, Android, SQLite-Schema 2, Kampagnen-JSON 1, Paketversion oder Lizenzen; keine Migration erforderlich.

## GETESTET

- Unveränderte `main`-Baseline: GitHub-Workflow #40094794864 `completed/success` auf `b60ffe7`. **Nicht** auf diesen neuen Code übertragbar.
- Neue Testfälle sind hinzugefügt, aber bis zum Abschluss eines eigenen erfolgreichen Workflows **noch nicht als bestanden gewertet**.

## NICHT GETESTET

- Finale CI auf dem letzten Dokumentations-HEAD des PR #170, vollständige Python-Suite, Flutter-Analyse/-Tests, Backend, native Android-Tests und Android-APK bis zum tatsächlichen erfolgreichen Lauf.
- Echte Android-Geräteinstallation, Upgrade historischer Spielstände, produktive Signatur.

## BLOCKIERT

- In dieser aktiven Umgebung kein Git-Checkout aus öffentlichem GitHub über lokalen Netzwerkzugriff (`Could not resolve host: github.com`), kein lokales Flutter-/Dart-/Android-SDK. Der GitHub-Connector kann Branch, Dateien, PR und Actions prüfen. CI-Nachweise müssen am jeweiligen Commit vorliegen.

## NOCH NICHT IMPLEMENTIERT

- Atomarer Quell-ZIP-Export bei Schreib- und Komprimierungsabbruch, vollständiges SRD, ausstehende Story-/Kampf-/UI-Funktionen aus den anderen PRs. Diese sind nicht Teil des vorliegenden Export-Sicherheitsfixes.

## Nächster exakt abgegrenzter Schritt

**Quell-ZIP-Erstellung bei Schreibabbruch atomar absichern.** Definition of Done: Ein vorheriger vollständiger ZIP-Export und seine SHA-256-Datei bleiben bei fehlgeschlagener Komprimierung unverändert, temporäre Dateien werden entfernt, bei Erfolg stimmen ZIP-Integrität und SHA-256 weiterhin; Regressionen für simulierte Dateifehler und vorhandene Exporte bestehen. Erst **nach** Abnahme von PR #170 beginnen.

Aktueller Abnahmebefehl für PR #170: `python3 scripts/verify_project.py && python3 -m unittest discover -s scripts/tests -v && python3 scripts/check_domain_boundaries.py && bash scripts/check.sh`; auf GitHub außerdem `flutter build apk --debug` und native Gradle-Tests gemäß Workflow. Keine neue APK/ZIP-Datei in dieser Sitzung erzeugt oder geprüft, keine Artefakt-SHA erfunden. Main nach Review getrennt integrieren.

### Änderungsprotokoll

- 25.10.2026: Sicherheitsfilter um Groß-/Kleinschreibung ergänzt; neue ZIP-Regressionen; PR #170 eröffnet, Actions zunächst laufend.

---

## Historischer Checkpoint vom 24.10.2026

Stand **2026-10-24T12:20:50+00:00**, lokal vollständig abgenommenes Paket. Frühere operative Angaben vollständig in [Historie](history/main_0.8.37_20261024/CODEX_CHECKPOINT.md) erhalten. Vor Wiederaufnahme Live-Git/PR/CI erneut prüfen.

## Git und Produkt

- Produktversion **0.8.38+88**; Branch `fix/sneak-attack-offhand-weapon-20261024`.
- Basis-main **dcb42c5efff40a757994d4f5b5f8e98b2ff128e9**, PR #157 bereits integriert, keine offenen PRs bei der Bestandsaufnahme.
- Main-CI [40092582286](https://github.com/ManuEtt/Dnd/actions/runs/40092582286) auf dcb42c5: **success** zum Dokumentationszeitpunkt. Vorher vollständig grüner Main-Lauf [40084074765](https://github.com/ManuEtt/Dnd/actions/runs/40084074765) auf3b5affd. Kein Nachweis für neue Änderungen.
- Früheres Paket PR #147 seit f99f27ac zusammengeführt; eigener integrierter Code a6a949c in CI40059091439 erfolgreich. Späterer Quellencheckpoint d54f554 mit ZIP/Patch separat erhalten; nicht über neueren Main kopiert.
- Funktionaler Code **aa79ce593790e5763e9125743b0adeab55b581d5**, auf GitHub gesichert. [PR #158](https://github.com/ManuEtt/Dnd/pull/158) offen und gegen Basisdcb42c5 konfliktfrei. Eigene Code-CI40093220106 auf aa79ce5 gestartet; aktuelle finale Checks **live am [PR](https://github.com/ManuEtt/Dnd/pull/158/checks)** prüfen. Abschlussdokumentation verändert keinen ausführbaren Code; der finale Dokumentations-HEAD wird im externen Artefaktmanifest ausgewiesen. Main nicht direkt verändert.

## IMPLEMENTIERT

Hinterhältiger Angriff prüft bei bestehender Nebenhandauflösung `pendingRoll.weaponId` statt der angelegten Hauptwaffe. Der Helper erhält optional `attackingWeaponId`; alte Hauptwaffenaufrufe bleiben gültig. Eindeutiger vorhandener Inventareintrag mit positiver Menge erforderlich. Kein Rückfall auf Hauptwaffe bei explizit ungültiger Referenz.

Beide gemischten Waffenrichtungen, zulässiger Zusatzschaden, Krit/Miss und bestehende einmalige Nutzung pro eigenem Zug sind angebunden. Die bisherige Abenteueraktion und deren Würfel-/Schadensjournal verwenden die Regel direkt; kein neuer Menüpfad. Die Änderung erfindet keinen Vorteil und erweitert weder Kampfstil-/Bonusaktionsvoraussetzungen noch die manuelle Verbündetenbestätigung auf Nebenhand.

Dateien: class_combat_features.dart, game_engine.dart, pubspec.yaml, ein bestehender Helpertest und neue sneak_attack_weapon_context_test.dart, Regelregister und Statusdokumentation. SQLite2 und Kampagnen-JSON1 unverändert; keine Migration. Story/KI/Backend/Berechtigungen unverändert. Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt partial, SRD5.2.1 Rogue/Sneak Attack S.61–62, CC BY4.0.

## GETESTET

- **27** bestehende Domain-/Kampf-/SQLite-/Widgetregressionen einschließlich zusätzlichem Waffenreferenztest erfolgreich.
- **8** neue tatsächliche Kampf-/Speichertests erfolgreich: beide Waffenrichtungen, zulässiger/unzulässiger Krit, Miss, aufgehobener Vorteil, gemeinsame Nutzung und erneute Freigabe im nächsten Zug; JSON-Import/Export, SQLite schließen/öffnen, Controller-Auflösung, Ereignisrekonstruktion und doppelte Auflösung.
- Neue Tests verwenden bereits bestätigten, normal importierten PendingRoll-Vorteil. Sie behaupten keinen neuen Vorteilsauslöser in der Oberfläche.
- Flutter3.35.7/Dart3.9.2, Java17, Node22.14 lokal geprüft. Gezielter Dart-Formatter ohne Änderungen.
- Protokolle: `/workspace/validation/20261024-offhand-existing-regressions.log`, `20261024-weapon-context-tests.log`. Gesamtlauf erfolgreich: **1505 Flutter-, 100 Python-, 31 Backend-Tests**, Typecheck/Build,356 Dateien ohne Formatänderung und Analyse ohne Befund; Backend-Protokolltest eingeschlossen. Log: `20261024-offhand-full-check.log`.
- Android: neue Debug-APK und ARM64-Alpha aus validiertem Quell-ZIP gebaut; **12 native Tests**, 0 Fehler/übersprungen. CRC, aapt-Version/ABIs, Signatur und **474 identische ausführungsrelevante Quelldateien** zwischen ZIP, Buildkopie und Branch geprüft. Version 0.8.38/Build 88, minSdk24/targetSdk36; lokale Debug-Testsignatur, keine Gerätefreigabe.
- Story-/Rules-Importgrenzen erfolgreich; Coverage 1.419 Prüfaufträge, 9 Inventurlücken, keine globale Quote.

## NICHT GETESTET

Echtes Android-Gerät, Altspielstand-Update und produktive Release-Signierung offen. GitHub-Prüfungen sind ein eigener Nachweis; deren aktuellen finalen HEAD und Status unter [PR158/checks](https://github.com/ManuEtt/Dnd/pull/158/checks) lesen. Lokale und GitHub-APKs tragen eigene Archiv-/Signaturdigests. Kein älterer grüner Lauf ist eine Freigabe für ungeprüfte neue Codeänderungen.

## BLOCKIERT

Kein Android-Realgerät und kein produktiver Signaturschlüssel. Lokale SDKs verfügbar; frühere fehlende-SDK-Angaben sind historisch. Bisher keine Fehler in den abgeschlossenen neuen Tests.

## NOCH NICHT IMPLEMENTIERT

Manuelle Verbündetenbestätigung für Nebenhand, neue Vorteilsquellen, allgemeine Positionsverwaltung, Gelegenheitsangriffe und vollständiges SRD. Sending-Dialog samt Slot-/Journalpfad aus Main erhalten; Nachrichtenzustellung/Antwort/8h-Weltuhr weiterhin offen. Kleiner beobachteter Sending-UI-Fall: W100-Feld erscheint auch bei unbestätigter Blockade; separat behandeln.

## Abschluss und nächster Schritt

Lokaler Gesamtcheck, beide APKs und native Tests abgeschlossen. Branch und PR158 gesichert. Abschließendes ZIP/Patch mit `scripts/create_checkpoint.py --output-dir /workspace/artifacts --base dcb42c5efff40a757994d4f5b5f8e98b2ff128e9 --label offhand-waffenpruefung-abschluss` erzeugen bzw. über externen Artefaktindex wiederfinden. Die endgültigen Namen, HEADs und SHA256 stehen im Manifest und SHA256SUMS; ältere Pakete bleiben erhalten.

Build-Quell-ZIP: `Wuerfelraunen_0.8.38+88_20261024T121355251852Z_offhand-waffenpruefung-vor-abnahme_Vollprojekt.zip`, SHA256 **93d18f63ae4542ee7b93b613aac18d31e206c8f6c883127aaecb094ba5cc6f31**,637 Dateien,Code aa79ce5. Neue APKs unter `/workspace/artifacts/0.8.38+88/`: Debug SHA256 `cab6226cb0b71fdbbc1e9ed184e66a67d8c6a80560f5c38c9402f18c0eb59fb5`; ARM64 SHA256 `a0e31900676e923ea3d001df95e1b3bae16016b001507cdeb9c264eb3f96bbd9`. Gesamtprotokoll `Wuerfelraunen_0.8.38+88_Pruefergebnisse.json`, einzelne APK-Prüfungen und SHA-Dateien daneben. Aktuelle Actions-Quell-/APK-Artefakte am PR nach tatsächlicher Erzeugung auswählen. [Importanleitung](ARTIFACT_IMPORT_20261024.md) und [Validierung](VALIDATION_0_8_38_20261024.md).

Genau ein nächstes fachliches Paket: **Verbündetenbestätigung für die tatsächlich angreifende Nebenhandwaffe**. DoD: Finesse/Fernkampf der echten Waffe, an Ziel/Probe gebundene Zustimmung, keine Nutzung vor Treffer, gemeinsame einmalige Zugnutzung, Krit/Miss, stale Revision, JSON/SQLite-Neustart; alte Hauptwaffen unverändert.

Prüfbefehle: `bash scripts/check.sh`, `python3 scripts/check_domain_boundaries.py`, `python3 scripts/srd_coverage.py --json`, `cd app && flutter build apk --debug`, `cd android && bash ./gradlew :app:testDebugUnitTest --no-daemon`. Toolchainpfade dieser Umgebung: `/workspace/validation/TOOLCHAIN.md`. Keine automatische Fortsetzung außerhalb aktiver Sitzung.

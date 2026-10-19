# Checkpoint 19.10.2026 – Nutzerfreigabe Fantasy-Grafiken

Branch `feature/fantasy-portraits-and-ui-20261019` von `main` `2f392e1`. Genehmigte Assets liegen nun in `app/assets/fantasy/` als offline ladbare Base64-WebP-Dateien: `portrait_atlas.webp.b64`, `night_sky.webp.b64`, `ui_icon_atlas.webp.b64`; Flutter-Assetdeklaration ergänzt. Neue `character_portrait_picker.dart`, `fantasy_approved_icons.dart`; bestehende Flutter-Fantasy-Oberflächen mit filigranen Goldverzierungen, Mondkulisse, fester Speicherleiste und Porträtanzeige erweitert. `HeroCharacter` trägt optionale Bildauswahl bzw. klein eingebettete eigene Bilddaten zur Sicherung/JSON-Migration. image_picker 1.1.x ist per Lockfile geprüft.

**Abnahme offen:** aktuelle vollständige Flutter-Tests, statische Analyse, Debug-/Release-APKs, native Android-Tests sowie echte Gerätegalerie. Kein Merge nach `main` ohne Grünstatus. Bestehende D&D-Regeln dürfen nicht beschädigt werden; Bilder haben keinen Regelaffekt. Noch nicht benötigte Branches nicht ohne bestätigte Merge-/Backupsituation löschen.

---

# Integrations-Checkpoint 19.10.2026

Branch `integration/character-creation-20261019` von `main` `b3e1de65`: PR #11 bereits enthalten; Code aus PR #9 konfliktfrei dreifach abgeglichen (vorheriges gemeinsames Git-Base `82f2786b`), ohne neue PR #11-Merkmale zu entfernen. PR #10 wurde fachlich mit PR #11 verglichen: seine einzigartige ASI-Auswahl (+2 oder +1/+1, bestätigte Attribute ≤20, rückwirkende KO-TP) ist in den bestehenden PR-#11-Regel- und UI-Weg integriert, mit `integrated_character_level_up_test.dart` getestet werden. Der konkurrierende zweite Dialog wird nicht übernommen. **Aktuelle gemeinsame CI und Android-Artefakte offen**; weder fertig noch installiert behaupten.

# CI-Verifizierung – RK und Bewegung, 19.10.2026

[Android-Alpha-Workflow 39201449428](https://github.com/ManuEtt/Dnd/actions/runs/39201449428): **SUCCESS** für Code-Commit `2f7ecb1589723075a09197d2f2f70efcae18477b` im Branch `fix/equipment-import-attributes-20261019` (PR #9). Der anfängliche Widgettest-Fehler beruhte darauf, dass ein Eingabefeld nach dem Scrollen nicht mehr im lazily gerenderten ListView montiert war; der Test wurde korrigiert und der **gesamte** Workflow erneut erfolgreich durchlaufen. Backend-, Flutter-, Android-Debug-/Native- und kompakte Alpha-APK-Schritte sind erfolgreich. Gerätetest und Review/Merge in `main` fehlen weiterhin. Keine vollständig implementierte SRD-Gesamtabdeckung behaupten.

---

# Zwischenstand 19.10.2026 – Fehlende RK/Bewegung korrigieren

PR #9, Branch `fix/equipment-import-attributes-20261019` ergänzt jetzt zusätzlich zum bereits CI-geprüften Ausrüstungsimport die Berechnung fehlender Kampfwerte: SRD-Speziesgeschwindigkeit, ungerüstete Grund-RK inkl. Mönch/Barbar, automatisch nach bestätigten Feldern im neuen Charaktereditor und explizit bei alten Figuren. `speedRemainderDecimeters` als optionales Legacy-sicheres JSON-Feld (Goliath/Waldelf 10,5 m) und angepasste Erschöpfungsbewegung; vorhandene manuelle Werte bleiben erhalten.

Neu: `app/lib/domain/srd_starting_combat_values.dart`, `app/test/srd_starting_combat_values_test.dart`, `app/test/ui_starting_combat_values_test.dart`; Änderungen an `models.dart`, `condition_rules.dart`, `character_editor.dart`. **CI-Durchlauf für dieses Inkrement ausstehend**, bisheriger grüner Stand `39199122240` gilt nur für den vorangegangenen Import-Fix. Keine Freigabe oder Merge ohne vollständige Analyse, Tests, APK und reale Geräteabnahme. SRD 5.2.1 bleibt insgesamt unvollständig.

---

# Checkpoint: Ausrüstungsattribute beim Import, 19.10.2026

Branch `fix/equipment-import-attributes-20261019` von `main` `82f2786b`. Parallel existiert PR #8 für die Aufstehen-Regel, hier bewusst nicht vermischt. Diese Änderungen: `app/lib/domain/starting_equipment_import.dart`, `app/lib/domain/models.dart`, `app/lib/ui/character_editor.dart`, `app/test/starting_equipment_import_test.dart`, `app/test/ui_starting_equipment_import_test.dart`. Alte Klassenstartsets bekamen bisher nur Namen und Mengen; nun werden eindeutige Katalog-IDs samt strukturierten Daten geschrieben. Validierte Katalog-ID ohne Stats wird beim Import wiederhergestellt, vorhandene individuelle Daten werden nicht überschrieben. Altgegenstände ohne ID werden erst nach expliziter UI-Vorschau und Bestätigung angereichert. 20 Pfeile werden korrekt als eine 20er-Packung behandelt.

Verifizierte CI: kompletter GitHub-Actions-Lauf [39199122240](https://github.com/ManuEtt/Dnd/actions/runs/39199122240) auf `a8f2f090` erfolgreich (Format, Analyze, Flutter-/Backendtests, Android-Debug-APK, native Tests, APK-Artefakte). Noch erforderlich: Test auf echtem Android-Gerät, Review, Merge/Statusabgleich und weitere SRD-Inkremente. Unbekannte Auswahlgegenstände bleiben bewusst offen. Für den Nutzerwunsch „komplettes D&D-Regelwerk“: nur lizenzierte SRD-5.2.1-Regeln und nachweislich getestete Regel-IDs implementieren, alle sonstigen als TEILWEISE/FEHLT führen; Details in README/Regelmatrix. **Dieser Checkpoint ist keine Freigabe.**

---



---

# Checkpoint 19.10.2026 – Charaktererstellung und Klassenaufstieg

Branch `feature/srd-character-level-up-20261019` ab `main` `cadaf7369f8899f29370fb28dfdc2a92c0ba98aa`. Die zwei offenen SRD-Charakter-/Ausrüstungsstränge aus anderen PRs nicht einfach überschreiben: vor Integration HEAD/PRs und eventuelle Konflikte prüfen.

**Neue Dateien:** `app/lib/domain/srd_class_level_up.dart`, `app/lib/ui/srd_class_level_up_dialog.dart`, `app/lib/domain/srd_character_creation_audit.dart`, `app/test/srd_class_level_up_test.dart`, `app/test/ui_srd_class_level_up_test.dart`, `app/test/srd_character_creation_audit_test.dart`. Geändert: `app/lib/ui/character_editor.dart` sowie README, CHECKPOINT, CHANGELOG, DEVELOPMENT_STATUS, SRD-Matrix.

**Funktion:** Klassenaufstieg der bisherigen 1. und bereits existierenden 2. Klasse (kein automatisches freies Drittklassenmodell) inkl. fixer TP, EP-Prüfung oder ausdrücklich bestätigtem Meilenstein, exakten Zustandsvergleichs vor Übernahme, begrenzter SRD-Unterklassenwahl, tabellarischer Merkmalsvorschau und offen notierter nicht automatisierter Wahl. SRD-Erstellungsprüfung zeigt gefüllte/fehlende/nicht implementierte Felder, ohne Spielstände zu ändern. **Keine pauschale vollständige Klassenregellogik**, insbesondere nicht Feat-/Herkunftstalent-/Zauber-/Unterklassen-Mechaniken.

**Abnahme offen:** Aktueller Branch-HEAD und GitHub Actions auf Format/Analyse/Fluttertest/Backend/APK prüfen, Fehler beheben, auf Android-Gerät testen, erst danach PR-Freigabe. Bei Auftragsfortsetzung wieder hier und in der Regelmatrix beginnen.

---

# Entwicklungscheckpoint 19.10.2026 – Aufstehen / Bewegungsbudget

Branch `feature/prone-stand-movement-20261019`, basiert auf GitHub-`main` `82f2786b17d626dbecbe31e788b2a2201a05e275`; PR #7 ist inzwischen in `main` übernommen. Neue Änderungen bleiben bis zur vollen CI-Abnahme separat.

Implementiert: typisierte Standkosten und Restberechnung in `prone_movement_rules.dart`; `Encounter.movementRemainderDecimeters` als optionales Schema-1-Feld; `GameEngine.standUp`, `GameController.standUp`, deutsche Abenteueraktion und genaue Bewegungsanzeige; Sperre gegen kostenlose Charaktereditor-Korrektur im laufenden Kampf und gegen normales Gehen im Zustand `liegend`. 9 m -> 4,5 m Standkosten; 7,5 m -> 3,6 m nach SRD-Rundung in Fuß. Tests: `app/test/prone_standing_rules_test.dart` und `app/test/prone_standing_storage_test.dart`.

**Nicht als abgeschlossen ausgeben:** neueste GitHub Actions, Android-APK und Gerätetest sowie Kriechen, Positionen, Terrain und Sonderbewegungen. Kein Code im `main` direkt geändert. Nach neuestem Branch-HEAD die CI/Logs prüfen, Fehler beheben und erst dann PR freigeben.

---

# Entwicklungscheckpoint vom 19.10.2026 – Bewusstlos / Liegend

Branch `feature/condition-source-ledger-20261018`, PR [#7](https://github.com/ManuEtt/Dnd/pull/7) gegen `main`. Der letzte bereits erfolgreich durchlaufene vollständige GitHub-Workflow war [39165288268](https://github.com/ManuEtt/Dnd/actions/runs/39165288268) für `c000e78b`. Die **neuen** Änderungen zu Bewusstlos/Liegend müssen separat durch CI und Android-Build abgenommen werden.

Neue Engine-Logik: bestätigte Bewusstlosigkeit hinterlässt Liegend als unabhängige manuelle Folge, selbst bei Heilung, natürlicher Todesrettungs-20 und Entfernung/Ablauf quellgebundener Effekte. Alte JSON-Spielstände verändern sich nicht beim bloßen Einlesen. Eine bestätigte handlungsunfähige Charakterbogenänderung beendet Konzentration. Neue Tests: `app/test/unconscious_prone_test.dart`. Regelmatrix, CHANGELOG und README aktualisiert. Offen: Format, statische Analyse, Flutter-/Backend-Suite, Android-Pakete und reales Gerät; Aufstehen, abgelegte Gegenstände und Fremdzielpositionsregeln weiterhin nicht implementiert.

---

# GitHub-Zwischencheckpoint – Quellgebundene Zustände, PR #7 (18.10.2026)

Branch: `feature/condition-source-ledger-20261018`; Basis `main` bei `2b2618a45158d068a8cf37ab3d133a9b11ca10fb`; Pull Request: https://github.com/ManuEtt/Dnd/pull/7. Vor Merge oder weiterer Arbeit **tatsächlichen Branch-HEAD, Checks und PR-Status neu prüfen**. Keine Änderung direkt auf `main`.

Implementiert auf dem Branch: getrennte manuelle und quellgebundene Zustände, strenge JSON-Validierung, deduplizierte Lesesicht, reine Quell-/Ablaufmutationen, Zugendrand der aktuellen Begegnung, Klassenzustandsheilung, Charakterbogenquellen und Domain-/Widgettests. Regel-ID `EFFECT-SOURCE-DURATION` bleibt **TEILWEISE**; Matrix in `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md`.

CI: Dieser Eintrag ist **kein grüner Prüfbeleg**; endgültige GitHub Actions des PR #7 müssen noch ausgewertet werden. Flutter/Dart-SDK ist in der hier genutzten lokalen Umgebung nicht vorhanden; keine lokalen Testläufe behaupten. Quellcode liegt im GitHub-Featurebranch; ein vollständig geprüftes neues APK-/ZIP-Artefakt erst nach erfolgreichem Workflow nennen.

Nächster Schritt: Format, Analyse, Tests und APK vollständig grün bekommen; anschließend neue Domain-/UI-/SQLite-Tests vollständig grün abnehmen, Gerät testen sowie allgemeine Zeit-/SRD-Effektquellen weiter ausbauen. Keine allgemeinen Echtzeit-/fremden-Zug-Dauern erfinden.

---

# Neuer Entwicklungsstand: 0.8.1+51 – Arescan entkoppelt (18.10.2026)

**Basis:** lokales vollständiges Projekt-ZIP 0.7.9+49 plus erste Etappe der UI-/Itemwert-Darstellung.

Umgesetzt: kein Arescan-Startspielstand/-Button, keine Arescan-Sonderhandlung im Produktivcode, keine Arescan-Datei im `app/assets`-Paket. Bestehende lokale und importierte Spielstände bleiben erhalten. Ältere Arescan-Daten werden ausschließlich in Kompatibilitätstests geladen. Für importierte Nicht-Demo-Kampagnen wurde die Rückfallbehandlung von Mooswacht-Skriptmechaniken abgekoppelt. Neues Versionskennzeichen 0.8.1+51.

**Prüfungen:** Python-Kompatibilitäts-/Paket-Tests und Strukturprüfung lokal; Flutter-/Android-Build noch nachzuholen (SDK hier nicht vorhanden). Alle tatsächlichen Prüfungen im Begleitbericht des Pakets dokumentiert.

**Als Nächstes:** `dart format`, `flutter analyze`, `flutter test` und Android-Build; die von bestehenden Widgettests ausgeführten JSON-Importpfade überprüfen, anschließend weitere UI-/Itemdatenmodell-Arbeiten.

---

# Würfelraunen – geprüfter Checkpoint 0.7.9+49

Stand: 18.10.2026, 06:28 UTC. Entwicklungsbranch: `feature/autonomous-srd-engine-20261016`. Letzter vollständig geprüfter Codecommit: `99b8a7bbed9c07132bf49e5eb78be9cfeb391d71`; danach nur Abschlussdokumentation. Der exakte finale HEAD steht im Dateimanifest und in `git log`.

## Basis und GitHub

Patchbasis dieser Fortsetzung: **c889ab6619fe88bd48a420bc45f12d2751af94f7** (GitHub-main, enthält bereits den bisherigen 0.7.7-Code). Konfliktfrei in den eigenen Branch übernommen; main nicht verändert. Der GitHub-main-Build [39055088686](https://github.com/ManuEtt/Dnd/actions/runs/39055088686) ist erfolgreich. Das ist keine Remote-CI-Abnahme des neuen Codes.

Der erneute Push am 18.10.2026 scheiterte mit HTTP403: `Permission to ManuEtt/Dnd.git denied to ManuEtt.` Kein erfolgreicher Remote-Branch/PR behauptet. Lokal sind geprüfte Commits und vollständige ZIPs/Patches vorhanden. Kein Force-Push, keine automatische Codex-Action, keine Credits/Limit-Zurücksetzung.

## Implementiert und angebunden

1. **0.7.8+48, Commit a2dd0da:** explizites eigenes Zugende ohne Aktion auch bei Handlungsunfähigkeit/stabilen 0 TP; echter UI-Button, SQLite/Ereignis. Kampfrauschablauf vor Gegnerangriff, Ausweichen verliert Wirkung bei Handlungsunfähigkeit/Sichtverlust/Bewegungsrate 0, positive 0,5 m bleiben positiv. Mönch-Selbstwiederherstellung ohne Aktionsbedarf; Gegnererstzug löst keinen eigenen Endrand aus.
2. **0.7.9+49, Commit b0fad28:** Todesrettungen mit Mönch-14-Übungsbonus, Erschöpfung genau einmal und Fokus-/Kämpfer-9-Unbeugsam-Wiederholung. Tatsächliche Klassenstufen, verbindlicher Ersatzwurf, natürliche 1/20 und Ressourcen bei 0 TP. Vorläufigen Fehlschlag erst nach Annehmen/Wiederholen bestätigen, einschließlich drohendem drittem Fehlschlag. Deutsche Auswahl, Neustart, atomare Speicherung und Revisionsschutz integriert. Eine Todesrettung pro eigenem Kampfzug; danach Zugende oder nach natürlicher 20 weiterspielen.
3. **Korrektur 99b8a7b:** extern bestätigter KO und bestätigte handlungsunfähige Charakterzustände beenden Kampfrausch/Ausweichen sofort und dauerhaft. Spätere Heilung reaktiviert keinen alten Kampfrausch. Bestehenden Erschöpfungstest an die jetzt angezeigte Version-1-Anfrage angepasst; alte gespeicherte Modifikator-0-Anfragen bleiben lesbar.

Regelquellen, Code und Grenzen: `docs/DEATH_SAVES_0_7_9.md`, `docs/RULE_COVERAGE.md`, `THIRD_PARTY_NOTICES.md`. Schema 1 bleibt kompatibel: zusätzliche Felder sind optional, ungültige Entscheidungen werden vollständig abgelehnt. Katalogeinträge sind keine umgesetzten Mechaniken; das vollständige SRD ist offen.

## Letzte verifizierte Prüfungen

**692 Flutter-, 31 Backend-, 56 Python- und 12 native Android-/JVM-Tests bestanden; 0 Fehler/Skips.** Flutter einschließlich echtem Node-/Dart-Protokolltest ohne kostenpflichtigen KI-Anbieter. Formatprüfung: 132 Dateien, 0 Änderungen. Analyse ohne Befunde. Backend-Typecheck/Build erfolgreich. Insgesamt 57 neue Fälle seit der übernommenen 0.7.7-Basis; gezielter Korrekturlauf 67/67 einschließlich zehn bestehender Erschöpfungsfälle.

Der erste Gesamtlauf hatte 688 Erfolge und eine veraltete Erwartung für den angezeigten Todesrettungsmodifikator. Korrigiert; erneuter vollständiger Lauf mit 692 Erfolgen. Keine offenen Test-/Analyse-/Buildfehler. Belege und Befehle: `docs/VALIDATION_0_7_9.md`, Logs in `/workspace/validation/0.7.9-*-final.log` bzw. `0.7.9-check-final.log`.

Debug-APK tatsächlich aus dem entpackten, verifizierten Korrektur-ZIP gebaut. 203 Quell-/Test-/Builddateien bytegleich mit aktuellem Code geprüft; danach nur Dokumentation. APK-CRC, aapt-Metadaten und apksigner erfolgreich: **0.7.9+49**, minAPI24/target36, ARM64/ARMv7/x86_64, 142493733 Bytes. APK-SHA256: `0b38dab8d03e001b46a2e925359d729842100b6b6e8053ab862de06a78f34c7b`. Lokale Debug-Testsignatur; keine Store-Freigabe.

**Nicht getestet:** Emulator/reales Gerät, tatsächliche Sprache-/SAF-Interaktion, Updateinstallation auf bestehende APKs, produktiver KI-Anbieter, neue Release-APKs je ABI. Der alte vor der letzten Korrektur gebaute APK-Kandidat bleibt mit `vor-korrektur` im Namen erhalten; final ist `Wuerfelraunen_0.7.9+49_Debug.apk`.

## Reale Artefakte und Import

Ablage außerhalb Repository: **/workspace/artifacts**. Finale Namen: `Wuerfelraunen_0.7.9+49_<UTC>_todesrettung_Vollprojekt.zip`, dazu `_Aenderungen.patch`, `_Dateimanifest.json` und `_SHA256SUMS.txt`. Stabiler ZIP-Alias: `Wuerfelraunen_LATEST_Vollprojekt.zip`. Separate finale APK, APK-Prüfbericht und globale/versionierte Prüfsummen. Exakte reale Dateinamen und finaler HEAD: `/workspace/artifacts/ARTEFAKTE.md`.

ZIP, Manifest und gefiltertes vollständiges Projekt werden byte-/modusgenau verglichen; Binärpatch wird tatsächlich auf sauberer c889ab6-Basis angewendet und gegen alle Quelldateien geprüft. Kein Git-Verzeichnis, SDK, Cache, Geheimnis oder APK im Quell-ZIP. Frühere vollständige 0.7.7-/0.7.8- und vorsorgliche Zwischenstände bleiben erhalten. Workspacepfade sind keine behaupteten externen Uploads.

Importanleitung: **IMPORT_0_7_9_49.md**. ZIP entpacken und Inhalte einschließlich `.github/` in einen neuen Klon auf eigenem Branch übernehmen; ZIP-Upload in GitHub entpackt nichts. Alternativ auf sauberer c889ab6-Basis `git apply --check <patch>` / `git apply <patch>`, prüfen, committen, pushen und PR erstellen. Neuere eigene Änderungen erhalten. Alte Patches dieser Sitzung haben teils die frühere Basis b66354f; nicht verwechseln. Prüfsummen: `sha256sum --ignore-missing -c Wuerfelraunen_0.7.9+49_SHA256SUMS.txt`.

## Offener Umfang und nächste drei Schritte

1. **Quellgebundene Zustände/Dauern implementieren.** `docs/CONDITION_EFFECT_DESIGN.md` ist ausschließlich Entwurf. Zuerst manuelle Zustände von abgeleiteten Quellen trennen, bestehende Mutatoren prüfen und kompatible JSON-Felder/Entfernen/Zugenden samt echten Speicher-/UI-Tests integrieren. Keine pauschalen Zeitgeber ohne bestätigte Weltzeit.
2. Optionale Klassenwiederholung von Konzentrationsrettungen und weitere Reaktionen an denselben bestätigten Entscheidungs-/Ressourcenablauf anschließen. Allgemeine Positions-/Sicht-/Reichweiten-/Gelegenheitsangriffsregeln bleiben teilweise offen.
3. Echte Fremdziele/Gruppenmitglieder, weitere verifizierte SRD-Zauber-, Gegenstands- und Monsterwirkungen ergänzen; volle Klassenstufen/Talente/Spezies/Hintergründe und Geräteabnahme fortsetzen. Keine bloßen Katalogergänzungen als Regelerfolg zählen.

## Exakte Wiederaufnahme

AGENTS.md, `docs/prompts/Wuerfelraunen_Codex_Masterprompt _Autonome_Entwicklung.md` (tatsächlich mit Leerzeichen), CHECKPOINT, DEVELOPMENT_STATUS, RULE_COVERAGE und VALIDATION_0_7_9 lesen. Tatsächlichen `git status`, Branch, HEAD und Remote gegen letztes Manifest prüfen. Neuere Dateien nicht mit älterem ZIP überschreiben. Ausgangscheckpoint vor größeren Änderungen erzeugen.

Werkzeuge hier außerhalb Repository: Flutter 3.35.7/Dart3.9.2 unter `/workspace/toolchains/flutter/bin`, Node22.14.0 unter `/workspace/toolchains/node-v22.14.0-linux-x64/bin`, Java17 unter `/workspace/toolchains/jdk17`, SDK `/workspace/toolchains/android-sdk`, Gradle-Cache `/workspace/toolchains/gradle-cache`. Linux-SQLite: `LD_LIBRARY_PATH=/workspace/toolchains/sqlite/lib`; frische Umgebungen brauchen libsqlite3-dev.

```bash
PATH=/workspace/toolchains/node-v22.14.0-linux-x64/bin:/workspace/toolchains/flutter/bin:$PATH LD_LIBRARY_PATH=/workspace/toolchains/sqlite/lib bash scripts/check.sh
# Android mit JAVA_HOME/SDK/Proxy-CA wie docs/VALIDATION_0_7_9.md und /workspace/validation/TOOLCHAIN.md:
cd app
flutter build apk --debug
cd android
./gradlew :app:testDebugUnitTest --no-daemon
```

Neue Sicherung aus Repositorywurzel: `python3 scripts/create_checkpoint.py --output-dir /workspace/artifacts --base c889ab6619fe88bd48a420bc45f12d2751af94f7 --label <name>`. Vor langen/riskanten Schritten CHECKPOINT aktualisieren und sichern. Bei tatsächlicher Limitwarnung laufenden Schritt konsolidieren statt neue große Arbeit zu starten; automatische Sitzungswiederaufnahme nicht voraussetzen.

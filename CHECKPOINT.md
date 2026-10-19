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

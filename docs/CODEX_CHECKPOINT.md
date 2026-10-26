# Chat D D-009 – sichere Quell-ZIP-Dateilesepfade (26.10.2026)

- **Basis-`main`:** `42d14ad36cc947691f7e5a1e8647a43f5421b86e`; **Branch:** `fix/chat-d/source-zip-symlink-swap-20261026`.
- **IMPLEMENTIERT:** Descriptor-relative POSIX-`O_NOFOLLOW`-Prüfung aller Verzeichniskomponenten und finaler Quelldatei während der ZIP-Erstellung, bestehende Stale-Source-Konsistenzprüfung bleibt erhalten.
- **TESTS:** 3 Symlink-Austausch-Regressionen und Korrektur eines alten `fstat`-Mocks. Erste CI entdeckte fehlendes `st_mode` im Mock; Code-/Testkorrektur veröffentlicht.
- **GETESTET:** bisher nur frühere Python-Teil-CIs und einzelne GitHub-Logs nachgewiesen; finale vollständige CI offen.
- **NICHT GETESTET:** finaler vollständiger Python-/Backend-/Flutter-/Android-CI-/Alpha-Build und Gerät; Windows-Nachschau nicht race-free.
- **BLOCKIERT:** finale CI und späterer Main-Abgleich; zwei offene unabhängige Chat-A/B-PRs #236, #237.
- **MIGRATION:** keine Persistenz-, Regel- oder App-Versionsänderung.
- **NÄCHSTER SCHRITT:** finalen CI-Nachweis auf PR-HEAD abnehmen; konfliktfrei integrieren. [Persönlicher D-009-Checkpoint](parallel/CHAT_D_CHECKPOINT.md).

---

# Chat B – Offline-Mock verwendet strukturierte NPC-Erinnerung (26.10.2026)

- **Basis:** `main` `20098805d8c70cbd361a13862379894c47ef4eb6`, Branch `feat/chat-b/mock-structured-npc-recall-20261026`. Offene PRs #216/#218/#219 vor Implementierung samt Dateipfaden geprüft: keine Überschneidung mit den Fachdateien.
- **IMPLEMENTIERT:** neuer rein lesender Erzähler-Auszug `backend/src/mock_npc_identity_hint.ts`; `mockStoryTurn` bevorzugt IDs und die zuletzt gespeicherte valide NPC-Notiz, fällt auf die bisherigen Legacy-Texte zurück und rät bei Mehrdeutigkeit keine NPC-ID.
- **TESTS GESCHRIEBEN:** neue positive/negative `backend/test/mock-npc-identity-hint.test.ts` mit Fastify-HTTP, Unicode, Legacy-Vertrag, Revision, Fremd-ID und Regel-/Narrationsgrenzen. PR [#222](https://github.com/ManuEtt/Dnd/pull/222); Code-/Testfix-Commit `29263f811ea78aa95d32c0202776286289613251`. Früherer CI-Lauf #40289475911 scheiterte an fehlerhafter *Testeingabe* (120 Emoji statt mehr als 160), Testfix in `29263f8...`. Finale CI-Abnahme nur für den späteren PR-HEAD.
- **KEINE MIGRATION:** unverändertes Fastify-Schema, SQLite, Kampagnen-JSON, Regelwerte und App-Version. Nichts wird vom Mock an bestätigtem Spielzustand geschrieben.
- **NICHT GETESTET:** reales Android, Store-Signierung, produktiver OpenAI-Provider; lokale Flutter/Dart-Ausführung mangels SDK; direkter Container-Checkout mangels GitHub-DNS.
- **NÄCHSTER KONKRETER SCHRITT:** explizite NPC-ID-Auswahl für gleichnamige Figuren durch die Story-UI im eigenen koordinierbaren PR; die Mock-Engine bleibt bis dahin fail-closed.
- **Details:** [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md). Bei Zusammenführung gemeinsam mit Chat D die zentralen Einträge konsolidieren; andere Prüfergebnisse bleiben erhalten.

---

# CODEX-CHECKPOINT – Klassenprüfung für Heilige Flamme

## Ergänzung Chat B (26.10.2026) – strikte NPC-Zeitstempel

Ausgangs-`main` `20098805d8c70cbd361a13862379894c47ef4eb6`, Branch `fix/chat-b/npc-timestamp-validation-20261026`, Implementierungscommit `d7d47523d0b6679c3210ab5a9e86e7c430b2933d`, [PR #220](https://github.com/ManuEtt/Dnd/pull/220). Im Story-Backend wird die stille Normalisierung ungültiger Kalenderdaten in optionalen bestätigten NPC-Identitätsnotizen abgewiesen. Die Änderungen umfassen den Validator und positive/negative Unit-/HTTP-Regressionstests. Bestehende Kampagnen-JSON-Version 1 und SQLite-Version 2 bleiben unverändert; keine Migration. Kein Eingriff in HP, Inventar, Quest- oder Regelzustand.

**GETESTET:** Backend-/Android-CI über PR #220 gestartet, zum Zeitpunkt dieses Nachtrags noch **in progress**, daher keine vollständige grüne Suite nachgewiesen. **NICHT GETESTET:** Backend-Typecheck/-Build/-Tests, Flutter, Python-Gates und APK auf finalem HEAD. **BLOCKIERT:** In dieser Sitzungsumgebung kein Flutter-/Android-SDK und kein vollständiger lokaler Repositorycheckout; CI-Ergebnis abwarten und prüfen. **NOCH NICHT IMPLEMENTIERT:** weitere KI-Erzählfunktionen; nächste isolierte Aufgabe nach Integration: validierte NPC-Revisionskontexte gezielt im kostenlosen Mock erzählerisch nutzen, ohne Statusänderung. [Detailcheckpoint](docs/parallel/CHAT_B_CHECKPOINT.md). Ältere Klassenprüfungs-Abnahme bleibt nachfolgend historisch erhalten.


Stand **2026-10-26T07:26:16+00:00**. Würfelraunen **0.8.41+91**, SQLite **2**, Kampagnen-JSON **1**.

## Git und überprüfbare Quellen

- Ursprungsbasis `575a885bd34ecae2bd173dc183abf88a367a69af`, regulär integriertes Main und finale Patchbasis `0212e99b6222f9fcae0714a2ee09123c3c78347c`. Main in diesem Paket nicht verändert.
- Arbeitskopie `/workspace/Dnd-sacred-flame-20261026`, Branch `fix/sacred-flame-caster-validation-20261026`, [PR #217](https://github.com/ManuEtt/Dnd/pull/217). Code-/Build-HEAD **`7c9441e650a3b809db50f1a2d708d39bddfb39b7`**; anschließende Dokumentationscommits ändern keine Build-Eingaben. Den neuesten Branch-HEAD bei Wiederaufnahme mit `git rev-parse HEAD` feststellen.
- Fachfix `cc0d309`, Main-Merge `a377ba8`. Klassenrechner aus PR #184 inzwischen auch in Main; kein zweiter Rechner. ZIP-Reparaturen aus PR #215 (`340fe91`/`8fd2141`) mit Autorenhistorie als `20afc25`/`14a75fb` übernommen. Geerbter NPC-Lint/Formatfehler in `5edf968` korrigiert; keine temporäre CI-Diagnose übernommen.
- Vollständige [PR-Android-CI #40284760958](https://github.com/ManuEtt/Dnd/actions/runs/40284760958) auf diesem Code-/Build-HEAD erfolgreich, einschließlich Debug-, nativer und drei Alpha-ABI-Builds. Spätere reine Dokumentationsnachträge sind über die [finalen PR-Checks](https://github.com/ManuEtt/Dnd/pull/217/checks) separat nachvollziehbar.
- Bei Bestandsaufnahme Main-Android-CI [#40283858187](https://github.com/ManuEtt/Dnd/actions/runs/40283858187) auf d03 fehlgeschlagen: drei ZIP-Pythontests, alle späteren Gates übersprungen. PR-#215-Läufe #40284284178/#40284279247 danach wegen `prefer_is_empty` rot. Beide Ursachen im aktuellen Code korrigiert. Grüne #40283858195 war ausschließlich eine Eldritch-Teilstrecke.
- Ursprüngliche Main-/PR-#184-Fassungen sowie d03 und cc0d309 unter `docs/history/sacred_flame_before_20261026/` bytegenau mit Commit/SHA256 archiviert. PR #215 wurde danach in Main integriert; anschließend regulär synchronisiert, sämtliche Laufzeit-/Builddateien weiter bytegleich zur abgenommenen Quelle7c9441e. Andere aktive PRs zuletzt #216 (Kampfkarte/große Schrift) und #218 (Gradle-Property-Schlüssel); vor Übernahme neue Köpfe und Checks live lesen, nicht automatisch schließen/löschen.

## IMPLEMENTIERT

Heilige Flamme verwendet den klassenbezogenen Rechner im echten Domain-/GameEngine-/Controllerpfad. Doppelte Klassenaliase, unbekannte Partner und widersprüchliche Klassenstufen werden vor RNG, HP-, Aktions- oder Journaländerung abgelehnt. Bestehende ausdrückliche SG-Bestätigung bleibt Voraussetzung. Gültige Kleriker-Zweitklasse nutzt WIS und Gesamtstufen-Übung. Der deutsche Dialog zeigt bestätigte Werte, sperrt ungültige Profile und scrollt Titel/Inhalt gemeinsam bei kleiner Android-Fläche.

Keine globale Klassen-/Importverschärfung: historische Profile und Ereignisse bleiben lesbar/bearbeitbar. Event, Snapshot und Revision weiterhin in der vorhandenen SQLite-Transaktion. Kein neues Schema, kein Netzwerk-/KI-Aufruf. Requirements `SPELL-ENTRY-SACRED-FLAME` / `RULE-SPELLS-SPELL-SAVE-DC` bleiben **partial**. Quelle SRD5.2.1 S25/S37, Wizards of the Coast LLC, CC BY4.0; `THIRD_PARTY_NOTICES.md` erhalten.

## GETESTET

**Vollständiges `scripts/check.sh` mit Exit0:** 1.703 Flutter-, 141 Python- und 57 Backend-Tests; 389 Dart-Dateien ohne Formatabweichung, Flutter-Analyse ohne Befund, Backend-Typecheck/-Build und Backend-Protokoll-Smoke erfolgreich. 518 Laufzeit-/Buildquelldateien stimmen mit der APK-Quelle überein.

Gezielte Abnahme: 20 Domain-, vier echte SQLite-/Controller- und sieben Widgettests. Sieben neue Domain-Gegenfälle zuerst rot gegen alten Code, nach Korrektur grün. Importierte Alias-/Unknown-Profile bleiben lesbar, erzeugen bei Ablehnung aber keine Würfel, Aktion, HP-, Revisions- oder Journaländerung. Wizard5/Cleric1 mit INT20/WIS12 nutzt SG12 und 2W8. Stale Revision, Wiederholung, Journal/Replay/Neustart und echter SQLite-Event-Insert-Fehler mit vollständigem Rollback geprüft. UI bei 360 dp, 1,8×Schrift und Tastatur.

**Android aus frischer isolierter ZIP-Kopie:** Debug gebaut, zwölf native JVM-Tests ohne Fehler/Skips, ARM64-Alpha gebaut. Version0.8.41/Code91, minSdk24/targetSdk36, CRC, ABIs und `apksigner` geprüft. Beide APKs mit derselben lokalen Debug-Testsignatur; keine produktive Signierung behauptet.

SRD-Register neu gezählt: 1.419 Prüfaufträge (8 tested, 32 partial, 7 missing, 1.372 unverified), 282 Klassenfreischaltungen, neun offene Inventurlücken. Kein vollständiger SRD-Nenner und keine globale Fertigstellungsquote.

## NICHT GETESTET

Echtes Android-Gerät, TalkBack, historisches Geräte-Upgrade, reale Dokumentauswahl, produktive Signierung/Store-Freigabe. Die erste alte Baseline-Gesamtsuite nach Main-Fortschritt gezielt mit SIGTERM/Exit143 abgebrochen; nur der neue kombinierte Lauf zählt als bestanden.

## BLOCKIERT

Kein echtes Gerät/Produktivschlüssel. Flutter3.35.7/Dart3.9.2, Java17, Node22.14 und Android-SDK lokal vorhanden; Tests/Builds deshalb tatsächlich ausgeführt. Kein offener reproduzierbarer Fehler im abgenommenen Paket bekannt.

## Artefakte und Import

Lokal **`/workspace/artifacts/0.8.41+91/`**: vollständige Quell-ZIPs, tatsächlich angewendete Git-Patches, Dateimanifeste, Prüfsummen, Debug-/ARM64-APKs und Test-/Buildberichte. Abschließende Dateinamen/SHA256 und neueste CI im dortigen Artefaktindex sowie im [PR #217](https://github.com/ManuEtt/Dnd/pull/217). ZIPs enthalten keine SDKs, Buildcaches, Geheimnisse oder APKs.

Tatsächliche APK-Quell-ZIP: `Wuerfelraunen_0.8.41+91_20261026T071518295880Z_kombinierter-buildquellstand_Vollprojekt.zip`, SHA256 **`b3d48e90c00cbbac1290c5ee02b2dd7b0654e343319756608b57e1e8158993e6`**, Commit **`7c9441e650a3b809db50f1a2d708d39bddfb39b7`**, 815 Dateien vor Build einschließlich ausführbarer Modi/CRC geprüft. Spätere finale Quellen enthalten zusätzliche Abnahmedokumentation; Laufzeit-/Builddateien bleiben byteidentisch.

- Debug `Wuerfelraunen_0.8.41+91_Debug.apk`,144.196.020Bytes,SHA256 `e3f207e75b0d7a723a1de4a85cf2cc3c9aad74cc35f014cc519eb5feecf92beb`, ARM64/ARMv7/x64.
- Alpha `Wuerfelraunen_0.8.41+91_arm64-v8a_Alpha.apk`,19.925.182Bytes,SHA256 `913c2aafe70ce5164ade4cb93eb85a2790cc97abfaf957ffc0f1aa89b3d9c3e2`, ausschließlich ARM64.

Am einfachsten bestehenden Branch abrufen und PR prüfen. Für Offlineimport: ZIP-Wurzel mit `app/`, `backend/`, `scripts/` und `.github/` in eine eigene Arbeitskopie übernehmen. Alternativ Patch auf `0212e99` mit `git apply --check` und `git apply` anwenden, Tests ausführen, eigenen Branch pushen/PR erstellen. Keine alten Stände ungeprüft über Main schreiben. Frühere uncommittete Worktrees und deren Checkpoints erhalten.

## NOCH NICHT IMPLEMENTIERT / genau ein nächster Schritt

**Feuerpfeil: unbekannte Zauberangriffsmodifikatoren ausdrücklich bestätigen.** Den vorhandenen klassenbezogenen Rechner im tatsächlichen FireBolt-Pfad nutzen; bestehende Magier-/Zauberer-Auswahl, Übung der Gesamtstufe und Erschöpfung genau einmal erhalten. Kein neuer paralleler Klassenrechner.

Definition of Done: fehlende/abgelehnte Bestätigung, ungültige Klassen und Grenzfälle des tatsächlich verwendeten Zauberattributs vor RNG/Zustandsänderung abweisen; bestehende englische/deutsche Aliasprofile laden; SG-/Angriffsvorschau erst nach echter Zustimmung; gültige Mehrklassen-/Erschöpfungskontrolle, Stale Revision, Neustart und SQLite-Rollback testen. Aktuelle Main-/PR-Stände zuerst prüfen, dann kleines eigenes Paket. Fachlich nur die für den gewählten Feuerpfeil-Klassenpfad maßgeblichen Attribute validieren.

```bash
bash scripts/check.sh
python3 scripts/srd_coverage.py --json
cd app
flutter build apk --debug
cd android
bash ./gradlew :app:testDebugUnitTest --no-daemon
```

Logs `/workspace/validation/20261026-sacred-*`, isolierte Buildkopie `/workspace/validation/build-0.8.41`. Keine automatische Weiterarbeit außerhalb einer aktiven Sitzung.

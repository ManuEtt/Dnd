# Würfelraunen – geprüfter Checkpoint 0.7.7+47

- Zeitpunkt: 2026-10-17 UTC; drei fachliche Entwicklungsphasen abgeschlossen.
- Git-Basis: `b66354f3112165d76aa340a2f2ab5705f8019e1a` (GitHub-main beim Start).
- Lokaler Branch: `feature/autonomous-srd-engine-20261016`; Implementierungscode `718d30fe1ca53ca01002fc03e9057229345e63be`. Exakten finalen HEAD aus Dateimanifest bzw. git log lesen (abschließend reine Dokumentation).
- GitHub-Push und verbundene Branch-Erstellung beide HTTP403. Kein Remote-Branch/PR behauptet, main unverändert. Basis-CI38933445408 erfolgreich; neuer Stand lokal vollständig geprüft.
- Primärquelle Repository, kein zusätzliches Projekt-ZIP vorhanden. Master-Prompt hat tatsächlich ein Leerzeichen: `docs/prompts/Wuerfelraunen_Codex_Masterprompt _Autonome_Entwicklung.md`.

## Implementiert und angeschlossen

1. Erschöpfte Angriffs-/Wahrnehmungs-/Fluchtproben über JSON/SQLite/Neustart repariert; 0-TP-Schadensfolgen trotz temporärer TP korrigiert. Backend-Mock mit leerer Journalbeschreibung und OpenAI-Redirectschutz repariert.
2. Gemeinsamer Schaden-/Abwehr-/TP-/Konzentrationsablauf für Gegnerangriffe und bestätigte externe Quellen. Deutsche Effektoberfläche für Schaden/Heilung/tempTP; Quelle, Ziel und Folgen atomar journalisiert. Echte Revisions-/Abbruch-/Neustarttests. Automatische STR/DEX-Fehlschläge, 2024-Betäubt-Bewegung und Versteinert-Schadensresistenz.
3. Wunden heilen und Heilendes Wort als tatsächliche Selbstheilzauber im Abenteuer/Kampf: eigene Klasse/Attribut, 2024-Würfel, höhere/Paktplätze, Komponenten, Lebensdomänenboni; echte TP-/Platz-/Aktionsänderung. Persistenter Platzverbrauch-je-Zug-Schutz für beide Pools, Reset zum nächsten eigenen Zug, kompatible alte Encounter-JSON-Daten. Deutsche Dialoge und UI-/SQLite-Test.
4. Dart-Formatierungsrückstand in eigenem Commit42a7e6c bereinigt; normalen Formatcheck in CI/scripts/check.sh ergänzt. Keine autonome Codex-Action. Android-Wrapper ausführbar.

Fachlicher Umfang/Quellen: docs/CHARACTER_EFFECTS_AND_HEALING.md, docs/RULE_COVERAGE.md, THIRD_PARTY_NOTICES.md. Vollständiges SRD bleibt ausdrücklich offen; Katalogeinträge sind keine Mechaniken.

## Letzte verifizierte Prüfungen

**635 Fluttertests, 31 Backendtests, 56 Pythontests und 12 native Androidtests bestanden; 0 Fehler/Skips.** Flutteranalyse ohne Befunde; Formatcheck127Dateien/0Änderungen. Echter Backendprotokolltest eingeschlossen. Debug-APK aus entpacktem überprüftem Vollprojekt-ZIP erfolgreich gebaut; APK-CRC, aapt-Metadaten und Signatur geprüft. Version0.7.7+47, minAPI24/target36, ARM64/ARMv7/x86_64. Ausführliche Befehle/Belege: docs/VALIDATION_2026_10_17.md.

Keine bekannten Test-/Analyse-/Buildfehler. Offen: reales Gerät, Emulator, Sprache/SAF/Onlinepfade und Kompatibilität zu bestehenden APK-Installationen. Keine reale OpenAI- oder Geräteabnahme behauptet. APK lokal mit Debug-Testschlüssel signiert; keine Store-Freigabe.

## Artefakte und Wiederherstellung

Alle realen Artefakte außerhalb Repository: **/workspace/artifacts**. Vollständige Basis0.7.4+44, Reparatur0.7.5+45 (876f55f) und Effekt0.7.6+46 (76e1ee2) unverändert erhalten. Zusätzlich vorsorgliche Zwischenstände vor einer tatsächlichen Teilagenten-Kontingentwarnung; keine Credits/Limitrücksetzung gekauft. Der letzte geprüfte Effektstand bestand isoliert587 Fluttertests, der jetzige635.

Finales ZIP: `Wuerfelraunen_0.7.7+47_<UTC>_heilzauber_Vollprojekt.zip`; stabiler Alias `Wuerfelraunen_LATEST_Vollprojekt.zip`. Passender vollständiger `_Aenderungen.patch` gegen b66354f, `_Dateimanifest.json` und `_SHA256SUMS.txt`; globales `SHA256SUMS.txt`. Die tatsächlich vergebenen Dateinamen stehen in /workspace/artifacts/ARTEFAKTE.md. ZIP/Manifest/Patch werden byteweise mit dem vollständigen gefilterten Projekt verglichen; Patch wird auf sauberer Basis tatsächlich angewendet. Keine SDKs, Geheimnisse, Buildcaches oder APKs im Quell-ZIP.

Separate APK: `/workspace/artifacts/Wuerfelraunen_0.7.7+47_Debug.apk` (142474157Bytes), .apk.sha256 und APK_Pruefung.json. APK-SHA256: bdf389221c6228be9c1a6d87ab106ca3ee9fa748295a791d3e5059bd95f003b1. Quellenhashes des gebauten ZIPs mit aktuellem Code verglichen; danach nur Dokumentation verändert.

GitHub-Import: IMPORT_0_7_7_47.md. ZIP lokal entpacken und Inhalte einschließlich .github/ in einen Klon auf eigenem Branch übernehmen; GitHub entpackt eine hochgeladene ZIP-Datei nicht automatisch. Alternativ neuen sauberen Branch auf b66354f anlegen, `git apply --check <patch>` und `git apply <patch>`, prüfen/committen/pushen. Neuere eigene Dateien nicht blind ersetzen, kein Force-Push. `sha256sum --ignore-missing -c SHA256SUMS.txt` prüft heruntergeladene Dateien.

## Nächste drei Aufgaben

1. Quellgebundene Zustände und Dauern als validierte Effekte samt Ende-/Entfernungsregeln implementieren; optionales Klassen-Wiederholen von Konzentrationsrettungen sauber in denselben Ablauf integrieren.
2. Mönch-Todesrettungsübung/-wiederholung, Reaktionen und weitere ausgewählte Klassenmerkmale mit tatsächlichen Zug-/Ressourcenwirkungen fortsetzen. Handlungsunfähige Figuren benötigen auch einen sauberen reinen Zug-beenden-Pfad.
3. Echte Fremdziele/Gruppenmitglieder, weitere verifizierte SRD-Zauber und Monsterfähigkeiten integrieren. Allgemeine Vorbereitung/Talente/Spezies/Hintergründe, volle Klassenstufen, Items, Spielzeit und Gerätetest bleiben offen. Action-Surge-/ursprüngliche-Magieaktions-Reihenfolge ist derzeit konservativ eingeschränkt.

## Exakte Wiederaufnahme

AGENTS.md, Master-Prompt am tatsächlichen Pfad, CHECKPOINT, RULE_COVERAGE und VALIDATION lesen. Tatsächlichen git status/HEAD gegen neuestes Dateimanifest prüfen. Ältere ZIPs nie über neuere Arbeitsstände kopieren. Erst letzte geprüfte Sicherung/Commit laden und Tests prüfen; nicht allein einer Zusammenfassung vertrauen.

Werkzeuge hier außerhalb Repository: /workspace/toolchains/flutter/bin (3.35.7/Dart3.9.2), /workspace/toolchains/node-v22.14.0-linux-x64/bin, /workspace/toolchains/jdk17, /workspace/toolchains/android-sdk. SQLite-Tests: LD_LIBRARY_PATH=/workspace/toolchains/sqlite/lib. Frische Umgebung benötigt libsqlite3-dev. Komplette Prüfung: PATH korrekt setzen und `bash scripts/check.sh`; APK gesondert `cd app && flutter build apk --debug`, native Tests app/android/: `./gradlew :app:testDebugUnitTest --no-daemon`. Lokale Proxy-/CA-Befehle: /workspace/validation/TOOLCHAIN.md, nicht Geheimnisse ausgeben.

Neue Sicherung: `python3 scripts/create_checkpoint.py --output-dir /workspace/artifacts --base b66354f3112165d76aa340a2f2ab5705f8019e1a --label <name>`. Vor neuen großen Änderungen und regelmäßig checkpointieren; mindestens zwei vollständige geprüfte Stände erhalten.

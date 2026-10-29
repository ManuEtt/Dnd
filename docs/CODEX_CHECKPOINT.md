# Codex-Checkpoint – Würfelraunen

## 29.10.2026 – Chat C: Zweireihige Charakter-Schnellnavigation bei 200 % Schrift

**Basis-main:** `1dc8d076786dbfb6a6792b6653bd1457bd7992d9`. **Branch:** `feat/chat-c/character-nav-large-text-20261029`. **IMPLEMENTIERT:** `app/lib/ui/fantasy_character_overview.dart`: fünf feste Aktionen ab mindestens 180 % Textskalierung und weniger als 500 dp Breite auf zwei Reihen verteilt; Aktionsbeschriftungen ohne `FittedBox`-Schrumpfung und mit zweizeiligem Text. Die normale einreihige Navigation und alle Spiel-Callbacks bleiben erhalten. **PR:** [#374](https://github.com/ManuEtt/Dnd/pull/374) (Draft). **FORMATDIAGNOSE:** Erstes Dart-Format-Gate fehlgeschlagen, offizielle [Flutter-Formatter-Diagnose #40820836420](https://github.com/ManuEtt/Dnd/actions/runs/40820836420) grün; drei Abweichungen korrigiert und temporären Workflow entfernt. **TESTS ERGÄNZT:** `app/test/fantasy_character_quick_navigation_large_text_test.dart` für 320/360 dp mit 200 % Schrift, Originalbelegung bei Normaltext und IME-Inset. **GETESTET:** neueste main-Basis, vollständige Masterprompt-Zuständigkeit, konkurrierende PR-Dateien und vorhandene Widgettests via GitHub überprüft. **NICHT GETESTET:** Dart-Format, Analyzer, Widget- und Gesamttests, APK/native und reales TalkBack-Gerät vor Abschluss der GitHub-CI auf finalem PR-HEAD. **BLOCKIERT:** Lokale SDK-Ausführung nicht verfügbar. **NICHT IMPLEMENTIERT:** Domain-/Story-/Regel-/Schemaänderungen, Geräteabnahme. **KOORDINATION:** PR #359 betrifft nur andere Tests, PR #365 Quest-HUD; gemeinsame README-/Checkpoint-Änderungen bei Integration konsolidieren.

**Nächster Schritt:** Formatter und Flutter-CI auf eigenem Branch vollständig auswerten, Abweichungen beheben, dann reale 320-dp-Android-Prüfung bei 200 % Systemschrift und aufgeklappter Tastatur.

---

## Abnahme 28.10.2026 – Charakter-Symbolwahl / Alpha 0.8.47+97

**IMPLEMENTIERT:** Kleriker/Paladin wählen im Klassenpaket A ausdrücklich Amulett,
Emblem oder Reliquiar. Typisierte Gegenstände und Gold werden nach Bestätigung
nur einmal übernommen. Neue Klassenbelege verwenden Version 2; historische
Version 1 bleibt unverändert lesbar, ungeklärt und ohne Nachvergabe. Wiederwahl
desselben Pakets erhält die Auswahl. Abbruch, Fremd-IDs und echte Paketwechsel
sind geprüft. SQLite **3** / äußeres JSON **1** bleiben unverändert, keine Migration.

**GETESTET:** [PR #369](https://github.com/ManuEtt/Dnd/pull/369) regulär integriert;
Produkt-Main `49b98d8aef7ae0e521320628b053c149c849dea0`.
[Finale PR-CI 40756846048](https://github.com/ManuEtt/Dnd/actions/runs/40756846048)
und [Main-CI 40758951956](https://github.com/ManuEtt/Dnd/actions/runs/40758951956)
sind vollständig **erfolgreich**: 2.265 Flutter-, 200 Python- und 72 Backend-Tests,
zusätzlich gezielter 20-Fälle-UI-Lauf; 507 Dart-Dateien unverändert formatiert,
Analyzer/Backend-/Debug-/native-/drei optimierte ABI-/Alpha-/Checkpoint-Schritte
bestanden. Lokal zusätzlich zwölf native App-Tests und die vollständige Suite
auf Produktcode `7ac32b1c` bestanden; finaler PR-Kopf `bfe4e5ab` ändert daran nur
Dokumentation. Main, PR-Kopf und tatsächlicher PR-Checkout `9bf0c017` besitzen
denselben vollständigen Git-Baum `f40b9dcf11093fef2e7331fdfd712537d391cd2b`.

Alle 1.248 heruntergeladenen Quelldateien mit Hash/Modus, Alpha-Quellpaket,
echte Binärpatch-Anwendung auf Basis `37a6142e`, isoliertes Git-Bundle/fsck und
32 historische Köpfe sind unabhängig geprüft. APK-Version/ABI/v2-Testsignatur
geprüft. [Source-ZIP/Patch/Manifest/History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40758951956/artifacts/12847443480) ·
[ARM64-Alpha](https://github.com/ManuEtt/Dnd/actions/runs/40758951956/artifacts/12846529536).

**NICHT GETESTET:** echtes Android-Gerät/TalkBack, Upgrade einer installierten
Altversion und produktive Signatur. Ein zusätzlicher freiwilliger Test aller
Fremdplugin-Unterprojekte scheiterte an ByteBuddy/Jetifier (Klassenmajor 68);
die im CI vorgeschriebenen `:app:testDebugUnitTest --no-daemon` bestehen.
**BLOCKIERT:** kein angeschlossenes Android-Testgerät.
**NOCH NICHT IMPLEMENTIERT:** vollständiger Wizard mit allen Spezies-, Klassen-,
Talent- und Zauberpflichtwahlen; Symbolbesitz bestätigt keine komplette
Fokus-/Zauberwirkung. `EQUIP-CHOICES` bleibt `partial`, SRD-Inventur 1.419/9 offen.

Arbeitsbranch `feat/character-holy-symbol-choice-20261028` ist nach grüner
Main-CI exakt als `archive/merged-20261027/feat/character-holy-symbol-choice-20261028-bfe4e5ab7fba`
archiviert und remote gelöscht; [Cleanup 40761280014](https://github.com/ManuEtt/Dnd/actions/runs/40761280014)
bestand. Elf neue aktive PR-Branches #356–#359/#361–#367 blieben erhalten;
vor jeder Folgeänderung Main/PRs/CI erneut live prüfen.

Dieser anschließende reine Dokumentationsabschluss auf Produkt-Main `49b98d8a`
ändert **keine** App-, Backend-, Skript- oder Workflowdatei und erhöht keine
Version. Seine statischen/Pythonprüfungen werden separat im Dokumentations-PR
geführt. Eine weitere APK oder Produkt-CI für dessen Dokumentationskopf wird
nicht behauptet. Ältere Berichte darunter sind historische Schreibstände.

## Quellen, Speicherung und Wiederherstellung

Regelquelle: SRD 5.2.1 S.36/53/97, CC BY 4.0; THIRD_PARTY_NOTICES.md unverändert.
Fachnachweis: [CHARACTER_HOLY_SYMBOL_CHOICE_20261028.md](CHARACTER_HOLY_SYMBOL_CHOICE_20261028.md).
Code: starting_equipment_import.dart, starting_class_choice.dart, lesender
srd_character_creation_audit.dart, bestehender Klassen-/Charaktereditor.
Keine Regel-/Story-Grenzänderung, keine KI-Kosten, keine Spielstand-Neuberechnung.

| Main-Datei | SHA256 |
| --- | --- |
| Vollprojekt-ZIP | `5c8a2b6e66f156104231ce60d91a3faafa8f3665165dd9b2e3adbfe397fe28ab` |
| Binärpatch | `1bd26a2a785257d8132e51449ed44ef17286309b1a2f2a4e8f163433efeaaa36` |
| ARM64-APK | `63ebe346fd2ea6ed2f631eb63910efc27e78208ecd269dbb6575c8aa6974ae89` |

Lokale Sicherungen: `/workspace/artifacts/character-holy-symbol-20261028/`,
Index `ARTEFAKTE_UND_IMPORT.md`; Logs/Prüfberichte `/workspace/validation/20261028-*`.
ZIP in leeren Ordner entpacken; Patch nur auf seine explizite Basis anwenden.
Das Paket ist bereits in Main enthalten: keinen identischen Patch nochmals
auf Main anwenden. Bundle für eine separate lokale Wiederherstellung verwenden;
vor neuen GitHub-Änderungen aktuellen Main/PR-Zustand und Prüfungen beachten.

## Genau nächster Schritt

Die im Mönch-Paket A ausdrücklich gewählte Werkzeug-/Instrumentausrüstung mit
der erforderlichen Werkzeugübung koppeln. Zuerst amtliches SRD 5.2.1 S.49 prüfen;
vorhandene Auswahl-/Persistenzfunktionen erweitern. Neue versionierte Entscheidung,
bestehende Klassenbelege v1/v2 ohne Pflichtfeldverschärfung bewahren, keine
Nachvergabe. Gültige/ungültige IDs, doppelte Übungen, Abbruch, Retry, stale Revision,
SQLite-Neustart und JSON, 320/360 dp bei 200 %/IME/Semantik testen; anschließend
`bash scripts/check.sh`, Debug/native und finale PR-CI. Kein Hintergrund-Codexjob.

## Dokumentationshistorie

Vorige README und beide Checkpoints bleiben bytegenau mit Git-Blob/SHA256 in
[history/character_symbol_abnahme_20261028/MANIFEST.json](history/character_symbol_abnahme_20261028/MANIFEST.json).
Die frühere Migration aller 28 Altbranches ist abgeschlossen; Bericht/Inventar
[BRANCH_MIGRATION_20261028.md](BRANCH_MIGRATION_20261028.md). Nicht wiederholen.

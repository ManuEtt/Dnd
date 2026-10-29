# Codex-Checkpoint – Würfelraunen

## Chat C – 29.10.2026 – Charakterbogen-Identität bei großer Schrift (PR #388)

**Basis-main:** `fde0ef6ed8b419d6a31c701a03aa05d61994c352` (App 0.8.47+97), **Arbeitsbranch:** `feat/chat-c/sheet-header-large-text-20261029`, **PR:** [#388](https://github.com/ManuEtt/Dnd/pull/388), Draft. Code-/Test-Commit vor Dokumentation: `1e4fdbe970c8f526a1d408e9085b89f9076237d6`. Finaler PR-HEAD und CI nach Dokumentationscommits erneut prüfen.

- **IMPLEMENTIERT:** Bei 320/360 dp und ab 180 % Textskalierung steht der Charaktertext vollständig unter dem Porträt statt mit Ellipse daneben. Standardlayout bleibt erhalten. Keine Änderung an SQLite 3, JSON 1, Appversion, Regeln, Story oder Controller; keine Migration.
- **GETESTET:** Codebestand, Testfixtures, Main-/PR-Überschneidungen und aktuelle GitHub-CI geprüft. Vorherige Main-CI [40867945743](https://github.com/ManuEtt/Dnd/actions/runs/40867945743) vollständig erfolgreich auf `fde0ef6ed8b419d6a31c701a03aa05d61994c352`, **nicht** auf dieser Änderung.
- **NICHT GETESTET:** Neuer Widgettest `app/test/fantasy_character_header_large_text_test.dart`, Flutter-/Backend-/Python-/Android-Prüfungen und reale TalkBack-/Geräteabnahme auf finalem PR-SHA stehen noch aus.
- **BLOCKIERT:** Lokaler Container ohne Flutter/Dart und DNS-Git-Checkout; neue PR-CI entscheidet. Kein Merge vor Abnahme.
- **NOCH NICHT IMPLEMENTIERT:** Manuelle Abnahme von langen realen Charakternamen/Unterklassen am Android-Gerät.
- **Dateien:** Charakterbogen-UI, neuer Test, `docs/parallel/CHAT_C_CHECKPOINT.md`, dieser Checkpoint, README.
- **Nächster Schritt:** Unabhängige Überprüfung der Klassenmerkmal-/Passivwahrnehmungstexte bei 320 dp mit 200 % Schrift; Erfolg bei vollständigen Werten, erreichbaren Aktionen, positiver/negativer Widgetregression.


## Integration 29.10.2026 – Regression bei großer Schrift nachvollziehbar scrollen

Im zusammengeführten Kandidaten wird die zuvor auf PR #379 nachweislich fehlgeschlagene Heldenkarten-Interaktion bei 200 % Schrift korrigiert: Die Tests scrollen ein tatsächlich über den Bildschirm hinausragendes `ListView` mit einer Nutzer-Geste und verlangen anschließend hit-testbare Buttons. Keine Beschriftung verkürzt, kein Test deaktiviert, kein Produkt-/Speicherverhalten geändert. Neue kombinierte CI auf dem Folge-Commit erforderlich.


## Konsolidierter Arbeitsstand – Integrationskandidat vom 29.10.2026

**Noch nicht in `main` integriert.** Die 24 offenen PRs von Chat A/B/C/D sind auf einem separaten technischen Integrationsbaum zusammengetragen; der gemeinsame Flutter-/Python-/Backend-/Android-CI-Lauf steht aus. Einzelne Pull Requests sind Entwürfe und bedürfen einer eigenen fachlichen Freigabe. Aktive Branches vor grüner gemeinsamer Abnahme und SHA-gesicherter Archivierung nicht löschen. [Herkunft, Originalbeschreibungen, HEADs und offene Risiken](parallel/INTEGRATION_20261029.md).


## Chat D – PR #358: Alpha-Release atomar pro Version sperren

**IMPLEMENTIERT:** `scripts/prepare_alpha_release.py` reserviert vor Publikationsbeginn ein atomar erzeugtes Lock-Verzeichnis pro Release-Version. Zweitaufrufe können keine fremden Dateien löschen. Drei positive/negative Regressionen (gleichzeitiger Aufruf, Fehler-Retry, verwaiste Sperre). **GETESTET:** vollständige CI auf dem vorherigen Stand `1d7b1723` bestanden ([Actions 40730971955](https://github.com/ManuEtt/Dnd/actions/runs/40730971955)). **NOCH NICHT GETESTET:** neuer kombinierter Head einschließlich PR #363, parallele Runner-Prozesse und reales Gerät. **BLOCKIERT:** kombinierte CI-Abnahme. **Migration:** keine. **Nächster Schritt:** kombinierte CI prüfen, danach Review/Merge nur bei Erfolg.

## Chat D – PR #363: Historische Checkpoint-Dateien nur aus sicheren Quellen

**IMPLEMENTIERT:** `scripts/create_checkpoint.py` lehnt unsichere Namen, Symlinks und nichtreguläre historische Artefakte vor Erzeugung des Prüfsummenindex ab. Neue Regressionen für Symlink, Zeilenumbruch und falschen ZIP-Typ. Keine Schema-/Versionsmigration. **GETESTET:** vollständige Python-, Backend-, Flutter- und Android-CI auf Vor-Integrations-HEAD `a02e2b9f` vollständig erfolgreich ([GitHub Actions 40730867003](https://github.com/ManuEtt/Dnd/actions/runs/40730867003)). **NOCH NICHT GETESTET:** kombinierter HEAD mit `main` `1dc8d076786d`, Gerätetest; diese Abnahme erfolgt auf dem neuen PR-HEAD. **BEKANNTE GRENZE:** kein racefreier Dateideskriptor beim Hashing. **Nächster Schritt:** kombinierte CI abwarten, erst danach integrieren.

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

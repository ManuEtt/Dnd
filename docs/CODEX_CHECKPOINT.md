# Codex-Checkpoint – Würfelraunen

## Chat B – 30.10.2026: sichere NPC-Identitäten im Erzählergedächtnis (Draft #396)

Auf Basis von main `55fe44475a113943c6310ec16a8ffb481185f4e9` wurde `feat/chat-b/safe-npc-identity-recall-20261030` ohne Überschneidung der Story-Fachdateien mit den zu Beginn offenen PRs angelegt. `app/lib/story/story_memory_engine.dart` zeigt bei gleichen NPC-Namen nur sichere eindeutige gespeicherte IDs mit `[A-Za-z0-9_-]{1,64}`; bei ungeeigneten IDs fehlen deren mehrdeutige NPC-Zeilen und Notizen im Rückblick/Recall, statt ungeprüfte Zeilentrenner zu publizieren. Eindeutige ältere Namen, andere bestätigte NPCs und ursprüngliche JSON-Spielstände bleiben unangetastet. Neuer Vier-Fälle-Test: `app/test/story_memory_unsafe_npc_id_test.dart`, inklusive Grenzwert und Roundtrip. **Nur Tests implementiert, noch keine erfolgreiche CI dieses PRs bestätigt.** Lokales Flutter/Dart nicht verfügbar, Git-Checkout durch DNS blockiert; Gerät/Provider nicht geprüft. Keine Schema- oder Regeländerung. [PR #396](https://github.com/ManuEtt/Dnd/pull/396), [Chat-B-Checkpoint](docs/parallel/CHAT_B_CHECKPOINT.md). README-/Checkpoint-Kollisionen vor Merge durch Chat D additiv konsolidieren.


## Abnahme – Mönch-Werkzeugwahl, Alpha 0.8.48+98

Stand: 29.10.2026, UTC. [PR #390](https://github.com/ManuEtt/Dnd/pull/390)
ist regulär integriert. Geprüfter Produkt-Main:
`4193000fd28154eeb8b0be3497acc722f674c5ab`; getesteter Arbeitskopf
`53e8e72a58dc07bda07cc50a984142465a8cef79`, Branch
`feat/character-monk-tool-proficiency-20261029`, Basis `fde0ef6e`.
Der PR-Checkout `2b211456` und Produkt-Main haben denselben vollständigen
Git-Baum `1f976980975d5a29ac0277c44e1bc7b79d062ab3`.

**IMPLEMENTIERT:** Neue Erstklassen-Mönche wählen ausdrücklich eine von 27
Handwerkszeug-/Instrumentübungen. Paket A liefert dasselbe Werkzeug und 11 GM;
B liefert 50 GM ohne Werkzeug, die Übung bleibt bestehen. Klassenbeleg v3
prüft Quelle und Paketbindung; v1/v2 bleiben unverändert lesbar und ungeklärt.
Keine automatische Nachvergabe, kein zweiter Gold-/Inventargewinn bei Wiederwahl.
Historisch bestätigte Übungen überleben spätere Anzeigenamens-/Inventaränderungen;
Mönch als neue Zweitklasse erteilt keine Erstklassen-Werkzeugübung.

Der Charakterbogen zeigt belegte Übungen und eine explizite Attributs-/Fertigkeits-
Probenvorschau. Einmaliger Übungsbonus, Vorteil bei passender trainierter Fertigkeit,
Zustände/Erschöpfung, Rüstungsnachteil für Geschicklichkeit (Heimlichkeit) und
Werkzeug-Verlässliches-Talent ab Schurke 7 sind berücksichtigt. Die Vorschau führt
keinen Wurf oder Werkzeugvorgang aus. Audit prüft Pflichtwahl/Paketbindung separat.
Die reproduzierte Sperre Mönch→Barbar→Mönch bei bereits übernommenem Paket ist
behoben. SQLite **3** / äußeres JSON **1** unverändert; keine DB-Migration.

**GETESTET:** Lokal `bash scripts/check.sh` auf `53e8e72a` vollständig bestanden:
**2.450 Flutter-, 221 Python-, 72 Backend-Tests**, Format 535 Dateien unverändert,
Analyzer/Backend-Typen/Build/Protokollsmoke erfolgreich. Zusätzlich ARM64-Debug-APK
und zwölf native `:app:testDebugUnitTest`-Fälle ohne Fehler/Skip. Finale
[PR-CI 40920118585](https://github.com/ManuEtt/Dnd/actions/runs/40920118585)
**erfolgreich**: dieselben 2.450/221/72 sowie 20 gezielte UI-Fälle,
Debug-APK/native Tests und alle drei optimierten ABI-APKs/Alpha-/Quellpakete.
Die zusätzliche [Main-CI 40922492508](https://github.com/ManuEtt/Dnd/actions/runs/40922492508)
ist ebenfalls vollständig **erfolgreich** auf `4193000f`; tatsächliche Logs
bestätigen dieselben Zähler und sämtliche Build-/Paket-Schritte.

Gezielte Gegenfälle: alle 27 Werkzeuge mit A/B, alle zwölf historischen Klassen
mit v1/v2, ungültige Quellen/IDs/Paketkonflikte, Doppelübungen, Abbruch/Retry,
JSON/SQLite-Neustart, stale Editor ohne Änderungen aller sechs Tabellen und
320/360 dp bei 200 % Schrift mit Tastatur/Semantik. Der alte rote Vorlauf
[40918212562](https://github.com/ManuEtt/Dnd/actions/runs/40918212562) scheiterte
am erwarteten Audit-Zähler 11 statt jetzt 12 beim Mönch. Er ist repariert und
durch die vollständige grüne Wiederholung ersetzt; kein Test deaktiviert.
Ein früher bewusst beendeter Lauf gilt nicht als bestandene Vollsuite.

Alle **1.286** heruntergeladenen Main- und PR-Quelldateien mit Hash/Modus, Alpha-Quellpaket,
echte Binärpatch-Anwendung auf `fde0ef6e` und isoliertes Bundle/fsck sind geprüft.
ARM64-APK: Version **0.8.48+98**, minSDK24/targetSDK36, v2-Debug-Testsignatur.
[Source-ZIP/Patch/Manifest/History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40922492508/artifacts/12918224840) ·
[ARM64-Alpha](https://github.com/ManuEtt/Dnd/actions/runs/40922492508/artifacts/12918823598).
Quell-ZIP-SHA256: `9070e1754b5d2838121f320a54c8d1fa5d93120b51f4f7bea6f47db51844116a`;
APK-SHA256: `4fdf28d6581dd94d7cbcdc7f00f470b313c249cd52d45c3d1ae454b20ae69c79`.

**NICHT GETESTET:** echtes Android-Gerät/TalkBack, installiertes Altversionsupgrade,
produktive Release-Signatur. **BLOCKIERT:** kein angeschlossenes Testgerät;
kein Code-/GitHub-Zugriffsblocker. **NOCH NICHT IMPLEMENTIERT:** vollständiger
Charakter-Wizard und übrige Spezies-/Klassen-/Talent-/Zauberpflichtwahlen;
ausgeführte Werkzeugaktionen samt Würfel-/Zeit-/Materialtransaktion.
`RULE-EQUIPMENT-TOOLS` / `EQUIP-CHOICES` bleiben `partial`; 1.419 Prüfaufträge
und neun Inventurlücken sind kein globaler SRD-Fertigstellungsprozentsatz.

Der eigene Produktbranch wurde nach grüner Main-CI durch
[Cleanup 40924681196](https://github.com/ManuEtt/Dnd/actions/runs/40924681196)
remote entfernt, exakt als
`archive/merged-20261027/feat/character-monk-tool-proficiency-20261029-53e8e72a58dc`
erhalten; fünf aktive fremde PR-Branches bleiben bestehen.

Amtliches SRD 5.2.1 S.8–9/49/63/83/93–95, CC BY 4.0;
THIRD_PARTY_NOTICES.md erhalten. Regel-/Story-Grenze und KI-Autorität unverändert.
Dieser anschließende Dokumentationsabschluss auf Branch
`docs/monk-tool-abnahme-20261029` ändert keine App-, Backend-, Skript- oder
Workflowdatei und erhöht keine Version. Seine statischen/Python-Prüfungen sind
separat; keine neue APK/Produkt-CI für den reinen Dokumentationskopf behaupten.

**Nächster Schritt:** drei Barden-Instrumentübungen und Paket-A-Instrumentbindung
nach amtlicher SRD-Quellenprüfung ausdrücklich auswählen und persistent belegen.
Neue Entscheidung kompatibel versionieren; v1/v2/v3 weder verschärfen noch mit
vermuteten Übungen anreichern. DoD: gültige/ungültige Instrument-IDs, drei eindeutige
Übungen, Paket A/B, Abbruch/Retry/stale Revision, Alt-JSON/SQLite-Neustart und
320/360 dp bei 200 %/IME/Semantik, danach komplette Prüfkette und finale PR-CI.
Keine automatische Fortsetzung nach Sitzungsende.

## Wiederaufnahme und Sicherung

1. Main, offene PRs und CI erneut live prüfen. Beim Abschluss sind #387–#389
   sowie #391/#392 fremde aktive Pakete; sie wurden nicht übernommen/gelöscht.
   Vorhandene WIP-Worktrees einschließlich Dnd-items bleiben erhalten.
2. AGENTS.md, Fortsetzungsprompt, diesen Checkpoint, README und amtliche Quellen
   lesen; Mönch nicht neu implementieren. Bardenpaket gegen offene PRs abgleichen.
3. `python3 scripts/generate_fantasy_buttons.py`, Projekt-/Grenz-/Coverageprüfer,
   221 Pythonfälle; bei Codeänderung `bash scripts/check.sh`, Debug/native und CI.
4. Alte Schreibstände bytegenau samt Git-Blob/SHA in
   docs/history/monk_tool_acceptance_20261029/ und monk_tool_start_20261029/.
5. Lokale Sicherungen außerhalb des Projekts:
   `/workspace/artifacts/character-monk-tool-20261029/`; Endstand im Unterordner
   `abschluss/`, Index `ARTEFAKTE_UND_IMPORT.md`. Source-ZIP enthält keine APK,
   privaten Spielstände, SDKs oder Schlüssel. Öffentliche Downloadlinks oben.
   Patchbasis ausdrücklich `fde0ef6ed8b419d6a31c701a03aa05d61994c352`; zuerst in
   separatem Branch/Clone `git apply --check <patch>` ausführen, bestehendes Main
   nicht mit ZIP-Dateien überschreiben. Auf integriertem Main keinen Patch erneut
   anwenden. Git-Bundle ermöglicht vollständige Wiederherstellung mit Historie.

Dokumentationsprüfung: 221 Pythonfälle, Projekt-/Grenz-/Registerprüfung erfolgreich.
`git diff --check` außerhalb des bytegenauen historischen Archivs sauber. Die
archivierte Original-CHANGELOG-Zeile 1061 enthält bereits im Quellstand ein
Leerzeichen am Zeilenende; es bleibt für die nachprüfbare Originaltreue erhalten.

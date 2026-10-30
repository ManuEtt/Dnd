# Würfelraunen – Der lebendige Spielleiter

## Chat A – bestätigte Zaubermaterial-IDs ohne Täuschungszeichen (30.10.2026)

Neues isoliertes SRD-5.2.1-Teilpaket `fix/chat-a/spell-material-id-integrity-20261030`:
Inventar-Stapelbelege für verbrauchte und ausdrücklich behaltene kostspielige
Materialien werden bei einem bestätigten Zaubervorgang auf unsichtbare
Unicode-Schreibrichtungszeichen, Steuerzeichen und Zeilentrenner geprüft.
Der Regel-Commit verweigert einen ungültigen Inventarbeleg, statt daraus
eine mehrdeutige Materialzuordnung zu bilden. Zulässige internationale Namen
und IDs bleiben erlaubt. Regressionstests sichern unter anderem `Secret Chest`
bei wiederholten, neu vorgeprüften Zaubern ohne Inventarverbrauch samt JSON-Roundtrip.
Es gibt keine Datenbankmigration, UI-Änderung oder Versionserhöhung; echte
Materialidentität und Geldwert müssen weiterhin separat bestätigt sein.
Vollständige CI-Abnahme für dieses neue Paket zum Einchecken noch ausstehend.

Die separaten Chat-A-PRs [#400](https://github.com/ManuEtt/Dnd/pull/400)
(Komponenten) und [#405](https://github.com/ManuEtt/Dnd/pull/405)
(Reichweiten) haben beide die vollständige Android-/Flutter-GitHub-CI erfolgreich
bestanden ([#41007599214](https://github.com/ManuEtt/Dnd/actions/runs/41007599214),
[#41011249059](https://github.com/ManuEtt/Dnd/actions/runs/41011249059)).
Sie sind noch nicht nach `main` gemergt.



Deutschsprachige Fantasy-Solo-App für Android. Alpha **0.8.48+98**;
vollständige Charaktererstellung und SRD-Regelengine bleiben in Entwicklung.

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

## Funktionen und Grenzen

| Bereich | Vorhanden | Weiter offen |
| --- | --- | --- |
| Charaktere | Attribute/Herkunft, vier Hintergrundpakete, zwölf Klassenstartgrundlagen, Klassenbelege, Talent-Zauberwahl, sichere Speicherung und Symbolwahl | Geführter Gesamtwizard, alle Spezies-/Klassen-/Talent-/Zauberpflichtwahlen |
| Regeln | Getestete Einzelmechaniken für Kampf, Ressourcen, Rasten, Ausrüstung, Klassenaufstieg und Zauber | Gesamte SRD-Automatik, alle Monster-/Zauberwirkungen und Ausnahmen |
| Kampagnen | Solo/Rabenwacht, Journal, Quests, bestätigtes NPC-Gedächtnis, Replay und dauerhafte Sendeaufträge | Keine universell autonome oder öffentliche Mehrspielerspielleitung |
| Android | Fantasy-UI, Schriftanpassung, Backups, geräteabhängige Sprache | Geräte-/TalkBack-Abnahme, produktive Signierung und Store-Veröffentlichung |

Die SRD-Matrix zählt 1.419 Prüfaufträge und neun Inventurlücken; das ist kein
vollständiger SRD-Nenner und kein Fertigstellungsprozentsatz.
[Audit](docs/SRD_5_2_1_COVERAGE_AUDIT.md) · [Charakterstatus](docs/CHARACTER_CREATION_COMPLETE.md).

## Lokal prüfen

Toolchain: Flutter 3.35.7, Dart 3.9.2, Java 17, Node.js 22.14.0 und Android SDK.

```bash
python3 scripts/generate_fantasy_buttons.py
bash scripts/check.sh
(cd app && flutter build apk --debug)
(cd app/android && bash gradlew :app:testDebugUnitTest --no-daemon)
```

Zum Spielen `cd app`, `flutter pub get`, `flutter run`. SQLite-Tests benötigen
libsqlite3. Optionale externe KI bleibt ausdrücklich einzurichten, keine
automatischen Kostenfreigaben. Vor Alpha-Updates Spielstände exportieren;
Testsignatur/APK-Build ersetzen keine echte Geräte- oder Upgradeabnahme.

[Checkpoint](docs/CODEX_CHECKPOINT.md) · [Architektur](ARCHITECTURE.md) ·
[Tests](TESTING.md) · [Änderungen](CHANGELOG.md) ·
[CC-BY-4.0-Namensnennung](THIRD_PARTY_NOTICES.md).
Frühere README-/Checkpoint-Stände bleiben bytegenau mit Git-Blob/SHA256 in
[docs/history/monk_tool_start_20261029/MANIFEST.json](docs/history/monk_tool_start_20261029/MANIFEST.json).

# Würfelraunen – Der lebendige Spielleiter

## 29.10.2026 – Chat C: Heldenidentität bei großer Android-Schrift

Die aktive Heldenkarte zeigt bei schmalen Android-Displays (unter 500 dp) und mindestens 180 % Textskalierung Porträt und vollständige Identitätsdaten untereinander statt lange Helden- oder Kampagnennamen abzuschneiden. Standardtext behält die kompakte Darstellung. Neue Widgettests prüfen 320/360 dp bei 200 %, lesbare Namen, echte Navigation und unveränderte Heldendaten. Keine Änderungen an SRD-Regeln, Kampagnendaten oder Speicherformat. Details: [Chat C](docs/parallel/CHAT_C_CHECKPOINT.md).

## Qualitätsabsicherung – Alpha-Release-Sperre (Chat D, PR #358)

Parallele Alpha-Packaging-Läufe mit derselben App-Version werden vor der Dateiprüfung durch ein exklusives `_Release.lock`-Verzeichnis serialisiert. Bei einem Fehler werden fremde Releases nicht gelöscht; nach normalem Abschluss oder behandelter Ausnahme wird die Sperre freigegeben. Eine verwaiste Sperre blockiert sicherheitshalber die Veröffentlichung. Drei Regressionen; keine Änderung an SQLite, JSON oder Regeln. [Erfolgreiche Vor-Integrations-CI](https://github.com/ManuEtt/Dnd/actions/runs/40730971955); der kombinierte Stand mit PR #363 erhält eine eigene Prüfung.

## Qualitätsabsicherung – Checkpoint-Historie (Chat D, PR #363)

Historische Dateien im Quell-Checkpoint werden vor Aufnahme in `SHA256SUMS.txt` auf sichere Namen und regulären Dateityp geprüft. Vorhandene Symlinks, Zeilenumbrüche oder ZIP-Verzeichnisse werden vor einer Veröffentlichung abgelehnt; drei neue negative Python-Regressionen sichern alte stabile Aliases. [Erfolgreicher CI-Stand auf dem vorigen Commit](https://github.com/ManuEtt/Dnd/actions/runs/40730867003); der jetzt kombinierte `main`-Stand wird separat geprüft. Keine Speicherformatmigration. Die Prüfung ist keine vollständige TOCTOU-Abwehr.

Deutschsprachige Fantasy-Solo-App für Android mit lokalen Charakteren,
Kampagnen, ausgewählten D&D-SRD-5.2.1-Regeln und optionalem KI-Erzähler.
**Alpha 0.8.47+97**; lokales Spielen benötigt keinen Account oder KI-Server.
Charaktererstellung und Regelengine sind noch nicht vollständig.

## Aktueller Stand und autonome Fortsetzung

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

## Genau nächster Schritt

Die im Mönch-Paket A ausdrücklich gewählte Werkzeug-/Instrumentausrüstung mit
der erforderlichen Werkzeugübung koppeln. Zuerst amtliches SRD 5.2.1 S.49 prüfen;
vorhandene Auswahl-/Persistenzfunktionen erweitern. Neue versionierte Entscheidung,
bestehende Klassenbelege v1/v2 ohne Pflichtfeldverschärfung bewahren, keine
Nachvergabe. Gültige/ungültige IDs, doppelte Übungen, Abbruch, Retry, stale Revision,
SQLite-Neustart und JSON, 320/360 dp bei 200 %/IME/Semantik testen; anschließend
`bash scripts/check.sh`, Debug/native und finale PR-CI. Kein Hintergrund-Codexjob.

## Lokal starten und prüfen

Toolchain: Flutter 3.35.7, Dart 3.9.2, Java 17, Node.js 22.14.0, Android SDK.

```bash
python3 scripts/generate_fantasy_buttons.py
cd app
flutter pub get
flutter run
```

```bash
bash scripts/check.sh
(cd app && flutter build apk --debug)
(cd app/android && bash gradlew :app:testDebugUnitTest --no-daemon)
```

SQLite-Tests benötigen die native SQLite-Bibliothek. Die Prüfkette enthält
Projekt-/Importgrenzen-/SRD-/Pythonprüfungen, Backend-Typecheck/Tests/Build,
Dart-Formatierung, Analyse und Fluttertests mit lokalem Backend-Protokolltest.
Ein optionaler eigener HTTPS-Erzähler wird in
[BACKEND_CONNECTION.md](docs/BACKEND_CONNECTION.md) erklärt. Externe KI benötigt
eine ausdrückliche Sitzungseinrichtung; keine automatischen Kostenfreigaben.

## Architektur, Sicherungen und Lizenz

`app/lib/domain/` enthält Regeln/Modelle, `story/` Kampagne/Gedächtnis, `data/`
SQLite, `services/` bestätigende Steuerung und `ui/` Flutter. `backend/` ist der
optionale Fastify-/TypeScript-Erzähler. KI-Texte sind keine bestätigten Würfe,
Charakterwerte oder Gegenstände; mechanische Änderungen prüft die Regelengine.

Vor Alpha-Updates Spielstände exportieren; eine Testsignatur und ein APK-Build
belegen kein Geräteupgrade. [Backups](docs/SAVE_BACKUPS.md) ·
[Android-Artefakte](docs/ALPHA_RELEASES.md) · [Tests](TESTING.md).

Regelquelle: [SRD 5.2.1](https://www.dndbeyond.com/srd), Wizards of the Coast LLC,
CC BY 4.0; [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) erhält die Namensnennung.
Nur lizenzierte Inhalte und eigene Texte verwenden.

[Checkpoint](docs/CODEX_CHECKPOINT.md) · [Entwicklungsstatus](DEVELOPMENT_STATUS.md) ·
[Architektur](ARCHITECTURE.md) · [Änderungen](CHANGELOG.md).
Ältere README-/Checkpoint-Stände sind bytegenau unter
[docs/history/character_symbol_abnahme_20261028/](docs/history/character_symbol_abnahme_20261028/MANIFEST.json)
mit Git-Blob-/SHA256-Nachweisen erhalten.

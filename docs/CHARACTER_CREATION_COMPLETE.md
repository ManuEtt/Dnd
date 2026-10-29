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

---

## Historischer Verlauf – frühere Aussagen gelten für ihren jeweiligen Stand

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

## Genau nächster Schritt

Die im Mönch-Paket A ausdrücklich gewählte Werkzeug-/Instrumentausrüstung mit
der erforderlichen Werkzeugübung koppeln. Zuerst amtliches SRD 5.2.1 S.49 prüfen;
vorhandene Auswahl-/Persistenzfunktionen erweitern. Neue versionierte Entscheidung,
bestehende Klassenbelege v1/v2 ohne Pflichtfeldverschärfung bewahren, keine
Nachvergabe. Gültige/ungültige IDs, doppelte Übungen, Abbruch, Retry, stale Revision,
SQLite-Neustart und JSON, 320/360 dp bei 200 %/IME/Semantik testen; anschließend
`bash scripts/check.sh`, Debug/native und finale PR-CI. Kein Hintergrund-Codexjob.

---

## Aktueller Charakterstand – 28.10.2026, Alpha 0.8.47+97

**IMPLEMENTIERT:** Im Klassenpaket A wählen Kleriker und Paladin ausdrücklich
Amulett, Emblem oder Reliquiar. Typisiertes Inventar und lesender Audit verwenden
die bestätigte Variante. Neue Klassenbelege sind Version 2; historische Version 1
bleibt lesbar, unverändert und ohne Nachvergabe. Goldalternativen enthalten kein
Symbol. Erneute Bestätigung verdoppelt keine Gegenstände oder Gold; die erneute
Auswahl desselben Pakets verliert keine bereits getroffene Symbolentscheidung.
[Regelquelle und Fachnachweis](CHARACTER_HOLY_SYMBOL_CHOICE_20261028.md).

**GETESTET:** Vollständiges `bash scripts/check.sh` auf Produktcode
`7ac32b1cb9e63ce35eb458d87e4b84d86526706a`: **2.265 Flutter-, 200 Python- und
72 Backend-Tests**, 507 Dart-Dateien unverändert formatiert, Analyzer und
Backend-Build erfolgreich. Android-Debug-APK gebaut, Metadaten und v2-Testsignatur
geprüft; **zwölf native App-Tests** gemäß CI bestanden. Gezielt zudem 16
Symbol-Dialog-, 13 Editor- und 16 SQLite-Speicherfälle bestanden, einschließlich
beider Klassen, aller Varianten, alter Belege aller zwölf Klassen, Neustart,
JSON-Import, ungültiger IDs, Retry und veralteter Revision. Widgetabnahme bei
320/360 dp, 200 % Schrift, simulierter Tastatur und Semantik; kein Gerätetest.
Die abschließende Dokumentation ändert gegenüber diesem Code keine Produktdateien.

**NICHT GETESTET:** echtes Android-Gerät/TalkBack, Upgrade einer installierten
Altversion und produktive Signatur. **BLOCKIERT:** kein angeschlossenes Testgerät.
Ein zusätzlicher Aufruf sämtlicher Fremdplugin-Unterprojekttests scheiterte an
ByteBuddy/Jetifier (Java-Klassenmajor 68); das im CI vorgeschriebene
`:app:testDebugUnitTest --no-daemon` besteht mit zwölf Tests. Dieser zusätzliche
Fehllauf wird nicht als bestanden ausgegeben. **NOCH NICHT IMPLEMENTIERT:**
vollständiger Wizard und alle übrigen Pflichtwahlen; Symbolbesitz bestätigt
keine vollständige Fokus-/Zauberwirkungsautomatik. SQLite 3 / äußeres JSON 1
unverändert, keine Migration. `EQUIP-CHOICES` bleibt ausdrücklich `partial`.

Arbeitsbranch `feat/character-holy-symbol-choice-20261028`, Main-Basis
`37a6142ea791a607c78065b50aa66fda90acda5c`, [PR #369](https://github.com/ManuEtt/Dnd/pull/369).
Die zusätzliche vollständige GitHub-Abnahme und tatsächlichen Artefakte sind
anhand des **aktuellen** [PR-Checklaufs](https://github.com/ManuEtt/Dnd/pull/369/checks)
zu beurteilen; der PR-Abnahmebericht hält die konkrete Run-ID und SHA fest.
Der initiale doppelte Pushlauf 40756156487 wurde bewusst beendet; ältere
Zwischenläufe sind keine Abnahme des abschließenden PR-Kopfs.

Nächster kleiner Charakter-Schritt: Mönch-Werkzeugübung ausdrücklich mit der
Paketwahl koppeln, nach SRD S.49. Versionierte Entscheidung, bestehende Belege
v1/v2 bewahren, keine Nachvergabe; Domain-/UI-/SQLite-/Import-/Doppelübungsfälle
und vollständige Prüfkette nachweisen. Gesamte Charaktererstellung bleibt offen.
Ältere Berichte unten sind historische Schreibstände.

---

## 28.10.2026 – Abnahme und aktuelle Main-Integration

Klassenstartpaket 0.8.45+95 in PR #319 gegenMain `a915717` vorbereitet. Produkt `30bb33e`:
CI 40584924719 und lokaler fester Flutter-Repeat grün (1.995 Flutter,164 Python,
72 Backend,12 lokale native Tests). Neuester Integrationsstand:57 gezielte Tests,
finale Gesamt-CI separat imPR. Mönch-PaketA bleibt ohne gekoppelte
Werkzeugübungsquelle ausdrücklich nicht automatisiert. AktuellerCheckpoint
nennt bestehende parallele PRs und den bereits angefangenen Editor-CAS-Branch;
keine Duplikation, keine vollständige Charaktererstellung behauptet.

## 27.10.2026 – 0.8.45+95: bestätigte erste Klassenwahl

Versionierter historischer `startingClassChoice`-Nachweis aus tatsächlicher
Klassenassistent-Bestätigung; typisierte Paket-/Fertigkeits-/Kämpferwahlen,
keine Doppelvergabe und keine Legacy-Neuberechnung. Strenge Importvalidierung,
lesender Quellenabgleich und Korrektur der Mönch-Werkzeugauswahl.
Gesamte Charaktererstellung bleibt unvollständig. Aktuelle Tests, PR und
konkrete Fortsetzung im CODEX_CHECKPOINT und Fachnachweis
`docs/CHARACTER_START_CLASS_CHOICE_20261027.md`; bisherige Abschnitte sind Historie.

## Aktueller Auditstand 27.10.2026 – Teilprüfung

Sieben Prüfzustände und Abgleich tatsächlicher Herkunfts-/Hintergrundbelege
sind im unabhängigen Auditpaket implementiert. Ausgefüllte Felder allein
bestätigen keine SRD-Erstellung. Aktueller Editorentwurf, historische Werte
und read-only SQLite-/JSON-Invarianz sind gezielt getestet; finale Prüfergebnisse
im CODEX_CHECKPOINT. [Fachbeleg](CHARACTER_CREATION_AUDIT_20261027.md).
Alle zwölf Klassen, sämtliche Spezies-/Talent-/Zauberentscheidungen und der
komplette geführte Assistent bleiben insgesamt unvollständig. Frühere Aussagen
unterhalb sind historische Entwicklungsstände, nicht neue Abnahmen.

# Charaktererstellung – Arbeits- und Abnahmenachweis (NICHT vollständig)

## 27.10.2026 – Gemeinsame Start-TP-/Ausrüstungsprüfung für alle zwölf Klassen (PR in Vorbereitung)

**Regelquelle:** D&D SRD 5.2.1, *Character Creation* und *Classes*, CC BY 4.0, https://www.dndbeyond.com/srd.

- Neue Stufe-1-Charaktere können die Klassenentscheidung nur nach einem gültigen KO-Wert und, wenn eine Klassen-Starterwahl offen ist, nach ausdrücklicher Wahl von Klassen-Ausrüstung oder Startgold übernehmen. Für alle zwölf Klassen wird W6/W8/W10/W12 + KO-Modifikator berechnet und nach Bestätigung vom vorhandenen Editor in die gespeicherten Start-TP-Felder übernommen.
- Der Kämpfer behält seine zusätzlichen Pflichtentscheidungen (Kampfstil und drei Waffenmeisterschaften); die übrigen elf Klassen erhalten dadurch **noch keine** vollständige Klassenmerkmals-/Zauberauswahl.
- Bereits bestehende Charaktere behalten die optionale, ausdrücklich bestätigte TP-Änderung; kein Backfill und keine SQLite-/JSON-Schemaänderung.
- **Code:** `app/lib/domain/srd_first_class_start_validation.dart`, `app/lib/ui/srd_class_selection_dialog.dart`, vorhandene `starting_hit_points.dart` und `character_editor.dart`.
- **Tests angelegt, noch nicht durch CI belegt:** zwölf parametrische Klassenfälle mit Pflichtkit und TP, unzulässige KO-Werte, Stufe > 1, bestehende Charaktere, doppelte Starterauswahl; Editor-Regression mit Waldläufer + 150-GM-Alternative.
- **Offen:** vollständige spezies-/hintergrund-/klassen-/talent-/zauberabhängige Pflichtentscheidungen, bearbeitbarer persistenter Entwurf, Altspielstand-/Import-E2E, reale Android-/TalkBack-Abnahme, vollständige Integrations-CI. Siehe `CHARACTER_CREATION_COVERAGE.json`.

## 27.10.2026 – Zusammengeführtes Charakterpaket (Integrationsprüfung)

Die Pakete #264/#272/#273/#275 stehen gemeinsam im Integrationskandidaten. Insbesondere ersetzt PR #275 im Akolythenpaket A den zuvor unbestimmten Symbol-Platzhalter durch eine explizite Wahl zwischen Amulett, Emblem und Reliquiar; Option B erteilt nur 50 GM. Die in den nachfolgenden historischen Einzelpaket-Abschnitten genannten **offenen Symbole und Provenienz** sind damit überholt. Vollständige Klassen-/Spezies-/Talentauswahl und echte Geräteabnahme sind weiterhin nicht belegt. [Integrationsbeleg](CHARACTER_STACK_INTEGRATION_20261027.md).

---

**Stand:** 26.10.2026 · Branch `feat/character-random-ability-rolls-20261026` · Draft-PR #264.

Dieser Dateiname kennzeichnet den geplanten Endzustand. **Weder die
Charaktererstellung noch der SRD-5.2.1-Audit sind bereits vollständig.**
Der jeweils letzte GitHub-Commit und dessen CI müssen gesondert geprüft werden.

## Entwicklungspaket 3 – Vier SRD-Hintergrundpakete (27.10.2026)

**Stack:** [#264](https://github.com/ManuEtt/Dnd/pull/264) →
[#272](https://github.com/ManuEtt/Dnd/pull/272) →
[#273](https://github.com/ManuEtt/Dnd/pull/273). Basis #272:
Actions #40443350659 **erfolgreich** (CI) inkl. Android.
Abnahme der Änderungen in #273 ist davon **separat**.

- `srd_background_package.dart`: Akolyth, Krimineller, Weiser und
  Soldat mit zwei fest vorgegebenen Übungen, Werkzeugübung,
  Herkunftstalent-Vermerk und originalen Startpaketen A oder
  ausdrücklich gewählten 50 GM B. Beim Soldaten ist ein
  **konkretes** SRD-Spielset Voraussetzung und zugleich Ausrüstung
  sowie Werkzeugübung.
- `srd_background_package_dialog.dart` und Charakter-Editor:
  ausdrückliche Bestätigung vor Hinzufügen; bestehende Helden,
  andere Hintergründe, bereits verbuchte Pakete oder Stufen >1
  werden nicht automatisch ausgestattet. Herkunftsinformationen
  als optionales `startingBackgroundPackage` am Helden gespeichert.
- SRD-Kataloggegenstände werden nach validierten IDs gespeichert;
  20 Pfeile sind **eine** Munitionseinheit mit 20 Pfeilen.
  Freie Varianten wie das konkrete Heilige Symbol bleiben
  bewusst ungeklärt und erhalten keine erfundenen Spielwerte.
- **Nicht fertig:** Regeln des Talents `Wachsam` und `Wilder
  Angreifer` sowie insbesondere konkrete Entscheidungen für
  `Magieinitiierter` (zwei Zaubertricks, ein Zauber 1. Grades und
  Zauberattribut). Die Eintragung eines Talentnamens ist **keine**
  vollständige Regelautomatik. Tool-Übungen werden als
  Herkunftsmerkmal eingetragen, ihre Würfelmechanik bleibt
  separat zu prüfen.
- Tests: `app/test/srd_background_package_test.dart` und
  `app/test/srd_background_package_dialog_test.dart`; finale
  CI muss Format, Analyse, vollständige Tests, Android-Build und
  Artefakte noch bestätigen.

**Nächster Schritt:** vollständige Herkunftstalent- und Zauberwahl
mit eigener SRD-Prüfung; danach weitere fehlende Klassen- und
Speziesmerkmale.

---

## Quellen und Regelgrenze

Verbindlich ist das offiziell lizenzierte D&D SRD 5.2.1,
https://www.dndbeyond.com/srd, *Character Creation*, S. 21,
„Generate Your Scores“ und „Assign Ability Scores“ (CC BY 4.0).
Aus den drei Methoden werden nun Standard Array, Point Cost und Random
Generation als separate, validierte Startwertquellen angeboten.

## Implementierungspaket 1: Würfelergebnisse für Attribute

- `app/lib/domain/ability_generation.dart`: `AbilityRollSet.generate`
  würfelt exakt sechsmal vier W6, verwirft pro Durchgang den niedrigsten
  Würfel, enthält alle 24 Würfelzahlen unveränderlich. Die Würfelquelle
  ist injizierbar und daher ohne Zufall testbar. Der Attribut-Entwurf
  ist nur gültig, wenn seine sechs Werte genau dem gewürfelten Multiset
  entsprechen. Hintergrundboni werden nur aus den Basiswerten komponiert.
- `app/lib/ui/ability_assignment_dialog.dart`: Dritte Auswahlmethode,
  transparente Würfelhistorie, Tauschzuweisung aller sechs Ergebnisse
  und obligatorische ausdrückliche Bestätigung. Der Benutzer muss
  zusätzlich weiterhin Hintergrund und Erhöhungen selbst wählen.
- `app/test/ability_random_generation_test.dart`: Anzahl, Gesamtsummen,
  Duplikate, ungültige Würfelzahlen, unveränderliche Daten,
  fehlende Würfelbelege und die einmalige Bonusanwendung.
- `app/test/ui_random_ability_assignment_test.dart`: die sichtbare
  Würfelmethode und die Bestätigungssperre mit festgelegter Würfelquelle.
- Es wurde kein Speicherschema geändert. Der vorhandene Editor übernimmt
  weiterhin nur die **ausdrücklich bestätigten Endwerte**; die 24
  Würfelzahlen werden noch nicht dauerhaft mit dem Helden gespeichert.
  **Dauerhafte Provenienz von Basiswerten/Bonusentscheidungen bleibt offen.**

## Ist-Soll-Matrix (konservativ)

| Bereich | Stand nach Paket 1 | Für Vollständigkeit offen |
| --- | --- | --- |
| Attribute – Standardsatz | vorhanden; bestehende Tests | finale CI auf Integrationsstand |
| Attribute – Punktekauf | vorhanden; bestehende Tests | finale CI auf Integrationsstand |
| Attribute – 4W6 | Code + Tests auf Draft-Branch | grüne CI, Persistenz der Würfel-Provenienz |
| Hintergründe – vier SRD-Einträge | **teilweise**: Attributboni | Talente, Übungen, Ausrüstung, Entscheidungen |
| Spezies – neun Basisfamilien | **teilweise/ungeprüft** | Varianten, Pflichtentscheidungen, Mechaniken, Persistenz |
| Zwölf SRD-Klassen | **teilweise**: Katalog und Startpakete | sämtliche Startmerkmale, Zauber, Auswahlen, Tests |
| Talente/Zauber | **nicht vollständig automatisiert** | Herkunftstalente, zulässige Klassenauswahl, Ressourcen |
| Ausrüstung | **teilweise** | echte Paketübergabe, Doppelwahl-Verhinderung |
| Stufenaufstieg/Mehrklassen | **teilweise** | vollständige verbindliche Pflichtentscheidungen |
| Audit / Character Wizard | **teilweise** | echte SRD-Vollständigkeits-Validierung und geführter Ablauf |
| SQLite/JSON/Android | bisherige Formate erhalten | Realgerät, persistente Entwürfe und End-to-End-Abnahme |

**Keine der Gruppen gilt durch diesen Eintrag als vollständig getestet.**

## Implementierungspaket 2: Versionierter Attribut-Herkunftsnachweis (Stack-PR)

- `app/lib/domain/starting_ability_origin.dart` speichert die **Ausgangswerte**
  vor Hintergrundbonus, Methode, bestätigte Hintergrunderhöhungen und bei
  4W6 alle sechs Würfe mit jeweils vier Würfelzahlen. Die Struktur ist
  unveränderlich, versioniert (`version: 1`) und wird beim JSON-Import
  **regelkonform validiert**.
- `HeroCharacter.startingAbilityOrigin` ist ein **optionales Feld** im
  bestehenden Charakter-JSON `schemaVersion: 1`. Wenn es in alten
  Daten fehlt, entsteht kein neuer Standardwert. Es ist **keine**
  SQLite- oder Kampagnen-Schemaänderung notwendig.
- Der bestehende Attributdialog übergibt erst nach expliziter Bestätigung
  die Herkunft; der Charakter-Editor überträgt sie ausschließlich
  beim Speichern passender, bestätigter Stufe-1-Werte.
- `app/test/starting_ability_origin_test.dart`,
  `app/test/ability_storage_integration_test.dart`,
  `app/test/ui_ability_assignment_test.dart`: JSON-/Editor-Nachweis,
  ungültige Quelle und Würfelwerte, vollständiger SQLite-Neustart sowie
  Helden-Export/-Import.
- Ein Herkunftsnachweis ist **historisch**: spätere Stufensteigerungen
  dürfen ihn erhalten, ohne die heutigen Werte rückwirkend auf die
  Anfangswerte zurückzusetzen. Der Nachweis selbst gewährt keine
  erneuten Boni. Alte Charaktere erhalten keinen fingierten Wurf.
- Weitere separate Verbesserung nötig: unveränderliche Änderungs-
  bzw. Stufenaufstiegshistorie für **nachträglich ersetzte** Startwerte.
  Die aktuelle Metadatenstruktur enthält einen bestätigten Anfangsstand,
  noch kein vollständiges revisionssicheres Änderungsjournal.

**Abnahme:** Neue Tests wurden erstellt und als nächster GitHub-CI-Schritt
vorgesehen; vor deren Erfolg kein vollständig getestetes Paket behaupten.

## Qualitäts- und Abnahmegrenze

Die neuen Tests und die bestehende CI sollen auf der **letzten**
Branch-SHA ausgeführt werden. Weder das Schreiben eines Tests noch eine
frühere grüne CI ist ein neuer bestandener Testnachweis.
Der lokale Ausführungsrechner verfügt nicht über Flutter/Dart- oder
Android-SDK; echte Android-Geräteprüfung ist weiterhin offen.

## Nächster Implementierungsschritt

Nach Abnahme des Attribut-Herkunftsnachweises die vier SRD-Hintergründe
mit Herkunftstalenten, Übungs- und Ausrüstungsentscheidungen als eigene
prüfbare Domain-/UI-Pakete einbinden. Anschließend die Speziesvarianten.

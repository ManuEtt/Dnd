## Aktueller Stand – Mönch-Werkzeugwahl, 0.8.48+98

Stand: 2026-10-29T17:00:04.686609+00:00. Arbeitsbranch
`feat/character-monk-tool-proficiency-20261029`, Basis-Main `fde0ef6ed8b419d6a31c701a03aa05d61994c352`.
Die vorherigen 24 PRs sind über [#386](https://github.com/ManuEtt/Dnd/pull/386)
integriert, [Main-CI 40867945743](https://github.com/ManuEtt/Dnd/actions/runs/40867945743)
auf `fde0ef6e` erfolgreich; live keine offenen PRs beim Start. Ältere Aussagen
„noch nicht integriert“ sind historische Schreibstände, kein aktueller Blocker.

**IMPLEMENTIERT:** Neue Mönche wählen ausdrücklich eine von 27 zulässigen
Handwerkszeug-/Instrumentübungen, auch bei Startgold. Paket A enthält genau
diesen Gegenstand und 11 GM; B enthält 50 GM ohne Gegenstand. Bestätigte
Klassenbelege v3 speichern die Auswahl, v1/v2 bleiben unverändert lesbar und
gewähren keine aus Inventar/Freitext erfundene Übung. Bereits erlernte typisierte
Klassen-/Hintergrundübungen bleiben bei späteren Namens-/Inventaränderungen erhalten.
Eine neue Zweitklasse allein erteilt keine erste Mönch-Werkzeugwahl.

Der Charakterbogen zeigt quellenbasierte Werkzeugübungen und eine ausdrücklich
gewählte Attributsvorschau. Die Regelengine berechnet Übungsbonus nur einmal,
Zustände/Erschöpfung, Vorteil bei ausdrücklich passender trainierter Fertigkeit
und Werkzeug-Verlässliches-Talent ab Schurke 7. Die Vorschau ist kein ausgeführter
Wurf und bestätigt weder Werkzeugbesitz, konkrete Verwendung, SG noch Herstellung.
Der lesende Erstellungs-Audit prüft die neue Pflichtwahl und Paketbindung getrennt.
Eine tatsächlich reproduzierte UI-Sperre beim Mönch→Barbar→Mönch-Rückwechsel mit
bereits übernommenem Paket ist behoben; gleiche Klasse/gleiches Paket erhalten
bereits bestätigte Entscheidungen. Keine doppelte Gold-/Ausrüstungsvergabe.

**KORRIGIERTE REGRESSIONEN:** Der komplette Vorlauf auf `be758357` hatte genau einen Fehler: die bisher feste Audit-Anzahl 11 ignorierte den neuen zwölften Mönch-Pflichtschritt. Erwartung und explizite Prüfung „Werkzeugwahl fehlt“ wurden ergänzt; kein Test deaktiviert. [CI 40918212562](https://github.com/ManuEtt/Dnd/actions/runs/40918212562) ist deshalb rot und keine Abnahme. Eine zusätzliche neue Gegenprobe reproduzierte fehlenden Rüstungsnachteil für ausdrücklich gewählte Geschicklichkeit (Heimlichkeit); die Vorschau berücksichtigt ihn jetzt, ohne ihn auf andere Attribute zu übertragen. 92 betroffene Domain-/SQLite-/Audit-/Panel-Fälle bestanden anschließend. Vollständige Wiederholung und neue finale CI sind erforderlich.

**GETESTET:** 66 gezielte Domain-/SQLite-Fälle, 17 Dialog-, 14 Vorschau- und
15 Editor-Widgetfälle bestanden. Darunter alle 27 Varianten mit A/B, alle zwölf
historischen Klassen/Kits in v1/v2, falsche/fehlende Quellen, doppelte Übungen,
JSON/SQLite-Neustart, stale Editor ohne Änderungen aller sechs Tabellen sowie
320/360 dp bei 200 % Schrift/IME/Semantik. 535 Dart-Dateien unverändert formatiert,
Analyse ohne Befund. Der erste Vollversuch wurde für die zusätzliche explizite Fertigkeitswahl nach Beginn der Flutter-Tests bewusst beendet; er gilt nicht als voller Erfolg. Vollständige gemeinsame Prüfkette und aktuelle CI folgen;
frühere Baseline-CI wird nicht als neue Abnahme ausgegeben.

**NICHT GETESTET:** komplette neue Flutter-/Python-/Backend-Suite und Android-
Builds bis zu ihrem tatsächlichen Abschluss; echtes Android-Gerät/TalkBack,
installiertes Altversionsupgrade und produktive Signatur.
**BLOCKIERT:** kein angeschlossenes Testgerät; kein Code-/GitHub-Zugriffsblocker.
**NOCH NICHT IMPLEMENTIERT:** vollständiger Charakter-Wizard, übrige verpflichtende
Klassen-/Spezies-/Zauberentscheidungen; tatsächliche Werkzeugaktionen und deren
Würfel-/Zeit-/Materialtransaktionen. SQLite 3 / äußeres JSON 1 unverändert,
keine Datenbankmigration. Regel-/Story-Grenze und KI-Autorität unverändert.

Quellen: offizielles SRD 5.2.1, S.8–9/49/63/83/93–95, CC BY 4.0;
THIRD_PARTY_NOTICES.md unverändert. [Fachnachweis](CHARACTER_MONK_TOOL_PROFICIENCY_20261029.md).
`RULE-EQUIPMENT-TOOLS` / `EQUIP-CHOICES` bleiben konservativ `partial`.

Arbeits-PR: [#390](https://github.com/ManuEtt/Dnd/pull/390); maßgeblich sind dessen aktuelle Checks, nicht die bewusst beendeten Zwischenläufe.

Nächster begrenzter Charakter-Schritt: die drei Barden-Instrumentübungen und die
Bindung des Paket-A-Instruments an eine davon ausdrücklich wählen und dauerhaft
belegen. Zuerst amtlichen SRD-Kerntrait prüfen; bestehende v1/v2/v3-Belege nicht
rückwirkend verschärfen. Keine automatische Nachvergabe, Gegenfälle/SQLite/UI/CI
wie im aktuellen Paket. Keine automatische Arbeit nach Sitzungsende.

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

## 27.10.2026 – Lesender Entscheidungs-Audit

Der bestehende Klassen-/Charaktereditor zeigt sieben deutsche Prüfzustände.
Bekannte Namen bestätigen nur die benannte Teilzuordnung; Klassenmerkmale,
Fertigkeiten und Ausrüstung benötigen eigene Entscheidungsbelege. Insbesondere
belegen Gold 0 und Hintergrundpakete kein Klassenstartpaket. Bestehende
Spielstände werden nicht neu berechnet. [Aktueller Fachstand](CHARACTER_CREATION_AUDIT_20261027.md).
Die älteren Abschnitte unten beschreiben die schrittweise Entwicklung.

# Klassenwahl und Startpakete – Aetheria 0.3.3

> **Neuer Teilstand (27.10.2026):** Für jede der zwölf SRD-Klassen ist bei der **neuen** Stufe-1-Klassenbestätigung jetzt ein gültiger Konstitutionswert für die Start-TP und, sofern die Klassen-Starterausrüstung noch auswählbar ist, eine ausdrückliche Ausrüstungs-/Goldwahl erforderlich. Die spätere Editor-Speicherung übernimmt die berechneten TP. Bereits gespeicherte Charaktere werden nicht zwangsweise umgerechnet. Die unten dokumentierten optionalen Kämpfer-/TP-Angaben stammen aus älteren Zwischenständen. Vollständige Klassenmerkmale, Zauber, Spezies- und Talentauswahl bleiben offen; nicht als abgeschlossene SRD-Erstellung verstehen. Nachweis: `docs/CHARACTER_CREATION_COVERAGE.json`.

Quelle: SRD 5.2.1, Abschnitt „Classes“: https://www.dndbeyond.com/srd

## Verwendung auf Android

1. **Neuen Helden erschaffen** öffnen. Name, Spezies und Stufe 1 eintragen.
2. Über **Attribute ermitteln** die offiziellen Grundwerte bestimmen (Standardsatz, 27-Punkte-Kauf oder 4W6 mit gestrichenem niedrigsten Würfel); Hintergrundboni ausdrücklich zuweisen.
3. **D&D-Klasse und Fertigkeiten wählen** öffnen und eine der zwölf unterstützten Klassen auswählen.
4. Die vorgeschriebene Anzahl unterschiedlicher, für diese Klasse erlaubter Fertigkeiten wählen. Die zwei passenden Rettungswurf-Übungen werden angezeigt.
5. Optional den Start-TP-Vorschlag einschalten, sobald ein bestätigter KO-Wert vorliegt. Bei einer neuen, noch nicht ausgestatteten Figur kann auch die SRD-Startausrüstung oder ein Startgoldpaket gewählt werden.
6. **Klasse und Fertigkeiten übernehmen** bestätigen, danach **Charakter speichern** wählen.

Auf Stufe 2–20 ist der neue Klassenauswahlassistent **nicht** als Stufenaufstiegs- oder Mehrklassen-Funktion verwendbar.

## Sicherer Umgang mit alten Charakteren

- Der Assistent verändert den Charakter erst nach Bestätigung. Abbruch lässt alles unverändert.
- Vorhandene Fertigkeiten und Rettungswurf-Übungen werden standardmäßig um neue ergänzt. **Bestehende Übungen ersetzen** überschreibt die Listen ausdrücklich und kann eingetragene Hintergrundübungen entfernen.
- Vorhandene Trefferpunkte werden nur dann überschrieben, wenn die entsprechende Checkbox bewusst aktiviert wird.
- Vorhandene Ausrüstung und Gold werden bei bestehenden Charakteren nicht angetastet. Startpakete sind nur für neu angelegte Charaktere verfügbar, solange noch keine Gegenstände oder Gold ausgewählt wurden.
- Ein Ausrüstungsgegenstand im Inventar wird nicht automatisch angelegt. Eine Rüstungsklasse wird nicht aufgrund dieses Pakets gesetzt.
- Fremde und alte Klassenbezeichnungen bleiben beim Öffnen des bestehenden Charakters erhalten. Die Auswahl einer SRD-Klasse ist freiwillig.

## Attributregeln

Bei neuen Charakteren schützt der Editor die durch den Standardsatz oder den Punktekauf einschließlich Hintergrundboni ermittelten Endwerte vor stillen manuellen Änderungen. Wer direkt eigene Attributwerte eintragen will, muss **Manuelle Attribute als Hausregel zulassen** aktivieren. Für historische Charaktere gilt diese neue Einschränkung nicht. Eine dauerhafte Herkunfts-/Regelversion-Metadatenerfassung steht noch aus.

## Unterstützter Umfang und Grenzen

Der Assistent setzt die Startlisten aus dem SRD 5.2.1 um: zwölf Klassen, Rettungswurf-Übungen, Klassenfertigkeiten, Trefferwürfel und optionale Ausrüstung/Startgold. Er implementiert noch **keine** Charaktermerkmale, Werkzeugauswahl, Hintergrund-Fertigkeiten, Talente, Zauberauswahl, automatische Rüstungsberechnung, Mehrklassenregeln oder automatische Stufenaufstiege.

Regeltexte sind für die Benutzeroberfläche vereinfacht und in eigene deutsche Bezeichnungen übersetzt. Vorrang hat das zitierte SRD. Automatische Python-Projektprüfungen sind kein Ersatz für Flutter-Analyse und Android-Gerätetests.

## Neu: EP und Kämpfer-Startwerte (Entwicklungsstand)

- Neue Charaktere starten auf Stufe 1 mit **0 EP**. Bei Änderung der
  Gesamtstufe wird die SRD-5.2.1-Untergrenze (1–20) eingetragen, solange die
  EP nicht ausdrücklich manuell bearbeitet wurden. Ein Neucharakter darf
  nur eine zum eingetragenen Level passende EP-Zahl speichern. Der Übungsbonus wird
  gemäß Gesamtstufe berechnet (+2 bis +6) und nicht doppelt gespeichert.
- Für einen neu angelegten **Kämpfer auf Stufe 1** verlangt der Klassenassistent
  bestätigte Konstitution, genau zwei Klassenfertigkeiten, einen der vier
  in SRD 5.2.1 publizierten Kampfstile, drei unterschiedliche Waffenarten mit
  Meisterschaftseigenschaft und eine der SRD-Startausrüstungen A/B/C.
- Nach Bestätigung werden **10 + KO-Modifikator** als maximale und aktuelle
  Trefferpunkte (mindestens 1), Übung in Stärke-/Konstitutionsrettungen,
  Kampfstil, Waffenmeisterschaftsauswahl und die Beschreibung von **Zweite Luft
  (2 Anwendungen)** übernommen. Die Startausrüstung/Goldauswahl bleibt wie bisher
  ausdrücklich gewählt; Rüstung wird nicht automatisch angelegt.
- Kampfstil- und Meisterschaftsauswahl wird im bestehenden Feature-Listenformat
  abgelegt. Sie beweist **keine automatische Umsetzung** der entsprechenden
  Kampfeffekte; diese dürfen nur durch bestätigte Regelengine-Mechaniken wirken.
- Alte importierte Charaktere behalten ihre bisherigen EP (auch `null`), TP,
  unvollständigen Daten und Geschichte. Kein rückwirkendes Überschreiben.

Regelquellen: https://www.dndbeyond.com/srd, SRD v5.2.1:
*Character Creation/Level Advancement*, *Classes/Fighter* und
*Feats/Fighting Style Feats* (CC BY 4.0).

## Ergänzung 26.10.2026 – 4W6-Attributmethode, PR #264

Die neue Methode ist auf einem Draft-Branch implementiert und besitzt
deterministische Domain- und UI-Tests. Noch nicht als vollständig
abgenommen: CI des letzten PR-Commits, lokale Flutter-/Android-Prüfung,
Persistenz der einzelnen Würfel und der Attribut-Provenienz,
übrige Pflichtentscheidungen. Details:
[Charaktererstellung](CHARACTER_CREATION_COMPLETE.md).

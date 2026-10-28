# Codex-Checkpoint – Klassenstartwahl 0.8.45+95

> **Letzte gemeinsame Abnahme vorbereitet – 2026-10-28T04:35:44.592299+00:00**
> Main `bf5999e98335c1da94b1eafbf2fc8088b392b6ef` regulär übernommen,
> kein Fachkonflikt. Auf diesem Stand 57 gezielte Fluttertests, Analyse,
> Format aller 465 Dartdateien und 168 Pythonprüfungen bestanden.
> Vollständige neue CI wird am endgültigen PR-Commit abgenommen.
> Zwischenkopf `019be0e` ist separat in CI 40631517151 vollständig grün mit
> 2.007 Flutter / 168 Python / 72 Backend und geprüftem 1.021-Dateien-Quellpaket.
> Der neue Main-Stand wird nicht mit diesem älteren Erfolg gleichgesetzt.
> Abnahme/Artefakte nach Abschluss im PR #319 und externen Artefaktindex,
> ohne geprüfte Quellen für nachträgliche Erfolgszeilen erneut zu ändern.



> **Neueste Koordination – 28.10.2026:** Der Editor-CAS-Fix wird bereits von
> einem anderen Verantwortlichen in [PR #330](https://github.com/ManuEtt/Dnd/pull/330)
> bearbeitet, zuletzt gemeldeter Kopf `76d5daa30e55e644acc1aece0ac63ecc01d1e9b6`.
> Diesen PR zuerst live auf Code, vorhandene Regressionstests und finale CI
> prüfen und abnehmen; keine zweite Implementierung oder doppelte Tests starten.
> PR #323 ist bereits in der jetzt integrierten Main-Basis `bf5999e` enthalten.
> PR #330 ist auf `76d5daa` bereits vollständig in
> [CI 40631254745](https://github.com/ManuEtt/Dnd/actions/runs/40631254745) geprüft,
> einschließlich sechs neuer SQLite-/CAS-Regressionen. Gegen das inzwischen
> fortgeschrittene Main bestehen Integrationskonflikte. Nächster Schritt ist
> ausschließlich die koordinierte Konfliktauflösung und erneute gemeinsame
> Abnahme von #330; keine zweite Implementierung und keine doppelten Tests.
> PR #324 wurde auf `d83d79a` aktualisiert; CI 40632775104 läuft noch.
> Frühere nächste Schritte weiter unten sind mit dieser Koordination zu lesen.
> Der geprüfte Zwischenkopf `019be0e` besitzt Alpha-Artefakt
> [12791887302](https://github.com/ManuEtt/Dnd/actions/runs/40631517151/artifacts/12791887302);
> 1.021 CI-Quelldateien wurden laut Hauptabnahme mit Inhalt und Dateimodus
> verifiziert. Die neue gemeinsame Abnahme nach `bf5999e` bleibt separat.

Stand 2026-10-28T04:12:49.192781+00:00 (UTC). Arbeitsbranch `feat/character-start-class-proof-20261027`,
[PR #319](https://github.com/ManuEtt/Dnd/pull/319) jetzt gegen **main**.
Main `a915717ba0f57c74acf03c9b1a066ced531c7c6a` und Audit-PR #318 (`89545ab`) über reguläre
Merges integriert. Letzter Synchronisationskopf `6d87c88` enthält auch die
neuen Main-Controller-/NPC- und Symlink-Projektprüfungen; Mönch-Quellenprüfung
aus `2717f1f` bleibt erhalten. Produktbasis `30bb33ec9eec5e6dbb75d8e30cd9268386120477`.
Endgültiger Commit im PR; keine Force-Pushes, kein direkter Main-Commit,
keine fremden Branches gelöscht.

## IMPLEMENTIERT

Versionierter, unveränderlicher `HeroCharacter.startingClassChoice` aus der
**tatsächlichen** neuen Stufe-1-Klassenbestätigung: Klasse, vorgeschriebene
Klassenfertigkeiten, optionale Paketwahl mit konkreten Katalog-IDs und
Kämpfer-Kampfstil/-Meisterschaften. Historischer Beleg gewährt selbst nichts.
Altdaten ohne Beleg bleiben unverändert; späteres Bearbeiten erzeugt keine
Neuvergabe. Aktuelle Klassen-/Übungswidersprüche im neuen Entwurf werden
abgewiesen. Erneute Klassenwahl ersetzt ihre frühere Übungsquelle, statt
Übungen anzusammeln; Gold und Ausrüstung nur einmal. Vollständige
Paketvorbereitung vor Änderung des Editorentwurfs, Abbruch ohne Mutation.

Mönch-Paket nur aus 17 SRD-Handwerkszeugen oder zehn Instrumenten, keine
anderen Werkzeuge. Die Übereinstimmung mit der noch nicht strukturierten
Werkzeugübung bleibt ausdrücklich **nicht automatisiert**. Ebenso werden
unaufgelöste Heilige Symbole, druidische Foki und Zauberbuch nicht durch
Freitext als fertige Ausrüstung bestätigt. Audit bestätigt nur echte
Teilentscheidungen; `class.choices`/`origin.feat` bleiben offen. Kein
Gesamt-SRD-Erfolgsflag. Quelle SRD 5.2.1 / CC BY 4.0, Choose Class S. 19, Core Traits
S. 28–77, Monk S. 49, Tools S. 93–94; THIRD_PARTY_NOTICES erhalten.

Requirement `CHAR-CLASS-START-CHOICE-EVIDENCE`; breite SRD-Anforderungen bleiben
partial. [Code-/UI-/Testmatrix](docs/CHARACTER_START_CLASS_CHOICE_20261027.md).
SQLite **2** und JSON-`schemaVersion:1` bleiben unverändert; optionales Feld,
keine Datenbankmigration. Keine Story-/KI-Autorität und keine bezahlten Aufrufe.

Am 28.10. zusätzlich Main-Synchronisation nach Aufnahme von #288/#321/#318.
Die letzten vier Main-Dateien wurden unverändert übernommen, neue
Dokumentationskonflikte additiv gelöst und Originale als `maina915717` archiviert.
Der laufende lokale Zwischenstand-Repeat auf `2717f1f` bleibt getrennt von
der abschließenden CI dieses jüngeren Integrationskopfs.

## GETESTET

- Produktcommit `30bb33e`: [CI 40584924719](https://github.com/ManuEtt/Dnd/actions/runs/40584924719)
  **success**, tatsächlicher Merge `d8a5204` mit demselben Gitbaum: 1.995 Flutter-,
  164 Python- und 72 Backend-Tests, Format/Analyse, Debug-APK, native Tests,
  drei kleine ABI-APKs und ARM64-Quellpaket. Zusätzlich lokaler eingefrorener
  Gesamt-Repeat auf demselben Commit: **1.995 Flutter-Tests bestanden**,
  `/workspace/validation/20261028-classproof-full-frozen.log`.
- Frühere lokale Suite hatte während der letzten Quellkorrekturen drei Fehler
  (Übungsansammlung/Mönch-Werkzeuge); diese wurden nicht abgeschwächt.
  Der anschließende feste Repeat und CI belegen die korrigierte Version.
- Neuester integrierter Stand: **57 gezielte Tests bestanden**, davon 35 neue
  Fälle (18 Domain, elf Widget, sechs echte SQLite). Alle zwölf Klassen und
  vorhandenen Kits im dokumentierten Teilumfang, 320/360dp/200%-Schrift,
  Tastatur/Semantik, Abbruch/Wiederholung, historische Änderungen,
  SQLite-Neustart, JSON-Manipulation, Repository-Stale-CAS und echter
  Transaktionsrollback. Analyse wird auf diesem Stand separat abgeschlossen.
- Lokaler Debugbuild auf `30bb33e` erfolgreich; zwölf native JUnit-Tests ohne
  Fehler/Skip, Version/ABIs/Signatur geprüft. Endgültiger Integrationsbuild wird
  von [aktuellen PR-Checks](https://github.com/ManuEtt/Dnd/pull/319/checks) belegt.

## NICHT GETESTET

Beim Schreiben ist die vollständige CI des finalen Integrationskopfs noch
abzunehmen. Erfolg des Produktcommits ist kein Erfolg aller neu hinzugekommenen
Main-Tests. Maßgeblich sind der tatsächliche letzte PR-Commit und dessen CI;
abschließende Nachweise/Hashes kommen in PR-Beschreibung und Artefaktindex,
ohne bereits geprüften Quellstand nur für eine Erfolgsmeldung wieder zu ändern.
Echtes Android-Gerät, TalkBack, installiertes Altversionsupgrade und produktive
Signierung fehlen. Gemeinsame Integration mit #297/#317/#324/#323 nicht erfolgt.

## BLOCKIERT / bekannte Fehler und Koordination

Keine lokale SDK-Blockade: Flutter 3.35.7 / Dart 3.9.2, Node 22.14, Java 17,
Android SDK 36 vorhanden. Kein reales Gerät/Release-Schlüssel.
Main-App-CI40587248221 auf `571edec` **success**; unabhängiger alter
Bereinigungsworkflow40589220593 rot. Separater PR #329 bearbeitet dessen
Stilllegung; dieser Branch ändert den fremden Workflow nicht zusätzlich.

**Editor-Stale-Schutz nicht hier gelöst:** `saveHero` nimmt im Bestand keine
ursprüngliche Editorrevision entgegen. Vorhandener SQLite-CAS-Test beweist
keinen Editor-CAS. Ein anderer aktiver Entwicklungszweig
`fix/character-editor-stale-save-20261028`, Commit `2173f57`, enthält bereits
Controller-/Repository-/App-Code dafür; bei dieser Bestandsaufnahme noch ohne
Test-/PR-Nachweis. **Nicht erneut unabhängig implementieren.**
PR #324 enthält bereits allgemeine Start-TP-/Kit-Pflichten; überschneidet
Klassenwahldialog und verlangt Anpassung unserer bisherigen Teilentwurfstests.
PR #317 enthält Magieinitiierter, überschneidet Modell/Editor/Audit; nur neue
Wahl ergänzen, niemals den älteren optimistischen Audit zurückkopieren.
PR #323 hat einen vom Eigentümer korrigierten Sparse-Attribut-Roundtriptest;
neue CI auf `4ef139e` war beim Lesen noch laufend. Kein fremder roter Test wurde
blind übernommen oder als bestanden ausgegeben. #297 ist separates eigenes
Würfel-/Bogenpaket. Laufende fremde Änderungen und Worktrees erhalten.

## NOCH NICHT IMPLEMENTIERT

Vollständiger Wizard und persistenter Entwurf, alle Speziesvarianten,
Werkzeugübungsquellen, Herkunftstalente, Klassenstartmerkmale, Zauber und Foki.
Klassenpaketwechsel mit Rücknahme im selben Entwurf ist nicht fertig;
nach übernommener Ausrüstung wird ein widersprüchlicher Klassenwechsel
abgewiesen. Importbelege werden strukturell/regelseitig validiert, nicht
kryptografisch als frühere Spielerbestätigung attestiert.

## Sicherung und Fortsetzung

Verifizierte ZIPs, binäre Patches, Manifeste/Hashes und geprüfte APKs unter
`/workspace/artifacts/character-class-choice-20261027T211114Z`. Exakter Produkt-CI-Checkpoint unter
`product-ci-30bb33e/`: alle **991** Dateihashes und Ausführungsrechte entsprechen
dem heruntergeladenen CI-Quellpaket. ARM64-APK `ci-product-PR #319/`, SHA256
`93057a53b1423b32c89f46b33d0d78235b120cd182046b4233253e742793a599`.
Download [Produkt-Alpha](https://github.com/ManuEtt/Dnd/actions/runs/40584924719/artifacts/12772642192).
Finaler integrierter ZIP-/Patch-Checkpoint wird nach Prüfung neu erzeugt;
Basis für dessen Patch ist Main `a915717ba0f57c74acf03c9b1a066ced531c7c6a`.
Originaldokumente von Main und Audit liegen bytegenau mit Manifest unter
`docs/history/character_class_main_20261028/`; frühere Paketbasis unter
`docs/history/character_class_choice_20261027T211114Z`. Keine privaten Daten/Schlüssel/SDKs/APKs im Quellen-ZIP.

**Genau nächster Schritt:** Vorhandenen **Editor-CAS-Branch `2173f57`** koordinieren,
prüfen und durch Regressionstests bis zum eigenen Integrations-PR ergänzen.
DoD: veraltete Speicherversuche aus zwei geöffneten Editoren, aktives Abenteuer
und Heldenarchiv, SQLite-Neustart, doppelter Retry und Rollback ohne Teiländerung;
ursprünglichen Kontext atomar vergleichen, deutsche Konfliktmeldung.
Vor jedem Edit aktuelle Main-/PR-Stände und etwaige neue CAS-Tests prüfen.
Danach #324/#317 gezielt integrieren, anschließend konkrete Klassen-Symbole/
Foki/Monk-Werkzeugkopplung. Bestehende Regel-/Speicherfunktionen wiederverwenden.
Prüfung `bash scripts/check.sh`, Debug-APK und native Tests nach Workflow,
abschließend echte exakte PR-CI. Keine Weiterarbeit außerhalb aktiver Sitzung.

## GitHub-Import

ZIP enthält app/, backend/, scripts/, .github/ direkt in der Wurzel. Patch in
sauberem Checkout der im Manifest genannten Basis mit
`git apply --check --binary` prüfen, dann `git apply --binary`; eigener Branch,
Commit/Push und PR. Für bereits integrierte Teile zuerst Git-Ancestry prüfen,
nicht denselben Patch zweimal anwenden. Aktueller Branch/PR ist der bevorzugte
Weg; APK ist getrennt vom Quell-ZIP und kein realer Gerätetest.

## Zusätzliche Main-Integration a915717 – 28.10.2026

Nach dem vorherigen Integrationskopf wurde Main
`a915717ba0f57c74acf03c9b1a066ced531c7c6a` mit den regulären Integrationen
von PR #318 (Audit), #288 (explizite NPC-Auswahl im Controller) und #321
(Python-Pflichtdateiprüfung) als weiterer fest fixierter Stand übernommen.
Dabei wurden ausschließlich README-/Checkpoint-Konflikte redaktionell gelöst;
aktuelle 0.8.45+95-Statusangaben bleiben oben. Fremde ursprüngliche Einträge
sind im [Main-Originalcheckpoint](history/character_class_main_20261028/maina915717/docs/CODEX_CHECKPOINT.md)
und die acht unveränderten Originaldokumente im erweiterten
[Historienmanifest](history/character_class_main_20261028/manifest.json) mit
SHA256/Git-Blob-IDs erhalten. Kein CAS-, Magic-Initiate-, Start-TP- oder anderes
noch separates Fachpaket wurde unabhängig neu übernommen. Die auf dem neuen
Mergekopf erforderlichen Tests und die exakte CI müssen gesondert abgenommen
werden; frühere grüne Läufe sind kein Nachweis dieses zusätzlichen Merges.


## Aktuelle Integrationsbasis – 28.10.2026

Die bisherige vollständige Charakter-Übergabe oben ist aus dem geprüften
Commit `019be0e9c208d1fc5e2eeab8230b4a8ba703c647` erhalten. Dessen vollständige
CI [40631517151](https://github.com/ManuEtt/Dnd/actions/runs/40631517151) war
**erfolgreich: 2.007 Flutter-, 168 Python- und 72 Backend-Tests**, zusätzlich
Android-/Alpha-Builds. Diese Abnahme gilt für den genannten Commit.

Anschließend wird der fixierte Main-Stand
`bf5999e98335c1da94b1eafbf2fc8088b392b6ef` regulär integriert. Er enthält
weitere parallel entwickelte Pakete, darunter #323, #290, #334 und #328.
Deren Quellcode wurde ausschließlich durch den normalen Git-Merge übernommen.
Die abschließende gemeinsame Prüfung des neuen Integrationskopfs steht noch
aus; ältere grüne Läufe dürfen sie nicht ersetzen. SQLite-Versionsangaben
in früheren Abschnitten beziehen sich auf ihren damaligen Stand; Main #290
bringt die getestete Migration 2 → 3 mit, unser Klassenmetadatenfeld selbst
benötigt weiterhin keine eigene Migration.

Um wiederholte Statuskonflikte zu vermeiden, bleiben README und gemeinsamer
CODEX_CHECKPOINT mit dem exakten Maintext als Präfix erhalten. Der aktuelle
Charakterstatus und der Verweis auf diese vollständige Übergabe werden jeweils
am Dateiende ergänzt. Beide Main-Originale und die eigene vorherige Übergabe
sind mit SHA256 und Git-Blob-ID im [Historienmanifest](history/character_class_main_20261028/manifest.json)
erhalten. Kein Datenverlust, keine eigenmächtige Neuimplementation der bereits
separat bearbeiteten Klassen-/Zauber-/CAS-Pakete. Vor einem weiteren Schritt
die aktuelle PR-/Main-Lage prüfen; keine Hintergrundausführung zugesagt.

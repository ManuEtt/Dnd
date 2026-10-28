# Codex-Checkpoint – Klassenstartwahl 0.8.45+95

Stand 2026-10-28T04:12:49.192781+00:00 (UTC). Arbeitsbranch `feat/character-start-class-proof-20261027`,
[PR #319](https://github.com/ManuEtt/Dnd/pull/319) jetzt gegen **main**.
Main `571edec9455fb32e4991432953c9a2479a6fffb2` und Audit-PR #318 (`89545ab`) über reguläre
Merges integriert, gemeinsamer Mergekopf `6812a97` vor der abschließenden
Mönch-Quellenprüfung. Produktbasis `30bb33ec9eec5e6dbb75d8e30cd9268386120477`.
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
partial. [Code-/UI-/Testmatrix](CHARACTER_START_CLASS_CHOICE_20261027.md).
SQLite **2** und JSON-`schemaVersion:1` bleiben unverändert; optionales Feld,
keine Datenbankmigration. Keine Story-/KI-Autorität und keine bezahlten Aufrufe.

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
Basis für dessen Patch ist Main `571edec9455fb32e4991432953c9a2479a6fffb2`.
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

# Codex-Checkpoint – Charakterstartwahl 0.8.45+95

Stand 20261027T211114Z (UTC). Main beim Einstieg `b7e3aa2db5eb551ff70e2fe49872b8b3de0d198c`;
Arbeitsbranch `feat/character-start-class-proof-20261027`, Basis des Vorgänger-Audit-PR #318
`09cbe6bdae98535f348baf264354216bbcc87ed8` (Main darin konfliktfrei integriert).
PR dieses neuen Pakets wird nach lokalem Prüflauf erstellt. Der ältere eigene
PR #297 (Würfelbelege/Bogen) bleibt separat, ebenso #317 (Magieinitiierter).

## IMPLEMENTIERT

`StartingClassChoice` speichert ausdrücklich bestätigte erste Klasse,
Klassenfertigkeiten, optionales Startpaket mit konkreten Katalogwahlen und
Kämpferwahlen als versionierten historischen Nachweis. Optionales Hero-JSON-Feld
`startingClassChoice`; SQLite-/Kampagnenschema 1 bleibt erhalten. Kein Grant beim
Laden, keine erfundenen Legacy-Nachweise, keine Neuvergabe bei Reconfirmation.
Editor bereitet vollständiges Paket vor Änderung vor, schützt neue Entwürfe
gegen Quellenwidersprüche und gegen Klassenwechsel nach Paketübernahme.
Audit prüft tatsächlich vorhandene Übungen und typisierte Paketwerte; unaufgelöste
Labels bleiben nicht automatisiert. Mönchwahl beschränkt auf 17 Handwerkszeuge
oder Musikinstrumente, keine anderen Werkzeuge. Source-ID
`CHAR-CLASS-START-CHOICE-EVIDENCE`, breite SRD-Anforderungen bleiben partial.
Details: [Fachnachweis](docs/CHARACTER_START_CLASS_CHOICE_20261027.md).

## GETESTET

56 gezielte Tests bestanden, davon 34 neue Fälle: 17 Domain-, elf Widget- und
sechs echte SQLite-Tests. Alle zwölf Klassen und jedes vorhandene Kit wurden
innerhalb des erklärten Teilumfangs geprüft. Aktuelle Analyse ohne Befund.
Vollständige aktuelle Abnahme und genaue Zahlen werden vor Abschluss ergänzt.
Vorheriger Audit-Commit 2344975: CI40572564661 grün, kein Nachweis neuer Änderungen.
Main b7e3aa2 neue Android-CI40583503220 beim Einstieg laufend; Wartungsworkflow
40575474591 auf3296d42 grün, älterer404-Bereinigungsfehler damit nicht mehr
als heutiger Blocker übernommen. SDKs vorhanden: Flutter3.35.7/Dart3.9.2,
Node22.14/Java17/AndroidSDK36. Keine bezahlten KI-Aufrufe.

## NICHT GETESTET

Finale eigene CI, APK/debug/native im aktuellen Paket zunächst ausstehend.
Echtes Android-Gerät, TalkBack, installiertes Altspielstand-Upgrade, produktive
Signierung und gemeinsame Integration mit #297/#317 sind nicht belegt.

## BLOCKIERT / bekannte Grenzen

Kein physisches Gerät/Release-Schlüssel. Kein Codeblocker bekannt.
Bestehendes `saveHero` besitzt keinen vom geöffneten Editor mitgegebenen
Revisionstoken: dieser Editor-Stale-Schutz bleibt offen. Getestete SQLite-CAS-
Ablehnung ist ausdrücklich kein Nachweis einer revisionsgebundenen Editorabnahme.
Importierte Nachweise werden strukturell/regelseitig validiert, nicht kryptografisch
als frühere Spielerbestätigung attestiert.

## NOCH NICHT IMPLEMENTIERT

Vollständiger Assistent, persistenter Entwurf, alle Spezies-/Talent-/Zauber- und
Klassenstartmerkmale. Einige Klassen-Kit-Labels sind nicht konkret aufgelöst
(Heilige Symbole, druidische Foki, Zauberbuch); keine vollständige Klassen-
oder Ausrüstungsautomation behauptet. Einzelne später wirkende Kampfmechaniken
bleiben außerhalb dieses Quellenpakets.

## Sicherung und Fortsetzung

Vollprojekt-ZIP, binärer Patch, Manifest und SHA256 unter `/workspace/artifacts/character-class-choice-20261027T211114Z`.
Früheren Stand mit Hashes unter `docs/history/character_class_choice_20261027T211114Z` erhalten.
Nächster konkreter Schritt: **Charaktereditor gegen veraltete Speicherstände
absichern**. DoD: ursprüngliche Kampagnen-/Heldenrevision beim Öffnen erfassen,
beim Speichern über Controller/Repository atomar vergleichen; veralteten Editor
mit deutscher Meldung ohne Teiländerung ablehnen; Neustart, zwei parallele
Editoren, aktives Abenteuer/Heldenarchiv, Retry und Rollback testen. Kleiner
koordinierter Integrations-PR für gemeinsame Controller-/Modellgrenzen.
Danach konkrete Heiliges-Symbol-Startwahl für Kleriker/Paladin und weitere
fehlende Foki-/Zauberbuchwahlen. Vor Änderungen Main/PRs erneut
prüfen, insbesondere #317. `bash scripts/check.sh`, Debug-APK/nativeTests und
aktuelle PR-CI ausführen. Keine Arbeit außerhalb aktiver Sitzung zugesagt.

## GitHub-Import

ZIP-Inhalt direkt in Repositorywurzel, app/, backend/, scripts/ und .github/.
Binären Patch auf sauberem Checkout der im Manifest genannten Basis zunächst
mit `git apply --check --binary` prüfen, danach `git apply --binary`; eigener
Branch und PR. Keine privaten Spielstände/Schlüssel/SDKs im Quellencheckpoint.

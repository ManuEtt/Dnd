# Chat A – Todesrettung: bestätigte Klassen vor Regelwirkung

Stand 30.10.2026 UTC, Basis-Main `55fe44475a113943c6310ec16a8ffb481185f4e9`,
Arbeitsbranch `feat/chat-a/death-save-class-validation-20261030`.
Laufzeit-/Testcommit `ee1e5a19e03b5db60fad838d0da36d1f360b84bc`. Dieses Paket ist ein eigener PR-Arbeitsstand;
Integration und Dokumentationskonsolidierung obliegen Chat D.
Appbasis `0.8.48+98`, SQLite **3**, äußeres JSON **1**, keine Migration oder
Versionsänderung. Der frühere Mönch-Abschluss ist bereits auf Main integriert;
ältere Aussagen „kein lokales SDK“, „SQLite2“ und „Integrationskandidat nicht main“
weiter unten sind historische Schreibstände.

## Ausgangsproblem und Akzeptanz

`Unbestätigt 6 / Mönch 14` und `Mönch 14 / Unbestätigt 6` erhielten mit natürlicher
4 unzulässig +6, einen Erfolg und Zugriff auf den Fokus-Wiederholungswurf. Die
bisherige Klassenprüfung bestätigte nur die numerische Verteilung. Unbekannte
Kämpferkombinationen konnten entsprechend Unbeugsamkeit freigeben.

- Hauptklasse und tatsächlich gewählte Zweitklasse müssen aus dem bestehenden
  SRD-Klassenresolver bestätigt sein; kanonische Aliase bleiben erlaubt.
- Unbekannte Klassen ergeben vor Bonus, neuer Todesrettung oder Ressourcenwahl
  eine verständliche FormatException; bestehende Stufen-/Doppelklassenprüfungen bleiben.
- Auch eine unversionierte historische offene Todesprobe wird **vor** einem
  zufälligen, natürlichen oder nur als Gesamtergebnis übergebenen neuen Wurf geprüft.
- Historische Profile, rohe Spielstände und unversionierte Proben bleiben lesbar,
  ohne stillschweigende Klassenergänzung oder Neuinterpretation ihrer Geschichte.
- Ablehnung erzeugt keinen Wurf, Ressourcenverbrauch, Event, Revisionswechsel oder
  SQLite-Teilstand. Gültige Klassen behalten Übung, Klassenstufe und gewählte Wiederholung.

## IMPLEMENTIERT

`DeathSavingThrowRules._validateClassLevels` prüft zusätzlich die beiden
Klassenidentitäten. `GameEngine.resolveRoll` ruft für Todesproben die bestehende
lesende Klassenprüfung vor `dice.check` auf, auch für alte Regelversion0. Neue
versionierte PendingRoll-/PendingDeathSave-Importe werden über ihre vorhandene
Revalidierung abgewiesen. Kein Modell-, Controller-, Repository- oder UI-Umbau;
die deutsche Fehlermeldung läuft durch den vorhandenen Fehlerkanal.

Gemeinsame `game_engine.dart`: genau fünf Zeilen Vorprüfung in einem koordinierten
Integrationsanteil dieses Pakets. Vor der Änderung wurden alle **27** zu diesem
Zeitpunkt offenen PRs samt Dateipfaden geprüft: kein anderer PR bearbeitete die
beiden Laufzeitdateien oder neuen Tests. PR175 ist bereits geschlossen/gemergt.
#387/#400/#405/#408 bleiben eigenständige fremde Zauberpakete; keine Übernahme,
kein Schließen/Mergen/Löschen ihrer Branches. README-/Checkpoint-Ergänzungen werden
nur im eigenen Branch geführt, bisherige Einträge bleiben erhalten.

## GETESTET

- **84** gezielte Domain-/bestehende Ablauf-/UI-Fälle bestanden, darunter **45**
  neue Klassenprüfungsfälle: alle zwölf Einzelklassen, elf Mönch-Mehrklassenfälle,
  Aliase, unbekannte/verschleierte Namen, Doppelklasse, unverändertes Hero-JSON.
- **Neun** neue Integrations-/SQLite-Fälle bestanden: vier ungültige Kombinationen,
  manipulierter versionierter Wurf/Entscheidung, alte offene Probe, gültige Mönch-
  und Kämpfer-Mehrklassenfälle, Neustart, Retry/stale Revision. Bei Ablehnung
  bleiben alle sechs rohen SQLite-Tabellen exakt unverändert und RNG unberührt.
- Die bestehenden Todesrettungs-Widgettests bei 320/360 dp bleiben grün.
- Der erste neue Flow-Testlauf hatte sieben Fixturefehler (Listeninitialisierung
  und JSON-Schlüsselreihenfolge), zwei Fälle bestanden. Fixtures korrigiert;
  rohe Datenbankvergleiche erhalten, anschließende neun Fälle grün. Kein Test deaktiviert.

Vollständige lokale Prüfkette `bash scripts/check.sh` auf dem eingefrorenen
Quellcode bestanden: **2.504 Flutter-, 221 Python-, 72 Backend-Tests**,
537 Dart-Dateien unverändert formatiert, Analyzer ohne Befund, Backend-Typprüfung,
Build und Protokollsmoke erfolgreich. Der lokale **ARM64-Debug-Build und zwölf native App-Tests** sind ebenfalls
erfolgreich; APK-ABI, Version98 und v2-Testsignatur geprüft. Der normale Debug-
Build und drei optimierte ABIs werden durch die GitHub-CI getrennt geprüft.
[PR #416](https://github.com/ManuEtt/Dnd/pull/416) · [maßgebliche CI-Ergebnisse des aktuellen Kopfs](https://github.com/ManuEtt/Dnd/pull/416/checks).
Die lokalen Ergebnisse sind kein Ersatz für diesen aktuellen CI-Nachweis;
Status, tatsächliche Lauf-IDs und Artefakte werden im PR geführt.
Frühere Main-CI40922492508 ist Basisnachweis, keine Abnahme des neuen Pakets.

## NICHT GETESTET / BLOCKIERT / NOCH NICHT IMPLEMENTIERT

Echtes Android-Gerät/TalkBack, installiertes Altversionsupgrade und produktive
Signierung fehlen. Kein Regel-/GitHub-Zugriffsblocker. Vollständiges SRD sowie alle
externen Rettungswurfmodifikatoren bleiben offen. Unbekannte manuelle Klassen
werden weiterhin gespeichert, erteilen aber keine bestätigte neue SRD-Todesrettung.
`RULE-CORE-RULES-DEATH-SAVING-THROWS` bleibt **partial**; keine Gesamtvollständigkeit.

## Regelquelle

Amtliches [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
CC BY 4.0, gedruckte S.17–18 (Death Saving Throws), **48** (Fighter9/Indomitable),
**52** (Monk14/Disciplined Survivor). Level-/Übungsboni nur aus bestätigter eigener
Klasse; keine Klasse aus KI-Text erfinden. Lizenzhinweise unverändert.

## Dateien / Wiederaufnahme

Laufzeit: `app/lib/domain/death_saving_throw_rules.dart`,
`app/lib/domain/game_engine.dart`. Neue Tests:
`app/test/death_save_class_validation_test.dart` und
`app/test/death_save_class_validation_flow_test.dart`. SRD-Register um Beleg
ergänzt, keine neue Anforderungszählung. Fachnachweis und Tests vor Änderungen lesen.
Vor Integration Main/PRs/CI erneut prüfen; Kombination anderer PRs separat abnehmen.

Genau nächster unabhängiger Schritt: **Kurze Rast ohne Trefferwürfelverbrauch**
prüfen und umsetzen. Amtliches SRD: Würfelverbrauch ist optional. Akzeptanz:
Ressourcen-/Paktregeneration auch bei leerem HD-Pool, keine Heilungs-/Würfelannahme,
explizite Bestätigung, kein RNG bei null Würfeln, Alt-JSON/SQLite/Retry und deutsche
Ablaufanzeige. Zuerst offene PRs und gemeinsame Engine-/Resultverträge abstimmen.
Keine automatische Arbeit nach Sitzungsende.

## GitHub und Sicherungen

Eigener [PR #416](https://github.com/ManuEtt/Dnd/pull/416); [aktuelle Checks](https://github.com/ManuEtt/Dnd/pull/416/checks).
Source-Commit `ee1e5a19e03b5db60fad838d0da36d1f360b84bc`; abschließende
Dokumentationscommits ändern die Laufzeit-/Testdateien nicht. CI-Läufe auf
überholten Köpfen gelten nicht als Freigabe. Chat D übernimmt die Integration;
keine fremden Branches werden geschlossen oder gelöscht.

Vollprojekt-ZIP und binärfähiger Patch außerhalb des Projekts unter
`/workspace/artifacts/chat-a-death-save-class-validation-20261030/`; Frühstand
`frueh/`, Endstand `abschluss/`, tatsächliche Prüfnachweise `pruefnachweise/`.
Patchbasis ausdrücklich Main `55fe44475a113943c6310ec16a8ffb481185f4e9`.
Nicht auf bereits integriertem Main erneut anwenden. Download- und Importdetails
im zugehörigen PR und lokalen `ARTEFAKTE_UND_IMPORT.md`; keine privaten Spielstände
oder Schlüssel in die Quellpakete aufnehmen.

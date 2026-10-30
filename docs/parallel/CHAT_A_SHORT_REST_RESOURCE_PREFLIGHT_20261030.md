# Chat A – Kurzrast-Ressourcen vor Trefferwürfeln prüfen

## Geprüfter Integrationsstand vor erneuter Abnahme

Main ist während dieses Pakets auf `69bfe78ec4eeb30042b26971978038a2ee9dac34`
(PR413, barrierefreie Todesrettungsoberfläche) weitergelaufen. Dieser Stand wird
regulär in den eigenen Branch übernommen; beide README-/Checkpoint-Berichte
bleiben erhalten. Der frühere Vollversuch auf Basis55fe4447 wurde vor Abschluss
bewusst beendet und gilt nicht als bestandene Vollsuite, auch wenn Flutter beim
SIGTERM Exit0 liefert. Die kombinierte Vollsuite und finale CI werden neu geprüft.
Der eigene Rast-Laufzeit-/Testcode19fe5e16 ist unverändert. Main wird durch diesen
Branch-Merge nicht verändert; PR416 und andere fremde Pakete bleiben getrennt.


Stand30.10.2026 UTC, Basis-Main `55fe44475a113943c6310ec16a8ffb481185f4e9`.
Branch `feat/chat-a/short-rest-resource-preflight-20261030`,
Quellcode-/Testcommit `19fe5e16394fae096c082a86e7aa8886461fc883`. [PR #428](https://github.com/ManuEtt/Dnd/pull/428) ·
[aktuelle CI-Ergebnisse](https://github.com/ManuEtt/Dnd/pull/428/checks). Kein Main-Merge behauptet; Chat D konsolidiert.
Appbasis **0.8.48+98**, SQLite **3**, äußeres JSON **1**, keine Migration.

## Ausgangsproblem / Akzeptanz

Ein Kämpfer2 mit SecondWind3, ActionSurge2 oder unverdienter Rage1 scheiterte
bisher erst **nach einem** Heilungswurf. Paktverbrauch1 ohne Hexenmeister wurde
sogar akzeptiert: HP3→6, Pakt1→0, ein Würfel. Die Ressourcengrenzen müssen vor
RNG/Heilung/Regeneration gelten; ein Erholungsreset darf einen ungültigen
Ausgangswert nicht verdecken. Gültige Erholung darf nicht doppelt erfolgen.

## IMPLEMENTIERT

`RestRules.shortRest` prüft direkt nach der vorhandenen Rastzulässigkeit:
`ClassFeatureResources.validate`, `ClassResourceRules.validate` und
`SpellcastingRules.availablePactSlots` auf dem **Originalhelden**, bevor ein
Trefferwürfel geworfen wird. Bestehende Regenerationskette und optionale
Zauberkraftregeneration bleiben unverändert. Keine GameEngine-, Modell-,
Controller-, Persistenz- oder UI-Datei verändert; deutsche Fehlermeldungen
nutzen den vorhandenen Fehlerkanal. Historische gültige Spielstände bleiben
unverändert lesbar, keine ungefragte Reparatur oder Neuberechnung.

Akzeptanzfälle: negative/überhöhte/unverdiente Zähler abweisen, ursprüngliche HP,
HD und Ressourcen bewahren, kein Würfel bei ungültigem Pool; gültige Mönch-,
Kämpfer-, Pakt- und weitere Klassenregeneration genau einmal; Abbruch/Import,
Retry, stale Revision, SQLite-Neustart und atomarer Rollback absichern.

## GETESTET

**65** gezielte Domain-/Bestandsfälle bestanden, darunter **33 neue** Unitfälle:
negative/überhöhte/unverdiente Zähler, 1/2HD, Klassen-/Alias-/Mehrklassenfälle,
unveränderte Eingabe, genau einmalige Regeneration und explizites Sorcerous-Restoration-Opt-in.
**Sieben neue** Flow-/SQLitefälle bestanden: echte Engine-/Controllerablehnung
vor RNG, unveränderte sechs Tabellen bei ungültigen Daten, gültige Erholung,
Request-ID-Replay vor/nach Neustart, stale Zweitcontroller, JSON-Export/Import,
Eventprovenienz und später SQLite-Fehler. Bei letzterem sind zwei gültige Würfe
bereits erfolgt; die Datenbank rollt zurück, Zufallszahlen werden nicht als
rückrollbar behauptet. Kein Test deaktiviert.

Ein erster Flow-Testlauf hatte fünf erfolgreiche Fälle und zwei neue
Fixturefehler (Roh-JSON-Exportvertrag, Wizard/Magier-Slotannahme). Fixtures auf
bestehende Verträge korrigiert; danach sieben grüne Fälle, unveränderte rohe
Tabellenvergleiche. Ursprünglicher Fehllog bleibt im externen Prüfnachweis erhalten.

Vollsuite, Analyse, Debug/native und aktuelle GitHub-CI werden separat anhand
[des aktuellen PR-Kopfs](https://github.com/ManuEtt/Dnd/pull/428/checks) und des vollständigen Testberichts im PR
geführt. Frühere Basis-CI oder PR416 gelten nicht als Abnahme dieses neuen Pakets.
Alle tatsächlich abgeschlossenen Läufe/Artefakte werden dort mit Commit/ID belegt.

## NICHT GETESTET / BLOCKIERT / NOCH NICHT IMPLEMENTIERT

Echtes Android-Gerät/TalkBack, installiertes Altversionsupgrade und produktive
Signierung bleiben offen. Kein Code-/GitHub-Zugriffsblocker. Dieser Fix gilt
**nur für kurze Rast mit Trefferwürfelverbrauch**. Engine-Sonderpfade ohne HD,
lange Rast, allgemeine Rastdauer/Unterbrechungen, freie Null-HD-Auswahl und
normale Zauberplatzvalidierung bleiben getrennt. Keine vollständige Rast- oder
SRD-Automatik behauptet. Requirement `RULE-SPELLS-PACT-MAGIC` bleibt **partial**.

## Quellen / Koordination

Amtliches [SRD5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
CC BY4.0, gedruckte S.187 Short Rest, S.48 Second Wind/Action Surge,
S.71 Pact Magic. Lizenzhinweise unverändert. Vor der Implementierung alle
**32** damaligen offenen PR-Dateilisten geprüft: keine Überschneidung von
`rest_rules.dart` und neuen Tests. Gemeinsame README-/Checkpoint-Ergänzungen
bleiben im eigenen Branch; Chat D konsolidiert sie bei Integration.

Voriger eigener [PR416](https://github.com/ManuEtt/Dnd/pull/416), Kopf870d4e98,
ist offen und mit [CI41074122650](https://github.com/ManuEtt/Dnd/actions/runs/41074122650)
geprüft. Sein GameEngine-Anteil wird hier nicht parallel verändert. Er ist
nicht auf Main übernommen; erfolgreiche Einzeltests ersetzen keine Kombination.
Historische ältere SDK-/SQLite2-/Integrationskandidaten-Aussagen darunter sind
Momentaufnahmen, kein aktueller Blocker.

## Sicherung / Wiederaufnahme

ZIP, Binärpatch, Manifest und Git-Bundle außerhalb des Projekts unter
`/workspace/artifacts/chat-a-short-rest-preflight-20261030/`, Frühstand `frueh/`,
Endstand `abschluss/`, tatsächliche Logs `pruefnachweise/`; Importanleitung
`ARTEFAKTE_UND_IMPORT.md`. Patchbasis ausdrücklich Main55fe4447; keine privaten
Spielstände/Schlüssel aufnehmen. Bestehende Arbeitsstände nicht mit ZIP überschreiben.
Vor neuen Änderungen Main/PRs/CI und Masterprompt erneut prüfen.

**Genau nächster Schritt:** bestätigte SRD-Klassenaliase bei normalen
Zauberplätzen kanonisieren. Reproduzierte separate Lücke:
`MulticlassRules.combinedSpellcasterLevel` vergleicht rohe Namen; Wizard erhält
keine Slots, Magier schon. Akzeptanz: gleiche Slotzahlen für alle erlaubten
Caster-Aliase und Mehrklassen, Pact Magic getrennt, unbekannte Klassen nicht
erraten, bisherige JSONs unverändert und Domain-/Persistenz-/CI-Nachweis.
Nicht im Rastpaket verändert; vor Umsetzung Überschneidungen erneut prüfen.
Keine automatische Entwicklung nach Sitzungsende.

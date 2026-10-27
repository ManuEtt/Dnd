# Charaktererstellung – Checkpoint 27.10.2026

Version **0.8.43+93**, Branch `feat/character-roll-provenance-20261027`,
Worktree `/workspace/Dnd-character-rolls-20261027`.
Letzte integrierte Main-Basis `4c2ad0ab8e00d22fac645c6f885c9f9cfcff2267`;
regulärer Integrationscommit `78ae2b7`. Den endgültigen Kopf mit
`git rev-parse HEAD` und dem Artefaktmanifest bestimmen.

## IMPLEMENTIERT

- Bestehende 4W6-/Herkunfts- und Hintergrundpakete aus Main wiederverwendet;
  keine parallele Hintergrundimplementation. PR #279 und nachfolgende
  Main-Regelergänzungen einschließlich #294 erhalten.
- Abbruch oder teilweise fehlgeschlagene Würfelquelle bewahrt den bisherigen
  Attributentwurf und Methodenwert. Deutsche Fehlermeldung als Live-Region;
  erneuter Versuch erzeugt einen vollständigen neuen Satz. Ein erfolgreicher
  Satz bleibt bei Methodenwechsel innerhalb desselben Dialogs erhalten.
- Der echte Charakterbogen zeigt optional die historischen Basiswerte,
  bestätigten Hintergrundboni und sämtliche 24 Rohwürfel in einem
  ausklappbaren Abschnitt. Aktuelle Attribute werden dabei nicht verändert.
  Summen kommen aus der Domäne, nicht aus einer zweiten UI-Regelberechnung.
- Herkunfts-Version muss eine ganze Zahl 1 sein. SQLite 2 / JSON 1 unverändert;
  ältere Charaktere erhalten keine erfundenen Würfel oder rückwirkenden Boni.
- Tatsächliche Layoutüberläufe im Fantasy-Charakterbogen bei 200 % beseitigt:
  ausreichend hohe Attributkarten und umbrechende Panelnavigation mit
  mindestens 48-dp-Touchflächen.

## GETESTET

Gemeinsamer gezielter Flutter-Lauf: **92 Tests bestanden** auf der neuen
Main-Kombination mit den aktuellen Produktänderungen. Einschließlich
Attributmethoden, exakter Wurfzuordnung, 7 Würfeldialogfällen, 13 bestehenden
Editor-/Dialogfällen, 11 SQLite-Fällen und Fantasy-Bogenregressionen.
320/360 dp mit echtem Fantasy-Theme und 200 % Schrift; Dialog zusätzlich mit
geöffneter Tastatur. Historischer STR-Startwert 19 bleibt neben aktuellem
STR 20 lesbar, Öffnen/Schließen ändert kein Charakter-JSON.

SQLite: aktiver Kampagnenstand, Ereignis-stateAfter, Revision-Rekonstruktion,
Archiv, Neustart, Helden-/Kampagnenexport/import; spätere Werte behalten den
Ursprung. Später SQL-Eventfehler rollt fünf Tabellen und sichtbare Snapshots
zurück. Manipulierte Herkunft/Versions-Typen ändern keine gespeicherten Daten.
Log: `/workspace/validation/20261027-character-combined.log`.

Die letzte beobachtete Main-CI
[40499412855](https://github.com/ManuEtt/Dnd/actions/runs/40499412855)
ist auf `4c2ad0a` erfolgreich. Das ist **kein** Nachweis unseres neuen Kopfes.

## NICHT GETESTET

Beim frühen Checkpoint: vollständiges `scripts/check.sh`, neuer Debug-Build,
native Android-Tests und finale Branch-CI noch ausstehend. Kein neuer APK-Download
behauptet. Reales Android-Gerät, TalkBack-Geräteabnahme, Altgeräte-Upgrade und
produktive Signatur fehlen. Erfolge werden erst nach beobachtetem Abschluss
nachgetragen.

## BLOCKIERT

Ein Teilagent meldete eine tatsächliche Kontingentgrenze. Daher keine weitere
Funktionsgruppe beginnen; zuerst sichern und laufendes Paket abnehmen.
Lokale Flutter-/Android-/Node-SDKs sind vorhanden. Kein reales Gerät und kein
Produktivsignaturschlüssel verfügbar. Keine kostenpflichtige KI verwendet.

## NOCH NICHT IMPLEMENTIERT

Vollständiger geführter Assistent mit dauerhaftem Entwurf und siebenstufigem
Auditstatus; sämtliche Speziesvarianten/-merkmale; vollständige Startentscheidungen
aller zwölf Klassen; Magic-Initiate-Auswahl und alle Herkunftstalente;
vollständige Zauber-/Fokuswahl; belastbare Herkunft von sämtlichen Startpaketen;
E2E-Abnahme aller Klassen und kombinierter Entscheidungen. Die Charaktererstellung
ist weiterhin **teilweise**, die Gesamt-Definition-of-Done nicht erfüllt.
[Ist-Soll-Matrix](CHARACTER_CREATION_COMPLETE.md),
[maschinenlesbar](CHARACTER_CREATION_COVERAGE.json).

## Sicherung und Wiederaufnahme

Quell-ZIP, binärer Git-Patch, Manifest und SHA256 unter
`/workspace/artifacts/character-rolls-20261027T031103Z/`.
`scripts/create_checkpoint.py` prüft ZIP-Inhalt/CRC/Modi und reproduziert den
Quellstand durch tatsächliche Patchanwendung auf die dokumentierte Basis.
Generierte 30 Fantasy-Button-PNGs gehören zum vollständigen lokalen Quellpaket,
werden in Git/CI reproduzierbar aus dem vorhandenen Skript erzeugt.

Nächster konkreter Schritt: finale gemeinsame Prüfungen und PR-CI auf exakter SHA
abschließen, beobachtete Fehler beheben. Erst anschließend den bestehenden
`SrdCharacterCreationAudit` um belegte Herkunfts-/Entscheidungszustände ergänzen;
keine bloße Spezies-/Hintergrundzeichenfolge als vollständige SRD-Wahl bestätigen.
Vor Implementierung Main und parallele PRs erneut lesen, insbesondere Klassen-
und Hintergrundänderungen. Keine fremden Branches löschen, kein Force-Push,
keine direkte Main-Änderung und keine automatische Fortsetzung zusagen.

Originaldokumente sind bytegenau mit SHA256 unter
`docs/history/character_rolls_20261027T031103Z/` erhalten.

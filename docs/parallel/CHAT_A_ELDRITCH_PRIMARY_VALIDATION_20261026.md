# Chat A – Eldritch Blast: unbekannte Hauptklasse blockieren

Stand: 26.10.2026, vor finaler CI-Abnahme.

## Problem und Reproduktion
`SrdEldritchBlastRules.resolve` verifizierte eine gültige Hexenmeister-Zweitklasse, aber nicht ausdrücklich, dass die Hauptklasse überhaupt als SRD-Klasse erkannt wird. Ein importierter Held mit `className='Unbekannte Klasse'`, `secondaryClassName='Warlock'`, `secondaryClassLevel=1` und Gesamtstufe 5 kam trotz unbekannter Hauptklasse durch die bisherige Klassen-Vorprüfung. Bei bestätigten Ziel-/Komponentendaten konnten dadurch W20-/Schadenswürfe erzeugt werden.

## Implementiert
- `app/lib/domain/srd_eldritch_blast_rules.dart`: Hauptklasse muss über die bestehende `findSrdClass`-Validierung auflösbar sein, bevor irgendein Würfel geworfen wird.
- `app/test/srd_eldritch_blast_rules_test.dart`: negativer importierter Legacy-Fall ohne Zufallsverbrauch oder Veränderung des Ausgangs-JSON; positiver Wizard/Warlock-Mehrklassenfall mit zwei bestätigten Strahlen.
- Keine Änderung an Hexenmeister-Reichweite, Strahlskalierung, Ressourcen, HP, Speichermodellen, Eventformaten oder dem UI.

## Kriterien
1. Unbekannte Hauptklasse + gültige Hexenmeister-Zweitklasse → `FormatException` vor RNG.
2. Gültige englische/deutsche Aliase, Einzel- und Mehrklassen → bestehende Regeln und Würfelergebnisse.
3. Alte JSONs weiterhin importierbar; die konkrete ungültige *neue Spielaktion* scheitert sicher.
4. `SPELL-ENTRY-ELDRITCH-BLAST` bleibt `partial`; keine pauschale SRD-Fertigstellung.

## Quelle
Offizielles *System Reference Document 5.2.1*, Regeln zu Klassen, Mehrklassen und `Eldritch Blast`, Wizards of the Coast LLC, CC BY 4.0. https://www.dndbeyond.com/srd

## Tests und Koordination
- Baseline: main `42d14ad36cc947691f7e5a1e8647a43f5421b86e`, erfolgreiche Android-CI #40329543284 und #40329543416 auf diesem Stand.
- Lokale Flutter-/Dart-Testausführung: nicht möglich (Flutter/Dart-SDK in dieser Umgebung nicht installiert).
- Eigene neue GitHub-CI: auf den finalen Codecommit bezogen auszuwerten.
- Vor Branchstart: keine offenen PRs. Bestehende Branches, GitHub-Historie und Main nicht überschrieben.
- SQLite 2, Kampagnen-JSON 1: unverändert; keine Migration.

## Nächster Schritt
Nach grüner CI und Review: Säurespritzer-Zauber-SG mit dem zentralen klassenbezogenen Rechner abgleichen; nur bei nachgewiesenem Unterschied als unabhängigen PR korrigieren.

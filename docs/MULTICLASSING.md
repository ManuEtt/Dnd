# Automatische Zweitklasse – D&D SRD 5.2.1

## Nutzung

1. Einen bestehenden Helden öffnen und **Charakter bearbeiten** auswählen.
2. **Zweitklasse automatisch hinzufügen / steigern** öffnen.
3. Die zweite D&D-Klasse auswählen. Die App überprüft die Hauptattribut-Voraussetzungen **beider** Klassen (mindestens 13), verbietet dieselbe Klasse doppelt und begrenzt die Gesamtstufe auf 20.
4. Bei Barde, Waldläufer oder Schurke eine neue zulässige Fertigkeit wählen.
5. Den berechneten Trefferpunkte-Zuwachs bestätigen. Der zusätzliche Trefferwürfel verwendet den **festen Wert für Stufen nach Stufe 1**, nicht den Höchstwert eines neuen Stufe-1-Charakters. Bereits erlittene Schadenspunkte bleiben erhalten.
6. Charakter speichern. Anschließend zeigt der Charakterbogen beide Klassenstufen und die gemeinsame Gesamtstufe an.

Der Assistent unterstützt **höchstens zwei Klassen**. Für die Zweitklasse können anschließend weitere Stufen aufgestiegen werden; beim Folgeaufstieg wird keine weitere zusätzliche Fertigkeit aus der Erstwahl gewährt. **Übungsbonus nach Gesamtstufe** wird bereits aus `hero.level` berechnet.

## Nicht vorgetäuschte Regelunterstützung

- Klassenfähigkeiten, Extra Attack, Rüstung/Waffen/Werkzeug-Übungen, Ressourcen und konkrete Zauber stehen noch nicht vollständig als automatische Datenmodelle zur Verfügung. Sie müssen für volle SRD-Unterstützung separat implementiert und validiert werden.
- Es werden keine Startpakete, kein Startgold und keine Rettungswurf-Übungen für eine Zweitklasse vergeben.
- Fehlende Trefferpunkte bleiben fehlend; die Vorschau wird nicht zur rückwirkenden Schätzung unbestätigter Spieldaten verwendet.
- Multiclass-Zauberplätze können als *theoretische* Tabelle berechnet werden (`MulticlassRules.spellSlots`); Pact Magic und tatsächliche Vorbereitungen sind getrennt zu behandeln. Das erzeugt keine nutzbaren Zauberressourcen.
- Gesamtstufen, Voraussetzungen und Trefferwürfel orientieren sich am [SRD 5.2.1](https://www.dndbeyond.com/srd) (Creative Commons Attribution 4.0).

## Datenformat

Die optionalen Felder `secondaryClassName` und `secondaryClassLevel` erweitern die vorhandene `schemaVersion:1`-Heldendatenstruktur ohne Datenbankmigration. `level` bleibt die **Gesamtstufe**; die Stufe der Ausgangsklasse ist `level-secondaryClassLevel`. Alte JSON-Dateien ohne Zweitklasse bleiben gültig.

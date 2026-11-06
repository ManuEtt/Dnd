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

## Zusätzliche Bestätigungssicherheit seit 0.5.4+24

Aufstiegsvorschläge sind nun an die Charakter-ID und den bestätigten Zustand bei der Berechnung gebunden: Fähigkeiten/Attribute, Fertigkeiten, bestehende maximale Trefferpunkte und Klassenstufen. Wenn sich dieser Zustand während einer geöffneten Bestätigung verändert, muss der Vorschlag neu berechnet werden und darf nicht stillschweigend auf eine andere oder inzwischen geänderte Figur angewandt werden. Ein zwischenzeitlicher Verlust aktueller TP verhindert den Levelaufstieg nicht und wird nicht rückgängig gemacht: Der nach SRD berechnete TP-Zuwachs erhöht den neuen aktuellen und maximalen Wert jeweils um denselben Betrag. Unplausible direkt konstruierte Klassenstufen werden zurückgewiesen. Das Datenbankschema bleibt 1.


## 06.11.2026 – Bestätigte Klassenprofile vor gemeinsamen Zauberplätzen

Die SRD-5.2.1-Mehrklassenrechnung erhält nun eine **Fail-closed-Vorprüfung** vor jeder normalen Zauberplatzkapazität: gültige Gesamtstufe 1–20, bekannte Hauptklasse mit mindestens einer Stufe sowie gegebenenfalls eine bestätigte, davon verschiedene Zweitklasse mit positiver Klassenstufe. Leere/verwaiste Nebenstufen, unbekannte Klassen und kanonisch identische Doppelaliase ergeben `combinedSpellcasterLevel = 0` statt eines nicht belegten Zauberplatzanspruchs. Dadurch verhindern `SpellcastingRules.availableSlots` und `SpellcastingRules.cast` auch eine tatsächliche reguläre Zauberplatzbuchung aus einem inkonsistenten Direkt-/Legacy-Charakter. Bereits verbrauchte, aber nicht belegbare Plätze werden weiter als `FormatException` abgelehnt, nicht stillschweigend angepasst. Bestätigte Vollzauberklassen-Aliase, halb aufgerundete Waldläufer-/Paladinstufen und die separate Hexenmeister-Paktmagie bleiben unverändert. Die ursprünglichen Klassennamen und Speicherstände werden beim Lesen nicht umgeschrieben.

**Regressionen:** `app/test/multiclass_spell_slot_class_profile_test.dart` mit 14 ungültigen Profilen, belegten Alias-/Mehrklassen- und Paktmagie-Positivfällen, normaler Platzbuchung, Fehlerfall vor Ressourcenmutation und JSON-Roundtrip. In `app/test/multiclass_spell_slot_alias_test.dart` wurde eine historische Erwartung korrigiert, die trotz unbekannter Hauptklasse fälschlich Wizard-Zweitklassenplätze freigab. Quelle: D&D SRD 5.2.1, *Character Creation / Multiclassing / Spellcasting / Spell Slots*, S. 25, Wizards of the Coast LLC (CC BY 4.0). Das Requirements-Register bleibt ausdrücklich `unverified` für die Gesamtmechanik; keine Zauberlisten-, Wirkungs-, UI-, JSON-/SQLite- oder Eventmigration. Finale CI auf dem PR-HEAD separat abnehmen.

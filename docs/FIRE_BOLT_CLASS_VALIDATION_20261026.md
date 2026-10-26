# Feuerpfeil: klassenrichtiger Zauberangriff mit expliziter Modifikatorbestätigung

**Regelquelle:** *System Reference Document 5.2.1*, Wizards of the Coast LLC, CC BY 4.0, Abschnitte Spellcasting (Spell Attack Modifier), Multiclassing (Proficiency Bonus), Attack Rolls sowie die Beschreibung *Fire Bolt*. [Offizielle SRD](https://www.dndbeyond.com/srd). Die Quellenangabe und `THIRD_PARTY_NOTICES.md` bleiben bestehen.

## Problem
Der vorherige `FireBoltRules.cast`-Pfad hat den Angriffsbonus unmittelbar aus den Werten des Charakters berechnet, obwohl eine streng validierende Klassenwertberechnung bereits verfügbar ist. Unbekannte weitere Klassenprofile und nicht bestätigte magische Modifikatoren konnten somit als Basisangriff behandelt werden.

## Lösung
Die vorhandene Funktion `SrdSpellSavingThrowRules.statsForClass` validiert vor einem d20 die konkrete Klasse, Alias-Duplikate, Stufenaufteilung und das von der gewählten Klasse verwendete Attribut. `noUnmodelledAttackModifiersConfirmed` muss vom Benutzer ausdrücklich als true geliefert werden, anderenfalls scheitert der Angriff. Die UI führt diesen Wert unmarkiert ein und zeigt die Angriffsvorschau erst nach Bestätigung. `FireBoltRules` addiert Erschöpfung genau einmal zum reinen Klassenwert. Der GameEngine-Event enthält einen nachvollziehbaren Bestätigungsbeleg.

## Akzeptanz / Regression
- Negativ: Bestätigung fehlt, ein unbekannter/duplizierter Klassenalias liegt vor oder Stufen sind inkonsistent ⇒ FormatException vor RNG und kein HP-/Aktions-/Revisions-/Eventeffekt.
- Positiv: Wizard / Sorcerer bei Gesamtstufe 6, ausgewählte Klasse nutzt INT beziehungsweise CHA mit Gesamtstufen-Übungsbonus; Erschöpfung einmal.
- UI: Anfangszustand ohne bestätigte Modifikatoren und ohne Vorschau; nach Bestätigung klassenspezifische Vorschau; ungültige Klassenprofile dürfen keine Auswahl bestätigen.
- Bestehende `spell.fireBolt`-Ereignisstruktur und SQLite-/JSON-Versionen bleiben kompatibel.

Tests: `app/test/fire_bolt_rules_test.dart` und `app/test/fire_bolt_dialog_test.dart`; vollständige [Android-CI #40290687523](https://github.com/ManuEtt/Dnd/actions/runs/40290687523) auf `588b746e60fa27d9f4c40064a70c13aa9f125dd0` erfolgreich, inklusive Flutter-Analyse, 1.706 Fluttertests, Debug-/nativen Android-/Alpha-Builds. Reales Gerät/Produktivsignatur weiterhin offen. Quellregistrierung nicht pauschal auf `tested` hochstufen, solange Gesamtwirkung und amtliche Inventur unvollständig sind.

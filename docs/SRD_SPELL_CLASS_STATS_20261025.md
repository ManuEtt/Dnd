# Chat A – Klassenbezogene Zauberwerte (SRD 5.2.1)

**Offizielle Grundlage:** *System Reference Document 5.2.1* von Wizards of the Coast, insbesondere *Spells / Spell Attack Rolls*, *Spell Save DC*, die Klassenabschnitte zu Spellcasting/Pact Magic und *Creating a Character / Multiclassing / Spellcasting*. CC BY 4.0; https://www.dndbeyond.com/srd. Lizenzhinweise in `THIRD_PARTY_NOTICES.md` bleiben erhalten.

**Requirements:** `RULE-SPELLS-SPELL-ATTACK-ROLLS`, `RULE-SPELLS-SPELL-SAVE-DC`. Die rein lesende Grundwertberechnung ist nur ein Teil dieser Anforderungen; insbesondere Zauberberechtigung, Zielbestätigung, Angriffswurf/Krit, Effekte, unbekannte Gegenstands- und Klassenboni sind hier nicht implementiert.

## Ausgangsproblem

Die bisherige Hilfsfunktion `SrdSpellSavingThrowRules.spellSaveDc` akzeptiert einen frei angegebenen Attributnamen. Daraus darf nicht ungeprüft die Zauberfähigkeit einer Klasse abgeleitet werden. Bei einem Mehrklassencharakter ist die Zuordnung zur **Klasse des gewirkten Zaubers** entscheidend. Übungsbonus richtet sich dagegen nach der Gesamtstufe.

## Implementiert

Neue ergänzende, abwärtskompatible Methode `SrdSpellSavingThrowRules.statsForClass` und unveränderliche `SrdClassSpellStats`, ohne die alte öffentliche API zu entfernen.

- SRD-Klassen: Barde, Kleriker, Druide, Paladin, Waldläufer, Zauberer, Hexenmeister, Magier. Bestehende deutsche/englische Klassenaliasnamen werden von `findSrdClass` unterstützt.
- Grundwert Zauberangriffsbonus = Attributsmodifikator + Übungsbonus; Grundwert Zauber-SG = 8 + Attributsmodifikator + Übungsbonus.
- Primär- oder echte Zweitklasse muss zum Charakter gehören; keine fremde Klasse, unbekannte Klasse, manipulierte Klassenstufen oder doppelte Klassen.
- Fehlende/ungültige Attribute (1–30), unbekannte Modifikatoren und unbestätigte Kontextangaben werden konservativ abgelehnt.
- Keine Würfe, Ausrüstungseffekte, Angriffsausführung, Slotkosten, Konzentrationsänderung oder Persistenzmutation. Keine SQLite-/JSON-Migration.

## Tests

`app/test/srd_class_spell_stats_test.dart`: Klassentabelle, Stufen 1/20, Multiclass-Unterscheidung Wizard/Sorcerer, Aliase, unzulässige Klasse, fehlende Attributbestätigung/Override-Freigabe, fehlerhafte Klassenstufen und unberührter Hero-JSON-Zustand.

Für Merge/Produktfreigabe zusätzlich vollständige GitHub CI mit Dart-Format, Flutter-Analyse, Flutter-Tests, Backend und Debug-APK; Android-Gerät/alte Spielstände sind separat abzunehmen.

## Grenzen / Nächster Schritt

Die Integration in konkrete Zauberangriffe und Gegner-Rettungswürfe benötigt weiterhin überprüfte Zauberklassenzuordnung, autorisierte Ziele/Würfel sowie atomare Controller-Buchung. Kein freier KI-Text darf eine Klassen-/Attributwahl festlegen.

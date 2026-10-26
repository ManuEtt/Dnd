# Chat A – Bestätigter Zauberangriff: W20-Auflösung (25.10.2026)

## Regelquelle und Lizenz

Wizards of the Coast, *System Reference Document 5.2.1* (CC BY 4.0), **Playing the Game – Attack Rolls, Rolling 20 or 1, Advantage/Disadvantage** und **Combat – Making an Attack, Cover** sowie **Spells – Spell Attack Rolls**. Originalquelle: https://www.dndbeyond.com/srd. Lizenz- und Drittquellenangaben im Projekt bleiben erhalten.

**Nachweisbare Teilanforderung:** `RULE-CORE-RULES-ATTACK-ROLLS` – bewusst nur `partial`, kein vollständiger Abschnitt. `RULE-SPELLS-SPELL-ATTACK-ROLLS` ist ebenfalls relevant, wird aber im unabhängigen Chat-A-PR #184 für Klassen-Zauberwerte bearbeitet; keine parallele Bearbeitung derselben Registerzeile.

## Warum ein eigenes Inkrement?

Ein ausgewählter Zauber allein autorisiert keinen Angriff. Klassenbasierter Bonus, konkrete Zauberberechtigung, Zielgültigkeit, Angriffsbedingungen und ggf. Deckung müssen zuerst unabhängig regelgeprüft werden. Der hier gelieferte Resolver entscheidet **ausschließlich einen autorisierten W20-Zauberangriff** und stellt keine Spielzustandsänderung dar.

## Implementierung

`app/lib/domain/srd_spell_attack_roll_rules.dart` enthält `SrdSpellAttackRollRules.resolve` und das reine Ergebnis `SrdSpellAttackRollResolution`.

- Nimmt einen bereits unabhängig bestätigten Gesamtangriffsmodifikator und die **Basis-RK vor Deckung** entgegen; erfindet keine Klassenattribut- oder magischen Boni.
- Vor dem Würfeln müssen Zauber-/Zielberechtigung, Kampfbedingungen und die relativen Deckungsverhältnisse bestätigt sein. Ohne Bestätigung wird abgebrochen.
- `CoverRules.armorClass` addiert bei tatsächlich wirksamer halber Deckung +2 oder Dreivierteldeckung +5; vollständige Deckung blockiert direktes Anvisieren **auch bei natürlicher 20**.
- `DiceEngine.check` verwendet deterministisch injizierbaren Zufall. Vorteil nutzt den höheren, Nachteil den niedrigeren W20; beide heben einander auf.
- Ein **einzelner manueller** W20 darf nicht fälschlich als Vorteils-/Nachteilsauswertung deklariert werden.
- `RulesEngine.attack` entscheidet nach tatsächlich gewürfelter 1 (immer Fehlwurf), 20 (immer kritischer Treffer) oder Gesamtergebnis gegen die wirksame RK.
- Kein Schaden, keine Zielzustandsmutation, keine Zauberbuchung, keine Aktion, kein Ereignisjournal, keine SQLite-/JSON-Formatänderung oder Migration.

## Negativ- und Grenztests

`app/test/srd_spell_attack_roll_rules_test.dart`: Grenzwert gegen RK, natürliche 1 und 20 gegen extreme Modifikatoren/RK, halbe und Dreivierteldeckung, Deckung aus falscher Richtung, Vollschutz vor Würfelverbrauch, Vorteil, Nachteil, Aufhebung von beiden, manueller Würfelmissbrauch, unbestätigte Berechtigungen/Deckungsbedingungen, ungültige RK/Modifikatoren/W20.

**Hinweis zu Kosten und Autorität:** Der Resolver prüft keine Charakterklasse oder Zauberklasse, sondern erwartet einen **zuvor autorisierten Gesamtangriffsbonus**. Der unabhängige PR #184 berechnet nur Klassen-Grundwerte. Spätere vollständige Integration benötigt separate bestätigte Zauberpreflight-Daten, Aktion/Slotkosten, Zielauswahl und atomare Protokollierung; sie darf eine KI-Erzählung nicht als Faktenquelle verwenden.

## Tests und Abnahme

Die Testdatei ist im Branch erstellt. GitHub Actions müssen auf dem **finalen** Commit Dart-Format, Flutter-Analyse/Tests, Python-/Backend-Prüfung, Android-Build und native Tests bestätigen. Lokales Flutter/Dart/Android-SDK steht in dieser Sitzung nicht zur Verfügung; reale Android-Geräteabnahme und Signierung bleiben getrennte Aufgaben.

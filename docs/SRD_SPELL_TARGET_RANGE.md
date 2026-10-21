# SRD 5.2.1 – Reichweite und Zauberursprung (Teilabdeckung)

Stand: 21. Oktober 2026. Quelle: [D&D SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), Kapitel *Spells* – *Casting Spells* – *Range* und *Targets* sowie *Rules Glossary* – *Cover*. Lizenz: CC BY 4.0.

## Implementiert

`app/lib/domain/srd_spell_target_rules.dart` prüft **nur den Ursprung** des Zaubers, nicht automatisch jedes Ziel im Wirkungsbereich:

- **Self:** Der Ursprung muss eindeutig beim Zaubernden liegen (0 Fuß). Bei Kegeln, Linien und Emanationen kann die Wirkung dennoch andere Ziele umfassen.
- **Touch:** Der Ursprung muss auf einer ausdrücklich erreichbaren Berührungsstelle liegen und eine freie Verbindung ohne vollständige Deckung bestätigt sein. Es wird **nicht** fälschlich eine pauschale Berührungsreichweite von 5 Fuß angenommen.
- **Feste Distanz:** Numerische SRD-Katalogreichweiten in Fuß und Meilen werden in Fuß umgerechnet. Der bestätigte Abstand des Ursprungspunkts muss größer/gleich null und kleiner/gleich der Katalogreichweite sein. Ohne ausdrücklich freien Weg wird keine direkte Zielbestätigung erteilt.
- **Sonderfälle:** `Sight`, `Unlimited`, `Special` oder künftige unbekannte Angaben werden bewusst abgelehnt (`UnsupportedError`) und erfordern einen eigenen Regelpfad.

`SrdSpellPreflightRules.preflight` nimmt zusätzlich das optionale, strukturierte `SrdSpellTargetFacts` entgegen. Vorhandene spezialisierte Zauber behalten ihren bisherigen API-Vertrag. **Der generische persistierte Ressourcen-/Material-Commit** in `GameEngine.commitConfirmedSpellMaterialCast` verlangt dagegen nun ausdrücklich die validierte `targetAssessment`; ein bloßes `targetRulesConfirmed: true` reicht dafür nicht. Der Revisionsjournal-Eintrag dokumentiert Ursprungstyp, Katalogreichweite sowie bei Distanz den bestätigten gemessenen Ursprungabstand.

## Nicht automatisch abgedeckt

Die Entfernung ist eine **bestätigte Eingabe**, kein aus einer Weltkarte berechneter Koordinatenabstand. Auch der freie Weg wird anhand expliziter Ortsdaten bestätigt; eine tatsächliche Sichtlinie, Wandkollision oder Deckungsgeometrie kann das Modul nicht selbst aus Text herleiten. Sichtbarkeit ist **keine universelle** Voraussetzung jedes Zaubers. Durch die Form des Wirkungsbereichs verdeckte Felder, mehrere Ziele, anvisierbare Kreaturentypen, Spell-Caster-Targeting, Zieleigenschaften, unerlaubte Ziele, Sonderziele, Reichweiten mit beweglichem Effekt und AoE-Ursprungsverschiebung bei einer nicht einsehbaren Stelle sind weiterhin eigenständige SRD-Anforderungen.

Die eigentliche Zauberwirkung muss vor dem Material-/Slot-Commit **separat** mit spezifischen Regeln aufgelöst und bestätigt sein. Dieser Branch fügt keine freie generische Kampfzauberaktion oder Charakter-/Inventar-Migration hinzu. Bereits bestehende dedizierte Kampf- und Heilzauberpfade bleiben unverändert.

## Prüfbelege

- `app/test/srd_spell_target_rules_test.dart`: gesamter Arbeitskatalog (339 Einträge), 3 Sonderreichweiten, Distanzgrenzen, Meilenumrechnung, Selbstausgangspunkt, Berührungsbedingungen, vollständige Deckung, fehlende Zielbestätigung und geprüfter Preflight.
- `app/test/srd_spell_inventory_persistence_test.dart`: journalisierte Touch-Prüfung und gesperrte nur boolesche, unstrukturierte Zielangabe.
- Bestehende Material- und Persistenztests schützen den atomaren Slot-/Materialabzug und Replay nach Neustart.

Maschinenlesbare Anforderungsbelege: `RULE-SPELLS-SPELL-RANGE` und `RULE-SPELLS-SPELL-TARGETS`, beide **partial** (keine Vollabdeckung).

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_target_rules_test.dart
flutter test
flutter build apk --debug
```

CI- und Android-Geräteabnahme sind unterschiedliche Nachweise; erfolgreicher CI-Branch-Build ist keine bestätigte manuelle Geräteprüfung.

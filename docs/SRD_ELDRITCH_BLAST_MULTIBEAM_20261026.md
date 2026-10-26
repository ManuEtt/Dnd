# Chat A – Eldritch Blast: Mehrstrahlregel nach SRD 5.2.1

**Regelstand:** 26.10.2026. **Quelle:** Wizards of the Coast, *System Reference Document 5.2.1*, *Spells / Eldritch Blast* und *Playing the Game / Attack Rolls*; https://www.dndbeyond.com/srd (CC BY 4.0). Der offizielle Zauber nennt auf Charakterstufe 1/5/11/17 ein, zwei, drei bzw. vier Strahlen, jeweils mit eigenem Fernkampf-Zauberangriff und 1d10 Energieschaden bei Treffer.

## Implementiert

Neue unabhängige Domain-Regel `app/lib/domain/srd_eldritch_blast_rules.dart`: `SrdEldritchBlastRules.beamCount` und `resolve`.

- Verwendet ausdrücklich die **gesamte Charakterstufe**, nicht nur die Hexenmeister-Klassenstufe. Mehrklassencharaktere werden mitgeprüft.
- Schränkt die Auswertung konservativ auf den bekannten Zaubertrick eines bestätigten Hexenmeisters ein; andere Quellen und Talente werden nicht erfunden.
- Verlangt bestätigte Zauberaktion, Komponenten, Angriffsbonus, nicht modellierte Boni, Gegner-/Objektziel, 120-Fuß-Reichweite, freie Verbindung, Deckungsrelation und Angriffsbedingungen.
- Verlangt genau so viele Zieleinträge wie Strahlen: mehrere Strahlen dürfen dasselbe Ziel verwenden, oder getrennte Ziele erhalten. **Jeder Strahl führt einen unabhängigen W20-Angriff aus.**
- Nutzt `DiceEngine.check` für Vorteil/Nachteil, `CoverRules.armorClass` für bestätigte relative Deckung und `RulesEngine.attack` für natürliche 1/20. Volle Deckung blockiert vor dem ersten Wurf; kritischer Treffer führt zu **2d10** statt **1d10** Würfeln.
- **Atomare Vorprüfung bezüglich Würfelverbrauch:** Alle Eingaben werden vor jedem Zufallszugriff validiert. Ein später ungültiger Strahl erzeugt keine teilweise abgewickelte Würfelsequenz.
- Gibt pro Strahl Angriff, Ziel-ID, Treffer/Krit, gewürfelten Roh-Energieschaden sowie die Summe zurück. Kein Schadensbonus aus Eldritch Invocations oder magischen Gegenständen wird automatisch erfunden.

## Nicht implementiert

Kein Slotverbrauch, keine tatsächliche Aktion/Zauberbuchung, keine Trefferpunktreduktion, kein zusätzlicher Hex- oder Agonizing-Blast-Schaden, keine magische Resistenz-/Immunitätsauflösung, keine Gegnerpositionen aus KI-Text, kein persistentes Kampf-/Event-Journal. Die endgültige Autorisierung und Zustandsänderung müssen durch GameEngine/GameController mit Revisions- und Doppelbestätigungsschutz erfolgen. SQLite-/Kampagnen-JSON-Schemata bleiben unverändert.

## Tests

`app/test/srd_eldritch_blast_rules_test.dart`: Gesamtstufen 1/5/11/17, Zweitklassenhexenmeister, getrennte und wiederholte Ziel-IDs, natürliche 1/20, doppelte Kritwürfel, relative Deckung, Vorteils-/Nachteilspfade, Vorausschluss später ungültiger Ziele ohne RNG-Verbrauch, ungültige Klassen/Berechtigungen und unverändertes Helden-JSON.

**SRD-Register:** `SPELL-ENTRY-ELDRITCH-BLAST`, `RULE-SPELLS-CANTRIP-SCALING` bleiben nur `partial`; der vollständige 339-Zauber-Katalog ist weiterhin nicht offiziell mechanisch komplett implementiert.

**Abnahme:** Erst nach tatsächlich erfolgreicher finaler GitHub-CI dürfen Dart-/Flutter-/Backend-/Android-Tests als bestanden gemeldet werden. Ein reales Android-Gerät ist separat zu prüfen.

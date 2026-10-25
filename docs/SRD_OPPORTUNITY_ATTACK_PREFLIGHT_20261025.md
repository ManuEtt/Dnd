# SRD 5.2.1 – Gelegenheitsangriff: bestätigte Auslöser (Vorprüfung)

**Requirement:** `RULE-COMBAT-OPPORTUNITY-ATTACKS`, Status **partial**.
**Offizielle Quelle:** [SRD 5.2.1](https://www.dndbeyond.com/srd), *Playing the Game → Combat → Melee Attacks → Opportunity Attacks*, Seite 15, Wizards of the Coast LLC, **CC BY 4.0**. Bestehende [Lizenzhinweise](../THIRD_PARTY_NOTICES.md) bleiben unverändert.

## Akzeptanzkriterien dieses begrenzten Inkrements

- Ausdrücklich bestätigte Gegnerbewegung **von innerhalb bis außerhalb** bestätigter Nahkampfreichweite, sichtbares Ziel und bewusste Erlaubnis des Spielers.
- Reaktion frei und Held handlungsfähig; existierender nicht abgeschlossener Kampf, aktiver Gegnerzug, passende Encounter-ID und keine schwebenden Wurf-/Schild-/Todesrettungsentscheidungen.
- Rückzug/Disengage, Teleportation, nicht vom bewegten Wesen ausgelöste Bewegung, bloßes Näherkommen oder Bewegung komplett außerhalb der Reichweite lösen **kein** Angebot aus.
- Nur ein bestätigter ausgerüsteter SRD-Nahkampf-Katalogeintrag mit eindeutiger Inventarreferenz oder `Unarmed Strike`; Fernkampf-, doppelte, unbekannte und nicht vorhandene Inventareinträge werden nicht als Waffenoption freigeschaltet.
- Ausgegeben wird ausschließlich `OpportunityAttackOffer` mit Encounter-ID, Revision und bestätigtem Angriffstyp. Weder Würfel noch Trefferpunkte, Reaktionsverbrauch, Events, Spielstand, Journal oder Story werden verändert. Dieselben alten Kampagnen-JSONs bleiben lesbar.

## Code und gezielte Regression

- Domänencode: `app/lib/domain/srd_opportunity_attack_rules.dart` (nur Regeln/Modelle, keine Flutter-, Story- oder Provider-Abhängigkeiten), öffentliche Fassade `app/lib/rules/rules_api.dart`.
- Regressionen: `app/test/srd_opportunity_attack_rules_test.dart`: reguläre und erweiterte Reichweite, Sicht, Spielerfreigabe, Rückzug, Teleport, Fremdbewegung, falsches Ziel/falscher Zug/verwendete Reaktion, Bewusstlosigkeit, Katalogwaffen, doppelter Gegenstand, waffenloser Schlag, alter JSON-Roundtrip und ausbleibende Zustandsmutation.
- Vollständige Format-/Analyse-/Test- und Android-Abnahme erfolgt in GitHub Actions auf dem **finalen Commit des neuen PR**. Ungetestete Änderungen niemals als fertig bezeichnen.

## Explizit noch offen

Das Paket liefert **keine automatisch benutzbare Kampfaktion in der Android-UI**. Die heutige `Encounter`-Struktur speichert keine bestätigten Gegnerpositionen, segmentierte Gegnerbewegung oder eine wartende Gelegenheitsangriff-Entscheidung. Für echten Einsatz fehlen der Bewegungsauslöser, Wahl-Dialog, revisionsgebundener Controller-Befehl, atomarer Reaktionsverbrauch, Treffer-/Schadensauflösung sowie SQLite-/Neustartregression. Keine Monster-Reichweite, freien Würfe oder Angriffsdaten aus Narration ableiten.

**Nächster abgegrenzter Folgeschritt:** Eine ausdrücklich bestätigte Gegnerbewegung als regelgebundenen Unterbrechungspunkt (mit gespeicherter eindeutiger Entscheidung) modellieren, bevor Schaden oder die Bewegungsfortsetzung verbucht wird. Dabei vorhandene Schildreaktion und `reactionUsed` gemeinsam koordinieren; Stale Revision und doppelte Bestätigung verhindern.

## Folgeinkrement am 25.10.2026 – Angebotsbindung und Revalidierung

Die Vorprüfung bietet nun zusätzlich `SrdOpportunityAttackRules.revalidate(campaign, trigger, offer)`. Ein früheres Angebot ist **nicht** dauerhaft gültig: jede spätere Verarbeitung muss die Revision, Encounter-ID, den gewählten Angriffstyp, die Waffen-ID und die ursprünglichen drei Distanz-/Reichweitenwerte exakt abgleichen und die komplette Vorprüfung im dann geltenden Zustand erneut durchlaufen. Dadurch scheitern Angebote nach Reaktionsverbrauch oder Waffenwechsel ebenso wie nach Revision oder Bewegungsersetzung. Neue Domain-Regressionen decken Happy Path, Unverändertheit, Revision, Distanztausch, Gegner-/Waffenwechsel und verbrauchte Reaktion ab. Ihr CI-Ergebnis muss noch auf dem neuen PR geprüft werden.

**Grenze:** Ein Angebot ist weder kryptografisch signiert noch dauerhaft gespeichert; Revalidierung bedeutet ausdrücklich **nicht** atomare Buchung oder eine Exactly-once-Garantie. Der Controller muss unmittelbar vor einer künftigen Zustandsänderung die Bedingungen in derselben SQLite-Transaktion prüfen und die Entscheidung revisions-/ID-gebunden persistieren. Schema und Export-JSON bleiben unverändert, SRD-Anforderung bleibt `partial`.

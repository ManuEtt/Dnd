# Chat E – Herkunftstalent Wachsam: Initiativbonus (SRD 5.2.1)

## Technischer Umfang
Nur **Initiative Proficiency** aus *Alert* wird nach D&D SRD 5.2.1 automatisiert. Die Regel gewährt den **Übungsbonus der gesamten Charakterstufe** zum normalen Initiative-Wurf. Der zweite Teil des Talents (**Initiative Swap** nach dem Wurf mit einem willigen, nicht handlungsunfähigen Verbündeten) wird **nicht** automatisch ausgelöst; er bleibt absichtlich offen. Kein automatisch angenommener verbündeter Teilnehmer und keine KI-Aussage werden als Beleg akzeptiert.

Der Bonus wird ausschließlich aus einem **bestätigten** Stufe-1-Hintergrundpaket `SrdBackground.criminal` bei weiterhin passendem Hintergrund `Krimineller` abgeleitet, nicht aus einem beliebig bearbeitbaren Talentnamen oder Freitext. Er wird genau einmal in `RulesEngine.initiativeBonus` addiert; `CharacterRuleEngine.initiative`, echte `GameEngine`-Initiativewürfe und die Charakterbogen-Vorschau benutzen denselben Wert. Erschöpfung bleibt separat. Keine Änderung anderer Würfelproben, JSON-Versionen, SQLite-Schema, Inventare, XP oder Klassenaktionen. Ältere Charaktere ohne bestätigtes Paket erhalten nicht rückwirkend ein Talent.

## Tests
`app/test/srd_alert_origin_rules_test.dart`: Profizienztabelle Stufen 1–20, Ablehnung von unbestätigtem und gefälschtem Talente-Freitext, falscher Hintergrund, Erschöpfung, JSON-Import/-Export, unveränderte Angriffs-/Fertigkeitsmodifikatoren.

## Nicht abgeschlossen
Initiativtausch mit willigem Verbündeten; sämtliche sonstigen Origin-Feat-Effekte (Magic Initiate und Savage Attacker), Echtgerät-/TalkBack-Abnahme und vollständige SRD-Regelabdeckung. Kein neues Release versprochen, bevor der tatsächliche CI-/Android-Build auf der exakten PR-SHA erfolgreich ist.

Quelle: [Wizards of the Coast, SRD 5.2.1](https://www.dndbeyond.com/srd) – *Feats: Alert*, CC BY 4.0.

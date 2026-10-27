# Chat E – Wilder Angreifer: persistierter Zugverbrauch (27.10.2026)

## Umsetzung
Die rein deterministische Wahlprüfung aus PR #286 erhält jetzt eine belastbare **einmal-pro-Zug**-Grundlage im bestehenden `Encounter`: das optionale Feld `savageAttackerUsedThisTurn`. Ein alter, bereits gespeicherter Kampagnenstand ohne Feld bleibt unverändert gültig (`false`); ein gespeichertes `true` wird exakt wiederhergestellt. Manipulierte Feldtypen werden verworfen. `Encounter.copyWith` erhält den Status bei Zwischenaktionen, statt ihn unbeabsichtigt zu löschen.

Die Hauptregel kann mittels `SrdSavageAttackerRules.canOfferOnTurn` gefahrlos prüfen, ob das bestätigte Talent auf dem aktuellen aktiven **eigenen Zug**, bei einem lebenden Helden und nicht bereits verbrauchtem Talent grundsätzlich verfügbar ist. Diese reine Vorprüfung verbraucht selbst nichts und prüft **noch keinen tatsächlichen Waffentreffer**.

Die bestehenden GameEngine-Grenzen löschen den Flag erst zum nächsten eigenen Zug – sowohl nach einem regulär abgewickelten Gegnerangriff als auch bei abgewehrtem Angriff durch vollständige Deckung. Ein mehrteiliger Gegnerzug führt keinen zwischenzeitlichen Reset aus. Action Surge, Extra Attack und Nebenhand bleiben innerhalb desselben Zuges begrenzt.

## Tests / Grenzen
Neue Regressionen prüfen ältere JSONs, Typfälschungen, Roundtrips, Zwischen-Copy, tatsächliche Zuggrenze mit GameEngine und Eligibility-Sperren. **Keine automatische Verbuchung eines Einsatzes**: Der gewählte Schadenswurf muss weiterhin in einem zukünftigen isolierten Kampfpaket mit gültigem Ziel, Revision, Spielerentscheidung und TP-Transaktion festgeschrieben werden. Dieses Paket führt deshalb keine Waffenschadensänderung, keine UI-Schaltfläche und keine heimliche Ressourcenausgabe aus. Kampagnen-JSON bleibt Schema 1, SQLite bleibt Version 2.

Quelle: [D&D SRD 5.2.1 / Feats: Savage Attacker](https://www.dndbeyond.com/srd), CC BY 4.0.

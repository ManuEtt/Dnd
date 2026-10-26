# Chat A – Eldritch Blast: Deckungs- und RK-Snapshot-Schutz (26.10.2026)

**Quelle:** Wizards of the Coast, *System Reference Document 5.2.1*, Playing the Game / Attack Rolls sowie Combat / Cover; https://www.dndbeyond.com/srd (CC BY 4.0). Die bestehende Mehrstrahlmechanik und die SQLite-Aktion wurden in früheren PRs bereits integriert; dieses Inkrement sichert den vorhandenen Pfad ab, ohne neue Zauberwirkungen zu erfinden.

## Befund

Der Gameplay-Pfad `GameEngine.castEldritchBlastSingleEnemy` kontrollierte für jeden eingereichten Strahl bereits die Ziel-ID, gespeicherte Rüstungsklasse und gespeicherte Deckungsstufe. Er akzeptierte aber den vom Aufrufer übergebenen `sourceOppositeCover: false` selbst dann, wenn im Encounter gegnerische halbe oder Dreivierteldeckung bereits **relativ zum aktuellen Angreifer** bestätigt war. Der reine Resolver blendet solche nicht gegenüberliegende Deckung bestimmungsgemäß aus. Zusammengenommen erlaubte dies, einen gespeicherten Deckungsbonus über einen abweichenden Request zu umgehen.

Zusätzlich akzeptierte der reine Resolver fälschlich einen Basis-RK-Wert 0 in seiner frühen Zielvalidierung und prüfte die obere Grenze doppelt. Die spätere `CoverRules.armorClass`-Validierung verhinderte zwar die Ausführung, aber die Frühprüfung war inkonsistent.

## IMPLEMENTIERT

- `app/lib/domain/game_engine.dart`: Besteht `fight.enemyCover != CoverLevel.none`, muss jeder einzelne `SrdEldritchBlastTarget` seine bestätigte relative Deckungsrichtung als `sourceOppositeCover: true` tragen. Eine manipulierte Abweichung wird **vor** jeder Würfelaufnahme verworfen. Kein stillschweigendes Ignorieren bestätigter Deckung.
- `app/lib/domain/srd_eldritch_blast_rules.dart`: Basis-RK ausschließlich 1 bis 100. Doppelte obere Schranke entfernt.
- `app/test/srd_eldritch_blast_encounter_test.dart`: negative Mutation gegen gespeicherte halbe Deckung und positiver Test, dass bei gültiger Relativdeckung beide Strahlen auf RK +2 würfeln.
- `app/test/srd_eldritch_blast_rules_test.dart`: zusätzliche Null-RK im **späteren** Strahl mit vollständiger Vorprüfung ohne RNG-Aufruf; Formatierung des Alt-PRs repariert.

## NICHT IMPLEMENTIERT

- Keine Erfindung unbekannter Mehrgegner-RK/Abwehrwerte; persistierte Mehrziel-Aktion braucht eigene pro-Gegner-Snapshots.
- Keine Änderung an Schaden, Resistenz, Aktionen, Spielstandformat, Controller-Revisions-/Idempotenzlogik oder KI-Story.
- Gerätetest/Produktionsrelease weiterhin nicht bewiesen.

## Test- und Integrationsgrenze

Die globale main-CI am Ausgangspunkt `e903ae38c6ae99abfa99a432e7f7777f0eee853f` war bereits wegen Fehlern im Projekt-ZIP-/Sicherungsmodul rot. Das betrifft nicht die hier bearbeitete SRD-Engine und wird nicht im Chat-A-Branch überschrieben. Für diesen PR werden Dart-Format/Analyze, gezielte Regeln-/Encounter-Tests und komplette GitHub-CI gesondert geprüft. Bei globalen rot bleibenden Fremdtests darf der PR nicht als vollständig grün deklariert werden.

**Nächster Schritt:** separate Mehrgegner-Snapshot-Verwaltung (pro Ziel stabile ID/RK/TP/Force-Abwehr) und atomare Aktionen erst nach dafür nachgewiesener Datenmodellvalidierung.

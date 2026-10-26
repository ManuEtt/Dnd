# Chat A – Eldritch Blast als gespeicherte Einzelgegner-Kampfaktion

**Datum:** 26.10.2026. **SRD:** Wizards of the Coast, SRD 5.2.1, *Spells / Eldritch Blast*, *Playing the Game / Attack Rolls, Cover, Damage*, CC BY 4.0. Quelle: https://www.dndbeyond.com/srd.

## Architektur und Grenze

Der vorangehende [PR #202](https://github.com/ManuEtt/Dnd/pull/202) löst bestätigte einzelne Eldritch-Blast-Strahlen rein lesend auf. Dieses **darauf gestapelte** Inkrement verbindet den Solver mit dem bereits revisionierten Abenteuerkampf und der SQLite-Speicherung. Die aktuelle `Encounter`-Struktur hat **nur einen** gespeicherten lebenden Gegner. Deshalb dürfen die Strahlen hier ausdrücklich nur auf genau diese gespeicherte Gegner-ID gerichtet sein; die allgemeinen Regeln aus #202 für verschiedene Ziele bleiben rein lesend, bis persistente Mehrgegner-HP verfügbar sind. Keine falsche Mehrgegner-Freigabe.

## Umsetzung

- `GameEngine.castEldritchBlastSingleEnemy`: prüft offenen eigenen Kampfzug, freie Aktion, vorhandene/lebende Gegnerinstanz, bestätigte eindeutige Zielbindung, aktuelle RK/Shield/Deckung, Verzicht auf ungeklärte Magie-/Schadensmodifikatoren, Komponenten, Sichtpfad und Reichweite pro Strahl. Offene Reaktionen und andere ausstehende Entscheidungen sperren den Abschluss.
- Die bestehende `SpellcastingRules.cast(... spellLevel:0)` prüft Rüstung, Handlungsfähigkeit und bekannten Zaubertrick, ohne Slots zu verbrauchen. Den tatsächlichen Angriffsbonus liefert das Hexenmeister-CHA des Helden plus Übungsbonus der Gesamtstufe und bekannte Erschöpfung – keine frei vorgegebene Zahl aus KI-Text.
- `SrdEldritchBlastRules.resolve` wirft für jeden Strahl separat. `EnemyForceDefenseRules.apply` verarbeitet resistenten/verwundbaren/immunen Energieschaden **je Trefferinstanz**, inklusive Abrundung bei Resistenz. Unbekannte Gegnerabwehr blockiert vor dem Würfeln.
- `GameEngine._commit` erzeugt **eine Revision/ein Ereignis** `spell.eldritchBlast` mit Strahl-Ziel-ID, W20, Treffer, Krit, Schadenswürfeln und angewendetem Schaden je Strahl, danach einem konsistenten Gegner-TP-Stand und verbrauchter Magic-Aktion.
- `GameController.castEldritchBlastSingleEnemy` verlangt explizite Kampagnenkennung und `expectedRevision`; `_effectCampaign` blockiert veraltete Antworten, `_commit` speichert Zustand/Journaleintrag atomar über die vorhandene SQLite-Transaktion.
- Keine Änderung an Speicher-/JSON-Schema oder App-Version.

## Tests

`app/test/srd_eldritch_blast_encounter_test.dart` prüft: Treffer+Fehlschlag als zwei getrennte Strahlen, keine Slotkosten, genau eine Revision/ein Journalereignis, Neustart mit JSON-Roundtrip, Resistenz pro Treffer bei ungeradem Schaden, Fehlermodus bei unbekannter Abwehr/alter Gegner-ID/alter RK/Deckung, schon verbrauchter Aktion/fehlender Bestätigung, SQLite-Neustart und Revisionsschutz, SQLite-Trigger-Fehler vor Journal-Insert mit vollständigem Rollback von Action und Gegner-TP.

## Nicht implementiert

- Mehrere **gespeicherte** Zielgegner und ihre getrennten HP (aktuelle `Encounter`-Grenze).
- Eldritch Invocations (Agonizing Blast), Hex, unbestätigte Modifikatoren und automatische Monsterfähigkeiten.
- Dialog/UI zur Benutzerbestätigung und echte Android-Geräteabnahme.
- Anbieterübergreifendes „Exactly-once“ nach verlorener Commit-Antwort: Stale-Revision schützt vor erneutem Persistieren, aber der Aufrufer muss den neuen Stand laden und den Journalbeleg anzeigen.

**SRD-Status:** `SPELL-ENTRY-ELDRITCH-BLAST` bleibt `partial`. CI auf dem endgültigen neuen Branch-HEAD ist vor Mergefreigabe vollständig abzunehmen. Der PR bleibt auf #202 gestapelt, bis #202 integriert ist.

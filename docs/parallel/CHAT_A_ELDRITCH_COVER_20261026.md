# Chat A – Eldritch Blast Deckungs-Snapshot (26.10.2026)

- **Branch:** `fix/chat-a/eldritch-cover-snapshot-20261026`.
- **Basis:** `main e903ae38c6ae99abfa99a432e7f7777f0eee853f`.
- **IMPLEMENTIERT:** gespeicherte relative Gegnerdeckung kann durch widersprüchlichen `sourceOppositeCover: false` nicht mehr umgangen werden; Basis-RK 0 vor dem Würfeln verworfen, doppelte Obergrenze entfernt. Zwei Regel-/Encounter-Testdateien erweitert.
- **GETESTET:** Neue Fälle geschrieben; CI-Ergebnis des finalen Branch-HEAD getrennt nachweisen.
- **NICHT GETESTET:** physisches Android, Signatur, Geräteupgrade.
- **BLOCKIERT:** globale Ausgangsbasis-CI rot wegen ZIP-/Quellpaket-Sicherungstests (Chat D); nicht im SRD-Branch überschreiben.
- **NOCH NICHT IMPLEMENTIERT:** pro Gegner bestätigte AC/Deckung/Force-Abwehr, mehrzielige persistente Eldritch-Blast-Casts, Release-Gerätetest.
- **NÄCHSTER SCHRITT:** CI des finalen Branches abnehmen; bei weiterhin rotem fremden ZIP-Gate Fehler sauber isolieren, dann koordiniert freigeben. Anschließend validierte Mehrgegner-Snapshots entwerfen.

[Detail-Nachweis](../SRD_ELDRITCH_COVER_SNAPSHOT_20261026.md).

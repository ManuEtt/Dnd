# Chat A – Spell Attack Roll (25.10.2026)

- **Basis:** `main 45bea9c2a897275583bdbe32ed50afde5d0a76b0`.
- **Branch:** `feat/chat-a/spell-attack-roll-resolution-20261025`.
- **Änderungen:** `app/lib/domain/srd_spell_attack_roll_rules.dart`, `app/test/srd_spell_attack_roll_rules_test.dart`, SRD-Register-ID `RULE-CORE-RULES-ATTACK-ROLLS`, fachliche SRD-Datei und Projekt-Checkpoints.
- **Parallele Chat-A-PRs:** [#180](https://github.com/ManuEtt/Dnd/pull/180) Dauer-Parsing, [#184](https://github.com/ManuEtt/Dnd/pull/184) Klassen-Zauberwerte. Keine gemeinsame Quell-/Testdatei verändert.
- **Offene fremde PRs:** B (Story), C (HUD) und D (APK-Qualität) werden nicht verändert.

## IMPLEMENTIERT

Rein lesende Auflösung eines vorher genehmigten einzelnen Zauberangriffs mit W20, natürlicher 1/20, Vorteil/Nachteil sowie bestätigter gegnerischer Deckung; strikte Negativprüfung. Keine Kampagnen- oder Ressourcenmutation.

## GETESTET

Testfälle geschrieben; GitHub-Workflow-Ergebnisse nur nach tatsächlich bestätigtem finalen Lauf als bestanden vermerken.

## NICHT GETESTET

Flutter/Dart lokal mangels SDK, reale Geräteabnahme, persistierter Zauberangriff, Spielstandmigration, Release-Signierung.

## BLOCKIERT

Volle Spell-Cast-Integration hängt von separater Klassenzuordnung, bestätigtem Ziel, Ressourcen, Reaktionslogik und atomarer Engine-/Controllerbuchung ab. Parallele Branches ändern gemeinsame README-/Checkpoint-Dateien; Änderungen vor Merge konsolidieren.

## NOCH NICHT IMPLEMENTIERT

Schaden und Zaubereffekte, Slot-/Aktionsverbrauch, Casting-Preflight-Verkettung, mehrfache Angriffe, anhaltende Effekte, Speichern oder Wiederaufnehmen dieses Rolls.

## NÄCHSTER SCHRITT

Nach vollständig grüner CI und koordinierter Integration der Chat-A-PRs eine konkrete bestätigte Zauberangriffsaktion inklusive Stale-/Idempotenz-/Neustart-Regression einführen, ohne Story oder fremde UI-Module zu ändern. SRD-Gesamtabdeckung bleibt unvollständig.

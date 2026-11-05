## 05.11.2026 – Barden-Inspiration nur aus konsistenten Klassenprofilen

**Branch:** `fix/chat-a/bard-superior-inspiration-profile-20261105`. **Basis-Main:** `7b76d34e42f9f536993035876f8789d3405d70f9` (Main-CI 42072388815 tatsächlich erfolgreich). **Fachcommit:** `d6cdc2778e098c358593f5450f7c43f097cd1c13`. **PR:** [#576](https://github.com/ManuEtt/Dnd/pull/576), finale [Checks](https://github.com/ManuEtt/Dnd/pull/576/checks). App **0.8.51+101** unverändert.

**IMPLEMENTIERT:** Der vorhandene automatische Helfer für Überlegene Inspiration (Barde 18) prüft bekannte kanonische Klassen, unterschiedliche Mehrklassen und gültige Stufen 1–20. Unbekannte Begleitklassen, doppelte Bardenaliase oder widersprüchliche Stufen erhalten denselben Hero und recovered=0. Keine stille Datenreparatur. Gültige Aliase, Barde 18/Kämpfer 2 in beiden Reihenfolgen, niedrigeres Ressourcenmaximum und vorhandene Formel bleiben erhalten. Regelquelle: amtliches SRD 5.2.1, S. 33 (Superior Inspiration), CC BY 4.0; Lizenzhinweise unverändert.

**GETESTET beim Einfrieren:** 24 neue Domainfälle, sechs tatsächliche Controller-/SQLite-Flows und zwei echte App-UI-Flows, außerdem zehn bisherige Fachtests. Alle drei tatsächlichen Kampfstartwege (Waldschrein, Rabenwacht, bestätigtes KI-Kampfangebot), lesbare Legacy-JSONs, unveränderte Ressourcen bei ungültigem Profil, valide Gutschrift, Export/Import, Neustart, requestId-Replay, stale Controller und später SQL-Rollback. Die regulären zwei Initiativewürfe finden weiterhin statt; keine RNG-freie Kampfabweisung behauptet. Der stale Controller rollt dagegen keinen zusätzlichen W20. Bei spätem SQL-Fehler bleibt die DB unverändert; legitime Zufallswürfe werden nicht zurückgerollt.

**WEITERE ABNAHME:** `bash scripts/check.sh` läuft auf identischem Regel-/Testcode. Finale CI/Android-Artefakte nach dem Dokumentationscommit separat auswerten; tatsächliche Ergebnisse im PR und externen Importleitfaden sichern, ohne einen unendlichen Status-Commit-Zyklus. Diese Zeilen sind ausdrücklich der eingefrorene Stand vor Gesamtabnahme. **NICHT GETESTET:** reales Androidgerät, TalkBack, tatsächliches Upgrade und produktive Signierung. **BLOCKIERT:** keine technische Implementierungsblockade; Review und Main-Integration durch Chat D noch ausstehend. Bekannte unveränderte SQLite-Warnung bei nullable NPC-whereArgs in removePendingAction bleibt ein gesonderter Persistenzhinweis, kein neuer Barden-Testfehler.

**GEÄNDERT:** ausschließlich `app/lib/domain/srd_bard_superior_inspiration_rules.dart`, drei neue Testdateien `srd_bard_superior_inspiration_profile{,_flow,_ui}_test.dart`, Dokumentation und der bestehende Requirementnachweis. GameEngine, gemeinsame Modelle, Controller, Speicher und öffentliche API bleiben unverändert. SQLite 3 / JSON 1 ohne Migration. Alle offenen PR-Dateilisten geprüft (zuletzt 20 andere, darunter #575); keine Modulüberschneidung. Der unabhängige eigene PR #557 ist bereits vollständig grün und zur Review freigegeben; seine Engine-Änderungen werden hier nicht dupliziert. Gemeinsame Dokumentation bei Integration additiv bewahren.

**NOCH NICHT IMPLEMENTIERT:** vollständige Bardenwirkungen, übrige Klassen-/Zaubermechaniken und das gesamte SRD. Requirement `CLASS-BARDE-18-BASE-SUPERIOR-INSPIRATION-0` bleibt `partial`. Keine neuen fiktiven Entitäten im Entity-Register. Kein direkter Main-Commit, kein Force-Push oder Branchlöschen.

**NÄCHSTER SCHRITT:** nach frischem Main-/PR-Abgleich weitere automatische Initiative-Klassenmerkmale auf bekannte, konsistente Klassenberechtigung prüfen; Akzeptanz: ungültige Profile erzeugen keine unberechtigte Ressource, gültige Mehrklassen und bestehende Initiative bleiben korrekt. Kein Eingriff in belegte Parallelmodule und keine automatische Fortsetzung nach Sitzungsende.

---

## Abgrenzung und Testnachweise

Die private Prüfung verwendet den bestehenden findSrdClass-Aliasresolver und vorhandene ClassResourceRules-Formeln. Eine öffentliche reine Klassenprofilprüfung existiert noch nicht; die Konzentrationsprüfung würde zusätzlich sachfremde Rettungswurfübungen verlangen. Keine neue globale Berechnung oder vorgetäuschte Bestätigungsflags. Die automatische Fähigkeit bleibt bei einem ungültigen Profil neutral, statt nach bereits gewürfelter Initiative einen neuen Kampf-Ausnahmezustand einzuführen.

Testdateien: srd_bard_superior_inspiration_profile_test.dart (24), srd_bard_superior_inspiration_profile_flow_test.dart (6), srd_bard_superior_inspiration_profile_ui_test.dart (2). Bisherige srd_bard_superior_inspiration_rules_test.dart (10) unverändert. Neuer UI-Nachweis bei 360 dp mit echter App, Outbox, sichtbarer Spielleiterantwort und SQLite-Neustart; kein Nachweis eines echten Androidgeräts.

Offizielles SRD-PDF SHA-256: 8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87. Quelle https://www.dndbeyond.com/srd . Quellen-ZIP, binärer Git-Patch und Bundle werden außerhalb des Repositories unter /workspace/artifacts/bard-profile-20261105 gesichert.

# Chat A – SRD 5.2.1: Sorcerous Restoration (Zauberer 5)

Datum: 28.10.2026. Branch: `feat/srd-sorcerous-restoration-20261028`

Quelle: D&D SRD 5.2.1 (CC BY 4.0), Klasse Sorcerer/Zauberer, Level 5: Sorcerous Restoration. https://www.dndbeyond.com/srd
Anforderung: `CLASS-ZAUBERER-5-BASE-SORCEROUS-RESTORATION-0`.

## Mechanische Umsetzung

- **Spielerbefehl:** `Kurze Rast mit Zauberkraftregeneration`. Die gewöhnliche `Kurze Rast` regeneriert keine Zaubereipunkte. Der Spieler entscheidet ausdrücklich, ob die einmalige Nutzung erfolgt.
- **Regelwerk:** `SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(hero)`, pure Zustandsänderung nach bestätigtem Abschluss der kurzen Rast. Ab Zauberer-Klassenstufe 5, bei Mehrklassencharakteren unabhängig von der Gesamtstufe. Maximum regenerierter Punkte = Zauberer-Klassenstufe ~/ 2, nicht mehr als die tatsächlich ausgegebenen Punkte.
- **Ressourcen-/Speichergrenze:** `spentClassResources['sorcerousRestoration']` maximal 1 ab Zaubererstufe 5, in `ClassResourceRules.maximum` validiert. Eine kurze Rast setzt die Fähigkeit nicht erneut frei; `ClassResourceRules.afterLongRest` entfernt verbrauchte Klassenressourcen. Das vorhandene schemaVersion=1-Format bleibt ohne Migration.
- **Rastpfade:** `RestRules.shortRest` bietet den opt-in-Parameter `restoreSorceryPoints`, vor Trefferwürfelverbrauch wird die Aktion geprüft. In `GameEngine.act` sind alle drei Kurzrast-Pfade erfasst: Trefferwürfel, volle TP, und keine Trefferwürfel verfügbar. Das `character.shortRest`-Ereignis enthält `sorcerousRestorationUsed` und `sorceryPointsRecovered`.
- **Gegenfälle:** kein Zauberer Stufe 5+, keine ausgegebenen Punkte, zweite Nutzung ohne Long Rest, manipulierter Zähler, 0 Trefferpunkte oder Tod – keine mechanische Änderung.

## Nachweispflicht und Grenzen

- **IMPLEMENTIERT:** Regel, Ressource, Short-Rest-Integration, Runtime-Teilstatus, Anforderungen und Tests auf eigenem Branch.
- **GETESTET:** erst nach dokumentiert erfolgreichem GitHub-Testlauf des aktuellen HEAD behauptbar.
- **NICHT GETESTET:** vollständige Flutter-Suite und Android-APK, bis die jeweilige CI-Abnahme erfolgreich ist.
- **NICHT IMPLEMENTIERT:** tatsächliche Simulation der mindestens einstündigen Rast, Unterbrechungen, freie Wahl eines niedrigeren Regenerationswerts oder automatische Weltzeit. Die Wiederherstellung regeneriert bis zur maximal erlaubten Anzahl von Punkten, sofern der Spieler sie ausdrücklich wählt. Die SRD-Anforderung bleibt deshalb **partial**, nicht `tested`.
- **Parallelentwicklung:** `game_engine.dart`, `rest_rules.dart`, `class_resource_rules.dart` sind Integrationsdateien. Vor jedem Merge aktuellen `main`-Stand und andere PRs konfliktprüfen.

Tests: `app/test/srd_sorcerous_restoration_rules_test.dart`.

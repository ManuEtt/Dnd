## 20.10.2026 – Schildreaktion nach tatsächlich getroffenem Gegnerwurf (0.8.20+70)

**Entwicklungsbasis:** `main` `89bd998563c58ae9a8e44a7db6a4ec996219f85d`. **CI und Android-Gerätetest für diese Änderung stehen noch aus.**

- Bei einem **tatsächlich treffenden Gegnerangriff**, wenn der Held Schild vorbereitet und mindestens einen verfügbaren Zauberplatz hat, wird der W20 einschließlich Naturwurf/Bonus atomar als `PendingEnemyShieldHit` gespeichert. **Vor der Entscheidung werden keine Schadenswürfel erzeugt und keine TP verändert.**
- Die UI zeigt das gewürfelte Angriffsergebnis an und bietet `Jetzt Schild wirken` bzw. `Treffer hinnehmen`. Schild setzt weiterhin eine eigene Magier-/Zaubererklasse, einen bestätigten normalen oder Paktplatz und bestätigte verbale/gestische Komponenten voraus.
- Beim Fortsetzen wird **ausschließlich der zuvor gespeicherte Angriff** verarbeitet, ohne zweiten W20-Wurf. Bei Schildentscheidung wird der Zauberplatz auch dann regelkonform verbraucht, wenn der W20 kritisch war oder +5 RK den Treffer nicht verhindert. Der Treffer richtet dann erst jetzt Schaden an. War +5 RK ausreichend, wird der Schaden verhindert.
- Neue `combat.shieldHitResolved`-Ereignisse und Controller-Methode `resolveEnemyShieldHit` haben Revisionsschutz und SQLite-Atomizität. Offene Entscheidungen sind mit gültigen Spielstanddaten gespeichert, während gewöhnliche Aktionen bis zur Entscheidung blockiert bleiben. `Campaign.fromJson` akzeptiert alte Spielstände ohne neues Feld, verwirft jedoch ungültige Würfelwerte, Ziel-IDs und laufende ungültige Reaktionszustände.
- Tests `hero_shield_post_hit_choice_test.dart` und `hero_shield_post_hit_storage_test.dart` sowie Update des Bestandsregressionstests: nachträgliche Schildwahl, Ablehnen, kritischer Treffer, nicht abwendbarer Treffer, Würfel-Nichtwiederholung, JSON, SQLite-Neustart, stale Revision. **CI beim Schreiben noch nicht ausgeführt.**
- **Grenzen:** Gegnerangriff bleibt ein einzelner Attack-Roll-Vorgang; noch keine multiattack-/mehrgegnerfähige Shield-Wirkung über mehrere gegnerische Züge oder gegnerisches Magisches Geschoss auf den Helden. Der zuvor implementierte, rein optionale Vorabautorisierungsweg bleibt zur Spielstandkompatibilität bestehen. Kein vollständiges SRD, kein getestetes echtes Android-Gerät.

**Fortsetzung:** Finalen PR-HEAD formatieren, Projektprüfung, Backend und Flutter Analyse/Tests, Android Debug/Release und native Tests in GitHub Actions prüfen. Gemeldete Probleme beheben, erneute CI; nur vollständiges Grün erlaubt Merge nach `main`. Danach CI, Merge-Commit und offene Grenzen dokumentieren.

## Abnahme und Merge: 0.8.19+69 (20.10.2026)

**CI- und Merge-Abnahme 20.10.2026:** Das eingeschränkte Regelpaket `SPELL-SHIELD-HERO-CONDITIONAL` in Version `0.8.19+69` wurde über [PR #49](https://github.com/ManuEtt/Dnd/pull/49) auf `main` integriert (Merge [`95792bb241c6123e34a1fae97c9fdef31d153ce2`](https://github.com/ManuEtt/Dnd/commit/95792bb241c6123e34a1fae97c9fdef31d153ce2)). Vollständiger [GitHub-Actions-Lauf #39394683773](https://github.com/ManuEtt/Dnd/actions/runs/39394683773) auf dem finalen Code-HEAD `090adb4c5fe21ddfc83d0903d5ef39181c50dd9f` **success**: Struktur-/Python-Tests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Tests und Alpha-APK-Artefakte. **Nicht geprüft:** Gerätetest; eine echte Reaktions-Unterbrechung *nach* dem gegnerischen Angriffswurf; mehrere Angriffe/Gegner und Shield gegen gegnerisches Magisches Geschoss. Diese Grenzen bleiben als offene SRD-Anforderungen bestehen.

---

## 20.10.2026 – SRD Hero Shield (Version 0.8.19+69)

**Basis:** `main` `12b2ddd8e524d674acbb909cc09025bc8ef2cfd9`. Featurebranch: `feature/srd-hero-shield-auto-reaction-20261020`. **Status beim Commit: implementiert, CI noch nicht bestätigt**.

- Neu: `HeroShieldReactionRules` und bedingte Held-Schild-Reaktion im Gegenzug. Voraussetzung sind bestätigter bekannter/vorbereiteter Zauber `Schild`/`Shield`, eigene Magier-/Zaubererklasse (inkl. geprüfter Mehrklassen), freier normaler oder Paktmagie-Platz und ausdrücklich bestätigte V/S-Komponenten.
- Der Benutzer **autorisiert vor dem unmittelbaren Gegnerzug** die Reaktion; beim Angriff entscheidet die Regelengine anhand des gewürfelten W20, ob ein tatsächlich treffender, nicht kritischer Angriff durch +5 RK verfehlt. **Erst beim Eintritt dieses Triggers** wird exakt ein Zauberplatz gebucht; Trefferpunkte bleiben geschützt und die Abwehr erscheint mit Würfelwerten im Ereignisjournal. Bei Fehlangriff, nicht abwendbarem Treffer oder kritischem Treffer wird kein Platz verbraucht. Keine frei erfundenen Trigger oder Würfelergebnisse.
- UI: Neue Aktion `Zug beenden: Schild ggf. wirken`, eigener Dialog mit Klasse, freiem Zauberplatz und V/S-Einwilligungen. Der Controller verwendet `expectedRevision`, `GameEngine.endHeroTurn` validiert vor dem Wurf, Zustand/Slots/Ergebnis landen atomar im bestehenden SQLite-JSON-Journal. Altes Spielstandschema und reguläres `Zug beenden` unverändert.
- Testdateien: `hero_shield_reaction_rules_test.dart` und `hero_shield_reaction_storage_test.dart` prüfen Schildwirkung, kritischen und zu hohen Angriff, fehlenden Platz, fremde Klasse, Zaubername, W20-Zufall, JSON-Roundtrip, SQLite-Neustart und Revisionsschutz. Testergebnis erst nach GitHub-CI dokumentieren.
- **Wichtige Grenze:** Noch keine interaktive Unterbrechung *nach* einem gegnerischen Treffer; die bewusste Vorautorisierung gilt ausschließlich für den **unmittelbar folgenden** automatisierten Gegner-Einzelangriff und nur, wenn die +5 RK den Treffer verhindert. Ein Spieler kann den Schildzauber in anderen SRD-zulässigen Situationen derzeit nicht nachträglich auslösen. Weitere Gegnerattacken pro Runde, Monsterzauber und Magisches Geschoss gegen Helden sind noch offen; das vollständige SRD 5.2.1 bleibt unvollständig.

**Wiederaufnahme:** Feature-PR auf GitHub kontrollieren, CI (Projekt-/Pythonprüfungen, Backend, Dart format/analyze/test, Android-JVM/APK) abwarten; alle Fehler korrigieren. Erst mit vollständig grünem CI-Run konfliktfrei nach `main` mergen, danach CI-ID, Commit und offenen Gerätetest nachtragen.

## Abgeschlossene Branch-Konsolidierung – 20.10.2026

**Branch-Bereinigung verifiziert (20.10.2026):** Alle neun historischen Feature-/Dokumentationsbranches waren bereits in `main` enthalten (`ahead_by=0`) und wurden über den geprüften einmaligen [GitHub-Actions-Lauf #39392381240](https://github.com/ManuEtt/Dnd/actions/runs/39392381240) entfernt. Auch der kurzlebige Maintenance-Branch ist gelöscht. Die GitHub-Branchliste wurde danach erneut gelesen: **nur `main` vorhanden**. Implementierte Features, Merge-Commits und Pull Requests bleiben erhalten; nichts wurde neu gecherry-pickt. Der temporäre Löschworkflow wurde nach erfolgreicher Bereinigung aus dem Hauptbranch entfernt. Prüfdokument: [`docs/BRANCH_RETIREMENT_20261020.md`](docs/BRANCH_RETIREMENT_20261020.md).

---

## CI-Abnahme und Integration – 20.10.2026 (0.8.18+68)

**CI und Merge bestätigt (20.10.2026):** [PR #46](https://github.com/ManuEtt/Dnd/pull/46) nach grünem [GitHub-Actions-Lauf #39386823499](https://github.com/ManuEtt/Dnd/actions/runs/39386823499), geprüfter Code-HEAD `81635c8eccb0d06e5d1bf95d54f5884c62f4a215`, erfolgreich in `main` integriert. Merge-Commit [`45160602b339c35e23e0d445f4e41e98b9b3dd5e`](https://github.com/ManuEtt/Dnd/commit/45160602b339c35e23e0d445f4e41e98b9b3dd5e). Erfolgreich: Struktur-/Python-Prüfung, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Unit-Tests, Alpha-APK-Artefakte und Quellcode-Checkpoint. **Noch offen:** echter Android-Gerätetest, vollständiges SRD, Held-Shield-Reaktion und verifizierte Gegner-Zauberlisten.

---

## 20.10.2026 – Shield-Reaktion des Gegners (0.8.18+68)

**Basis:** `main` `c48e1452a08057ecdc4f9f526b0b6b5d56903bcb`. Branch `feature/srd-enemy-shield-reaction-20261020`. **Status: Implementiert, CI noch nicht nachgewiesen.**

- Neues `Encounter`-Reaktionsmodell: `enemyShieldSlotsRemaining` (**null** = unbekannt, nicht geraten), `enemyShieldReactionUsed`, `enemyShieldActive`. Historische Spielstände bleiben ohne Änderung gültig, gefälschte unplausible Kombinationen werden beim Import abgewiesen.
- Ein Gegner darf Schild (`Shield`) nur als ausdrücklich bestätigte Reaktion auf `Magisches Geschoss` wirken, wenn vorbereiteter Zauber, verbal/gestische Komponenten, freie Reaktion und bestätigte verbliebene Zauberplätze vorliegen. Der gegnerische Zauberplatz wird genau einmal verbraucht, die Treffer verlieren alle Wirkung; der Held verbraucht trotzdem seine Aktion und den eigenen Zauberplatz. Keine Würfel werden für komplett blockierte Geschosse verbraucht.
- `enemyShieldActive` führt +5 RK bis **zum Beginn des nächsten Gegnerzuges**, sperrt weitere Magische Geschosse und wird bei `_enemyTurn` zurückgesetzt; gegnerische Reaktion wird dann erneut verfügbar.
- Der bestehende Magisches-Geschoss-Dialog bietet einen separaten bestätigten Shield-Reaktionszweig mit manueller initialer Gegnerzauberplatzanzahl. Der bisherige Weg ohne Schild bleibt erhalten, damit alte Controller- und Testaufrufe nicht unbemerkt andere Regeln ausführen.
- Tests für Schaden 0, Würfelaufrufe 0, Zauberplatz- und Reaktionsverbrauch, Shield-RK, Dauer bis zum nächsten Zug, Legacy-JSON, ungültige Daten, SQLite-Neustart und Revisionsschutz in `enemy_shield_reaction_rules_test.dart` und `enemy_shield_reaction_storage_test.dart`. CI/Android-Build **noch offen**, nicht als bestanden ausgeben.
- **Weiter offen:** `Shield` als Heldreaktion auf gegnerische Angriffe, Gegner-Zauberplätze aus verifiziertem Monsterstatblock, echte Monster-KI, tatsächliche Kartenpositionen, vollständig generische Reaktions-/Schadensregeln und Gerätetest.

**Wiederaufnahme:** [PR prüfen](https://github.com/ManuEtt/Dnd/pulls), vollständige GitHub-Actions-Ausführung für den **finalen** PR-HEAD abwarten, gemeldete Flutter-/Dart-/Backend-/Android-Probleme im Feature-Branch korrigieren. Erst bei vollständig grünem CI-Lauf konfliktfrei in `main` mergen; dann README, CHANGELOG, CHECKPOINT, Entwicklungsstatus und Matrix mit dem nachgewiesenen Workflow und Merge-Commit aktualisieren.

## CI- und Merge-Abnahme 20.10.2026 – Version 0.8.17+67

**CI-Freigabe und Integration 20.10.2026:** [PR #44](https://github.com/ManuEtt/Dnd/pull/44) wurde nach erfolgreich abgeschlossener [GitHub Actions #39383477544](https://github.com/ManuEtt/Dnd/actions/runs/39383477544) (finaler geprüfter Head `8f703b0002ae6dcb5279893020bea63e14771184`) nach `main` gemergt; Merge-Commit [`fa2ee36caff2c210eabaa651321b9591de46737f`](https://github.com/ManuEtt/Dnd/commit/fa2ee36caff2c210eabaa651321b9591de46737f). Bestanden: Struktur-/Python-Tests, Backend Typecheck/Build/Tests, Dart format, Flutter analyze/test, Android-Debug-Build, native Android-Tests und Release-APK-Artefakte. **Weiter offen:** echter Android-Gerätetest, vollständige Shield-Reaktionsmechanik, allgemeine Monster-Abwehr und komplette SRD-Abdeckung.

---

## Inkrement 0.8.17+67 – Gegnerische Energieschaden-Abwehr (20.10.2026)

**Basis:** `main` `5c0882644283b63225774d4e88f7e7fdd493dafe`, Branch `feature/srd-missile-force-defense-20261020`. **Status beim Erstellen: implementiert, CI-/APK-/Gerätetests noch nicht bestätigt.**

- `Encounter.enemyForceDefense` enthält nun `unknown`, `normal`, `resistant`, `immune` oder `vulnerable`. Historische Spielstände ohne Feld bleiben `unknown`, werden nicht rückwirkend umgedeutet. Falsche/unbekannte Importwerte werden zurückgewiesen. Keine SQLite-Tabellenmigration erforderlich (vorhandenes JSON-Ereignismodell).
- `EnemyForceDefenseRules` integriert `DamageRules` und wendet Resistenz (abrunden), Immunität und Verwundbarkeit auf **jedes einzelne Geschoss** an, nicht auf die Gesamtsumme. Alle Werte werden im `spell.magicMissile`-Journal (roh und angewendet) protokolliert.
- Neue Gegnerabwehr-Auswahl im bestehenden `MagicMissileDialog`: Ohne bestätigten Wert ist das Wirken gesperrt. Ein bereits gespeicherter bestätigter Wert kann beim nächsten Mal wieder verwendet werden; Änderungen müssen erneut bestätigt werden. Getrennte Pflichtbestätigung: Kein wirksamer Schildzauber (Shield). Kein unbestätigtes Gegnerprofil und keine KI-Erzählung erzeugen eine Abwehr.
- Zauberplätze, Runde, HP, Abwehr und Journal werden erst nach der Regelprüfung und der Bestätigung in derselben Repository-Transaktion gespeichert. Altes `noProtectionConfirmed`-API bleibt für bisherige Aufrufer kompatibel, sofern der Nutzer ausdrücklich keine Schutzwirkung bestätigt.
- Tests `enemy_force_defense_rules_test.dart`, `enemy_force_defense_storage_test.dart`, angepasster `magic_missile_dialog_test.dart`: Resistenz-Rundung je Geschoss, Immunität, Verwundbarkeit, unbekannter Altspielstand, manipulierte JSON-Werte, bestätigte UI-Auswahl, SQLite-Neustart, veraltete Revision. Bestehende Magic-Missile-Rollback-Tests bleiben erhalten.
- **Noch offen:** tatsächlich ausgeführter Shield-Reaktionszauber mit Ressourcen und Dauer, generisches getyptes Monster-Immunitätsprofil über alle Schadensarten, vollständiger Mehrzielkampf, Gegnerinventar und Gerätetest.

**Nächster Schritt/Wiederaufnahme:** vollständigen CI-Workflow auf dem finalen PR-HEAD verfolgen (Backend, Python, Dart format, Flutter analyze/test, Android-JVM und APK-Build). Fehler im selben Branch korrigieren; erst nach grünem Endergebnis mergen. Danach Merge-Commit und exakten GitHub-Actions-Lauf hier nachtragen.

## Abnahme- und Merge-Nachtrag 20.10.2026

**CI und Integration bestätigt (20.10.2026):** [PR #42](https://github.com/ManuEtt/Dnd/pull/42) wurde nach vollständig erfolgreicher [GitHub Actions CI #39381087593](https://github.com/ManuEtt/Dnd/actions/runs/39381087593) (geprüfter Head `78d89230281f8196edbff628ca243d591ef092b3`) nach `main` integriert. Merge-Commit: [`259dcf69fa2471c5546e1ba1b1003cef148e1cb9`](https://github.com/ManuEtt/Dnd/commit/259dcf69fa2471c5546e1ba1b1003cef148e1cb9). Erfolgreich: Python-Projektprüfung, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse/Tests, Android-Debug-APK, native JVM-Tests, drei Alpha-APK-Varianten und Artefaktbereitstellung. **Ein realer Gerätefunktionstest und die vollständige SRD-5.2.1-Abdeckung bleiben offen.**

---

## 20.10.2026 – Magisches Geschoss (SRD 5.2.1, Version 0.8.16+66)

**Ausgangsbranch:** `main` `963fe9e0eb38fb3f5595fe4325031cf619782f95`. **Status: Implementiert, GitHub-CI / Geräteabnahme noch offen.** Eine erfolgreiche CI darf erst nach einem beobachteten erfolgreichen Workflow dokumentiert werden.

- `MagicMissileRules`: ausschliesslich bestätigter Zauber eines eigenen Magiers/Zauberers (auch valide Zweitklasse), normale oder Paktmagie-Zauberplätze, 3 Geschosse bei Grad 1 +1 je höherem Zauberplatz, jedes einzeln `1W4+1` Energieschaden mit kontrollierter Zufallsquelle. Französische oder andere nicht nachgewiesene Schreibweisen werden nicht erfunden; Deutsch und Englisch ausdrücklich unterstützt.
- Zielprüfung: aktueller einzelner Gegner, Spieler bestätigt Sicht, max. 120 Fuß Reichweite, V/S-Komponenten und Fehlen bekannter Schutzwirkung; vollständige Deckung sperrt den direkten Effekt. Ungeprüfte Immunität, Resistenz, Schildzauber und Feindposition werden **nicht** automatisch abgeleitet.
- `GameEngine.castMagicMissile`: eigene Magieaktion, maximal ein zum Wirken verbrauchter Zauberplatz pro Zug, Kampfrausch-/Aktionsschub-/Wurfblockaden, Gegner-TP, Questabschlusspfad, Revisionssicherung und `spell.magicMissile`-Ereignis in einer atomaren Änderung.
- `GameController.castMagicMissile` mit `expectedRevision`; `MagicMissileDialog` mit Auswahl einer eigenen Zauberklasse, verfügbarer Plätze, Vorschau und expliziten Kontrollkästchen. Charakterwerte und Inventar bleiben unverändert, wenn die Prüfung fehlschlägt.
- Neue Tests: `magic_missile_rules_test.dart`, `magic_missile_storage_test.dart`, `magic_missile_dialog_test.dart`: Würfel, Skalierung, Klassen und Mehrklassen, Fehler vor Zufall, Spielzug, UI, JSON, SQLite-Neustart, Revisionskonflikt und Rollback. **Testausführung und Android-APK-Prüfung stehen beim Commit dieses Eintrags noch aus.**
- **Abgrenzung:** Nur ein Gegner ohne bekannte defensive Sonderwirkung; keine frei verteilten Geschosse an mehrere Ziele, keine autonome Monster-/Positions-/Gegenzauberlogik, kein Vollständigkeitsanspruch für SRD-Zauber.

**Wiederaufnahme:** PR-HEAD und offenen CI-Lauf ermitteln; `python3 scripts/verify_project.py`, `python3 -m unittest discover -s scripts/tests -v`, Backend `npm ci && npm run typecheck && npm run build && npm test`, Flutter `flutter pub get && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build apk --debug` und Android `./gradlew :app:testDebugUnitTest --no-daemon` kontrollieren. Fehler in eigenem Branch beheben, CI erneut durchführen, erst bei vollständigem Grün PR nach `main` integrieren und Testergebnisse dokumentieren.

## Abnahme- und Integrationsnachtrag – 20.10.2026

**Abnahme nach Merge:** [PR #40](https://github.com/ManuEtt/Dnd/pull/40) vollständig über [CI-Lauf 39378443958](https://github.com/ManuEtt/Dnd/actions/runs/39378443958) am Code-HEAD `3462106592157953473c7d777b0d5b664872243a` mit **success** geprüft: Projekt-/Python-Strukturtests, Backend-Typecheck/Build/Tests, Dart-Formatierung, Flutter-Analyse und Tests, Android-Debug-APK, native Android-Unit-Tests, drei Alpha-APK-Varianten und Artefakterstellung. Am 20.10.2026 konfliktfrei nach `main` gemergt: [`f7c6a68c09155880fd9a08b0c2f308d324b27b82`](https://github.com/ManuEtt/Dnd/commit/f7c6a68c09155880fd9a08b0c2f308d324b27b82). **Nicht geprüft:** echter Android-Gerätetest, Langzeitmigration auf Nutzergeräten, vollständiges SRD-Regelwerk.

---

## 20.10.2026 – SRD-Regelinkrement: bestätigtes Kriechen (0.8.15+65)

**Basis:** `main` `f06fb2ffac476ceec0dee2a4c6979d972e0c1a72`; Branch `feature/srd-crawling-20261020`, Code-Commit `72f51dd0b1af24069dc95bdd68f3535908f24024`, Test-Commit `4b0154dc85ad3e1a507baaddf82a018b31a725d1`. **CI-/Geräteabnahme vor Ausführung: offen.** Kein vollständiges SRD beansprucht.

- Neue `CrawlingMovementRules` berechnen die SRD-5.2.1-Bewegungskosten: pro Fuß Kriechstrecke 2 Fuß Bewegungsbudget beziehungsweise 3 Fuß bei bestätigtem schwierigem Gelände.
- `GameEngine.crawl` prüft aktiven eigenen Kampfzug, Liegend, Bewegungsbudget, Würfel-/Todesrettungsstatus und positive Geschwindigkeit. Die Aktion verbraucht weder Aktion noch Bonusaktion; zuvor bestätigte Deckung entfällt. Erzählung allein darf das Gelände nicht bestimmen.
- Neues „Kriechen“-Menü in der Abenteuer-UI: 1,5 m oder 3 m, jeweils normales oder schwieriges Gelände, mit vorab angegebenen Kosten. Auswahl bestätigt genau diese regelgeprüfte Bewegung.
- `GameController.crawl` verwendet Revisionsschutz und atomaren `combat.crawled`-Ereigniseintrag; aktuelles Schema und historische Speicherstände bleiben unverändert.
- Neue Tests `prone_crawling_rules_test.dart` und `prone_crawling_storage_test.dart` für Terrainkosten, Statussperren, Budget, Dezimeter, JSON-Rundlauf, SQLite-Neustart, veraltete Revision und Transaktions-Rollback. **Vor GitHub-Actions-Ausführung nicht als bestanden kennzeichnen.**
- **Offen:** vollständiges Positions-/Kartensystem, Gegnerbewegung, Terrain aus verifizierter Kartengeometrie, umfassende Zauber-/Klassen-/Monsterregeln, Android-Geräteabnahme.

**Prüf- und Wiederaufnahmebefehle:** `python3 scripts/verify_project.py`, `python3 -m unittest discover -s scripts/tests -v`; in `backend/`: `npm ci && npm run typecheck && npm run build && npm test`; in `app/`: `flutter pub get && dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test && flutter build apk --debug`; in `app/android/`: `./gradlew :app:testDebugUnitTest --no-daemon`. CI/PR prüfen, Abweichungen beheben, **erst bei Grün** in `main` mergen. Danach hier Merge-SHA und GitHub-Actions-Lauf dokumentieren.

## 19.10.2026 – Integration statt konkurrierender Entwicklungszweige

Neuer Branch `integration/character-creation-20261019`: PR #11 in `main`, getypte Ausrüstung und Startkampfwerte aus PR #9 ergänzt (drei konfliktfreie Code-Diff3-Dateien plus neue Module und Tests). PR #10 und #11 hatten konkurrierende Aufstiegsassistenten. Einziger verbleibender Dialog ist `SrdClassLevelUpDialog`; die einzigartige ASI-Validierung und rückwirkenden Konstitutions-TP aus PR #10 wurden dort und im Regelmodul eingearbeitet. Die Integrationsregressionen sind neu zu prüfen. Gemeinsame Tests/CI/Android-Build noch ausstehend; keine hundertprozentige SRD-Abdeckung behaupten.

## 19.10.2026 – RK/Bewegung grün im CI

Für PR #9: Verifizierter GitHub-Lauf [39201449428](https://github.com/ManuEtt/Dnd/actions/runs/39201449428), Code-HEAD `2f7ecb15`: Backend-, Dart-Format-/Analyse-, alle Flutter-/Widgettests, Debug-APK, native Android-Tests und kompakte Alpha-APKs erfolgreich. Die vorherige Teststörung (Lazy-ListView Finder bei nicht sichtbarem Bewegungsfeld) wurde korrigiert. Der Sourcecode-Fix inklusive exakter 10,5-m-Spezieswerte ist erfolgreich getestet; Android-Gerätetest und Integration in `main` noch offen.

---

## 19.10.2026 – Fehlerbild Rüstungsklasse und Bewegung ohne Startwerte

Bei der Charaktererstellung wurden `armorClass` und `speed` bisher nicht aus der gewählten SRD-Spezies und den bestätigten Attributen vorbelegt. Der Fix setzt Grund-RK 10 + GE bzw. die relevanten ungerüsteten Klassenmerkmale (Mönch WEI, Barbar KON). Bewegung wird über explizite Speziesnamen gesetzt (meist 9 m, Goliath/Waldelf 10,5 m), mit rückwärtskompatiblem optionalem halben Meter im Hero-JSON. Beim Import alter/anderer Figuren werden keine Werte erraten oder überschrieben; die UI bietet einen gesonderten Button „Fehlende RK und Bewegung berechnen“. Ausrüstung wird weiterhin gesondert angelegt und mit dem bestehenden SRD-EquipmentRules-Dialog berechnet.

Neue Domain-/Widgettests vorhanden, **diese Änderung muss noch durch die neueste CI verifiziert werden**. PR #9 bleibt vorläufig Entwurf, PR #8 ist davon getrennt. Das Gesamt-SRD ist weiterhin nicht vollständig implementiert.

---

## 19.10.2026 – Fehlerbehebung Klassen-Startausrüstung

Root Cause bestätigt in `CharacterEditor._configureSrdClass`: Einträge aus dem SRD-Klassenset wurden bisher ohne `catalogId` und `stats` erstellt, obwohl der SRD-Katalog diese Attribute besitzt. Neuer validierter Resolver `StartingEquipmentImport`: exakte Namen, selektiv geprüfte Aliasnamen, richtige Packgröße für 20 Pfeile, unbekannte Auswahlen ohne erfundene Werte. Der bestehende Katalogimport übernimmt jetzt verfügbare Kataloghinweise. Eingehende Gegenstände mit expliziter `catalogId` und fehlenden Stats werden vervollständigt; Benutzerwerte bleiben immer erhalten. Eigener Bestätigungsdialog für ältere Klasseninventare im Charaktereditor. Domain-/Widgettests ergänzt.

Entwicklungsbranch: `fix/equipment-import-attributes-20261019` ab `82f2786b`, PR #8 bleibt separater ungemergter Entwicklungszweig. Gesamtregelwerk ist nicht vollständig; SRD-5.2.1-Anforderungsmatrix und künftige vertikale Klassen-/Zauber-/Kampf-/Erkundungstests sind nötig. Build-/APK-Abnahme für diesen neuen Fix noch ausstehend.

---



---

## 19.10.2026 – Klassenaufstieg und Erstellungsprüfung (laufender PR)

Branch `feature/srd-character-level-up-20261019`: neue regelgeprüfte Stufe +1 für alle 12 vorhandenen Klassen, inkl. bereits gewählter Zweitklasse, bestätigter fester Trefferpunkte, gültiger XP-Schwelle oder ausdrücklichem Meilenstein, Klassentabellen-Vorschau und Persistenz offener Entscheidungen als Notiz. Neue SRD-Erstellungsprüfung für Stufe-1-Daten mit klaren Hinweisen auf noch nicht implementierte Herkunfts- und Klassenentscheidungen. Tests für Domäne und UI angelegt.

**Stand vor endgültiger CI: NICHT ABGENOMMEN.** Weder alle Klassenmechaniken noch das vollständige SRD 5.2.1 sind implementiert. Offene Regel-ID-Matrix und nächste Arbeiten siehe `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md`.

---

## 19.10.2026 – SRD 5.2.1 Aufstehen aus „liegend“

Nach der Übernahme von PR #7 in `main` wurde der neue Branch `feature/prone-stand-movement-20261019` von `82f2786b` abgezweigt. Implementiert sind ein ausdrückliches Aufstehen mit bestätigter Bewegungsrate, genauem Fuß-Rundungsmodell im vorhandenen Meter-System (Dezimeterrest), Abzug des verbleibenden Budgets, Schutz bei Bewegungsrate 0/Handlungsunfähigkeit/noch aktiver Quelle und ein deutscher Abenteuer-Button. `GameController` prüft die erwartete Revision und persistiert Ereignis + Bewegungsstand gemeinsam in SQLite. Ein Editor kann den Zustand während des Kampfes nicht ohne Bewegungskosten löschen; normales Gehen im Liegen wird nicht als kostenloser Lauf gewertet.

Neue Regeln und Speicherregressionen: `prone_standing_rules_test.dart`, `prone_standing_storage_test.dart`. Schema-Version 1 bleibt erhalten; neue Bewegungsreste sind optional. **Abnahme und Android-Build noch zu überprüfen**, ebenso echte Geräteinteraktion, Kriechen, Fremdziele und Positionen. Dokumentation in README und CHECKPOINT nachführen, sobald der vollständige PR-Workflow erfolgreich ist.

---

## Weiterentwicklung 19.10.2026 – Bewusstlos bewirkt bleibendes Liegend

Der geprüfte Featurebranch `feature/condition-source-ledger-20261018` (PR #7, letzte grüne Basis `c000e78b` / Actions 39165288268) wird um die SRD-5.2.1-Folge `bewusstlos` → `liegend` erweitert: neue Bewusstlosigkeit aus Schaden, Todesrettungen, Quellzuständen und bestätigten Charakteränderungen setzt `liegend` getrennt. Die Folge überlebt das Aufwachen, Quellenende und JSON-/SQLite-Bestätigung; Legacy-Daten werden beim Lesen nicht automatisch migriert. Handlungsunfähigkeit durch bestätigte Charakterbogenänderung beendet Konzentration. Acht neue Testfälle sind unter `unconscious_prone_test.dart` eingereicht.

**Prüfstatus dieses Inkrements: NICHT ABGENOMMEN.** Neue GitHub-Checks, APKs und Gerätetests erst nach verifiziertem Erfolg eintragen. Nächster Schritt: offizielle Dart-Formatierung, kompletter CI-Lauf, eventuelle Testkorrekturen, danach reale Android-Abnahme. Weitere SRD-Folgen (Fallenlassen gehaltener Gegenstände, Aufstehen/Kriechen und Positionsregeln) noch offen.

---

## Laufender GitHub-Entwicklungsbranch – quellgebundene Zustände (18.10.2026)

- PR [#7](https://github.com/ManuEtt/Dnd/pull/7) gegen `main`; kein Merge und keine Veränderung von `main`.
- Quellenabhängige 2024-SRD-Zustände als eigene validierte `ConditionEffect`-Einträge, optionales JSON-Feld, deduplizierte effektive Zustände. Reine Domänenaktionen für Einzelentfernung, Gesamtentfernung und eigenen Zugendpunkt; vorhandene Regelmutatoren bewahren die Trennung.
- Regelanzeige/Quellenanzeige im Charakterbogen; manuelle Einträge bleiben separat editierbar. Neue Domain-/Widgettests wurden eingereicht; Ergebnis des endgültigen PR-CI ist vor Freigabe zu prüfen.
- **Ergänzt im gleichen PR:** bestätigte UI-/Controller-Aktionen für Quellen und Einzelentfernung; neue Handlungsunfähigkeit beendet Konzentration/Rage/Dodge sofort. Domänen-, Dialog- und SQLite-Konflikt-/Rollbacktests ergänzt. README aktualisiert.
- **Noch offen:** erfolgreiche endgültige CI-/APK-Abnahme aller Änderungen, Geräteabnahme, allgemeine Weltzeit und breitere SRD-Effektmechaniken. Keine vollständige SRD-Abdeckung behaupten.
- Checkpoint: PR #7 und dieser Branch. Ein neuer Lauf muss HEAD/PR-Checks erneut abfragen und erst bei grünem Status weiter integrieren. Kein automatischer Codex-Workflow.

## Abschlussprüfung 0.7.9+49 (18.10.2026)

**692 Flutter-, 31 Backend-, 56 Python- und 12 native Androidtests bestanden, 0 Fehler/Skips.** Analyse/Format sauber, korrigierte Debug-APK aus entpacktem geprüftem ZIP gebaut; Integrität, Metadaten, Signatur und 203 Quell-/Test-/Builddateien verglichen. Geprüfter Codecommit `99b8a7bbed9c07132bf49e5eb78be9cfeb391d71`; finale Dokumentation folgt separat. GitHub-Push erneut HTTP403, main unverändert; ZIP/Patch/Importanleitung vorhanden. Exakte Fortsetzung: CHECKPOINT.md, Prüfbericht docs/VALIDATION_0_7_9.md.

Nächster zusammenhängender Schritt: quellgebundene Zustände/Dauern gemäß docs/CONDITION_EFFECT_DESIGN.md implementieren, mit Trennung manueller/abgeleiteter Zustände und echten UI-/Speichertests. Danach Konzentrationswiederholungen/Reaktionen sowie weitere echte Ziele/Zauber-/Monsterwirkungen. Keine vollständige SRD- oder Geräteabnahme behauptet. Vor neuer großer Arbeit einen vollständigen Ausgangscheckpoint sichern; beobachtete frühere Teilagenten-Limitwarnungen nicht durch Credits/Resets umgehen.

## 0.7.9+49 – Todesrettungen mit Klassenentscheidung (18.10.2026)

- Todesrettungen verwenden jetzt Mönch-14-Rettungswurfübung und den Erschöpfungsmalus genau einmal. Natürliche 1/20 behalten ihre Sonderfolgen; Kämpfer-9-Unbeugsam addiert beim Ersatzwurf die tatsächliche Kämpferstufe.
- Ein fehlgeschlagener Wurf mit verfügbarer Wiederholung bleibt vorläufig: deutsche Auswahl zum Annehmen oder Wiederholen, mit Neustart erhaltener Entscheidung. Auch ein drohender dritter Fehlschlag lässt sich ersetzen. Verbrauch und Folgen werden erst gemeinsam bestätigt.
- Im aktiven Solokampf nur eine Todesrettung pro eigenem Zug; anschließend bewusstlos den Zug beenden oder nach natürlicher 20 normal fortsetzen. Gegnerzug, offene Entscheidung, veraltete Oberfläche und manipulierte Importe sind gesperrt.
- Kampfrausch und Ausweichen enden auch bei extern bestätigtem KO und beim Bestätigen handlungsunfähiger Charakterzustände sofort; spätere Heilung reaktiviert keinen alten Kampfrausch.
- 57 neue gezielte Fälle sowie 10 bestehende Erschöpfungsregressionen erfolgreich: 19 Todesrettungs-Domänenfälle, 18 Ablauf-/UI-/SQLite-Fälle und 20 Zuggrenzenfälle. Gesamtprüfung und Android-Build werden separat in CHECKPOINT.md nachgewiesen. Quelle und genaue Grenzen: docs/DEATH_SAVES_0_7_9.md.

## 0.7.8+48 – Korrekte eigene Zuggrenzen (17.10.2026)

- Reines Zugende trotz Handlungsunfähigkeit, auch für stabile bewusstlose Figuren; eigener UI-Button und atomare SQLite-Speicherung. Keine Ausweichaktion durch Textbeimischung.
- Kampfrausch endet vor dem folgenden Gegnerangriff, wenn sein Endzeitpunkt erreicht ist, sowie endgültig bei Handlungsunfähigkeit. Ausweichen verliert Wirkung bei Handlungsunfähigkeit, Sichtverlust oder Bewegungsrate0; positive halbe Meter bleiben positiv.
- Mönchs-Selbstwiederherstellung kann ohne Aktion vor dem eigenen Zugende ausgewählt werden. Feindlicher Initiative-Erstzug löst kein eigenes Zugende aus.
- 17 neue Grenz-/UI-Tests erfolgreich; aktuelle Analyse ohne Befunde. Generische Zustandsdauer bleibt ausdrücklich Entwurf, siehe docs/CONDITION_EFFECT_DESIGN.md.

## Abschlussprüfung 0.7.7+47 (17.10.2026)

**635 Flutter-, 31 Backend-, 56 Python- und 12 native Androidtests erfolgreich**, keine Skips/Fehler; Analyse und Formatierung sauber. Debug-APK tatsächlich aus entpacktem Quell-ZIP gebaut, Integrität/Metadaten/Signatur geprüft. Gerät/Emulator/Updatesignatur nicht abgenommen. GitHub-Write HTTP403; main unverändert. Finale ZIP-/Patch-/Hash-Artefakte und exakte Fortsetzung in CHECKPOINT.md; ausführlicher Prüfbericht docs/VALIDATION_2026_10_17.md. Umfang bleibt eine Teilmenge des SRD5.2.1.

## 0.7.7+47 – Ausführbare Heilzauber im Spiel (17.10.2026)

- Wunden heilen und Heilendes Wort wirken auf den eigenen Charakter: 2024-Würfel (2W8/2W4 pro tatsächlichem Platzgrad), eigenes Klassenattribut, Hochstufung, normale/Pakt-Plätze und Lebensdomänenboni (Kleriker 3/17).
- Deutsche Auswahl mit Klassen-/Platz-/Komponentenbestätigung direkt im Abenteuer/Kampf. Ereignis, TP, Platz und Aktion werden atomar bestätigt; keine automatischen Regeln aus Erzähltext.
- Persistenter Zugschutz: nur ein Platzverbrauch für Zauberwirken je Zug, gemeinsam für normale und Paktplätze; reset erst beim nächsten eigenen Zug. Alte Begegnungen bleiben lesbar. Action Surge erlaubt keine zusätzliche Magieaktion.
- 26 Domain-, 13 Dialog- und 9 Integrationsfälle geprüft. Vollständige Formatbereinigung und verpflichtende Formatprüfung im normalen Test-/Buildworkflow, keine autonome Codex-Action.
- Vollständige Suite und Android-Prüfung werden im aktuellen CHECKPOINT.md getrennt nachgewiesen. Umfang/Grenzen: docs/CHARACTER_EFFECTS_AND_HEALING.md.

## 0.7.6+46 – Ausführbare Charaktereffekte (17.10.2026)

- Gemeinsamer Schaden-/Konzentrationsablauf für bestätigte externe Quellen und Gegnerangriffe: Abwehr vor temporären/echten TP; auch absorbierter Schaden löst Konzentration aus.
- Deutsche Oberfläche für Schaden, Heilung und temporäre TP mit Quelle und bestätigten Abwehrregeln. Atomare Speicherung und Revisionsschutz für offene Dialoge.
- Versteinert-Schadensresistenz und automatische Stärke-/Geschicklichkeitsfehlschläge bei gelähmt/versteinert/betäubt/bewusstlos; betäubt sperrt Bewegung nach 2024 nicht generell.
- 50 gezielte Domain-/Kampfregressionen, 6 Dialogtests und 7 echte UI-/SQLite-Tests erfolgreich; Flutter-Analyse ohne Befunde. Details im Checkpoint.

## 0.7.5+45 – Verifizierte Korrekturen (17.10.2026)

- Basis `b66354f3112165d76aa340a2f2ab5705f8019e1a`, eigener Branch `feature/autonomous-srd-engine-20261016`; keine Änderung von main.
- Erschöpfte offene Proben überleben Speicherung/Neustart. Schaden bei 0 TP mit temporären TP korrigiert. Zwei Backendfehler korrigiert (leere Handlungsstränge, Redirects).
- Flutter 3.35.7/Dart 3.9.2 lokal installiert: Analyse ohne Befunde; Suite 544 erfolgreich, 1 optionaler Backend-Protokolltest übersprungen. 30 gezielte Flutter-Regressionsfälle erfolgreich. Backend unter CI-Node 22.14.0: Typecheck, Build und 31 Tests erfolgreich.
- Ursprüngliche Formatprüfung meldete 84 unformatierte Dateien; Formatbereinigung folgt isoliert nach Integration. Android-Build/Gerät weiterhin gesondert nachzuweisen.
- `docs/RULE_COVERAGE.md` und `CHECKPOINT.md` sind die aktuelle Fortsetzungsbasis. Allgemeine Effekte/Heilzauber folgen als getrennte Inkremente.

## 0.7.4+44 — Tatsächliche Implementierung (16.10.2026)

- **BASIS:** vollständiges Quellprojekt 0.7.3+43; GitHub `main` wurde bei der Entwicklung als 0.7.2+42 (`91ffddd`) gelesen.
- **NEU:** Paladin-Handauflegen (Bonusaktions-/Ressourcenlogik und Entgiftung), Mönch-15-Perfect-Focus in der Initiative, explizite W20-Rettungswürfe mit Mönch-14- und Kämpfer-9-Wiederholungswurf, Speicherung/Ereignisse/UI.
- **GEPRÜFT:** 38 Python-Projekttests, Projektdateistruktur, Patch-/ZIP-Integrität nach Verpackung.
- **OFFEN:** Flutter analyze, Dart-Test-Suite, Android-Build, echte Gruppenmitglieder, automatisch ausgelöste Rettungswürfe aus allen Quellen, verbleibende SRD-Regelengine. Die 1.247 Anforderungen sind keinesfalls vollständig umgesetzt.
- **DETAILS:** `docs/CLASS_ACTIONS_AND_SAVES_0_7_4.md`.

## 0.7.3+43 – Mönch-Selbstwiederherstellung und alle Rettungswurfübungen (16.10.2026)

- **BASIS:** GitHub `ManuEtt/Dnd` main `91ffddd246a3aa07780bf1bbafa9ce2c17726e21` / 0.7.2+42.
- **IMPLEMENTIERT:** Stufe-10-Selbstwiederherstellung am Ende eines bestätigten eigenen Kampfzugs, eindeutige Zustandsauswahl bei mehreren, optional gespeicherte Auswahl und Ereignisnachweis; Stufe-14-Rettungswurfübung (alle sechs, ohne doppelte Berechnung); CI-Fix `monk_flurry_rules.dart` für `int?`.
- **GETESTET:** Projektstruktur, 38 Python-Projekttests, ZIP-/Patchintegrität (siehe Übergabebericht).
- **NICHT GETESTET:** Neue Dart-Domain-/Widgettests, `flutter analyze`, vollständige Flutter-Test-Suite, Android APK und Gerät. Kein Flutter SDK vorhanden.
- **OFFEN:** Disziplinierter-Überlebender-Wiederholungswurf nach fehlgeschlagener Rettung, Hunger-/Durst-Erschöpfungslogik, weitere Klasse- und Ziel-Effekte, voller Android-Build.
- **QUELLE:** SRD 5.2.1, CC BY 4.0. Siehe `docs/MONK_SELF_RESTORATION_0_7_3.md`.

## 0.7.2+42 – Temporäre Trefferpunkte, Monk Heightened Focus (16.10.2026)

- Basis: GitHub `ManuEtt/Dnd`, Commit `73c5bfe5f39b5f3189eec5dc5aeeebe5fc083fa2` (0.7.1+41).
- Implementiert: temporäre TP als getrennte, persistierte Ressource; Schaden absorbieren, HP-Überhang korrekt berechnen, Verlust nach Langrast, Anzeige und Ereignisnachweise.
- Geduldige Verteidigung auf Mönchsstufe 10+: 2 Kampfkunstwürfel für einen Fokuspunkt, Schutz gegen Stapelung.
- CI-Hinweis `unnecessary_non_null_assertion` aus GitHub-Actions-Lauf 38866660863 korrigiert.
- Neue Dart-Domain-/Widgettests enthalten; Flutter-/APK-Tests erst nach CI als bestanden melden.

## 0.7.1+41 – Schlaghagel als ausführbare Bonusaktion (16.10.2026)

- **BASIS:** GitHub `main` `47b549125d95973b2d9e066e9a2401488ef322d2` (0.7.0+40).
- **NEU:** zwei beziehungsweise drei unabhängige Mönchs-Unarmed-Strikes nach SRD 5.2.1; Fokuspunktverbrauch, Bonusaktionslimit, eigener Treffer-/Krit-/Schadenswurf, Mehrklassen-Skalierung, Siegauflösung, UI-Schaltfläche und JSON-Persistenz ohne Schemaänderung.
- **CI-FIX:** Fehler aus Run `38857593290` (473 Tests erfolgreich, 2 fehlgeschlagen) gezielt adressiert: `6 m`-Widget-Erwartung und Eingabe „Ich weiche aus“ in laufender Angriffsaktion.
- **TESTS:** neue Dart-Domain- und Integrationsregressionen vorhanden, Flutter/Android in dieser Umgebung nicht ausgeführt. Weitere Grenzen `docs/MONK_FLURRY_0_7_1.md`.
- **GITHUB:** Repository nicht geschrieben; vollständiges ZIP und Patch separat zur Übergabe. Keine APK behauptet.

## 0.7.0+40 – Mönchsfokus & Rückzug (16.10.2026)

- **Neu**: Patient Defense (0/1 Fokus), Step of the Wind (0/1 Fokus), Flinke Aktion: Rückzug; gemeinsamer Bonusaktionsverbrauch, Speichern/Laden der temporären Kampfzustände, Ausweichnachteil beim Gegnerangriff.
- **Tests**: `app/test/monk_focus_actions_test.dart` ergänzt. Python/Flutter/Android-Ergebnisse gesondert dokumentieren; keine nicht ausgeführten Tests als bestanden ausweisen.
- **Grenzen**: Noch keine Flurry of Blows, Level-10-Temp-TP, Gelegenheitsangriffe oder Sprunggeometrie. Die neuen Flags sind keine Belege für deren vollständige Automatisierung.
- **Ausgangsbasis**: GitHub main 7cd36e9bcb7a4533d34bcc95a77ba83d86c2fc4e / 0.6.9+39.

## 0.6.9+39 — Kampf-Klassenaktionen (2026-10-16)

- **IMPLEMENTIERT:** Barbaren-Kampfrausch (Bonusaktion, Ressource, Rundenablauf, Nahkampfbonus, explizit typisierte Resistenz), Flinke Aktion: Sprinten und bestätigter Hinterhältiger Angriff.
- **GETESTET:** Projektstruktur und 38 Python-Tests; ergänzte Flutter-/Dart-Tests noch nicht ausgeführt.
- **OFFEN:** Vollständiges Rage-/Zauber-/Positions-/Reaktionssystem; siehe `docs/CLASS_ACTIONS_0_6_9.md`.
- **GITHUB:** Projektpaket und Patch vorbereitet; kein Commit oder APK-Build behauptet.

## 0.6.7+37 – Fighter-Ressourcen (16.10.2026)

- Basis: GitHub `main` (`de88027f842a9dca80dd58ffccedb5a961551338`).
- Implementiert: Second-Wind-Ressourcen und Heilung als Bonusaktion; Action-Surge-Ressourcen und reservierte zweite Angriffsaktion im vereinfachten Kampf, Einzel-Zuglimit, Kurz-/Langrast-Regeneration und Speicherkompatibilität.
- Behoben: Flutter-Analyzer meldete `dangling_library_doc_comments` in `damage_rules.dart`; freistehenden Kommentar korrigiert.
- Tests: Neue Unit- und Kampfintegrationstests enthalten; Python-Projekttests lokal bestanden. Flutter analyze/test, Backend-Abnahme und Android-APK **nicht lokal ausgeführt**.
- Grenzen: Action Surge im Demo-Kampf nur zusätzliche Angriffsaktion; Tactical Mind, Tactical Shift, Rage und andere Klassenmerkmale noch offen.
- Importhinweise: `docs/CLASS_RESOURCES_0_6_7.md`.

## 0.6.6+36 – SRD-Klassenfortschritt und Extra Attack (16.10.2026)

- Basis: Repo `ManuEtt/Dnd` Commit `26d1d8b` (enthält 0.6.5+35).
- Klassenstufen-spezifische reguläre Extra-Attack-Mechanik integriert, einschließlich Fighter 11/20 und Mehrklassenregel ohne Stacken.
- Zusätzliche Attacken innerhalb einer Angriffsaktion werden einzeln im Kampfsystem abgewickelt. Verbleibende Angriffe in `Encounter` persistiert; altes Schema 1 weiterhin lesbar.
- Charakterbogen um bestätigte Angriffe pro Angriffsaktion und **nur vorausschauende** Meilensteine ergänzt.
- Testerweiterungen: `class_progression_rules_test.dart`, `class_progression_combat_test.dart`.
- Nicht behauptet: vollständiges Level-up, Unterklassen-/Talentwirkungen, vollständiges Aktionssystem, Flutter-Test, Android-Build oder GitHub-Push.

## 0.6.5+35 – SRD-Schadensauflösung und CI-Korrektur (16.10.2026)

- **BASIS:** GitHub `main` `49c8c39af045c6d0e3a78eba23e95383c3c31a84`, identische ursprüngliche Datei-Blob-SHAs aus Actions-Quell-Checkpoint.
- **CI-BLOCKER-KORREKTUR:** Bewegungsformatierung im Charakterbogen liefert bei ganzzahliger Geschwindigkeit `9 m` statt `9.0 m`; halbe Meter bleiben erhalten. Widget-Regression ergänzt. Basis-CI: 413 Tests bestanden, 1 fehlgeschlagen (Charakterbogen).
- **REGELKORREKTUR:** Konzentrations-SG hat gemäß SRD 5.2.1 eine maximale Schwierigkeit von 30; Grenztests ergänzt.
- **NEUE REGELKOMPONENTE:** `DamageRules` für 13 Schadensarten, Resistenz, Anfälligkeit, Immunität, Nicht-Stapelung, Reihenfolge und Mehrfachkomponenten; bewusste `RulesEngine.damageWithDefenses`-Integration. Keine Spezies-/Monsterresistenz aus Freitext erraten.
- **NACHWEIS:** Projektstruktur und 38 Python-Tests lokal erfolgreich. Neu angelegte Flutter-/Dart-Tests, Analyzer und APK-Build **noch nicht ausgeführt**, weil kein Flutter SDK verfügbar ist.
- **OFFEN:** Automatische Anbindung an Monster/Zauber/Charakter-Defensivdaten; vollständige Klassen- und Zauberengine; GitHub-Push (Schreibrechte verweigert, 403). Kein installierbares APK behauptet. Siehe `docs/SRD_DAMAGE_RULES.md`.

## 0.6.4+34 – Zauberressourcen in der gemeinsamen Regelengine (15.10.2026)

- **BASIS:** vollständiges 0.6.3+33-Quell-ZIP; Entwicklung unabhängig von Codex.
- **IMPLEMENTIERT:** `SpellcastingRules`, getrennte Verbrauchspools für normalen Zauberplatz und Paktmagie, persistierte Konzentration; Eingabe über Charaktereditor; Anzeige im Charakterbogen, Rast- und Kampfintegration, Einbeziehung bestehender Modifikatoren für Konzentrationsrettungswürfe; Sicherung und Importvalidierung ohne Schemawechsel.
- **TESTS ERGÄNZT:** `spellcasting_rules_test.dart` und `spellcasting_dialog_test.dart`.
- **NICHT GETESTET:** Neue Dart-Tests, Flutter-Analyse, Android-/Geräte-Build. Kein Flutter SDK vor Ort. Projekt-/Python-Tests getrennt prüfen.
- **OFFEN:** SRD-Zauberkatalog und Zaubergradvalidierung, Aktionsökonomie, Zauberwirkungen, manuelle Konzentrationsrettungen, sonstige Schadensquellen. `docs/SPELLCASTING_RESOURCES.md`.
- **GITHUB:** Kein Push behauptet, keine Codex-Action hinzufügen.

## 0.6.3+33 – bereichsübergreifende D&D-Regelengine (15.10.2026)

- **AUSGANGSBASIS:** Vollständiges Quell-ZIP 0.6.2+32; unabhängig von Codex fortgeführt. Keine GitHub-Änderungen vorgenommen.
- **IMPLEMENTIERT:** Gemeinsamer `CharacterRuleEngine`-Zugriff auf bestätigte Charakterdaten für Initiative, Angriffe, Fertigkeits-/Attributsproben, Rettungswürfe und effektive Bewegung. Erschöpfung, wichtige Zustandsfolgen, Rüstungs-/Waffen-Grenzen und Vorteils-/Nachteilsregeln werden berücksichtigt.
- **KOMPONENTEN:** `GameEngine`, `DiceEngine` via versioniertem `PendingRoll`, Charakterbogen, Ausrüstungsvorschau, Charaktermodell und Eventjournal angeschlossen. Ältere PendingRoll-JSON-Daten enthalten keine neuen Pflichtfelder. Ein AI-Erzähler kann keine eigenen Regelwerte bestätigen.
- **GETESTET:** Projektstruktur und 38 Python-Tests lokal. Neue Dart-Domain- und Widgettests vorhanden. **NICHT GETESTET:** Flutter Analyze, Flutter Unit-/Widgettests, Backend-CI, neue APK und physische Geräteabnahme; Flutter-SDK fehlt in lokaler Umgebung.
- **OFFEN:** Kontextabhängige Zustände/Zauber, Konzentration, begrenzte Zauberplätze, Ressourcen, vollständige Aktionsökonomie, alle SRD-Monster-/Klassenaktionen; schrittweise mit auditierbaren Tests ergänzen.
- **DETAILS:** `docs/UNIFIED_RULE_ENGINE.md`.

## 0.6.2+32 – SRD-Zustände und Erschöpfung (15.10.2026)

- **Basis:** Vollständiges ZIP 0.6.1+31, mit aktuellem GitHub-`main` 45862495f9da abgeglichen. Android CI #38749928875 für 0.6.1+31 war erfolgreich.
- **IMPLEMENTIERT:** Optionale Erschöpfungsstufe 0–6 im Charaktermodell, sichere Importvalidierung, Unveränderlichkeit historischer Snapshots, Tod bei Stufe 6; W20-Mali bei Angriff/Initiative/Wahrnehmung/Todesrettung und reduziertes Kampfbewegungsbudget. Lange Rast reduziert Erschöpfung um eine Stufe. Konservative Auflistung von 14 weiteren SRD-Zuständen mit ausgewählten Aktions-/Bewegungsblockaden; eigener Editorbereich.
- **EINGESCHRÄNKT:** Keine automatisch bestätigte Spielzeit/Dauer, keine automatische Erschöpfungsursache, nicht alle Zauber/Rettungswürfe/Zustandsregeln flächendeckend in jeder Engineaktion angebunden; siehe `docs/CONDITIONS_EXHAUSTION.md`.
- **GETESTET:** Python-Projektstruktur und 38 Python-Regressionstests; neue Dart-Tests ergänzt. **NICHT GETESTET:** Dart-Analyse, neue Dart-Tests, Android-APK und reale Geräteinstallation mangels Flutter-Toolchain.
- **Nächster Schritt:** Gegen laufende Codex-Änderungen auf eigenem Branch zusammenführen, GitHub-CI ausführen, Fehler beheben, danach Gerätetest.

## 0.6.1+31 – Flutter-Analyzer und Rast-Testfixtures (15.10.2026)

- **BEHOBEN:** `srd_equipment_catalog.dart` verwendet für das Gewicht eine einfache Stringinterpolation (`$weightLb`), wodurch der in CI reproduzierte Analyzer-Lint `unnecessary_brace_in_string_interps` entfällt. Keine Änderung der Ausrüstungswerte.
- **BEHOBEN:** Die `HeroCharacter.fromJson`-Fixture in `app/test/rest_rules_test.dart` enthält wieder die erforderliche `species`-Angabe `Mensch`. Sieben vorangegangene Testfehler waren `FormatException: Spezies ist ungültig.` beim Aufbau der Fixture, nicht Regel-Aussagen. Der produktive Importvalidator bleibt unverändert.
- **BASIS:** `main` `0963303fe4802aae9c42739b267e6d33057ef63d`, GitHub Actions #38746011222 (Analyzer-Fehler); früherer Rast-Testlauf #38734808085. Die geänderten Ausgangsdateien wurden gegen ihre Git-Blob-SHAs geprüft.
- **PRÜFUNG:** Projektstruktur, Python-Tests, ZIP/SHA256 sowie saubere Anwendung des Git-Patches auf `0.6.0+30`. Flutter SDK ist in dieser Umgebung nicht vorhanden: `flutter analyze`, `flutter test` und Android-APK-Build sind für 0.6.1+31 **noch nicht nachgewiesen**.
- **NÄCHSTES:** Auf separatem Branch übernehmen, kompletten GitHub-CI-Lauf ausführen; bei neuen Testproblemen Logs analysieren und beheben; bei grünem Lauf APK verwenden. Codex-Actions nicht reaktivieren.

## 0.6.0+30 – Bestätigtes SRD-Ausrüsten (15.10.2026)

- **IMPLEMENTIERT:** Domain-Modul `equipment_rules.dart` mit reiner Vorschau und erneuter Berechnung bei Bestätigung; Inventory-basiertes Anlegen von Rüstungen/Schilden/Waffen und RK-/Waffenwert-Updates im Editor; optionale Felder für ausgerüstete Inventar-Instanz-IDs. Kein heimlicher Goldabzug/Magieeffekt. Quellen/Ausnahmen: `docs/EQUIPMENT_RULES.md`.
- **TESTS ERGÄNZT:** Unit-/Widgettests für AC, Trainingsfolgen, Waffenauswahl, Fähigkeitsschwellen, ungültige Referenzen und Savegames. Sie sind **noch nicht mit Dart/Flutter ausgeführt**.
- **VOR FREIGABE:** Vollständige Flutter-Analyse, alle Widget-/Domain-Tests, Backend, Android-APK-Build, Installations- und Spielstandsprüfung. Codebasis ist das vorherige lokale 0.5.9+29-ZIP; es kann Codex-Änderungen überschneiden, daher kein blinder Merge.
- **ALS NÄCHSTES:** SRD-Effekte von Erschöpfung und Zuständen implementieren; danach begrenzte Zauber- und Klassenressourcen. Vorher neue Tests grün bekommen.

## 0.5.9+29 – SRD-Ausrüstungskatalog (15.10.2026)

- **Ausgang:** Separater Projektzweig auf dem Quellstand `0.5.8+28`, basierend auf GitHub `main` `c635ee376649d02ec37017c01805f2fa4d1a9806`. Parallel zu einer möglichen Codex-Weiterentwicklung, **nicht** direkt in GitHub eingecheckt.
- **IMPLEMENTIERT:** 38 Standardwaffen, 13 Rüstung/Schild-Einträge, Abenteuerausrüstung/Werkzeuge sowie 79 katalogisierte magische Namen, Suchfunktion nach Deutsch/Englisch, Kategorienfilter, Item-Auswahl, optionale Inventar-`catalogId`, Preise in Kupferstücken und reine Rüstungs-KV/RK-Berechnungs-Vorschau.
- **NICHT IMPLEMENTIERT:** Automatisches Anlegen, Rüstungsübung/Einschränkungen in Kämpfen, Einkaufs-Geldtransaktion, vollständige magische Gegenstandseffekte und alle Items aus nicht-SRD-Quellen. Magische Namen sind ausdrücklich nur Katalog/Referenz.
- **GETESTET:** Python-Projektstruktur + 38 Python-Tests, ohne Flutter-SDK. Zusätzliche Dart-Unit- und Widgettests sind erstellt, aber **NICHT ausgeführt**. ZIP, SHA-256 nach Verpackung prüfen.
- **BESTEHENDER CI-BLOCKER AUF BASIS 0.5.8:** GitHub-Lauf #38734808085 mit 355 Flutter-Tests bestanden, 7 Rast-Tests fehlgeschlagen. Der vorherige Quellstand 0.5.7+27 war erfolgreich. Diese Rast-Testfehler wurden im Item-Inkrement nicht bearbeitet.
- **NÄCHSTER SCHRITT:** Katalogänderungen auf einem eigenen Branch mit dem aktuellen Codex-HEAD konfliktbewusst zusammenführen, erst dann `flutter analyze`, alle `flutter test` und Android-APK-Build; die Rast-Testfehler getrennt beheben. Magic-Item-Metadaten pro Eintrag gegen das SRD verifizieren, bevor automatisierte Effekte aktiviert werden.

## 0.5.8+28 – Rast- und Trefferwürfelregeln (15.10.2026)

- **Ausgangsstand:** GitHub `main` `96ae347f61ad4e1c132caa848c1904444976f7d5` (0.5.7+27); die wesentlichen Model-/Engine-Quelldateien anhand ihrer Git-Blob-SHAs mit dem vollständigen lokalen Quellarchiv abgeglichen. Der GitHub-CI-Lauf #38731206833 für **0.5.7+27 ist inzwischen erfolgreich abgeschlossen** (Flutter, Backend und Android-APK). 0.5.8+28 bleibt ungeprüft.
- **IMPLEMENTIERT:** Kurze Rast mit begrenztem klassenspezifischem Trefferwürfelpool (auch zwei Klassen), Konstitution, HP-Maximum und Würfeljournal. Lange Rast regeneriert TP und alle verbrauchten Trefferwürfel. Blockade bei 0 TP, Tod, Kampf, ausstehender Probe, fehlenden Werten und unklarer Rast. Neues Character-Sheet-Detail für freie/gesamte Würfel.
- **Speicher:** Optionale Karte `spentHitDice` mit Sicherheitsvalidierung; alte Schema-1-Daten bleiben lesbar. Die KI kann keinen der Werte setzen.
- **TESTS:** Neue Dart-Domain-, GameEngine- und Flutter-Widgettests geschrieben, aber Flutter/Dart hier nicht installiert. Lokale Python-Tests/Struktur sowie ZIP/Prüfsumme getrennt zu dokumentieren. Keine neue Android-APK als bestanden melden.
- **Offene Arbeit:** Flutter-Analyse und alle Dart-Tests in GitHub Actions; Arbeitszeit/Rastunterbrechungen, 16-h-Regel, Erschöpfung und aufladen klassenspezifischer Ressourcen fehlen noch.
- **Nächster Schritt:** Quelländerungen auf einem neuen GitHub-Branch übernehmen, CI vollständig ausführen, Fehler beheben; bei grüner Pipeline ARM64-APK freigeben.

## Version 0.5.7+27 – CI-Inventartest-Fix (15.10.2026)

- **Ausgangs-HEAD:** `42b9ad37efcfce29bab62a1eae6fcbcc47a7ef73` (`main`), GitHub Actions #38729844876.
- **Vorbefund:** Flutter-Analyse, Backend und Struktur erfolgreich, 351 Flutter-Tests bestanden, 1 Test fehlgeschlagen (`ui_character_editor_test.dart`: „Inventory can be added with quantity through accessible fields“). Die zuvor gescheiterten Schnellaktionstests sind bereits grün.
- **Ursache/Behebung:** Schrittweite 500 beim `scrollUntilVisible` des kurzen Inventarbuttons in langer `ListView` konnte dessen Aufbau/Sichtbarkeit verfehlen. UI-Inventarbutton mit stabilem Key identifizierbar, Test scrollt den Editor mit kurzen Schritten und prüft Hit-Testbarkeit vor `tap`.
- **Lokale Prüfungen:** Projektstruktur, Python-Unittests, Archivintegrität. Flutter/Android-SDK vor Ort nicht vorhanden; kompletter Flutter-/Android-Build erst nach GitHub-Import.
- **Nächster Schritt:** Änderungen gegen den aktuellen GitHub-HEAD prüfen/importieren, anschließend `flutter analyze`, `flutter test`, Android-Build und native Tests in Actions. Bei Fehlschlag Logs ansehen, keine APK als fertig behaupten.
- **Codex:** Der separate automatische Codex-Workflow bleibt gelöscht; nur normaler Android-Build unter `.github/workflows/android-build.yml`.

## Stand 0.5.6+26 – lokale Korrektur der drei CI-Widgettestfehler (15.10.2026)

- **GitHub-Basis:** `main` `a8e77778c171132c9d9cabdb56d5a19c9e170953` (0.5.5+25), Actions-Lauf https://github.com/ManuEtt/Dnd/actions/runs/38728029583. Keine externen Dateien überschrieben.
- **Bestätigter Vorfehler:** 349 bestandene und drei fehlgeschlagene Flutter-Tests. Fehler: Tastatur-Erkennung der Docküberschrift; Layout-Overflow bei 320dp und Schrift 180%; Inventar-Button außerhalb 800x600-Testviewport.
- **Implementiert:** Behebung der drei Ursachen in `fantasy_art.dart`, `ui_character_editor_test.dart` sowie erweiterten Schnellaktions-Regressionstests. Eine separate `app/pubspec.yaml`-Versionsnummer `0.5.6+26` identifiziert diesen Quellstand. Keine Änderungen an Regellogik, SQLite-Daten, API-Verträgen oder App-Paket-ID.
- **Getestet:** Python-Projektstruktur, Python-Regressionstests, Archive-/SHA-256-Integrität lokal zu prüfen und separat zu dokumentieren. **Flutter SDK und Android SDK nicht verfügbar; Flutter-Test/Analyse und Android-APK dieser Version in CI noch offen.**
- **Letzter grüner GitHub-CI-Stand:** 0.5.1+21, Lauf https://github.com/ManuEtt/Dnd/actions/runs/38706060048. Neuere Alpha-Versionen nicht als bestätigt bezeichnen.
- **Codex:** Workflow `autonomous-development.yml` ist auf dem GitHub-Branch entfernt, nur regulärer Android-Workflow vorhanden.
- **Nächster Schritt:** Vollständiges Projekt auf eigenem Branch einspielen, GitHub Actions prüfen. Falls weiterer Widgettest scheitert, Logs lesen und nachbessern. Danach ARM64-APK aus dem bestätigten Build abrufen und Android-Gerätetest durchführen.
- **Schreibberechtigung:** GitHub-Connector hatte bei früheren Create/Delete-Versuchen HTTP 403; es wird kein Push als erfolgreich behauptet.

## 0.5.5+25 – untere Schnellaktionsleiste (15.10.2026)

- **Implementiert:** Abenteuer-Schnellaktionen `Sprache`, `Untersuchen`, `Angriff`, `W20` als feste `Scaffold.bottomNavigationBar` auf der Abenteuerseite, zwischen Eingabebereich und Hauptnavigation. Doppelte `Sprechen`- und `Würfeln`-Bedienelemente im Composer entfernt. `Rückblick` bleibt verfügbar.
- **Tests:** Widgettests für Klicks/Scrollen/Tastatur bereits vorhanden und an eindeutige Schnellaktions-Keys angepasst. Vollständige Flutter-/Android-Abnahme steht mangels Flutter SDK in dieser Ausführungsumgebung aus. Nicht als kompilierte APK deklarieren.
- **Speicher:** Keine Änderungen an SQLite, Modellen, Versionierung der gespeicherten Daten oder KI-Schnittstellen.
- **GitHub:** Direkter Schreibzugriff zuvor 403; ZIP muss bei Verwendung mit dem aktuellen Branch abgeglichen werden. Codex-Action bleibt aus den Workflows entfernt.

## CI-Anpassung 15.10.2026 – Codex aus GitHub Actions entfernt (0.5.4+24)

- **IMPLEMENTIERT:** Nur der normale Android-Build bleibt im vollständigen ZIP unter `.github/workflows/`; der separate autonome Codex-Workflow wurde entfernt.
- **ERHALTEN:** Python-, Backend-, Flutter-, Android-Tests, APK-Release und nicht freigegebene Quellcode-Checkpoints.
- **GETESTET:** Projektstruktur, Python-Tests und ZIP-Prüfung. Flutter-/Android-Abnahme weiterhin offen.
- **GitHub:** Der Löschversuch via Connector auf `main` scheiterte an HTTP 403; das GitHub-Repository bleibt unverändert. Für die wirksame Abschaltung bestehender Actions bei GitHub ist ein Lösch-Commit der dort vorhandenen Datei nötig.

## 0.5.4+24 – Bestätigungsschutz und vollständige ARM64-Release-Artefakte (15.10.2026)

**Quelle:** Verifizierbares vollständiges Arbeitsarchiv 0.5.3+23 aus dem letzten Entwicklungszyklus, **nicht** als GitHub-Commit veröffentlicht. Android-Paket-ID und Datenbankschema unverändert. Ein GitHub-Schreibversuch wurde zuvor mit HTTP 403 verweigert; daher keine Behauptung eines Pushs.

**IMPLEMENTIERT:** Zweitklassen-Vorschläge binden sich an den Helden und die regelrelevanten bestätigten Eingangsdaten. Wird der Charakter zwischen Vorschlag und Bestätigung verändert, wird der veraltete Vorschlag sicher abgelehnt; zwischenzeitlicher Schaden darf übernommen werden. Inkompatible direkt konstruierte Mehrklassenstufen werden abgewiesen.

**IMPLEMENTIERT:** GitHub-CI kann nach komplett grüner Test- und Buildkette ein gemeinsam versioniertes ZIP/APK/SHA256/ReleaseNotes-Artefakt mit Architektur-/ZIP-Prüfung ausgeben; `scripts/prepare_alpha_release.py` ist ohne Flutter separat testbar. Release-APKs bleiben intern mit **Debug-Testschlüssel** signiert und sind keine produktiven, langfristig verlässlich aktualisierbaren Builds. Quellen-Checkpoint bei CI-Fehlschlag bleibt erhalten.

**GETESTET:** Python-Archiv-, Struktur-, Paket- und Release-Tests lokal; Projektstruktur erfolgreich. Alle sieben neuen Paket-/Fehlerfalltests bestanden (zusätzlich zu den bisherigen 25). **NICHT GETESTET:** fünf neue Dart-Tests, Flutter-Analyse und Flutter-Widgets, native Android-Tests, Geräteinstallation und neue APK; dafür wird GitHub Actions benötigt. Offline-Backend-Abhängigkeiten konnten wegen fehlendem `undici-types`-Cache nicht installiert werden; deshalb keine Behauptung bestandener Backend-Tests.

**Version:** `0.5.4+24` (neues vollständiges Import-ZIP, noch kein CI-bestätigter Release). **Letzter grüner GitHub-Build:** 0.5.1+21 / Actions #23 vom 15.10.2026. **Nächster Schritt:** Import des ganzen Archivs auf neuem Branch, vollständigen CI-Lauf prüfen und gegebenenfalls korrigieren; erst dann ARM64-APK freigeben.

## Komplette Quellcode-Übergabe – 15.10.2026 (0.5.3+23)

Alle zuvor gesicherten Dateien der 0.5.3+23-Quelle inklusive neuer UI-Schnellaktionsleiste sind in diesem ZIP enthalten. Zusätzlich wurden Codex-/Checkpoint-Workflows, ein `pubspec.yaml`-Regressionstest sowie Fortsetzungs- und Importdokumentation ergänzt. **Keine verifizierte neue Android-APK** und **kein GitHub-Push**; GitHub-`main` war 0.5.2+22. Letzter grüner CI-Build ist weiterhin 0.5.1+21. Für Details siehe `docs/AUTONOMOUS_DEVELOPMENT_STATE.md`.

## Aktuell: Würfelraunen 0.5.3+23 – Untere Schnellaktionsleiste

Die vier Schnellaktionen befinden sich nun als nicht scrollbar mit dem Abenteuerinhalt verknüpfter Footer direkt oberhalb der Hauptnavigation. Die Erzählung ist separat scrollbar; der Eingabebereich bleibt an Ort und Stelle. Die Aktionen bleiben auch bei geöffnetem Keyboard sichtbar, mit kompakter Darstellung. Ein Buildfehler aus der Vorversion wegen YAML-Doppelpunkt in `app/pubspec.yaml` wurde korrigiert.

**Verifiziert:** Projektstruktur, 22 Python-Tests, gültiges `pubspec.yaml`, vollständiges Quellcode-Paket. **Noch nicht verifiziert:** Flutter-Analyse, Widgettests und Android-APK in GitHub Actions. Neue Tests in `app/test/fantasy_pinned_actions_test.dart` und `app/test/ui_app_test.dart`.

## 0.5.2+22 – Würfelraunen / Zweitklasse

Der Projektname wurde in den Benutzeroberflächen zu **Würfelraunen** geändert. Die technische Paket-ID und historischen Weltdaten bleiben erhalten. Mehrklassenregeln (zwei Klassen, Voraussetzungen, fester Trefferpunkte-Zuwachs, Fertigkeitswahl) sind in `app/lib/domain/multiclass_rules.dart` implementiert und an den Charaktereditor angebunden. Vollständige Klassenfähigkeiten sowie Ressourcen- und Rüstungsregeln fehlen noch und müssen in weiteren Zyklen ergänzt werden. Aktuell steht die Flutter-/Android-CI-Abnahme für 0.5.2+22 aus.

## 0.5.1+21 – Flutter-CI-Abnahme des illustrierten Designs (15.10.2026)

- **CI-Ursache:** Letzter GitHub-Actions-Lauf für `0.5.0+20` (`a3a05d3888a9c0e19d3e43d2469cc849f5e1a4eb`) scheiterte trotz 328 bestandener Flutter-Tests an zwei veralteten Widgettest-Interaktionen.
- **Charakterbogen:** Der Test für unbekannte Angaben scrollt zur verzögert aufgebauten Tab-Navigation, bevor er die Tabs antippt. `ensureVisible` allein konnte den zunächst noch nicht aufgebauten Tab nicht finden.
- **Startseite:** Der 360-dp-Navigationstest scrollt zum echten Demo-Button unter dem illustrierten Header, überprüft die Antippbarkeit und startet dann die Demo. Keine Hit-Test-Warnungen unterdrückt und keine Tests deaktiviert.
- **Umfang:** Nur Widgettests, Versionsnummer und Dokumentation geändert. Alle zwölf neuen Illustrationen, UI-Widgets, Spiellogik, Backend und gespeicherte Daten bleiben unverändert.
- **Status:** Lokale Python-/Paketprüfungen durchgeführt; Flutter-Analyse, Flutter-Tests und APK-Build müssen die neue Version in GitHub Actions bestätigen. Ohne grünen Build noch keine Freigabe.

## Aktuell: Aetheria 0.5.0+20 – Illustriertes Dark-Fantasy-UI

Basierend auf dem nachweislich erfolgreichen GitHub-CI-Stand `a85cf97c113d397259677d7a3612f3b229045315` (0.4.3+19). Erweitert wurde ausschließlich die Präsentationsschicht durch 12 lokal eingebundene WebP-Grafiken, ein responsives Bild-/Rahmen-/Aktions-Widgetsystem und Anpassungen an Startseite, Kampagnen, Abenteuer, Helden, Charakterbogen, Chronik und Inventar. Neue Regressionstests in `app/test/fantasy_art_ui_test.dart`. Details: `docs/ILLUSTRATED_UI.md`.

**Status:** Quellcode erstellt und ZIP-Struktur/Python-Tests geprüft; Flutter SDK und Android SDK in dieser Arbeitsumgebung nicht vorhanden. Ein erfolgreicher Flutter-/Android-Build dieses neuen Stands wurde **nicht** behauptet. GitHub `main` unverändert.

## Aktuell: 0.4.3+19 – Attributkartenlayout korrigiert

**Basis:** GitHub `main` `9a75719b07fb2607f49818e12018a277e0b5f5dc`. Der letzte CI-Lauf stoppte nach 319 bestandenen, vier fehlgeschlagenen Widgettests (`fantasy_character_sheet_test.dart`); Ursache und Testselektor im Quellcode korrigiert. Kotlin/Android-APK noch nicht überprüft. Kein direkter GitHub-Push ausgeführt.

## Stand 0.4.2+18 – Flutter-Compilefix, noch nicht CI-validiert (15.10.2026)

Das Release 0.4.1+17 erreichte `flutter analyze` nicht: `mainAxisExtent` wurde irrtümlich an `GridView.count` übergeben (GitHub Actions Run 38691911056). 0.4.2+18 setzt stattdessen `GridView(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(mainAxisExtent: ...))` ein. Regressionstest ergänzt. Die neuen Zeilenhöhen gegen UI-Überlauf bleiben erhalten. Backend, Datenbank und Spiellogik unverändert. Vollständig grüner CI-Lauf steht für dieses Inkrement aus.

## Aktueller Stand: 0.4.1+17 – Fehlerkorrektur im Charakterbogen

Aufbauend auf `main`-Commit `c4d0dedd851ae1085d01a26afb6c0c7ff78c8830`.
Der CI-Lauf `38690872031` hatte 22 erfolgreiche Python-, 29 erfolgreiche Backend- und 316 erfolgreiche Flutter-Tests, aber drei Layout-Fehler durch zu niedrige Statistik-Kacheln in `fantasy_character_sheet.dart`. Die Kachelhöhe wurde vom starren Seitenverhältnis auf eine skalierbare feste Hauptachsengröße umgestellt; die Widgettests wurden erweitert.

**Status:** Quellcode-Korrektur und ZIP fertig; Flutter/Android-Tests müssen noch über GitHub Actions laufen. Keine Veränderungen an Spielregeln, KI oder Datenformaten.

## Aktueller Stand: 0.4.0+16 (vollständiger UI-Redesign-Stand)

Die deutsche Dark-Fantasy-Designsprache des Charakterbogens ist im existierenden App-UI vereinheitlicht. Status: vollstaendiges Quellcode-Inkrement für GitHub-Import, **nicht als grüner Flutter-/Android-Build nachgewiesen**. In dieser Umgebung bestanden die Strukturprüfung und 22 Python-Tests. Die Widgettests und Android-APK müssen in GitHub Actions laufen. Siehe `docs/UI_DESIGN_SYSTEM.md`.

## Status 0.3.9+15 – Oberflächengestaltung (15.10.2026)

**Integriert:** Neue native, responsive Flutter-Charakterbogenansicht mit vollständigen deutschen Labels und drei Bereichen; App-Farb- und Typografie-Thema angepasst. Einstieg aus Heldenliste und aktiver Kampagne, Weiterleitung zum bisherigen Editor. Kein geändertes Speicherformat, keine Hintergrundmigration, keine neuen Laufzeitabhängigkeiten. Das Mockup ist eine visuelle Referenz; die Android-App zeigt weiterhin echte, gespeicherte Daten.

**Ausstehend:** Flutter-/Dart-Analyse, vollständige Widgettests, Android-APK-Build, Smartphone-Abnahme und Prüfung des Designs mit Schriftgrößen-/Barrierefreiheitseinstellungen. Der jüngste GitHub-Workflow von `125fc3630722002a955a4e3479395edd6bfb6635` stoppte im Backend-Test durch eine veraltete Versionserwartung `0.3.0` statt `0.3.1`; diese Assertion ist in dieser ZIP korrigiert. CI muss diesen und die neuen UI-Tests bestätigen.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## 0.3.7+13 – KI-Kampagnen (15.10.2026)

Die neue Funktion erfordert einen verbundenen Backend-Erzähler. Im Testmodus erzeugt der Mock lediglich eine feste Story-Variante; kreative Kampagnen benötigen den ausdrücklich genehmigten OpenAI-Anbieter (`AI_PROVIDER=openai`, `ALLOW_PAID_AI=true`, serverseitig API-Key und Modell). Die App verbraucht pro Start und freiem Zug eine freigegebene Backend-Anfrage, zählt sie lokal mit und nutzt serverseitige Limits. Bei Abbruch bleibt der letzte bestätigte Spielstand erhalten.

Aktuelle Grenzen: kein autonomes Training der Modellgewichte, keine Live-Sprach-KI, kein KI-berechneter Kampf und keine garantierte Korrektheit freier KI-Prosa. Stattdessen kontextbasierte Story-Entwicklung aus persistenter Story-Bibel, NPC- und Handlungsstrangstatus und begrenzten früheren Entscheidungen. Die „geheime“ Wendung bleibt im lokalen gespeicherten Story-Kontext und damit beim Export sichtbar.

Grundlage: Repository `main` Commit `ea486481d28856228abf65dd209857028b3b3c45`. Dieser Stand scheiterte im CI mit 299 erfolgreichen und 2 fehlerhaften Flutter-Tests (Widget-Selektor / Tagebuch-Scrollen); die betreffenden Tests wurden im Quellpaket korrigiert. Die Korrekturen sind mangels Flutter noch nicht in CI bestätigt. Vor Übergabe lokal 22 Python-Tests und TypeScript-Syntax erfolgreich; vollständige Test- und APK-Abnahme ausschließlich in GitHub Actions.

## 0.3.6+12 – Erweiterung des Kampagnengedächtnisses (15.10.2026)

**Implementiert:** Drei neue Bereiche im Tagebuch für speicherbare Sitzungsschnappschüsse, Status und Beschreibung offener Handlungsstränge sowie protokollierte NPC-Beziehungen. Alle Änderungen erfordern eine Benutzeraktion. Neue Ereignistypen `memory.sessionRecapSaved`, `memory.npcRelationshipRecorded`, `memory.storyThreadSaved`; Änderungen liegen im bestätigten SQLite-Revisionsjournal und JSON-Export. Die lokale Erinnerungssuche berücksichtigt diese Einträge. Automatische generative Lore- und Beziehungsentscheidungen bleiben ausgeschlossen.

**Kompatibilität:** Alte `schemaVersion: 1`-Kampagnen dürfen die neuen optionalen Felder weglassen; dann werden leere Sammlungen angenommen. Keine SQLite-Migration und keine neuen Laufzeitabhängigkeiten. Maximal 60 Zusammenfassungen, 100 Handlungsstränge, 300 Beziehungseinträge sowie strenge Text-/Statusvalidierung. Es handelt sich um benutzergeführte Notizen, nicht um eine autonome semantische Gedächtnis-KI.

**Bekannter Vorfehler:** GitHub Actions für `6e967080baba7de252fac378d51758a20f6556ae` (`https://github.com/ManuEtt/Dnd/actions/runs/38683059572/job/116251682233`) zeigte erfolgreiche Analyse und 290 bestandene Flutter-Tests, aber einen Hit-Test-Fehler in `ui_app_test.dart` beim Button „Vervollständigen“ auf 360 px. Der Test scrollt nun kontrolliert zu diesem Button. Kein neuer GitHub-CI-Lauf für die 0.3.6-Änderungen erfolgt.

**Prüfungen:** Vollständige Projektstrukturprüfung und 22 Python-Tests erfolgreich. Neue Dart-Domain-, Widget- und SQLite-Testfälle sind im Quellcode vorhanden, jedoch ohne Flutter-SDK in dieser Umgebung noch nicht ausführbar; Android-APK-Build und reale Geräteabnahme stehen aus.

**Basis:** GitHub `main` Commit `6e967080baba7de252fac378d51758a20f6556ae` (0.3.5+11). Vollständige ZIP-Übergabe, der Hauptbranch wurde nicht verändert.

## 0.3.5+11 – Neues Inkrement (15.10.2026)

**IMPLEMENTIERT:** Lokaler Rückblick via GameEngine/MemoryEngine, thematisch gefilterte bestätigte Erinnerungen für D&D-Kampagnen, Schaltfläche „Rückblick“ mit Erhalt eines ungesendeten Entwurfs, und zustandsabhängige Mira-Antworten im Demo-Abenteuer.

**SICHERHEIT/DATEN:** Abfragen verwenden ausschließlich bereits bestätigte Kampagnenfakten, NPCs, Quests, Inventar und Orte. Unbestätigte Szene-/Nachrichtentexte werden nicht übernommen; Rückblicke verändern weder TP, Würfel, Inventar, Quests noch ausstehende Proben. Speicherung/Import/Export bleiben Version 1; keine neuen Server- oder Netzwerkrechte. Komplexe, freie KI-Erzählungen und semantische Gedächtnissuche sind weiterhin nicht implementiert.

**CODETESTS:** `app/test/memory_recall_test.dart` ergänzt; `app/test/ui_app_test.dart` erweitert. **Vorbereitete** Dart-/Flutter-Tests sind noch keine bestandenen Laufzeittests. Python-Projektprüfungen und Backend-Prüfungen sind separat nach Ausführung zu dokumentieren. Lokale Umgebung hat kein Flutter/Dart-/Android-SDK. GitHub Actions muss die neuen Dart-Tests und APK-Builds nach Import ausführen.

**GITHUB-BASIS:** `239ee5f7d333a6388159e7d431039abb92e936b7` vom 15.10.2026. Keine Änderungen direkt in den Hauptbranch geschrieben; ZIP kann in einem neuen Branch importiert werden. Vor Merge prüfen, ob GitHub seit dem Basisstand weiterentwickelt wurde.

## 0.3.4+10 – Fehlerkorrektur und Attribut-Modifikatorvorschau (15. Oktober 2026)

Basis fuer diesen Quellstand ist der per Git-Tree-SHA bestaetigte main-Commit
`3b91a9778abe14184f35ac1db16f5acf121a84b5`. Dessen GitHub-Actions-Job
`116229696416` schlug im Flutter-Test `new manually changed score requires explicit
house-rule consent` fehl: `scrollUntilVisible` suchte vorwaerts, obwohl die
Hausregel-Checkbox nach einem Speicherversuch oberhalb lag (281 erfolgreich,
1 fehlgeschlagen). Der Test verwendet nun einen negativen Scroll-Schritt.

Weiterentwicklung: Gueltige Attributwerte zeigen ihre regelkonform berechneten
Modifikatoren direkt im Charaktereditor. Vorschau, keine neue Spielzustandsquelle;
bei leeren oder ungueltigen Attributen wird kein Wert angenommen. Ein separater
Widgettest prueft `14/+2`, `9/-1`, Zuruecksetzen auf leer und kein Speichern.

Status: Quellcode integriert, Python-/Backend-Pruefungen separat dokumentiert.
Flutter-Analyse, Widgettests und Android-APK dieser Version sind **nicht**
lokal verifiziert. GitHub-Actions erneut durchlaufen lassen. Bei Erfolg APK
auf einem echten Android-Geraet einschliesslich Import/Export und Sprache pruefen.

## 0.3.3 – CI-Korrektur (15. Oktober 2026)

- Im offiziellen GitHub-Actions-Lauf [38675268449](https://github.com/ManuEtt/Dnd/actions/runs/38675268449) für Commit `02380c2180f98de9a31d1759fee8566d7575f3ce` wurden Projektstruktur, 22 Python- und 22 Backend-Tests erfolgreich geprüft. `flutter analyze` stoppte mit genau einem Dart-Hinweis `dangling_library_doc_comments` in `app/lib/domain/srd_character_classes.dart:1:1`; nachfolgende Flutter-Tests und APK-Builds wurden übersprungen.
- Diese ZIP behebt den Kommentarfehler ohne eine fachliche Codeänderung. Der Korrekturstand muss erneut in GitHub importiert und durch die gesamte Actions-CI geprüft werden. Ein Erfolg der noch ausstehenden Flutter-Tests und APK-Builds wird nicht behauptet.

## 0.3.3 – Stand der ergänzten Klassenwahl, 14. Oktober 2026

- BASIS: vollständig exportierte 0.3.2-Version aus GitHub `4007b2b65f3413238c0a828813d57b98c4498732`, bereits durch Actions für Flutter/Android getestet. Letzter freigegebener Gerätebericht: Attributverteilung, Spracheingabe, Sprachausgabe, Stufe-1-TP funktionieren.
- IMPLEMENTIERT (0.3.3): 12 SRD-5.2.1-Klassenprofile mit Rettungswurf-Übungen, Fertigkeitswahl, optionalem Startpaket/Startgold; UI-Klassenassistent mit Vorschau/Bestätigung, bestehende Werte nicht automatisch überschreiben; neuer manueller Hausregelweg für abweichende Startattribute bei neuen Charakteren. Keine Schema- oder Backend-Änderung.
- SOURCE-QA: neues Paket mit zusätzlichen Unit-/Widgettests; Gesamtprojektstruktur und vorhandene Python-Tests werden vor ZIP-Abgabe separat geprüft.
- OFFEN: Flutter-Analyse, Flutter-Tests und Android-Build für Version 0.3.3 können in der aktuellen Dateiumgebung ohne Flutter-SDK nicht ausgeführt werden. Nach GitHub-Import über Actions prüfen; 0.3.3 nicht bereits als Gerätetest ausgeben.
- REGELGRENZE: keine automatische Hintergrunderfahrung, Klassenmerkmale, aufgenommene Ausrüstung/Rüstungsklasse, Zauberplätze, Level-Ups oder Mehrklassenregeln. Mit zusätzlichen Stufe-1-Klassenübungen werden bestehende Einträge optional zusammengeführt; Ursprung der üblichen Mehrfach-Übungen ist in den bestehenden Listen noch nicht separat nachverfolgbar.

# Entwicklungsstatus

## Entwicklungsinkrement: SRD-5.2.1-Start-Trefferpunkte (0.3.2+8, im Quellstand integriert)

- Neue reine Dart-Regellogik `StartingHitPoints.propose` für die zwölf
  SRD-5.2.1-Klassen (deutsche/englische Namen): Stufe 1 = maximaler
  Klassen-Trefferwürfel + bestätigter Konstitutionsmodifikator, mindestens 1 TP.
- Im Charaktereditor ein separater, ausdrücklich zu bestätigender Vorschlag.
  Abbrechen, unbekannte Werte und Stufen größer 1 ändern keine Charakterwerte.
- Neue Domänen- und Widgettests hinzugefügt; **in diesem Übergabepaket nicht
  ausgeführt**, da die aktuelle Arbeitssitzung keine Flutter-/Dart-Toolchain hat.
- **Vollständiger Quellstand direkt integriert**: Alle 103 Originaldateien aus
  GitHub-main `4a8cfe9` über ihre Git-Blob-SHA geprüft, dazu fünf direkte
  HP-Code-/Test-/Statusänderungen und die Versions-/Dokumentationsaktualisierung.
  Projektstrukturprüfung und 22 Python-Tests erfolgreich.
- **Noch nicht nach GitHub geschrieben**: Die GitHub-Integration verweigert
  Branch-Erstellung mit 403. Nach Import `flutter analyze`, `flutter test`
  und GitHub-CI ausführen; erst danach als getestet melden.
- Nächstes Inkrement: Verteilungsmethode/Basiswerte/Boni persistieren und
  freie Attributbearbeitung bei regelkonform neu erstellten Charakteren
  gegen Umgehung des 27-Punkte-Budgets absichern, Altimporte schützen.

Hinweis zum vorherigen Stand: Der GitHub-Actions-Lauf `38582180726`
auf `4a8cfe9` war tatsächlich erfolgreich: 254 Flutter-Tests, Backend- und
Python-Tests sowie Debug-/ARM64-/ARM32-/x86_64-APKs. Diese Ergebnisse
gelten für 0.3.1, **nicht** als Abnahme des neuen 0.3.2-Codes.

Stand: 14. Oktober 2026. Aktuelle Etappe: App 0.3.1 mit Android-Sprachkorrekturen, Geräte-Rückmeldung und nachgewiesener GitHub-CI-Ursache; autonome Entwicklung mit gesicherten Inkrementen für `ManuEtt/Dnd`.

Der Lesezugriff auf GitHub ist jetzt vorhanden. Der hochgeladene main-Stand
`bc6c942483189acdcd82b37005de1040b49b36b8` stimmt in allen Dateiinhalten mit dem
gesicherten lokalen 0.3.0-Stand überein; nur vier Ausführungsrechte unterscheiden
sich. Der bestehende Actions-Lauf ist geprüft, direkte Schreiboperationen
erhalten weiterhin HTTP 403. Neue Korrekturen sind deshalb zusätzlich als ZIP
zu übernehmen; ein neuer GitHub-Lauf oder Pull Request ist noch nicht bestätigt.

## IMPLEMENTIERT

- Flutter-/Android-Projekt mit Material 3 und deutscher Navigation: Start, Charaktere, Abenteuer, Journal und Einstellungen.
- Flaches Korrektur-ZIP ohne äußeren Dnd-Ordner, Projektprüfung vor SDK-Installation und 22 Python-Paket-/Strukturtests. Kleine optimierte interne Alpha-APKs für ARM64, ARM32 und x86_64, weiterhin mit Testsignatur.
- Explizite Attributstarthilfe: Standardsatz oder Punktekauf bis 27 Punkte, vier SRD-Hintergründe, getrennte Grund-/Bonus-/Endwerte mit Modifikatorvorschau. Bekannte Werte benötigen Ersetzbestätigung; Öffnen/Abbruch bewahrt historische und ungespeicherte Eingaben. Nur Attribute und Hintergrundname werden übernommen.
- Charaktereditor mit nullable, ausdrücklich unbestätigten Werten; JSON-Export/-Import, Kampagnenauswahl und lokale Löschfunktionen. Seit 0.2.2 direkte Android-Dokumentauswahl und Dateisicherung, explizite Importbestätigung sowie Zwischenablage als Fallback.
- Deterministischer deutscher Spielleiter als kostenlose Voreinstellung. Optionaler HTTPS-Backend-Erzähler für freie Texte; lokale Regeln, Würfel und bestätigte Daten bleiben maßgeblich. Anbieterantworten ersetzen ausschließlich die neue Erzählung und ihren Ereignis-Checkpoint.
- Demo „Das Licht von Mooswacht“ in Lunaris mit Liora, Erkundung, Schlüssel, Quest und einfacher Gegnerbegegnung.
- Historischer Arescan-Zustand „Das Herz der Ewigkeit“: bekannte Geschichte, fehlende Attribute, historische Werte 19/14 und ungeprüfter Modifikator +7; keine erfundenen Helden- oder Gegnerkampfwerte.
- Würfel W4/W6/W8/W10/W12/W20/W100, natürliche Ergebnisse getrennt von Gesamtergebnissen, Vorteil/Nachteil und kontrollierbare Zufallsquelle.
- Regelgrundlagen für Attributmodifikatoren, Übungsbonus, Initiative, Angriffe, kritischen Schaden, Trefferpunkte, Heilung und Todesrettung. Demo-Kampf mit automatischer Gegenrunde; kein vollständiges SRD-Kampfsystem.
- SQLite-Schema 1, gemeinsame Speicherung von Snapshot und Ereignissen, Revisionsjournal, Konfliktprüfung, Idempotenz und Wiederherstellung bestätigter Zustände.
- Grundlegender Kurzzeitkontext, faktengestützte Sitzungsübersicht und Langzeitfakten zu NPCs, Quests und Inventar; Checkpoint-Ereignisrekonstruktion.
- Deutsche Systemspracherkennung mit bearbeitbarem Transkript, TTS, Stimmwahl, optionaler automatischer Ausgabe und Unterbrechung. Seit 0.3.1 geprüfte Anbieterergebnisse, deutsche Locale-Rangfolge, deduplizierte Stimmmetadaten und erneute Prüfung ohne Mikrofonzugriff. Fehlende Daten/Netzwerkprobleme erhalten verständliche Meldungen; nicht antwortende Dienste und Wiedergabe haben Zeitgrenzen. Lokale Oberfläche startet vor der Sprachdienstprüfung. Kein automatischer Mikrofon-Neustart.
- Fastify-/TypeScript-Backend mit validierter, ausschließlich erzählender API, eigenen kurzlebigen Read-only-Tokens, In-Memory-Anfragelimits und kostenlosem Mock. Optionaler OpenAI-Responses-Provider ausschließlich serverseitig und mit ausdrücklichem Kosten-Opt-in. Kein Realtime-Token.

Zusätzlich seit 0.2.0: HTTPS-Transport mit begrenzten JSON-Antworten, verweigerten Weiterleitungen, Ablaufprüfung, ausdrücklicher Kostenfreigabe und lokalem Anfragenversuchslimit. Token und Kostenfreigabe werden nicht gespeichert. Sitzungstest per authentifiziertem GET ohne Modellaufruf; neue Server-CLI gibt nur kurzlebige Sitzungstokens aus. Fehler führen ohne automatischen POST-Retry zur lokalen Demo. Ein Replay-Fehler durch unterschiedliche JSON-Objektschlüsselreihenfolge wurde behoben, ohne veränderte Werte oder Listen als identisch zuzulassen. Seit App 0.2.1 wählt MemoryEngine.retrieve bis zu 20 bestätigte Fakten, NPC-, Quest-, Inventar- und Ortsinformationen anhand deutscher Worttreffer und wichtiger Zustände aus. Keine Modelltexte oder Spielerbehauptungen werden als Faktenquelle verwendet; Datenbankschema und Importe bleiben Version 1.

Seit App 0.2.2 trennt BackupFiles die Dateiverarbeitung von Oberfläche und Repository. Die native Android-Brücke verwendet das Storage Access Framework ohne allgemeine Speicherrechte, prüft Dateinamen und tatsächliche Datenmenge bis 10 MiB und arbeitet im Hintergrund. Dart prüft striktes UTF-8 und erlaubt ein anfängliches BOM. Abbruch und Fehler speichern keine Importdaten; Erfolg beim Export setzt einen geschlossenen Stream voraus. Die echte Geräte-Dateiauswahl ist noch nicht abgenommen. Einrichtung und Grenzen: docs/SAVE_BACKUPS.md.

Der Workflow `.github/workflows/android-build.yml`, Projekt- und Übergabedokumentation liegen vor. CI verwendet Flutter 3.35.7, Dart 3.9.2, Java 17 und Node.js 22.14.0.

Seit 0.3.1 installiert CI Android Commandline Tools mit
android-actions/setup-android@v3, festgelegtem Build 12266719, vor dem
sdkmanager-Aufruf. Die Ursache des alten APK-Ausfalls ist durch GitHub-Logs
bestätigt, der korrigierte Workflow bleibt bis zur Übernahme separat zu prüfen.

## GERÄTERÜCKMELDUNG

Der Benutzer berichtet funktionierenden App-Betrieb auf einem **Samsung Galaxy
S26 Ultra**, aber Probleme bei einigen Sprachen. Das ist ein Benutzerbericht,
kein vollständig dokumentierter Entwickler-Gerätetest. App-/Android-/One-UI-
Version, Sprachdienst, genaue betroffene Sprache und Eingabe beziehungsweise
Ausgabe sind noch offen. 0.3.1 verbessert konkrete im Paketcode bestätigte
Fehlerpfade; deren Behebung auf dem Samsung ist noch nicht bestätigt. Die
Hauptsprache ist Deutsch, weitere Spielsprachen sind nicht implementiert.
Anleitung und Diagnosedaten: docs/SPEECH_TROUBLESHOOTING.md.

## GETESTET

Gezielte Sprachprüfung 0.3.1: **31 Controller-Tests** (24 neu) und **7 neue
Widgettests** bestanden, gezielte Analyse ohne Befunde. Geprüft sind 0/false
bei TTS-Kommandos, fehlende/doppelte Stimmendaten, lokale/Netzwerk-Metadaten,
gespeicherte entfernte Stimmen, Wiederholung nach Paketinstallation,
hängende Sprachabfrage/Wiedergabe, Fehlercallbacks, Abbruch und verzögerte
Ergebnisse. Die Einstellungen bestehen auf 360 px mit 1,3- und 2-facher
Schriftgröße. Die neue Startprüfung mit echter temporärer SQLite-Datenbank
zeigt die lokale Oberfläche während einer offenen nativen Stimmabfrage.

Abschließende Prüfungen für 0.3.1: **254 Flutter-Tests** einschließlich lokalem
Node-/Dart-Protokolltest erfolgreich mit Node 22.14.0 und RUN_BACKEND_SMOKE=1;
**22 Backend- und 22 Python-Tests**, Backend-Typecheck/Build und saubere
Flutter-Analyse. Insgesamt 32 neue Flutter-Tests. Universeller Debug-Build
0.3.1+7 erfolgreich; Version, API 24/36 und gleiche lokale Testsignatur geprüft.
Keine kostenpflichtigen Modellaufrufe. Native Dateisicherungsquellen unverändert,
deren bestehender Nachweis bleibt 12 JVM-Tests.

Der reale GitHub-Lauf **38560369343** auf main `bc6c942` besteht Strukturprüfung,
22 Python-, 22 Backend- und 222 Flutter-Tests sowie Codeanalyse. Job
115839661846 scheitert danach beim SDK-Schritt mit **sdkmanager: command not
found**, Exit 127. Alle APK-Schritte sind übersprungen. Dies ist ein tatsächlich
beobachteter Remote-Testlauf, aber kein erfolgreicher Remote-APK-Build.

Gesamter scripts/check.sh-Lauf für 0.3.0 erfolgreich: **222 Flutter-Tests** einschließlich lokalem Node-/Dart-Protokolltest, **22 Backend-Tests**, **22 Python-Paket-/Strukturtests** und Flutter-Analyse ohne Befunde mit der festgehaltenen Toolchain/Node 22.14.0. Zusätzlich nach Ergänzung der beiden neuen Pflichtdateien Python-Prüfer und alle 22 zugehörigen Tests erneut bestanden. 44 neue Flutter-Tests: 24 Domain-Regeltests, 7 echte SQLite-/Controller-Tests und 13 Widgettests. Der Debug-APK-Build 0.3.0+6 ist erfolgreich, Metadaten und Testsignatur geprüft.

Die Regeltests prüfen alle 720 Standardsatz-Zuweisungen, Punktekostentabelle, Budget und jede erlaubte Hintergrundsteigerung. Die UI-Prüfung umfasst 360 px, explizite Auswahl, Restpunkte, Basis-/Bonusvorschau, Modifikator 17→+3, Bestätigung und Abbruch. SQLite prüft Neustart/Export/Import, keine doppelten Boni, Arescan 19/14 und unbestätigten +7 sowie unveränderte Welt-/Inventardaten und ungültig gewordene alte Würfelproben. Ein echter später SQLite-Triggerfehler bestätigt vollständigen Rollback von Ereignis/Snapshot und Anzeige; erneutes Speichern gelingt. Statische zusätzliche Regel-/UI-Prüfung ohne Blocker. Kein realer Geräte-/Sprach-/GitHub-Test dadurch behauptet.

Erneuter kompletter scripts/check.sh-Lauf für 0.2.3 erfolgreich: Projektstrukturprüfung, **22 Python-Paket-/Strukturtests**, Backend-Typecheck/Build und **22 Backend-Tests** mit Node.js 22.14.0, saubere Flutter-Analyse sowie **178 Flutter-Tests** mit RUN_BACKEND_SMOKE=1. Neue Tests prüfen beide ZIP-Wurzeln, Byte-Erhalt, Geheimnis-/Cache-Ausschluss, Symlinkablehnung, unvollständige Uploads, Gradle-JAR-CRC und Unix-Zeilenenden. Keine kostenpflichtigen Modellaufrufe.

Drei optimierte Alpha-APKs lokal erfolgreich gebaut und geprüft: arm64-v8a 17.382.068 Byte, armeabi-v7a 14.861.712 Byte, x86_64 18.554.326 Byte. Alle Version 0.2.3, Buildcode 5, API 24+, richtige ABI und gleiche verifizierte lokale Debug-Testsignatur wie die bisherige 0.2.2-APK. Je ABI --target-platform verwendet, damit keine ABI-Codeoffsets spätere Updates verhindern. Kein Store-Release. ARM64 und ARM32 privat auf Google Drive erstellt und per Metadaten mit korrekter Größe/MIME/Owner-Recht gelesen; ARM64 zusätzlich über die Drive-Download-API abgerufen und byteidentisch per SHA-256 mit dem Original verglichen. Der Benutzerdownload und die Installation auf einem echten Gerät bleiben separat abzunehmen.

Flutter 3.35.7/Dart 3.9.2: Codeanalyse ohne Befunde und **178 Tests bestanden** mit RUN_BACKEND_SMOKE=1. Enthalten sind 74 bisherige Tests, 23 Transporttests, 13 Erzähl-/Replay-Tests, 13 SQLite-/Backend-Controller-Tests, 7 Backend-Widgettests, 13 Abruf-/Konsistenztests, 21 Dateikanal-/UTF-8-Tests, 13 Datei-Widgettests und ein echter lokaler Protokolltest. Der aktuelle Gesamtlauf verwendet Node 22.14.0 auch für den realen Protokolltest. Der Protokolltest startet den kompilierten Node-Server, stellt mit der Server-CLI einen synthetischen Sitzungstoken aus und prüft Dart-Transport, Backend-Erzählung, SQLite-Bestätigung und den Rückfall nach Serverabschaltung. Er verwendet ausschließlich lokale Mock-Dienste und Testdaten.

Backendquellen unverändert seit 0.2.0: Typecheck, Produktionsbuild und **22 Tests** erfolgreich mit Node.js 22.14.0 und 24.19.0. Geprüft sind neue Sitzungsprüfung, verbindliches outcome, Provider-/Tool-Abweisung, Authentifizierung, Eingabevalidierung, Nutzungslimits und sichere Fehler. Die historischen 0.1.0-Prüfungen und Quellenangaben bleiben im Änderungsprotokoll nachvollziehbar. Es wurden keine kostenpflichtigen Modellaufrufe ausgeführt.

Native Android-JVM-Prüfung mit Java 17 und Gradle 8.12: **12 Tests bestanden**, keine Fehler, keine übersprungenen Fälle. Geprüft sind reale Byte-Grenze statt Provider-Metadaten, Dateinamen, Lesen/Schreiben, Streamschluss und I/O- beziehungsweise Abbruchfehler. Lebenszyklus und SAF-Ergebniszustellung sind statisch geprüft, nicht durch diese JVM-Tests oder auf einem Gerät nachgewiesen.

Die Abschlusskorrektur ist ebenfalls abgenommen: Trennung und Dispose beenden ausstehende Backend-Wartevorgänge sofort; aktive HTTP-Verbindungen werden geschlossen, und verspätete Antworten bleiben wirkungslos. Der Abbruchknopf ist während einer laufenden Anfrage bedienbar. Bereits ausgelöste Anbieteraufrufe werden dadurch nicht automatisch erstattet.

## NICHT GETESTET

- Vollständig dokumentierter End-to-End-Ablauf auf einem echten Android-Gerät, einschließlich neuer Attributshilfe mit großer Schrift/Screenreader; Benutzer meldet App-Betrieb auf Samsung Galaxy S26 Ultra.
- Echte Android-Dokumentauswahl, Dokumentanbieter, Berechtigungsübergabe, Schreibfehler und Aktivitätsende während einer Dateisicherung. Die Dateibrücke ist kompiliert; Dart-Kanal, Oberfläche und native I/O-Helfer werden getrennt automatisiert geprüft.
- Deutsche Mikrofoneingabe und Sprachausgabe mit einem konkreten Android-Sprachanbieter.
- Unterbrechung, Berechtigungsablehnung und Ausfall von echten Gerätesprachdiensten; die zugehörige App-Logik ist mit Mocks getestet.
- GitHub-Actions-Lauf mit der SDK-Korrektur 0.3.1 und Herunterladen eines neuen APK-Artefakts; bisheriger Lauf scheitert nach erfolgreichen Tests.
- Reale, kostenpflichtige OpenAI-Aufrufe und eine mobile HTTPS-Verbindung zu einem produktiven Server.

## BLOCKIERT

- Direkte Übertragung der Änderungen: Lesen funktioniert, tatsächlicher Push auf fix/android-voice-reliability erhält HTTP 403 „Permission to ManuEtt/Dnd.git denied to ManuEtt“. Connector-Branchanlage erhält ebenfalls403 „Resource not accessible by integration“. Allgemeines push:true in Repository-Metadaten bestätigt nicht die Integrationsberechtigung. ZIP und docs/UPLOAD_TO_GITHUB.md ermöglichen die Übernahme durch den Eigentümer. Actions-Ursache ist inzwischen bestätigt und lokal korrigiert.
- Eine vollständige Prüfung auf einem Android-Gerät benötigt ein Gerät beziehungsweise einen geeigneten Emulator mit Sprachdiensten.
- Produktive KI-Anbindung benötigt sichere Serverkonfiguration und Anbieterzugang; der Demo-Modus bleibt unabhängig davon.

## NOCH NICHT IMPLEMENTIERT

- Vollständiges SRD-5.2.1-Regelsystem einschließlich regelkonformer automatischer Charaktererstellung, aller Klassen, Zauber, Ressourcen, Bonus- und Reaktionsaktionen sowie automatischem Stufenaufstieg.
- Regelkonforme Fortsetzung des historischen Arescan-Kampfs bei weiterhin unbekannten Gegnerwerten.
- Durchgängiger geprüfter mobiler OpenAI-Realtime-WebRTC-Sprachpfad und Ausstellung von OpenAI-Realtime-Credentials.
- Öffentlicher Mehrspielerdienst, PostgreSQL-Synchronisierung und Benutzerverwaltung.
- Vollständige mehrstufige Erinnerungsverdichtung und semantische Langzeitabrufe.
- Automatische sichere Sitzungserneuerung; Tokens müssen derzeit nach Ablauf neu ausgestellt werden.
- Signierter Veröffentlichungsbuild und Store-Veröffentlichung.
- Abgenommene Windows- und iOS-Versionen.

## Letzter Build und nächste Aufgabe

**App 0.3.1+7: universeller Android-Debug-Build erfolgreich**, API 24+, Ziel 36,
gleiche Paket-ID und verifizierte lokale Testsignatur wie 0.3.0. Drei optimierte
Alpha-APKs erfolgreich gebaut und geprüft: ARM64 17.447.960 Byte, ARM32
14.927.604 Byte, x86_64 18.685.754 Byte. Alle normaler Buildcode 7, richtige ABI,
gleiche lokale Testsignatur; neue Sprachtexte im kompilierten AOT-Code geprüft.
Toolchain unverändert;
kein Entwickler-Gerätetest und kein erfolgreicher neuer Remote-APK-Build.

**App 0.3.0+6: universeller Android-Debug-Build erfolgreich**, API 24+, Ziel 36, gleiche Paket-ID, Metadaten und Debug-Signatur geprüft. Drei optimierte kleine Alpha-APKs wurden mit normaler Buildnummer 6 erstellt und per Metadaten, Architektur und gleicher lokaler Testsignatur geprüft; alle unter 25 MiB. Toolchain unverändert wie im historischen Debugnachweis unten; letzte Gerätemessung weiterhin nicht vorhanden.

**App 0.2.3+5: drei optimierte kleine Alpha-APKs erfolgreich gebaut**, Release-AOT mit interner Debug-Testsignatur; Toolchain wie im folgenden Debugnachweis. Die CI-Konfiguration baut zusätzlich weiterhin die universelle Debug-APK, prüft die Struktur früh und hält die kleinen Artefakte 30 Tage bereit. YAML und lokale Befehle sind geprüft; der tatsächliche GitHub-Lauf ist weiterhin blockiert.

**App 0.2.2+4: Android-Debug-Build erfolgreich** mit Flutter 3.35.7/Dart 3.9.2, Temurin-JDK 17.0.20.1, Gradle 8.12, AGP 8.9.1, Kotlin 2.1.0, SDKs 34/35/36, Build Tools 35.0.0, NDK 27.0.12077973 und CMake 3.22.1. Paket-ID `de.aetheria.lebendiger_spielleiter`, Android ab API 24 (7.0), Ziel-API 36. APK-Metadaten (Version 0.2.2, Code 4), erforderliche Rechte und Debug-Signatur wurden geprüft. Keine allgemeine Speicherberechtigung hinzugefügt. Die Debug-Signatur entspricht der vorherigen 0.2.0-APK; ein Update ist damit grundsätzlich möglich, aber noch nicht auf einem Gerät geprüft. Der abschließende Build nach Dateiintegration war erfolgreich.

Anfangs fehlten ein vollständiger Java-Compiler, die Sprachplugin-SDKs und CMake. Diese Entwicklungswerkzeuge wurden installiert. Proxy-/CA-Vertrauen wurde ausschließlich in der lokalen Cloud-Werkzeugumgebung konfiguriert, ohne TLS-Prüfung zu deaktivieren. Lokale Werkzeugpfade und Cloud-Konfiguration gehören nicht zum ZIP. Die CI installiert die benötigten SDK-Komponenten ausdrücklich. Der erfolgreiche lokale Build ist **kein** ausgeführter GitHub-Actions-, Emulator- oder Gerätetest.

## Gesicherter Stand und Fortsetzung

- Letzter gesicherter Funktionsstand: `07c98db` (0.3.1), davor `8dc38b6` für CI-Werkzeuge. Branch `fix/android-voice-reliability` basiert auf dem tatsächlich gelesenen GitHub-main `bc6c942`; keine fremden Dateiinhalte überschrieben. Die frühere unabhängige Historie bleibt lokal als feat/solo-alpha erhalten. Abschließende Dokumentationscommits stehen im tatsächlichen Git-HEAD.
- Zuletzt fertiggestellt: Sprachkorrekturen, robuste Einstellungen und unabhängiger lokaler App-Start 0.3.1; fehlendes sdkmanager als echte CI-Ursache korrigiert. 254 Flutter-, 22 Backend- und 22 Python-Tests, Analyse und Debug-/drei optimierte APK-Builds erfolgreich. Bestehende native I/O-Tests bleiben 12 bestanden, unveränderter Code.
- Aktueller Abschluss: Code, Anbieterfehler und Historie geprüft; lokale APKs mit Version/Architektur/Signatur und neuen Sprachtexten im AOT-Code abgenommen. ARM64 und ARM32 privat auf Drive erstellt und per Größe/MIME/Rechten bestätigt. ARM64 erneut heruntergeladen und byteidentisch per SHA-256 geprüft. Flaches Quell-ZIP enthält 103 Dateien; Webupload in mindestens zwei Stapeln. Keine Schemaänderung, neue Laufzeitabhängigkeit oder kostenpflichtige Modellaufrufe. ZIP-Prüfung und endgültige Downloadlinks/Prüfsummen im externen Checkpoint.
- Bekannte Grenzen: genaue betroffene Sprache und Android-Anbieter unbekannt; Samsung-Sprachkorrektur nicht am Gerät bestätigt. Native TTS-Callbacks besitzen keine Wiedergabe-ID, sehr späte Ereignisse lassen sich deshalb nicht perfekt zuordnen. Kein automatischer Token-Refresh, kein vollständiges Regelwerk, keine abgenommenen produktiven OpenAI-/neuen Actions-APK-Tests. Bestätigte Spielstände bleiben in den ausgeführten Tests erhalten.
- Nächster konkreter Schritt: 0.3.1 auf dem Samsung getrennt für Erkennung und Vorlesen prüfen und ZIP mit CI-Korrektur übernehmen; neuen GitHub-Lauf/Artefakte abnehmen. Ohne Geräte-/Schreibzugriff anschließend Stufe-1-Trefferpunkte aus ausdrücklich gewählter Klasse und bestätigtem Konstitutionsmodifikator vorschlagen: vorher offizielle SRD-Quellen lesen, historische Werte erhalten, Vorschlag/Bestätigung/Persistenz testen.
- Übergabepakete: Dnd-Projekt-0.3.1.zip mit Dateien direkt in der Wurzel sowie Der-lebendige-Spielleiter-0.3.1-arm64.apk/arm32.apk. Externer Dnd-0.3.1-status.json erfasst abschließenden Git-HEAD, SHA-256 und bestätigte private Drive-Links. Alte Übergabepakete bleiben erhalten.
- Der tatsächliche Git-HEAD wird vor jeder Fortsetzung mit `git log -1 --oneline` geprüft. Keine zusätzlichen Credits oder Limit-Zurücksetzungen wurden ausgelöst. Ein erkennbares Kontingentlimit wird nicht aus nicht vorhandenen Messwerten abgeleitet.

## 0.6.8+38 – SRD-Klassenmerkmalregister (16.10.2026)

- **BASIS:** unveränderte Vollversion 0.6.7+37.
- **NEU:** `SrdClassFeatureCatalog` für zwölf Grund- und SRD-Unterklassen, `ClassResourceRules` für Ressourcenstände und Rastregeneration, `ClassCombatFeatures` für Champion-Krit und Schurken-Voraussetzungen.
- **INTEGRATION:** Charakterbogen, Speichermodell, Rast und bestätigte Kampfangriffe; passive Klassenmerkmale bei Bewegung und Initiative.
- **TESTS:** Vorhandene Python-Projekttests ausgeführt; neue Dart-Tests hinzugefügt, aber ohne Flutter-SDK hier nicht ausführbar.
- **OFFEN:** Vollständige automatische Implementierung sämtlicher Klasse-/Unterklassenwirkungen, komplexer Zauber und Entscheidungen – siehe `docs/CLASS_FEATURES_0_6_8.md`.
- **GITHUB:** Kein Push; GitHub-App hat bislang Schreiben mit HTTP 403 abgewiesen.

## Neues Inkrement: Kämpfer-Erstellung und EP (18.10.2026)

Implementiert im separaten Arbeitsstand: SRD-5.2.1-Erfahrungstabelle für
Gesamtstufen 1–20, Übungsbonus-Vorschau und Stufe-1-Kämpferauswahl mit
explizitem Kampfstil, drei Waffenmeisterschaften und Startpaket. Keine
rückwirkende Neuberechnung bestehender Spielstände. Für Kampfstil/Meisterschaft
wird ausschließlich die Wahl dokumentiert; vollständige Kampfeffekte werden
nicht durch die Wahl eines Merkmaltexts aktiviert.

Lokale Python-Projekttests ausgeführt; Flutter-Test, Flutter-Analyse und
Android-Build noch auf GitHub mit Flutter-SDK ausführen. Neues Inkrement
nicht als abgenommene Android-Version bezeichnen.

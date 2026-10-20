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

# Checkpoint 19.10.2026 – individuelle SRD-Startgegenstände (0.8.6+56)

Branch `feature/srd-start-equipment-choices-20261019` ab `main` `8d717230` (PR #15 mit in-App-Version, Porträt-Tests und Fantasy-UI bereits enthalten). Code: `starting_equipment_import.dart` mit expliziter validierter Kategorieauswahl und Fail-Closed bei manipulierten Optionen; `srd_class_selection_dialog.dart` mit Instrument-/Werkzeugauswahl; `character_editor.dart` schreibt bestätigte getypte Gegenstände. Tests: `starting_equipment_choices_test.dart`, `ui_srd_start_equipment_choices_test.dart`. `pubspec.yaml` auf 0.8.6+56.

Nächste Schritte: Vollständigen Dart-Format-/Analyse-/Flutter-/Backend-/APK-Workflow am letzten HEAD verifizieren, Testfehler beheben, dann PR-Review. Kein direktes Löschen alter Spielstände oder Doppel-Auswahl unter falscher Klasse. Weiterhin offen: SRD-Holy-Symbol-/Fokus-Unterkategorien, weitere lizenzierten Ursprungsobjekte, Herkunftstalente, Klassenregeln, echter Android-Test. Kein autonomer Hintergrundlauf behauptet.

---

# Checkpoint 19.10.2026 – Nutzerfreigabe Fantasy-Grafiken

Branch `feature/fantasy-portraits-and-ui-20261019` von `main` `2f392e1`. Genehmigte Assets liegen nun in `app/assets/fantasy/` als offline ladbare Base64-WebP-Dateien: `portrait_atlas.webp.b64`, `night_sky.webp.b64`, `ui_icon_atlas.webp.b64`; Flutter-Assetdeklaration ergänzt. Neue `character_portrait_picker.dart`, `fantasy_approved_icons.dart`; bestehende Flutter-Fantasy-Oberflächen mit filigranen Goldverzierungen, Mondkulisse, fester Speicherleiste und Porträtanzeige erweitert. `HeroCharacter` trägt optionale Bildauswahl bzw. klein eingebettete eigene Bilddaten zur Sicherung/JSON-Migration. image_picker 1.1.x ist per Lockfile geprüft.

**Abnahme offen:** aktuelle vollständige Flutter-Tests, statische Analyse, Debug-/Release-APKs, native Android-Tests sowie echte Gerätegalerie. Kein Merge nach `main` ohne Grünstatus. Bestehende D&D-Regeln dürfen nicht beschädigt werden; Bilder haben keinen Regelaffekt. Noch nicht benötigte Branches nicht ohne bestätigte Merge-/Backupsituation löschen.

---

# Integrations-Checkpoint 19.10.2026

Branch `integration/character-creation-20261019` von `main` `b3e1de65`: PR #11 bereits enthalten; Code aus PR #9 konfliktfrei dreifach abgeglichen (vorheriges gemeinsames Git-Base `82f2786b`), ohne neue PR #11-Merkmale zu entfernen. PR #10 wurde fachlich mit PR #11 verglichen: seine einzigartige ASI-Auswahl (+2 oder +1/+1, bestätigte Attribute ≤20, rückwirkende KO-TP) ist in den bestehenden PR-#11-Regel- und UI-Weg integriert, mit `integrated_character_level_up_test.dart` getestet werden. Der konkurrierende zweite Dialog wird nicht übernommen. **Aktuelle gemeinsame CI und Android-Artefakte offen**; weder fertig noch installiert behaupten.

# CI-Verifizierung – RK und Bewegung, 19.10.2026

[Android-Alpha-Workflow 39201449428](https://github.com/ManuEtt/Dnd/actions/runs/39201449428): **SUCCESS** für Code-Commit `2f7ecb1589723075a09197d2f2f70efcae18477b` im Branch `fix/equipment-import-attributes-20261019` (PR #9). Der anfängliche Widgettest-Fehler beruhte darauf, dass ein Eingabefeld nach dem Scrollen nicht mehr im lazily gerenderten ListView montiert war; der Test wurde korrigiert und der **gesamte** Workflow erneut erfolgreich durchlaufen. Backend-, Flutter-, Android-Debug-/Native- und kompakte Alpha-APK-Schritte sind erfolgreich. Gerätetest und Review/Merge in `main` fehlen weiterhin. Keine vollständig implementierte SRD-Gesamtabdeckung behaupten.

---

# Zwischenstand 19.10.2026 – Fehlende RK/Bewegung korrigieren

PR #9, Branch `fix/equipment-import-attributes-20261019` ergänzt jetzt zusätzlich zum bereits CI-geprüften Ausrüstungsimport die Berechnung fehlender Kampfwerte: SRD-Speziesgeschwindigkeit, ungerüstete Grund-RK inkl. Mönch/Barbar, automatisch nach bestätigten Feldern im neuen Charaktereditor und explizit bei alten Figuren. `speedRemainderDecimeters` als optionales Legacy-sicheres JSON-Feld (Goliath/Waldelf 10,5 m) und angepasste Erschöpfungsbewegung; vorhandene manuelle Werte bleiben erhalten.

Neu: `app/lib/domain/srd_starting_combat_values.dart`, `app/test/srd_starting_combat_values_test.dart`, `app/test/ui_starting_combat_values_test.dart`; Änderungen an `models.dart`, `condition_rules.dart`, `character_editor.dart`. **CI-Durchlauf für dieses Inkrement ausstehend**, bisheriger grüner Stand `39199122240` gilt nur für den vorangegangenen Import-Fix. Keine Freigabe oder Merge ohne vollständige Analyse, Tests, APK und reale Geräteabnahme. SRD 5.2.1 bleibt insgesamt unvollständig.

---

# Checkpoint: Ausrüstungsattribute beim Import, 19.10.2026

Branch `fix/equipment-import-attributes-20261019` von `main` `82f2786b`. Parallel existiert PR #8 für die Aufstehen-Regel, hier bewusst nicht vermischt. Diese Änderungen: `app/lib/domain/starting_equipment_import.dart`, `app/lib/domain/models.dart`, `app/lib/ui/character_editor.dart`, `app/test/starting_equipment_import_test.dart`, `app/test/ui_starting_equipment_import_test.dart`. Alte Klassenstartsets bekamen bisher nur Namen und Mengen; nun werden eindeutige Katalog-IDs samt strukturierten Daten geschrieben. Validierte Katalog-ID ohne Stats wird beim Import wiederhergestellt, vorhandene individuelle Daten werden nicht überschrieben. Altgegenstände ohne ID werden erst nach expliziter UI-Vorschau und Bestätigung angereichert. 20 Pfeile werden korrekt als eine 20er-Packung behandelt.

Verifizierte CI: kompletter GitHub-Actions-Lauf [39199122240](https://github.com/ManuEtt/Dnd/actions/runs/39199122240) auf `a8f2f090` erfolgreich (Format, Analyze, Flutter-/Backendtests, Android-Debug-APK, native Tests, APK-Artefakte). Noch erforderlich: Test auf echtem Android-Gerät, Review, Merge/Statusabgleich und weitere SRD-Inkremente. Unbekannte Auswahlgegenstände bleiben bewusst offen. Für den Nutzerwunsch „komplettes D&D-Regelwerk“: nur lizenzierte SRD-5.2.1-Regeln und nachweislich getestete Regel-IDs implementieren, alle sonstigen als TEILWEISE/FEHLT führen; Details in README/Regelmatrix. **Dieser Checkpoint ist keine Freigabe.**

---



---

# Checkpoint 19.10.2026 – Charaktererstellung und Klassenaufstieg

Branch `feature/srd-character-level-up-20261019` ab `main` `cadaf7369f8899f29370fb28dfdc2a92c0ba98aa`. Die zwei offenen SRD-Charakter-/Ausrüstungsstränge aus anderen PRs nicht einfach überschreiben: vor Integration HEAD/PRs und eventuelle Konflikte prüfen.

**Neue Dateien:** `app/lib/domain/srd_class_level_up.dart`, `app/lib/ui/srd_class_level_up_dialog.dart`, `app/lib/domain/srd_character_creation_audit.dart`, `app/test/srd_class_level_up_test.dart`, `app/test/ui_srd_class_level_up_test.dart`, `app/test/srd_character_creation_audit_test.dart`. Geändert: `app/lib/ui/character_editor.dart` sowie README, CHECKPOINT, CHANGELOG, DEVELOPMENT_STATUS, SRD-Matrix.

**Funktion:** Klassenaufstieg der bisherigen 1. und bereits existierenden 2. Klasse (kein automatisches freies Drittklassenmodell) inkl. fixer TP, EP-Prüfung oder ausdrücklich bestätigtem Meilenstein, exakten Zustandsvergleichs vor Übernahme, begrenzter SRD-Unterklassenwahl, tabellarischer Merkmalsvorschau und offen notierter nicht automatisierter Wahl. SRD-Erstellungsprüfung zeigt gefüllte/fehlende/nicht implementierte Felder, ohne Spielstände zu ändern. **Keine pauschale vollständige Klassenregellogik**, insbesondere nicht Feat-/Herkunftstalent-/Zauber-/Unterklassen-Mechaniken.

**Abnahme offen:** Aktueller Branch-HEAD und GitHub Actions auf Format/Analyse/Fluttertest/Backend/APK prüfen, Fehler beheben, auf Android-Gerät testen, erst danach PR-Freigabe. Bei Auftragsfortsetzung wieder hier und in der Regelmatrix beginnen.

---

# Entwicklungscheckpoint 19.10.2026 – Aufstehen / Bewegungsbudget

Branch `feature/prone-stand-movement-20261019`, basiert auf GitHub-`main` `82f2786b17d626dbecbe31e788b2a2201a05e275`; PR #7 ist inzwischen in `main` übernommen. Neue Änderungen bleiben bis zur vollen CI-Abnahme separat.

Implementiert: typisierte Standkosten und Restberechnung in `prone_movement_rules.dart`; `Encounter.movementRemainderDecimeters` als optionales Schema-1-Feld; `GameEngine.standUp`, `GameController.standUp`, deutsche Abenteueraktion und genaue Bewegungsanzeige; Sperre gegen kostenlose Charaktereditor-Korrektur im laufenden Kampf und gegen normales Gehen im Zustand `liegend`. 9 m -> 4,5 m Standkosten; 7,5 m -> 3,6 m nach SRD-Rundung in Fuß. Tests: `app/test/prone_standing_rules_test.dart` und `app/test/prone_standing_storage_test.dart`.

**Nicht als abgeschlossen ausgeben:** neueste GitHub Actions, Android-APK und Gerätetest sowie Kriechen, Positionen, Terrain und Sonderbewegungen. Kein Code im `main` direkt geändert. Nach neuestem Branch-HEAD die CI/Logs prüfen, Fehler beheben und erst dann PR freigeben.

---

# Entwicklungscheckpoint vom 19.10.2026 – Bewusstlos / Liegend

Branch `feature/condition-source-ledger-20261018`, PR [#7](https://github.com/ManuEtt/Dnd/pull/7) gegen `main`. Der letzte bereits erfolgreich durchlaufene vollständige GitHub-Workflow war [39165288268](https://github.com/ManuEtt/Dnd/actions/runs/39165288268) für `c000e78b`. Die **neuen** Änderungen zu Bewusstlos/Liegend müssen separat durch CI und Android-Build abgenommen werden.

Neue Engine-Logik: bestätigte Bewusstlosigkeit hinterlässt Liegend als unabhängige manuelle Folge, selbst bei Heilung, natürlicher Todesrettungs-20 und Entfernung/Ablauf quellgebundener Effekte. Alte JSON-Spielstände verändern sich nicht beim bloßen Einlesen. Eine bestätigte handlungsunfähige Charakterbogenänderung beendet Konzentration. Neue Tests: `app/test/unconscious_prone_test.dart`. Regelmatrix, CHANGELOG und README aktualisiert. Offen: Format, statische Analyse, Flutter-/Backend-Suite, Android-Pakete und reales Gerät; Aufstehen, abgelegte Gegenstände und Fremdzielpositionsregeln weiterhin nicht implementiert.

---

# GitHub-Zwischencheckpoint – Quellgebundene Zustände, PR #7 (18.10.2026)

Branch: `feature/condition-source-ledger-20261018`; Basis `main` bei `2b2618a45158d068a8cf37ab3d133a9b11ca10fb`; Pull Request: https://github.com/ManuEtt/Dnd/pull/7. Vor Merge oder weiterer Arbeit **tatsächlichen Branch-HEAD, Checks und PR-Status neu prüfen**. Keine Änderung direkt auf `main`.

Implementiert auf dem Branch: getrennte manuelle und quellgebundene Zustände, strenge JSON-Validierung, deduplizierte Lesesicht, reine Quell-/Ablaufmutationen, Zugendrand der aktuellen Begegnung, Klassenzustandsheilung, Charakterbogenquellen und Domain-/Widgettests. Regel-ID `EFFECT-SOURCE-DURATION` bleibt **TEILWEISE**; Matrix in `docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md`.

CI: Dieser Eintrag ist **kein grüner Prüfbeleg**; endgültige GitHub Actions des PR #7 müssen noch ausgewertet werden. Flutter/Dart-SDK ist in der hier genutzten lokalen Umgebung nicht vorhanden; keine lokalen Testläufe behaupten. Quellcode liegt im GitHub-Featurebranch; ein vollständig geprüftes neues APK-/ZIP-Artefakt erst nach erfolgreichem Workflow nennen.

Nächster Schritt: Format, Analyse, Tests und APK vollständig grün bekommen; anschließend neue Domain-/UI-/SQLite-Tests vollständig grün abnehmen, Gerät testen sowie allgemeine Zeit-/SRD-Effektquellen weiter ausbauen. Keine allgemeinen Echtzeit-/fremden-Zug-Dauern erfinden.

---

# Neuer Entwicklungsstand: 0.8.1+51 – Arescan entkoppelt (18.10.2026)

**Basis:** lokales vollständiges Projekt-ZIP 0.7.9+49 plus erste Etappe der UI-/Itemwert-Darstellung.

Umgesetzt: kein Arescan-Startspielstand/-Button, keine Arescan-Sonderhandlung im Produktivcode, keine Arescan-Datei im `app/assets`-Paket. Bestehende lokale und importierte Spielstände bleiben erhalten. Ältere Arescan-Daten werden ausschließlich in Kompatibilitätstests geladen. Für importierte Nicht-Demo-Kampagnen wurde die Rückfallbehandlung von Mooswacht-Skriptmechaniken abgekoppelt. Neues Versionskennzeichen 0.8.1+51.

**Prüfungen:** Python-Kompatibilitäts-/Paket-Tests und Strukturprüfung lokal; Flutter-/Android-Build noch nachzuholen (SDK hier nicht vorhanden). Alle tatsächlichen Prüfungen im Begleitbericht des Pakets dokumentiert.

**Als Nächstes:** `dart format`, `flutter analyze`, `flutter test` und Android-Build; die von bestehenden Widgettests ausgeführten JSON-Importpfade überprüfen, anschließend weitere UI-/Itemdatenmodell-Arbeiten.

---

# Würfelraunen – geprüfter Checkpoint 0.7.9+49

Stand: 18.10.2026, 06:28 UTC. Entwicklungsbranch: `feature/autonomous-srd-engine-20261016`. Letzter vollständig geprüfter Codecommit: `99b8a7bbed9c07132bf49e5eb78be9cfeb391d71`; danach nur Abschlussdokumentation. Der exakte finale HEAD steht im Dateimanifest und in `git log`.

## Basis und GitHub

Patchbasis dieser Fortsetzung: **c889ab6619fe88bd48a420bc45f12d2751af94f7** (GitHub-main, enthält bereits den bisherigen 0.7.7-Code). Konfliktfrei in den eigenen Branch übernommen; main nicht verändert. Der GitHub-main-Build [39055088686](https://github.com/ManuEtt/Dnd/actions/runs/39055088686) ist erfolgreich. Das ist keine Remote-CI-Abnahme des neuen Codes.

Der erneute Push am 18.10.2026 scheiterte mit HTTP403: `Permission to ManuEtt/Dnd.git denied to ManuEtt.` Kein erfolgreicher Remote-Branch/PR behauptet. Lokal sind geprüfte Commits und vollständige ZIPs/Patches vorhanden. Kein Force-Push, keine automatische Codex-Action, keine Credits/Limit-Zurücksetzung.

## Implementiert und angebunden

1. **0.7.8+48, Commit a2dd0da:** explizites eigenes Zugende ohne Aktion auch bei Handlungsunfähigkeit/stabilen 0 TP; echter UI-Button, SQLite/Ereignis. Kampfrauschablauf vor Gegnerangriff, Ausweichen verliert Wirkung bei Handlungsunfähigkeit/Sichtverlust/Bewegungsrate 0, positive 0,5 m bleiben positiv. Mönch-Selbstwiederherstellung ohne Aktionsbedarf; Gegnererstzug löst keinen eigenen Endrand aus.
2. **0.7.9+49, Commit b0fad28:** Todesrettungen mit Mönch-14-Übungsbonus, Erschöpfung genau einmal und Fokus-/Kämpfer-9-Unbeugsam-Wiederholung. Tatsächliche Klassenstufen, verbindlicher Ersatzwurf, natürliche 1/20 und Ressourcen bei 0 TP. Vorläufigen Fehlschlag erst nach Annehmen/Wiederholen bestätigen, einschließlich drohendem drittem Fehlschlag. Deutsche Auswahl, Neustart, atomare Speicherung und Revisionsschutz integriert. Eine Todesrettung pro eigenem Kampfzug; danach Zugende oder nach natürlicher 20 weiterspielen.
3. **Korrektur 99b8a7b:** extern bestätigter KO und bestätigte handlungsunfähige Charakterzustände beenden Kampfrausch/Ausweichen sofort und dauerhaft. Spätere Heilung reaktiviert keinen alten Kampfrausch. Bestehenden Erschöpfungstest an die jetzt angezeigte Version-1-Anfrage angepasst; alte gespeicherte Modifikator-0-Anfragen bleiben lesbar.

Regelquellen, Code und Grenzen: `docs/DEATH_SAVES_0_7_9.md`, `docs/RULE_COVERAGE.md`, `THIRD_PARTY_NOTICES.md`. Schema 1 bleibt kompatibel: zusätzliche Felder sind optional, ungültige Entscheidungen werden vollständig abgelehnt. Katalogeinträge sind keine umgesetzten Mechaniken; das vollständige SRD ist offen.

## Letzte verifizierte Prüfungen

**692 Flutter-, 31 Backend-, 56 Python- und 12 native Android-/JVM-Tests bestanden; 0 Fehler/Skips.** Flutter einschließlich echtem Node-/Dart-Protokolltest ohne kostenpflichtigen KI-Anbieter. Formatprüfung: 132 Dateien, 0 Änderungen. Analyse ohne Befunde. Backend-Typecheck/Build erfolgreich. Insgesamt 57 neue Fälle seit der übernommenen 0.7.7-Basis; gezielter Korrekturlauf 67/67 einschließlich zehn bestehender Erschöpfungsfälle.

Der erste Gesamtlauf hatte 688 Erfolge und eine veraltete Erwartung für den angezeigten Todesrettungsmodifikator. Korrigiert; erneuter vollständiger Lauf mit 692 Erfolgen. Keine offenen Test-/Analyse-/Buildfehler. Belege und Befehle: `docs/VALIDATION_0_7_9.md`, Logs in `/workspace/validation/0.7.9-*-final.log` bzw. `0.7.9-check-final.log`.

Debug-APK tatsächlich aus dem entpackten, verifizierten Korrektur-ZIP gebaut. 203 Quell-/Test-/Builddateien bytegleich mit aktuellem Code geprüft; danach nur Dokumentation. APK-CRC, aapt-Metadaten und apksigner erfolgreich: **0.7.9+49**, minAPI24/target36, ARM64/ARMv7/x86_64, 142493733 Bytes. APK-SHA256: `0b38dab8d03e001b46a2e925359d729842100b6b6e8053ab862de06a78f34c7b`. Lokale Debug-Testsignatur; keine Store-Freigabe.

**Nicht getestet:** Emulator/reales Gerät, tatsächliche Sprache-/SAF-Interaktion, Updateinstallation auf bestehende APKs, produktiver KI-Anbieter, neue Release-APKs je ABI. Der alte vor der letzten Korrektur gebaute APK-Kandidat bleibt mit `vor-korrektur` im Namen erhalten; final ist `Wuerfelraunen_0.7.9+49_Debug.apk`.

## Reale Artefakte und Import

Ablage außerhalb Repository: **/workspace/artifacts**. Finale Namen: `Wuerfelraunen_0.7.9+49_<UTC>_todesrettung_Vollprojekt.zip`, dazu `_Aenderungen.patch`, `_Dateimanifest.json` und `_SHA256SUMS.txt`. Stabiler ZIP-Alias: `Wuerfelraunen_LATEST_Vollprojekt.zip`. Separate finale APK, APK-Prüfbericht und globale/versionierte Prüfsummen. Exakte reale Dateinamen und finaler HEAD: `/workspace/artifacts/ARTEFAKTE.md`.

ZIP, Manifest und gefiltertes vollständiges Projekt werden byte-/modusgenau verglichen; Binärpatch wird tatsächlich auf sauberer c889ab6-Basis angewendet und gegen alle Quelldateien geprüft. Kein Git-Verzeichnis, SDK, Cache, Geheimnis oder APK im Quell-ZIP. Frühere vollständige 0.7.7-/0.7.8- und vorsorgliche Zwischenstände bleiben erhalten. Workspacepfade sind keine behaupteten externen Uploads.

Importanleitung: **IMPORT_0_7_9_49.md**. ZIP entpacken und Inhalte einschließlich `.github/` in einen neuen Klon auf eigenem Branch übernehmen; ZIP-Upload in GitHub entpackt nichts. Alternativ auf sauberer c889ab6-Basis `git apply --check <patch>` / `git apply <patch>`, prüfen, committen, pushen und PR erstellen. Neuere eigene Änderungen erhalten. Alte Patches dieser Sitzung haben teils die frühere Basis b66354f; nicht verwechseln. Prüfsummen: `sha256sum --ignore-missing -c Wuerfelraunen_0.7.9+49_SHA256SUMS.txt`.

## Offener Umfang und nächste drei Schritte

1. **Quellgebundene Zustände/Dauern implementieren.** `docs/CONDITION_EFFECT_DESIGN.md` ist ausschließlich Entwurf. Zuerst manuelle Zustände von abgeleiteten Quellen trennen, bestehende Mutatoren prüfen und kompatible JSON-Felder/Entfernen/Zugenden samt echten Speicher-/UI-Tests integrieren. Keine pauschalen Zeitgeber ohne bestätigte Weltzeit.
2. Optionale Klassenwiederholung von Konzentrationsrettungen und weitere Reaktionen an denselben bestätigten Entscheidungs-/Ressourcenablauf anschließen. Allgemeine Positions-/Sicht-/Reichweiten-/Gelegenheitsangriffsregeln bleiben teilweise offen.
3. Echte Fremdziele/Gruppenmitglieder, weitere verifizierte SRD-Zauber-, Gegenstands- und Monsterwirkungen ergänzen; volle Klassenstufen/Talente/Spezies/Hintergründe und Geräteabnahme fortsetzen. Keine bloßen Katalogergänzungen als Regelerfolg zählen.

## Exakte Wiederaufnahme

AGENTS.md, `docs/prompts/Wuerfelraunen_Codex_Masterprompt _Autonome_Entwicklung.md` (tatsächlich mit Leerzeichen), CHECKPOINT, DEVELOPMENT_STATUS, RULE_COVERAGE und VALIDATION_0_7_9 lesen. Tatsächlichen `git status`, Branch, HEAD und Remote gegen letztes Manifest prüfen. Neuere Dateien nicht mit älterem ZIP überschreiben. Ausgangscheckpoint vor größeren Änderungen erzeugen.

Werkzeuge hier außerhalb Repository: Flutter 3.35.7/Dart3.9.2 unter `/workspace/toolchains/flutter/bin`, Node22.14.0 unter `/workspace/toolchains/node-v22.14.0-linux-x64/bin`, Java17 unter `/workspace/toolchains/jdk17`, SDK `/workspace/toolchains/android-sdk`, Gradle-Cache `/workspace/toolchains/gradle-cache`. Linux-SQLite: `LD_LIBRARY_PATH=/workspace/toolchains/sqlite/lib`; frische Umgebungen brauchen libsqlite3-dev.

```bash
PATH=/workspace/toolchains/node-v22.14.0-linux-x64/bin:/workspace/toolchains/flutter/bin:$PATH LD_LIBRARY_PATH=/workspace/toolchains/sqlite/lib bash scripts/check.sh
# Android mit JAVA_HOME/SDK/Proxy-CA wie docs/VALIDATION_0_7_9.md und /workspace/validation/TOOLCHAIN.md:
cd app
flutter build apk --debug
cd android
./gradlew :app:testDebugUnitTest --no-daemon
```

Neue Sicherung aus Repositorywurzel: `python3 scripts/create_checkpoint.py --output-dir /workspace/artifacts --base c889ab6619fe88bd48a420bc45f12d2751af94f7 --label <name>`. Vor langen/riskanten Schritten CHECKPOINT aktualisieren und sichern. Bei tatsächlicher Limitwarnung laufenden Schritt konsolidieren statt neue große Arbeit zu starten; automatische Sitzungswiederaufnahme nicht voraussetzen.

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

## 0.8.14+64 – Abenteuer-Status und Auftragsübersicht (19.10.2026)

- Neuer Fantasy-HUD im Abenteuerbildschirm mit 2- bis 4-spaltigem, responsivem Raster für tatsächlich bestätigte Trefferpunkte, Rüstungsklasse, Bewegungsrate und Erfahrungspunkte. Trefferpunkte- und EP-Fortschritt erscheinen nur bei bestätigten Werten.
- Temporäre TP, dokumentierte Zustände, Konzentration und regelgeprüfter Stufenaufstieg werden angezeigt, ohne Spielwerte oder Zustände zu verändern.
- Neue aufklappbare Auftragsübersicht liest ausschließlich die bestätigten `Campaign.quests`, unterscheidet aktiv/abgeschlossen/gescheitert und bietet einen direkten Tagebuchaufruf.
- Der Abenteuerkopf führt Aktionen auf schmalen Displays in einer separaten, umbrechenden Leiste; Import/Export, Charakterbogen, Ausrüstung, Zustände und Heilung bleiben auf ihren bisherigen Controller-Aktionen.
- Tests für kleine und breite Displays, große Schrift, unbekannte Werte, Queststatus und Tagebuchnavigation. Vollständige GitHub-CI-/APK-Abnahme für den finalen Commit gesondert prüfen; ein echter Android-Gerätetest steht noch aus.

## 0.8.13+63 – Illustrierte Heldenübersicht (19.10.2026)

- Neuer Fantasy-Dashboard-Bereich auf der Startseite bei vorhandenen Kampagnen: gespeichertes Charakterporträt, Name, Klasse, Stufe und Kampagnentitel.
- Trefferpunkte mit tatsächlichem Maximum und visualisiertem Zustand, Rüstungsklasse, bestätigte Bewegung einschließlich 0,5 m, EP-Fortschritt und regelgebundener Aufstiegshinweis. Historisch unbekannte Werte bleiben sichtbar unbekannt.
- Direktaktionen „Abenteuer fortsetzen“ und „Helden verwalten“ nutzen die vorhandenen Controller- und Navigationswege ohne zusätzliches Datenbankschema.
- Neue Widgettests mit 320/360/960 dp, echten/fehlenden Werten, Touch-Aktionen und Stufenaufstieg. Android-CI und Geräteprüfung sind getrennt nachzuweisen; der erste erfolgreiche CI-Lauf auf dem finalen Commit entscheidet über die technische Freigabe.

## Unveröffentlicht – Version 0.8.6+56 / ausdrückliche SRD-Startpaketwahl (19.10.2026)

- Barden: konkrete Auswahl eines SRD-Musikinstruments; Mönche: konkrete Auswahl eines SRD-Handwerkszeugs oder -Musikinstruments statt eines untypisierten Platzhalters.
- Auswahl-ID wird gegen die jeweilige Klassenset-Kategorie geprüft und beim Übernehmen als strukturierter Kataloggegenstand mit Preis und Gewicht geschrieben; manipulierte/stale IDs werden abgewiesen, Wechsel der Klasse/Startausrüstung setzt Auswahl zurück.
- Unbekannte, nicht im SRD-Katalog abgedeckte Gegenstände bleiben explizit ohne erfundene Eigenschaften; keine automatische Ausrüstung.
- Regressionstests für alle zwölf Sets und echte Klassenassistenten-Auswahl. Version in `pubspec.yaml` erhöht; Anzeige im Einstellungsbildschirm folgt automatisch.
- Neuer PR wird vor Android-Gerätetest, CI-Abnahme und Review nicht als fertig freigegeben.

## Unveröffentlicht – Versionsanzeige, Porträt-CI und Repositorypflege (19.10.2026)

- **Optionen → App-Version:** Paketversion und Android-Buildnummer aus der gebündelten `app/pubspec.yaml`; kein hartcodierter zweiter Versionsstand. Unit- und Bundle-Test hinzugefügt.
- Porträt-Regressionstests wieder kompilierbar: `HeroCharacter` ist keine const-Klasse; fehlerhafte const-Fixtures korrigiert.
- Nach belegtem Merge-Nachweis und exaktem Branch-HEAD zehn erledigte GitHub-Feature-/Integrationsbranches gelöscht. Main und nicht zusammengeführte Arbeitszweige bleiben.
- Integration in `main` erst nach grüner vollständiger CI dieses separaten Fixes.

## Unveröffentlicht – Fantasy-UI und Charakterporträt (19.10.2026)

- Neun bestätigte Fantasy-Charakterporträts als offline eingebetteter WebP-Atlas, Galerie mit Vorschau, Übernehmen/Abbrechen, Auswählen/Entfernen und eigener Bildwahl via Android-System-Bildwähler.
- Selbsterstellte Bilder werden klein in den Character-JSON-Daten statt in temporären Cachepfaden gespeichert; sichere ID-/Größenprüfung, ältere Savegames unverändert.
- Nächtliche Burgkulisse und echte goldene Icons aus den freigegebenen UI-Grafiken; wiederverwendbare Ornamentrahmen für FantasyPanel.
- Charaktereditor: stets sichtbare Schaltflächen Speichern/Abbrechen; Porträt auf Charakterliste und Charakterbogen.
- Neue Domain- und Widgettests; CI-/Geräteabnahme für diesen Entwicklungszweig noch offen.

## Integration 19.10.2026 – PR #11 und PR #9

- SRD-Klassenaufstieg und Erstellungsprüfung aus PR #11 mit der Startausrüstung/RK/Bewegungs-Korrektur aus PR #9 auf separatem Integrationsbranch zusammengeführt. Integrationstest und Merge nach `main` stehen aus. Die gegenüber PR #11 neue Funktion aus PR #10 – validierte ASI (+2/+1+1) mit rückwirkender KO-TP-Berechnung – wurde in den vorhandenen Klassenaufstiegsdialog übernommen. Der alternative doppelte Dialog wird nicht eingebaut.

**Prüfnachweis (19.10.2026):** RK-/Bewegungs-Fix im vollständigen GitHub-Lauf [39201449428](https://github.com/ManuEtt/Dnd/actions/runs/39201449428) auf `2f7ecb15` erfolgreich; echte Android-Geräteabnahme und Merge noch offen.

## Unveröffentlicht – Start-RK und Spezies-Bewegung (19.10.2026)

- Vorher fehlende `Rüstungsklasse` und `Bewegung` bei der Erstellung werden nach tatsächlich bestätigten Klassen-, Spezies- und Attributwerten vorgeschlagen (10 + GE; bei ungerüstetem Barbar KON und ungerüstetem Mönch WEI).
- SRD-2024-Spezies: 9 m / 30 Fuß üblich, 10,5 m / 35 Fuß für Goliath/Waldelf; optionales Feld `speedRemainderDecimeters` für exakte halbe Meter und alte Spielstände unverändert.
- Automatische Berechnung beim Neuanlegen bzw. Bestätigen der Attribute; ältere Figuren erhalten einen expliziten Button für fehlende Werte. Manuelle Werte und ungeklärte Spezies werden nicht überschrieben/erraten.
- Angelegte Rüstung/Schilde weiterhin nur nach separater ausdrücklicher Bestätigung wirksam. Domain-/Widgettests ergänzt, Android- und CI-Prüfung für diese neue Änderung ausstehend.

## Unveröffentlicht – Ausrüstung im Klassenassistenten/Import (19.10.2026)

- Fehlerursache: SRD-Startsets wurden bisher nur als Name/Menge, ohne `catalogId` und `InventoryItemStats`, übernommen.
- Neue `StartingEquipmentImport`-Zuordnung für eindeutige SRD-Katalogeinträge in allen zwölf Startklassen. Ungeklärte Optionen bleiben ohne erfundene Werte; 20 Pfeile werden als genau eine 20er-Packung gespeichert.
- Vorhandene `catalogId`-Importe ohne `stats` werden rekonstruiert, **eigene Stats werden nie überschrieben**. Bereits gespeicherte freie Altgegenstände können nach explizitem Preview und Bestätigung im Charaktereditor sicher ergänzt werden.
- SRD-Katalogtexte werden, falls vorhanden, als Beschreibung übernommen. Ausrüstung und magische Wirkung werden nicht stillschweigend aktiviert.
- Regressionstests für alle Klassensets, Inventar/Altimport und Editor nachgerüstet. **CI-/APK-Abnahme für diesen Fix ausstehend.** Komplettimplementierung des SRD nicht behauptet.



---

## Unveröffentlicht – Klassenentwicklung und SRD-Erstellungsprüfung (19.10.2026)

- `SrdClassLevelUpRules`: fixer klassenspezifischer TP-Zuwachs, 1-stufiger Aufstieg in eine der vorhandenen Klassen, EP-Schwellenprüfung oder expliziter Meilenstein, Schnappschuss-/Stale-Prüfung und Level-20-Grenze.
- SRD-Klassenmerkmale des nächsten Levels werden nur als Vorschau gezeigt. Nicht automatisierbare Talente/Unterklassen/-fähigkeiten bleiben als offene Wahl notiert statt ungeprüft gewährt; explizite Hauptklassen-Unterklasse auf Stufe 3 aus lizenzierter Auswahl.
- Neuer deutscher Dialog im Charaktereditor, finaler Spielstandswechsel erst nach Charakterbogen-Speichern.
- SRD-Erstellungsprüfung mit fehlenden und technisch noch nicht automatisierten Schritten für alle zwölf Basisklassen.
- Tests der gesamten 12-Klassen-Festwertprogression, Meilensteine, Talente, Zweitklassenaufstieg, Datenänderungen, Grenzen und UI. **CI-/APK-Abnahme ausstehend; vollständige 5.2.1-Abdeckung weiterhin offen.**

## Unveröffentlicht – Prone: regelkonformes Aufstehen (19.10.2026)

- Explizite Aufstehen-Aktion mit Bewegungskosten in Fuß: Hälfte der bestätigten aktuellen Bewegungsrate, abgerundet, keine Aktion/Bonusaktion. 
- Dezimetergenaues Bewegungsrestfeld im bestehenden Begegnungs-JSON (Schema 1, optional; alte Spielstände bleiben lesbar). 30 Fuß: 4,5 m; 25 Fuß: 3,6 m.
- Deutsche Schaltfläche im Abenteuer, revisionsgeschützte Controller-Aktion, atomarer SQLite-Ereignischeckpoint.
- Kein Aufstehen bei fehlendem Budget, Bewegungsrate 0, Bewusstlosigkeit, fremdem Zug oder aktiver verbleibender Zustandsquelle; Editor kann aktive Kampfbewegung nicht umgehen. Normales Laufen im Zustand `liegend` wird geblockt, Kriechen ist noch offen.
- Neue Domain- und SQLite-/Revisions-/Rollbacktests in `prone_standing_rules_test.dart` und `prone_standing_storage_test.dart`. **Vollständige CI-/APK-Abnahme ausstehend**; keine Gerätefreigabe.

## Unveröffentlicht – SRD 5.2.1: Bewusstlos hinterlässt Liegend (19.10.2026)

- Bestätigtes Bewusstloswerden setzt `liegend` als unabhängige, persistierte Folge; bei Erwachen durch Heilung/natürliche Todesrettungs-20 oder Ende einer separaten Quelle bleibt der Zustand erhalten.
- Altdaten werden beim Lesen nicht verändert; neue bestätigte Regelaktionen ergänzen die Folge. Bewusstlos-Quellen behalten weiterhin eigene IDs und Ablaufgrenzen.
- Manuell bestätigte Handlungsunfähigkeit beendet nun auch bei Änderungen im Charakterbogen die Konzentration.
- Neue Regressionstests in `app/test/unconscious_prone_test.dart`. Der Gesamtworkflow für dieses neue Inkrement ist **noch nicht als erfolgreich dokumentiert**; letzte grüne Vorversion: `c000e78b` / Actions `39165288268`.

## Unveröffentlicht – PR #7: Ursachengetrennte Zustände (18.10.2026)

- Optionales Zustandseffekt-Register mit eindeutigen IDs, Quellen und eigenen Zugendpunkten; manuelle/Legacy-Zustände bleiben getrennt. Effektiver Regelzustand dedupliziert die Ursachen ohne sie zu verlieren.
- Quellenpersistenz, Validierung, Schaden/Heilung, Todesrettung und Erschöpfung auf Eigentümertrennung angepasst; Paladin/Mönch beenden nach bestätigter Regel sämtliche Ursachen eines ausgewählten Zustands.
- Zugendgültige Effekte nur in der jeweiligen Begegnung ablaufen lassen; Anzeige der Quellen im Charakterbogen und effektiver Zustände im Abenteuerbereich.
- Neue bestätigte Bedienoberfläche und revisionsgesicherte GameEngine-/GameController-Aktionen zum Anlegen und gezielten Entfernen einzelner Quellen. Neue handlungsunfähige Zustände beenden Konzentration und Kampfrausch/Ausweichen sofort.
- Domänen-, Widget- und echte SQLite-Neustart-/Rollback-/Konflikttests ergänzt. Status: **nicht freigegeben, CI-/APK-Abnahme ausstehend**; allgemeine Weltzeit und Geräteszenarien bleiben offen.

## 0.8.1+51 – Kein fest eingebauter Arescan-Spielstand (18.10.2026)

- Festen Startknopf und Startgeschichte von Arescan entfernt; keine automatische
  Generierung oder eingebettete JSON-Datei mehr im Android-App-Asset-Paket.
- Testdaten nur noch in `app/test/fixtures/arescan_legacy.json`. Tests importieren
  sie manuell, statt einen Produktionscodepfad zu verwenden.
- Historische Nutzerspielstände bleiben über SQLite / JSON-Import erhalten,
  werden aber nicht automatisch gelöscht oder wiederhergestellt.
- Für andere importierte Kampagnen keine festen Mooswacht-Demo-Ereignisse mehr;
  regelunklare Kämpfe blockieren ohne erfundene Werte.
- Regressionstests für Startbildschirm und importierte Alt-Daten ergänzt.

## 0.7.9+49 – Todesrettungen mit Klassenentscheidung (18.10.2026)

- Todesrettungen verwenden jetzt Mönch-14-Rettungswurfübung und den Erschöpfungsmalus genau einmal. Natürliche 1/20 behalten ihre Sonderfolgen; Kämpfer-9-Unbeugsam addiert beim Ersatzwurf die tatsächliche Kämpferstufe.
- Ein fehlgeschlagener Wurf mit verfügbarer Wiederholung bleibt vorläufig: deutsche Auswahl zum Annehmen oder Wiederholen, mit Neustart erhaltener Entscheidung. Auch ein drohender dritter Fehlschlag lässt sich ersetzen. Verbrauch und Folgen werden erst gemeinsam bestätigt.
- Im aktiven Solokampf nur eine Todesrettung pro eigenem Zug; anschließend bewusstlos den Zug beenden oder nach natürlicher 20 normal fortsetzen. Gegnerzug, offene Entscheidung, veraltete Oberfläche und manipulierte Importe sind gesperrt.
- Kampfrausch und Ausweichen enden auch bei extern bestätigtem KO und beim Bestätigen handlungsunfähiger Charakterzustände sofort; spätere Heilung reaktiviert keinen alten Kampfrausch.
- 57 neue gezielte Fälle sowie 10 bestehende Erschöpfungsregressionen erfolgreich: 19 Todesrettungs-Domänenfälle, 18 Ablauf-/UI-/SQLite-Fälle und 20 Zuggrenzenfälle. Gesamtprüfung erfolgreich: 692 Flutter-, 31 Backend-, 56 Python- und 12 native Tests; Analyse/Format sauber und korrigierte Debug-APK aus geprüftem ZIP gebaut. Nachweise in CHECKPOINT.md. Quelle und genaue Grenzen: docs/DEATH_SAVES_0_7_9.md.

## 0.7.8+48 – Korrekte eigene Zuggrenzen (17.10.2026)

- Reines Zugende trotz Handlungsunfähigkeit, auch für stabile bewusstlose Figuren; eigener UI-Button und atomare SQLite-Speicherung. Keine Ausweichaktion durch Textbeimischung.
- Kampfrausch endet vor dem folgenden Gegnerangriff, wenn sein Endzeitpunkt erreicht ist, sowie endgültig bei Handlungsunfähigkeit. Ausweichen verliert Wirkung bei Handlungsunfähigkeit, Sichtverlust oder Bewegungsrate0; positive halbe Meter bleiben positiv.
- Mönchs-Selbstwiederherstellung kann ohne Aktion vor dem eigenen Zugende ausgewählt werden. Feindlicher Initiative-Erstzug löst kein eigenes Zugende aus.
- 17 neue Grenz-/UI-Tests erfolgreich; aktuelle Analyse ohne Befunde. Generische Zustandsdauer bleibt ausdrücklich Entwurf, siehe docs/CONDITION_EFFECT_DESIGN.md.

## 0.7.7+47 – Ausführbare Heilzauber im Spiel (17.10.2026)

- Wunden heilen und Heilendes Wort wirken auf den eigenen Charakter: 2024-Würfel (2W8/2W4 pro tatsächlichem Platzgrad), eigenes Klassenattribut, Hochstufung, normale/Pakt-Plätze und Lebensdomänenboni (Kleriker 3/17).
- Deutsche Auswahl mit Klassen-/Platz-/Komponentenbestätigung direkt im Abenteuer/Kampf. Ereignis, TP, Platz und Aktion werden atomar bestätigt; keine automatischen Regeln aus Erzähltext.
- Persistenter Zugschutz: nur ein Platzverbrauch für Zauberwirken je Zug, gemeinsam für normale und Paktplätze; reset erst beim nächsten eigenen Zug. Alte Begegnungen bleiben lesbar. Action Surge erlaubt keine zusätzliche Magieaktion.
- 26 Domain-, 13 Dialog- und 9 Integrationsfälle geprüft. Vollständige Formatbereinigung und verpflichtende Formatprüfung im normalen Test-/Buildworkflow, keine autonome Codex-Action.
- Abschluss: 635 Flutter-, 31 Backend-, 56 Python- und 12 native Androidtests bestanden; saubere Analyse/Formatierung und Debug-APK aus dem Quell-ZIP gebaut und geprüft. Umfang/Grenzen: docs/CHARACTER_EFFECTS_AND_HEALING.md.

## 0.7.6+46 – Ausführbare Charaktereffekte (17.10.2026)

- Gemeinsamer Schaden-/Konzentrationsablauf für bestätigte externe Quellen und Gegnerangriffe: Abwehr vor temporären/echten TP; auch absorbierter Schaden löst Konzentration aus.
- Deutsche Oberfläche für Schaden, Heilung und temporäre TP mit Quelle und bestätigten Abwehrregeln. Atomare Speicherung und Revisionsschutz für offene Dialoge.
- Versteinert-Schadensresistenz und automatische Stärke-/Geschicklichkeitsfehlschläge bei gelähmt/versteinert/betäubt/bewusstlos; betäubt sperrt Bewegung nach 2024 nicht generell.
- 50 gezielte Domain-/Kampfregressionen, 6 Dialogtests und 7 echte UI-/SQLite-Tests erfolgreich; Flutter-Analyse ohne Befunde. Details im Checkpoint.

## 0.7.5+45 – Prüfbare Speicher- und Backendkorrekturen (17.10.2026)

- Erschöpfte Angriffs-, Wahrnehmungs- und Fluchtproben bleiben beim JSON-/SQLite-Neustart gültig; manipulierte Boni werden weiterhin abgewiesen.
- Schaden bei 0 TP beendet Stabilität und verursacht Todesrettungsfehlschläge auch bei vollständiger Absorption durch temporäre TP; kritische Treffer und sofortiger Tod werden getrennt geprüft.
- Gültige leere Tagebuchbeschreibungen verursachen im Backend-Mock keinen HTTP 502 mehr. OpenAI-POSTs weisen Redirects ab.
- Reproduzierbares Checkpointwerkzeug mit vollständigem ZIP, Binärpatch, Dateimanifest, Prüfsummen und tatsächlicher Wiederherstellungsprüfung; lokale Regelabdeckungsmatrix ergänzt.
- Gezielte Flutter-Regressionsprüfung: 30 bestanden; vollständiger lokaler Lauf: 544 bestanden, 1 optionaler Protokolltest übersprungen. Backend mit Node 22.14.0: 31 bestanden. Details im Checkpoint.

## 0.7.4+44 – Klassenaktionen, Rettungswürfe und Ressourcen (16.10.2026)

- Paladin-Handauflegen als ausführbare Heil-/Entgiftungs-Bonusaktion, eigener Heilpunktevorrat, UI-Schaltflächen, Rastregeneration und Ereignisjournal.
- Mönch 15: Perfekter Fokus beim Initiativewurf, für Demo- und KI-Begegnungen mit überprüfbaren Freischalt-/Regenerationsbedingungen.
- Manuelle, explizit angeforderte Rettungswürfe samt optionalem Mönch-14-/Kämpfer-9-Wiederholungswurf; Ressource `indomitable` nach Kämpfer-Klassenstufe und verbindlichem Zweitergebnis.
- Charakterbogen zeigt Handauflegen und Unbeugsam. Legacy-Speicherschema unverändert; neue Dart-Domain-/Integrationsfälle hinzugefügt.
- Python-Tests und Integritätsprüfungen ausgeführt; Flutter- und APK-Verifikation steht noch aus. Keine Behauptung vollständiger 1.247-SRD-Anforderungen.

## 0.7.3+43 – Mönch-Selbstwiederherstellung und disziplinierter Überlebender (16.10.2026)

- Selbstwiederherstellung ab Mönchsstufe 10 zur gezielten Entfernung eines von drei Zuständen am Ende des eigenen Zugs, mit Entscheidung bei mehreren Zuständen, UI-Auswahl, Kampfjournaleintrag und rückwärtskompatiblem Encounter-JSON.
- Alle sechs Rettungswurfübungen ab Mönchsstufe 14 berechnet, ohne Proficiency zu verdoppeln oder vorhandene Charakterbögen umzuschreiben.
- GitHub-Actions-Compilerfehler `monk_flurry_rules.dart` (`int?` statt `int`, Commit 91ffddd) gezielt korrigiert; Regressionen für nur ein bestätigtes Angriffsattribut ergänzt.
- Flutter-/Android-Test noch ausstehend. Dokumentation `docs/MONK_SELF_RESTORATION_0_7_3.md`.

## 0.7.2+42 – Temporäre TP und Mönch: erhöhter Fokus (16.10.2026)

- Verstärkte Geduldige Verteidigung ab Mönchsstufe 10: zwei Kampfkunstwürfel temporäre TP für einen Fokuspunkt; Kampfrunden- und Ereignisintegration.
- Eigenes rückwärtskompatibles Speicherfeld für temporäre Trefferpunkte, Schadenspuffer vor echten TP, Heil- und Rastregeln sowie Anzeige in der UI.
- CI-Lint für `monk_flurry_rules.dart` korrigiert. Neue Dart-Domain- und Widget-Regressionsprüfungen hinzugefügt.
- Siehe `docs/TEMP_HP_MONK_HEIGHTENED_FOCUS_0_7_2.md`; Flutter-/APK-Prüfung noch offen.

## 0.7.1+41 – Mönch: Schlaghagel und letzte CI-Regressionen (16.10.2026)

- Ausführbarer Schlaghagel für Mönchsstufe 2+ (2 Unarmed Strikes) und 10+ (3 Unarmed Strikes), Fokusverbrauch und Aktionsturn-Reihenfolge; Treffer/Krits und Schadenswürfe einzeln protokolliert.
- Bonusaktion vor oder nach der normalen Attack action; Quest-/Kampfsieg auch über Schlaghagel, Mehrklassen-Klassenstufe und Persistenz unverändert im Schema 1.
- Behebung der in GitHub Actions `38857593290` bestätigten Regressionen: Widget-Test `6.0 m` versus `6 m`, blockierte Zweitaktion bei Eingabe „Ich weiche aus.“.
- Neue Dart-Tests und Dokumentation. Python-Strukturprüfungen separat. Keine ungeprüfte Behauptung eines erfolgreichen Flutter-/APK-Builds. Details: `docs/MONK_FLURRY_0_7_1.md`.

## 0.7.0+40 – Mönchsfokus: defensive Bonusaktionen (2026-10-16)

Geduldige Verteidigung und Schritt des Windes mit kostenlosen und fokussierten Varianten. Persistente, am Zugende automatisch zurückgesetzte Dodge-/Disengage-/Sprungstatus; Rogue Cunning Action Disengage. Separate Domain- und Kampf-Regressionstests. Kein Gelegenheitsangriffs-/Sprunggeometriesystem; keine Flurry-Ausführung. Flutter-/Android-Build noch nicht ausgeführt. Siehe docs/MONK_FOCUS_0_7_0.md.

## 0.6.9+39 — Ausführbare Kampf-Klassenaktionen (2026-10-16)

Kampfrausch-Runden und gesonderter Ressourcenverbrauch, bestätigter Stärke-Nahkampfbonus, optional bestätigte körperliche Schadensresistenz, Flinke Aktion: Sprinten und Hinterhältiger Angriff auf Treffern mit bestätigtem Vorteil. Neue Regressionstests, Speicherkompatibilität und Dokumentation. Flutter/Android nicht lokal getestet.

## 0.6.7+37 – Fighter resource engine (16.10.2026)

- Second Wind: resource pool by Fighter class level; 1d10 + class level as Bonus Action, rest recovery, save-state validation.
- Action Surge: resource pool, once-per-turn reservation of an additional Attack action in the simplified combat system; restored on Short/Long Rest.
- Character sheet now shows remaining Fighter resources. Old schema 1 saves remain readable.
- Flutter analyze CI fix for `damage_rules.dart` dangling library doc comment.
- Added Dart regression tests; **Flutter/Android execution pending**. See `docs/CLASS_RESOURCES_0_6_7.md`.

## 0.6.6+36 – Klassenmeilensteine & Mehrfachangriffe (16.10.2026)

- SRD-5.2.1-Klassenstufen: Vorschau der Unterklassen-, Talent- und Kämpfer-Meilensteine; keine automatischen freien Klassenmerkmale behauptet.
- Mehrfachangriffe je Angriffsaktion: fünf Grundklassen ab Klassenstufe 5, Kämpfer ab 11 drei, ab 20 vier; Mehrklassen-Merkmale nicht kumulativ.
- Demo- und KI-Kampfsystem: einzelne Attacken nacheinander mit eigenem W20, kritischem Treffer und Schaden; Gegnerzug erst nach Abschluss oder freiwilligem Zugende.
- Laufende Angriffsaktion rückwärtskompatibel speichern; Anzahl möglicher Angriffe und nächste Meilensteine im Charakterbogen anzeigen.
- Tests ergänzt, Flutter-CI/APK nicht vor Ort ausgeführt. Details: `docs/CLASS_PROGRESSION_0_6_6.md`.

## 0.6.5+35 – Regelengine: Schadensarten + bekannte CI-Blockade (16.10.2026)

- Bewegungsanzeige im Charakterbogen korrekt formatiert, einschließlich halber Meter; Regressionstests ergänzt.
- Konzentrations-SG auf SRD-Maximum 30 begrenzt; zusätzliche Grenzwerttests.
- Neues Modul für typisierten Schaden, Resistenz/Anfälligkeit/Immunität und mehrere Schadenskomponenten; eigene Domänentests, bewusster Einstieg in die zentrale TP-Regelengine.
- **Nicht als fertig freigegeben:** automatische Integration in alle Kämpfe, Charakter-/Monsterdefensiven, Dart-Tests und APK-Build ausstehend. GitHub-`main` unverändert; Import separat erforderlich.

## 0.6.4+34 – Zauberplätze, Paktmagie und Konzentration (15.10.2026)

- Persistente und stufenvalidierte Zauberplatzverbräuche, separate Hexenmeister-Paktmagie und aktiver Konzentrationszauber im weiterhin kompatiblen Schema 1.
- Charaktereditor-Dialog mit bestätigter Zauber-/Gradwahl, Charakterbogen zeigt verbleibende Plätze; keine unbestätigte Zauberwirkung.
- Kurze Rast erneuert Paktmagie, lange Rast alle Plätze; Kampfschaden löst dokumentierte Konzentrationsrettungswürfe aus. 0 TP/Tod beendet Konzentration.
- Tests ergänzt, Flutter-/Android-CI ausstehend; lokale Python-/Strukturprüfungen werden separat aufgeführt. Grenzen und SRD-Quellen: `docs/SPELLCASTING_RESOURCES.md`.

## 0.6.3+33 – gemeinsame Regelengine für Spiel und Oberfläche (15.10.2026)

- `CharacterRuleEngine` als rein lesende Quelle für Kampf-, Proben-, Rettungswurf- und Bewegungsmodifikatoren einschließlich Erschöpfung, Zustand und bestätigter Ausrüstung.
- Kampf, Initiative, Wahrnehmung, Flucht und Gegenangriffe mit dokumentierten Vorteils-/Nachteilquellen verbunden. PendingRoll speichert Vorteil/Nachteil optional, ältere Spielstände bleiben lesbar.
- Charakterbogen zeigt effektive Initiative, effektive Bewegung, erschöpfungsbereinigte Rettungswürfe und Zustandserklärungen; Ausrüstungsvorschau erläutert vorübergehende Angriffsabzüge.
- Achtung: Nicht alle situativen SRD-Effekte werden ohne zusätzliche bestätigte Eingabedaten erraten. Datenbank und Backend-Verträge unverändert.
- Neue Domain- und Widgettests ergänzt; 38 Python-Tests und Projektstruktur lokal erfolgreich. Flutter-/Android-CI für diese Version **noch ausstehend**. Details: `docs/UNIFIED_RULE_ENGINE.md`.

## 0.6.2+32 – Zustände und Erschöpfung (15.10.2026)

- Persistente, validierte Erschöpfungsstufen 0–6 nach SRD 5.2.1: −2/Stufe auf W20-Tests, −1,5 m/Stufe, Tod bei Stufe 6 und Wiederherstellung um eine Stufe nach langer Rast.
- Charaktereditor mit Anzeige der Erschöpfung und der rechnerischen Auswirkungen; alte Spielstände bleiben kompatibel.
- Initiative, Waffenangriff, Wahrnehmung und Todesrettungen nutzen den bestätigten W20-Abzug; Kampftempo und elementare Zustandsverbote werden berücksichtigt.
- `ConditionRules` enthält 14 SRD-Zustandsüberblicke; kontextabhängige Effekte bleiben ausdrücklich offen.
- Neue Domänentests; Flutter-/Android-CI für diesen Stand noch ausstehend. Siehe `docs/CONDITIONS_EXHAUSTION.md`.

## 0.6.1+31 – Flutter-Analyzer und Rast-Testfixtures (15.10.2026)

- **BEHOBEN:** `srd_equipment_catalog.dart` verwendet für das Gewicht eine einfache Stringinterpolation (`$weightLb`), wodurch der in CI reproduzierte Analyzer-Lint `unnecessary_brace_in_string_interps` entfällt. Keine Änderung der Ausrüstungswerte.
- **BEHOBEN:** Die `HeroCharacter.fromJson`-Fixture in `app/test/rest_rules_test.dart` enthält wieder die erforderliche `species`-Angabe `Mensch`. Sieben vorangegangene Testfehler waren `FormatException: Spezies ist ungültig.` beim Aufbau der Fixture, nicht Regel-Aussagen. Der produktive Importvalidator bleibt unverändert.
- **BASIS:** `main` `0963303fe4802aae9c42739b267e6d33057ef63d`, GitHub Actions #38746011222 (Analyzer-Fehler); früherer Rast-Testlauf #38734808085. Die geänderten Ausgangsdateien wurden gegen ihre Git-Blob-SHAs geprüft.
- **PRÜFUNG:** Projektstruktur, Python-Tests, ZIP/SHA256 sowie saubere Anwendung des Git-Patches auf `0.6.0+30`. Flutter SDK ist in dieser Umgebung nicht vorhanden: `flutter analyze`, `flutter test` und Android-APK-Build sind für 0.6.1+31 **noch nicht nachgewiesen**.
- **NÄCHSTES:** Auf separatem Branch übernehmen, kompletten GitHub-CI-Lauf ausführen; bei neuen Testproblemen Logs analysieren und beheben; bei grünem Lauf APK verwenden. Codex-Actions nicht reaktivieren.

## 0.6.0+30 – SRD-Waffen und -Rüstungen anlegen (15.10.2026)

- Reine Vorschau plus bestätigte Übernahme von Katalog-Waffen/Rüstungen/Schilden in Kampfwerte. Waffenattribute, Würfel, Übung, RK-Berechnung, STR-Grenzen, Finesse, Wurf-/Zweihand-/schwere Waffen mit Regeln und Warnungen.
- Optionale Instanzreferenzen/Übungsbestätigungen für Savegames; alte Schema-1-Daten bleiben ohne Änderung lesbar. Ungültige Referenzen blockieren Importe; keine Magie-/Gold-/Munitionsbuchung.
- Regeltests und Widgettest für Dialog ergänzt. Flutter-/Android-CI und Geräteabnahme für diesen Stand noch offen, siehe docs/EQUIPMENT_RULES.md.
- Eigener Entwicklungsstand aus vollständigem ZIP 0.5.9+29. Keine Übernahme auf Codex-Branch oder GitHub behauptet; GitHub-Schreibberechtigung noch nicht bestätigt.

## 0.5.9+29 – SRD 5.2.1: Waffen-, Rüstungs- und Gegenstandskatalog (15.10.2026)

- **Ausrüstung:** 38/38 Standardwaffen, 13/13 Rüstungen/Schilde sowie Werkzeuge, Abenteuerausrüstung, Munition, Foki, Reittiere, Fahrzeuge und eine ausdrücklich unvollständige Magie-Gegenstandsauswahl: insgesamt **272 Einträge**.
- **SRD-Werte:** Waffen mit Schaden, Typ, Eigenschaften, Meisterschaft, Reichweite, Kosten und Gewicht; Rüstung mit Basis-RK, GE-Beschränkung, ST-Mindestwert und Heimlichkeitsnachteil. Reine, explizite RK-Vorschau ohne ungeprüfte Boni.
- **Charaktereditor:** Such-/Kategoriedialog auf Deutsch und Englisch, bewusstes Hinzufügen aus dem Katalog; bestehender Freitext-Inventardialog bleibt erhalten. Optionale `catalogId` ohne Änderung der bisherigen gespeicherten Pflichtfelder; ältere Daten bleiben kompatibel.
- **Sicherheit:** Kein automatischer Goldabzug, kein automatisches Anlegen oder Überschreiben von AC/Waffenwerten; magische Effekte, Ladungen und Einstimmung sind noch nicht automatisiert. Lizenz/Quellen: `docs/SRD_AUSRUESTUNGSKATALOG.md` und `THIRD_PARTY_NOTICES.md`.
- **Tests:** Dart-Domain-, Widget- und Editor-Tests angelegt (Flutter CI ausstehend); 38 lokale Python-Tests und Strukturprüfung bestanden. Ausgangsbasis 0.5.8+28; deren GitHub-CI hatte sieben fehlschlagende Rast-Tests. Neue Änderungen auf GitHub noch nicht übertragen.

## 0.5.8+28 – SRD-5.2.1-Rasten und Trefferwürfel (15.10.2026)

- Eigenständiges `RestRules`-Modul implementiert kurze Rast mit klassenspezifischen Trefferwürfeln, Konstitutionsbonus, Mindestheilung und TP-Limit; keine unbegrenzte Pauschalheilung mehr.
- Lange Rast stellt TP und ausgegebene Trefferwürfel wieder her. Rasten bei 0 TP, Tod, aktiver Begegnung und offener Würfelprobe blockiert; unklare Rastbefehle erfordern explizite Wahl.
- Optionale `spentHitDice`-Karte in bestehenden JSON-Spielständen (Schema 1) und SQLite-Snapshots; keine Datenmigration, vorhandene Speicherstände laden ohne Würfelverlust.
- Neue Journalereignisse `character.shortRest` / `character.longRest` sowie Trefferwürfelanzeige im Charakterbogen. Dart-Tests für Mehrklassen, Speicherung, Sicherheitsgrenzen und Spielaktionen hinzugefügt.
- **Status:** Projektstruktur und Python-Tests lokal geprüft. Flutter/Dart-Analyse, Widgettests, Android-APK und Gerätetest für diesen Stand nicht durchgeführt. Nur Android-Actions-Workflow, keine Codex-Action.
- **Referenz:** `docs/REST_RULES.md`, SRD 5.2.1 unter CC BY 4.0.

## 0.5.7+27 – Inventar-Widgettest robuster gemacht (15.10.2026)

- **CI-Ursache (Lauf #38729844876, Commit `42b9ad37`):** 351 Flutter-Tests erfolgreich, ein Inventar-Widgettest fehlgeschlagen (`StateError: Bad state: No element`). Flutter-Analyse und Backend-Prüfungen waren erfolgreich.
- **Korrektur:** Die Aktion „Gegenstand hinzufügen“ besitzt einen stabilen `ValueKey`. Der Test scrollt die tatsächliche Charaktereditor-`ListView` mit kleinen Schritten bis die Schaltfläche wirklich antippbar ist. Er verschluckt keine Fehler und deaktiviert keine Tests.
- **Status:** Quellcode korrigiert, Projektstruktur und Python-Tests lokal geprüft. Flutter-Testlauf und Android-APK auf GitHub noch **nicht** bestätigt. Datenmodell und Spielstandschema unverändert.
- **GitHub:** Änderungen nur lokal gesichert; bei verweigerten Schreibrechten kein Commit auf `main`.

## 0.5.6+26 – CI-Fixes: Schnellaktionen und Inventar (15.10.2026)

- **Schnellaktionen:** Beim Öffnen der Android-Tastatur erkennt der feste Dock über `View.of(context).viewInsets` den tatsächlichen IME-Bereich auch hinter einem verschachtelten `Scaffold`. Die Überschrift wird ausgeblendet, die vier Aktionen bleiben erhalten.
- **Große Schrift:** Die Docküberschrift verwendet ein flexibles, auf eine Zeile begrenztes Textfeld; die Höhe der vier Buttons skaliert ausreichend mit bis zu zwei Zeilen großer Schrift. Behebt die CI-Overflows bei 320dp/180%.
- **Charaktereditor:** Der Inventartest scrollt den tatsächlichen `OutlinedButton` vollständig ins sichtbare Fenster und prüft vor dem Antippen die Trefferfläche. Keine Funktion oder Inventarlogik geändert.
- **Regression:** Der Tastaturtest prüft nun alle vier betätigbaren Schnellaktionen.
- **Eingangslage:** CI #38728029583 für 0.5.5+25: 349 Flutter-Tests grün, 3 rot; Flutter-Analyse, Backend und Python erfolgreich. **Neuer Flutter-CI-Lauf für 0.5.6 steht aus**, eine APK-Freigabe wird nicht behauptet.
- **Workflow:** Nur `.github/workflows/android-build.yml`; kein Codex in Actions. Datenbankschema 1 und historische Spielstände unverändert.

## 0.5.5+25 – feste Schnellaktionen am unteren Bildschirmrand (15.10.2026)

- Die Abenteuer-Schnellaktionen sind nun im `Scaffold.bottomNavigationBar` der Abenteueransicht verankert, nicht im scrollbaren Inhalt oder im Composer. Sie stehen unter dem Texteingabefeld und direkt über der allgemeinen App-Navigation.
- Die doppelten Sprach- und Würfel-Schaltflächen aus dem Composer entfernt. **Sprache/Stopp**, **Untersuchen**, **Angriff** und **W20** bleiben unten einheitlich erreichbar; **Rückblick** bleibt separat neben dem Eingabebereich.
- Bei offener Android-Tastatur bleibt die Leiste angedockt; die vorhandene Tastaturkompaktansicht bleibt erhalten. Funktionalität und gespeicherte Spielstände unverändert.
- Flutter-Widgettests auf die neuen Schnellaktions-Selektoren umgestellt und Integrationstest erweitert. Python- und Projektstrukturprüfungen werden getrennt protokolliert; Flutter-CI-Abnahme für 0.5.5 noch erforderlich.
- Keine Codex-Entwicklung in GitHub Actions; regulärer Android-/Release-Workflow bleibt vorhanden.

## Prüf- und Analysekorrekturen 0.5.4+24 – 15.10.2026 (nicht Flutter-CI-validiert)

- Automatischer Codex-Workflow bleibt aus dem vollständigen Import-ZIP ausgeschlossen; normaler Android-Workflow erhalten.
- Flutter-Analysefehler im Test der fixierten Schnellaktionen (`const NavigationBar`) korrigiert.
- Zwei Dart-Lint-Hinweise zu fehlenden Blockklammern in Charaktereditor und Zweitklassen-Dialog korrigiert.
- Projektprüfung und 35 Python-Tests erfolgreich; Flutter/Android-Build bleibt ausstehend.
- Live-GitHub enthält die alte Codex-Datei weiterhin; dortige Löschung noch erforderlich.

## 0.5.4+24 – GitHub Actions ohne automatische Codex-Entwicklung (15.10.2026)

- `.github/workflows/autonomous-development.yml` aus dem vollständigen Projekt entfernt. Es gibt im neuen Archiv keinen Zeitplan, keinen `openai/codex-action`-Aufruf und keinen automatischen Codex-PR-Job mehr.
- `.github/workflows/android-build.yml` und die regulären Flutter-, Backend-, Python-, Android- und Release-/Checkpoint-Jobs unverändert erhalten. Manuelle Codex-Verwendung außerhalb von GitHub Actions bleibt möglich.
- Import- und Fortsetzungsdokumentation aktualisiert; ein neuer Python-Regressionstest verhindert, dass versehentlich wieder ein Codex-Workflow in `.github/workflows` landet.
- **Keine App-Änderung und keine neue APK-Abnahme.** Die Versionsnummer `0.5.4+24` bleibt unverändert. GitHub-Commit nicht ausgeführt: Contents-API gibt HTTP 403 zurück. Bestehende Workflow-Datei auf GitHub muss gesondert mit `git rm` entfernt werden.

## 0.5.4+24 – Mehrklassen-Aufstieg absichern und versionierte Alpha-Auslieferung vorbereiten (15.10.2026)

- **Mehrklassen:** Vor dem Übernehmen einer Zweitklassen-Stufe wird jetzt überprüft, ob der Vorschlag noch zum selben Helden und zu denselben bestätigten Attributen, Fertigkeiten, maximalen Trefferpunkten und Klassenstufen gehört. Nachträglich ungültige Vorschläge werden ohne stillen Charakterfehler zurückgewiesen. Erlittener Schaden zwischen Vorschlag und Bestätigung bleibt erhalten und wird korrekt zum TP-Zuwachs berücksichtigt.
- **Defensive Validierung:** Direkte inkonsistente Primär-/Sekundärklassenstufen werden abgewiesen. Fünf Dart-Regressionstests ergänzen die bestehenden Mehrklassen-Tests.
- **Release-Automatisierung:** Neues `scripts/prepare_alpha_release.py` erzeugt nach **vollständig erfolgreichem CI-Lauf** ein versioniertes vollständiges Quellarchiv, die zuvor gebaute ARM64-APK, Release-Notizen und SHA-256-Prüfsummen. ARM64-Bibliotheken und APK-ZIP-Integrität werden vor Freigabe geprüft; die bestehende interne Debug-Testsignierung ist eindeutig gekennzeichnet.
- **Tests:** Sieben neue Python-Fälle decken die sichere Auslieferung ab. GitHub-Actions-Workflow nutzt das Skript und lädt die versionierten Dateien als gemeinsames Release-Artefakt hoch. Fehlerhafte Builds behalten die bisherige gesonderte **nicht freigegebene** Quell-Checkpoint-Veröffentlichung.
- **Abnahme:** Lokale Python- und Projektstrukturtests bestanden; Flutter-/Dart-Tests und Android-Build sind ohne SDK lokal **nicht ausgeführt**. Backend-`npm ci --offline` war wegen fehlendem Cache für `undici-types` nicht ausführbar. GitHub-`main` wurde nicht verändert. Dieser Entwicklungsstand bleibt ein *unverifizierter Quellcode-Checkpoint*, bis CI vollständig erfolgreich ist.

## Ergänzung zur Quellcodeübergabe 0.5.3+23 – 15.10.2026

- Vollständigen Quellstand mit bereits vorhandenen fixierten Schnellaktionen (0.5.3+23) übernommen; keine Spielstands-/Schemaänderung.
- Python-Regressionstest gegen ungültige `pubspec.yaml`-Beschreibung ergänzt.
- GitHub-Actions-Quellencheckpoint und einen getrennten, zunächst deaktivierten Codex-Workflow vorbereitet.
- `docs/AUTONOMOUS_DEVELOPMENT_STATE.md` und Importanleitung ergänzt. Neue APK/Flutter-CI-Abnahme noch ausstehend.

## 0.5.3+23 – Fixierte Schnellaktionen im Abenteuer (15.10.2026)

- **Navigation:** Die vier Schnellaktionen **Sprache, Untersuchen, Angriff und W20** wurden aus der scrollbaren Abenteuerszene in eine stets am unteren Rand sichtbare Aktionsleiste direkt **über der Hauptnavigation** verschoben. Sie sind auch in der Kampfübersicht erreichbar.
- **Responsive Darstellung:** Kompakte Fantasy-Kacheln passen nebeneinander auf 320/360/400 dp; bei eingeblendeter Tastatur entfällt nur die Leistenüberschrift. Doppelte Buttons im Eingabebereich werden bei geöffneter Tastatur ausgeblendet, um Platz zu schaffen.
- **Bestehende Funktionalität:** Die Schnellaktionen verwenden dieselben Methoden zur Mikrofonsteuerung, Untersuchung, Angriffseingabe und Würfelfunktion. Keine Änderungen an D&D-Regeln, KI, SQLite oder Spielstandformat.
- **Buildblocker korrigiert:** `app/pubspec.yaml` hatte seit der Umbenennung eine nicht maskierte zweite Doppelpunkt-Sequenz in `description`. Die Beschreibung ist jetzt gültig in Anführungszeichen gesetzt, damit `flutter pub get` nicht mehr bei der YAML-Analyse scheitert. Ursprünglicher Fehler: GitHub Actions Commit `bb5383b7a52b5052a5c2e8ce4714fe16b0e600da`.
- **Tests:** Neue Widgettests für fixierte Position bei Scrollbewegungen, Bedienbarkeit, schmale Bildschirme und geöffnetes Keyboard; Integrationstest mit echter Kampagnenseite. 22 Python-Tests und Strukturprüfung bestanden, YAML erfolgreich geparst. Flutter-Tests und APK-Build stehen auf GitHub Actions noch aus.

## 0.5.2+22 – Neuer Name und SRD-Zweitklassen-Assistent (15.10.2026)

- Neuer Produktname **Würfelraunen – Der lebendige Spielleiter** in Startseite, Android-Launcher, App-Titel, Sprecherprobe, Lizenzansicht und KI-Prompt; technische App-ID bleibt zur Update-Kompatibilität unverändert.
- Automatisierte Zweitklasse beim Stufenaufstieg (maximal zwei Klassen, Gesamtstufe bis 20): Primärattribut-Voraussetzungen beider Klassen, feste zusätzliche TP nach Trefferwürfel und Konstitution, gezielte neue Klassenfertigkeit bei Barde/Schurke/Waldläufer.
- Optionale Mehrklassenfelder in den bestehenden `schemaVersion:1`-Heldendaten; vorhandene Speicherstände und Importe bleiben lesbar, keine SQLite-Migration.
- Kein fälschliches Gewähren von Startausrüstung, neuem Start-TP-Maximum oder Rettungswurf-Übungen. Anzeige im Charakterbogen, Heldenliste und KI-Kontext; Regel-/Widgettests ergänzt.
- Grenzen: Klassenspezialfähigkeiten, Rüstung-/Waffen- und Werkzeugübungen sowie Zauberressourcen sind nicht vollständig automatisiert; ermittelte Zauberplätze dienen vorerst der Vorschau.
- Neues Quellpaket erstellt, Flutter/Android-CI für diese Version noch nicht ausgeführt.

## 0.5.1+21 – Flutter-CI-Abnahme des illustrierten Designs (15.10.2026)

- **CI-Ursache:** Letzter GitHub-Actions-Lauf für `0.5.0+20` (`a3a05d3888a9c0e19d3e43d2469cc849f5e1a4eb`) scheiterte trotz 328 bestandener Flutter-Tests an zwei veralteten Widgettest-Interaktionen.
- **Charakterbogen:** Der Test für unbekannte Angaben scrollt zur verzögert aufgebauten Tab-Navigation, bevor er die Tabs antippt. `ensureVisible` allein konnte den zunächst noch nicht aufgebauten Tab nicht finden.
- **Startseite:** Der 360-dp-Navigationstest scrollt zum echten Demo-Button unter dem illustrierten Header, überprüft die Antippbarkeit und startet dann die Demo. Keine Hit-Test-Warnungen unterdrückt und keine Tests deaktiviert.
- **Umfang:** Nur Widgettests, Versionsnummer und Dokumentation geändert. Alle zwölf neuen Illustrationen, UI-Widgets, Spiellogik, Backend und gespeicherte Daten bleiben unverändert.
- **Status:** Lokale Python-/Paketprüfungen durchgeführt; Flutter-Analyse, Flutter-Tests und APK-Build müssen die neue Version in GitHub Actions bestätigen. Ohne grünen Build noch keine Freigabe.

## 0.5.0+20 – Illustriertes Aetheria-Design (15.10.2026)

- Echte, kompakte App-Grafiken aus den zuvor entworfenen Aetheria-Illustrationen als lokale WebP-Assets (`app/assets/art/`, 12 Motive). Keine eingebetteten Bildschirm-Screenshots als UI.
- Neues `FantasyIllustratedBanner` mit realen Kampagnendaten und Fortsetzen-Aktion; gerahmte Kampagnenkarten mit regionalen Motiven; horizontale Schnellzugriffe zu bestehenden Funktionen.
- Abenteueransicht mit atmosphärischer Szene, weiterhin gespeicherter Szenentext und bestehende Spielaktionen. Zusätzliche Aktionskacheln verwenden die realen Spiel-/Sprach-/Würfelmethoden.
- Heldenarchiv mit individuellen Initialenmedaillons (kein erfundenes Porträt); Charakterbogen mit Burgenillustration, dekorativen Rahmen.
- Inventar mit einzelnen bebilderten Gegenständen auf Basis von `hero.inventory`: Anzahl und Name aus gespeicherten Daten, Detaildialog nur informativ, keine vorgetäuschte Anlegen-/Ablegen-Funktion.
- Chronik-Banner und einheitlicher Fantasy-Startbildschirm.
- Neues Testmodul zu Bild-Assets, Darstellung bei 320/360/400/950 dp und echten Inventargegenständen.
- Keine Änderungen an Backend, SQLite, Spielregeln oder den vorhandenen Import-/Exportformaten.
- Paket-/Strukturtests erfolgreich. Flutter-Analyse, Flutter-Widgettests und Android-APK müssen über GitHub Actions noch bestätigt werden.

## 0.4.3+19 – CI-Fix: überlaufende Attributkarten und mehrdeutige Widgettests (15.10.2026)

- GitHub Actions `38692820652`: Flutter-Analyse erfolgreich, 319 Tests erfolgreich, vier neue Layouttests rot. Drei Ursachen: `_AbilityCard`-Spalten bei 320 dp und 1.4x-Schrift überlaufen; bei 360/400 dp suchten Tests mehrdeutig nach `GridView` und warfen `Bad state: Too many elements`.
- Die sechs Attributkarten verwenden jetzt statt `GridView.count(childAspectRatio: ...)` einen expliziten `SliverGridDelegateWithFixedCrossAxisCount(mainAxisExtent: ...)`. Die Höhe passt sich mittels `MediaQuery.textScalerOf` an Systemschriftgrößen an. Keine Werte werden abgeschnitten oder verworfen.
- Übersichts- und Attributgrids haben eindeutige `ValueKey`s; Widgettests suchen gezielt das jeweilige Grid und scrollen bis zu den Rettungswürfen, um alle sechs Attributkarten zu rendern. Extra Test für TextScaler 1.4.
- Keine Änderungen an Spielregeln, Speicher, Backend oder Sicherheitsmodell; keine neuen Pakete.
- Prüfstatus: Projektstruktur, Python-Tests und ZIP-Integrität lokal; `flutter analyze`, `flutter test` und APK-Build erst durch GitHub Actions belegbar.

## 0.4.2+18 – Korrektur des CI-Kompilierfehlers (15.10.2026)

- `app/lib/ui/fantasy_character_sheet.dart`: `GridView.count` durch `GridView` mit `SliverGridDelegateWithFixedCrossAxisCount` ersetzt. Der Parameter `mainAxisExtent` befindet sich nun am richtigen Delegate.
- Bestehender Schutz vor `RenderFlex overflow` auf schmalen Displays und bei größerer Systemschrift bleibt erhalten.
- Regressionstest prüft Grid-Delegate, Anzahl Spalten und feste Kachelhöhe.
- Basiert auf `main` Commit `35a7b4062c5248b288598b587da6c606bf80122d` (0.4.1+17).
- Auslöser: GitHub Actions Build 38691911056 schlug am 15.10.2026 bei `flutter analyze` fehl (`undefined_named_parameter` in Zeile 237).
- Projektstruktur/Python-Tests hier geprüft; vollständige Flutter-/Android-Abnahme über GitHub Actions steht aus.

## 0.4.1+17 – Korrektur der Charakterbogen-Kacheln (15.10.2026)

- Die vier Statistik-Kacheln verwenden jetzt eine von Schriftgröße und Layout unabhängige Mindesthöhe statt eines festen Seitenverhältnisses. Dies behebt die drei `RenderFlex overflowed`-Fehler aus GitHub Actions beim Charakterbogen und beim Öffnen des Bogens aus dem Abenteuer.
- Große Textdarstellung wird durch eine an den TextScaler gekoppelte Höhe berücksichtigt. Lange Beschriftungen dürfen auf zwei Zeilen umbrechen; Zahlen werden bei Platzmangel horizontal skaliert.
- Zusätzliche Widget-Regressionstests für 320, 360, 400 logische Pixel und 140 % Schriftgröße.
- Keine Änderung an Regeln, Datenbank, KI-Backend oder gesicherten Charakterwerten. Der GitHub-Actions-Build muss die Korrektur bestätigen.

## 0.4.0+16 – 15.10.2026 – Gesamtes App-Design vereinheitlicht

- Das vollständige bestehende Flutter-UI orientiert sich jetzt am deutschen Dark-Fantasy-Charakterbogen. Zentrales Material-3-Theme und wiederverwendbare Widgets in `app/lib/ui/fantasy_ui.dart`.
- Einheitliche Farben, Serif-Überschriften, goldene/silberblaue Rahmen, einheitliche Buttons, Panels, Formulare, Dialoge, Chips, Listen, Erweiterungsfelder und Bottom Sheets.
- Hauptansichten **Start/Kampagnen**, **Abenteuer/Kampf**, **Helden/Charakterbogen**, **Tagebuch/Gedächtnis** und **Einstellungen/Backend** optisch angepasst. Inventar-Bottom-Sheet und Charaktereditor ebenfalls einbezogen.
- Responsive Navigation: unter 920 Pixel unten, ab 920 Pixel mit seitlicher Navigationsleiste. Keine künstlichen Inhalte oder nicht vorhandenen Karten-/Regel-Seiten.
- Zusätzliche Widgettests für Theme und Komponenten auf 320/360/1000 Pixeln sowie Dokumentation `docs/UI_DESIGN_SYSTEM.md`.
- Keine Spielregel-, Kampagnen-, Speicher-, API-, Kosten- oder Paketabhängigkeitsänderungen. Weiterhin echte bestätigte Daten und sichere Exportfunktionen.
- GitHub-Basis `ce64d5bd10288611bd3a8482b01a32939a309f76` (0.3.9+15). Strukturprüfung und 22 Python-Tests hier erfolgreich. **Flutter-/Android-Tests nicht lokal durchführbar.** Kein direkter Push auf `main`.

## 0.3.9+15 – 15.10.2026 – Neuer deutscher Fantasy-Charakterbogen

- Eigenständiger, deutschsprachiger Charakterbogen nach der abgestimmten Dark-Fantasy-Vorlage: dunkelblaue Flächen, goldene Kanten, farbige Attributkarten, Trefferpunktebalken und responsive Karten für Übungsbonus, Bewegung, Initiative und Rüstungsklasse.
- Aus der **Heldenverwaltung** („Bogen ansehen“) und aus dem **Abenteuer** („Charakterbogen ansehen“) erreichbar; vom Bogen aus ist der bisherige Charaktereditor weiterhin verfügbar.
- Abschnitte für Attribute/Rettungswürfe/Fertigkeiten, Zustände/Merkmale und Verteidigungsinformationen. Alle Informationen stammen aus dem echten `HeroCharacter`; unbekannte Werte bleiben als Strich bzw. „Nicht erfasst“ stehen. Mangels gespeicherter Portraitdaten wird ein Initialen-Avatar gezeigt, kein erfundenes Charakterporträt.
- Übungsbonus wird ausschließlich aus gültiger Stufe 1–20 berechnet, Attributmodifikatoren aus bestätigten Werten. Rettungswürfe addieren nur die explizit gespeicherte Übung; andere Effekte werden nicht erfunden. Die bestehende Bewegungseinheit bleibt **Meter**.
- Globales Designsystem an die neue Ansicht angepasst: marineblaue Karten/Hintergründe, Goldakzent, kontrastreichere Schriften und Buttons; Datenbankformat, Sprachausgabe, Kampagnen und Regel-Engine unverändert.
- Neue Flutter-Widgettests für deutsche Bezeichnungen, responsives Layout bei 320/360 px, Modifikatoren, fehlende Werte und Bearbeitungsaktion. Tests können hier mangels Flutter-SDK nur als Quellcode geprüft werden; sie müssen in GitHub Actions laufen.
- Korrektur des vorherigen Backend-CI-Testfehlers: Versionsassertion im Health-Test auf die tatsächliche Backend-Version `0.3.1` aktualisiert (vorher erwartete `0.3.0`).
- GitHub-Basis `125fc3630722002a955a4e3479395edd6bfb6635` (0.3.8+14). Kein direkter Push in `main`.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## 0.3.7+13 – 15.10.2026 – KI-gestützte eigene Kampagnen und Entscheidungen

- Optionaler Start neuer Kampagnen mit Wunschthema und bereits angelegtem Helden. Der verbundene OpenAI-Dienst erzeugt ein neues Abenteuer mit Welt, Einstiegsszene, verborgenem Plot, Ziel, 2–4 offenen Handlungssträngen, NPCs und Orten. Der Mock-Dienst bietet ausdrücklich nur eine deterministische Testgeschichte.
- Beim Weiterspielen berücksichtigt die KI die aktuelle Szene, gespeicherten Plot, bisherige Handlungsstränge, NPC-Beziehungen, geeignete bestätigte Erinnerungen und letzte sechs Spieleraktionen. Sie schlägt eine neue Szene, Statusänderungen, neue Fäden und Beziehungsentwicklungen vor. Die lokale Engine prüft die Struktur und übernimmt erlaubte erzählerische Daten als ein einziges atomar gespeichertes Ereignis.
- Persistenter `storyBible`-Block im Kampagnen-JSON (optional, alte Spielstände gültig), ohne neue SQL-Migration. Verborgene Wendungen stehen **nicht** in der allgemeinen Faktensuche oder im sichtbaren Tagebuch, wohl aber im privaten JSON-Export. Fortschritt, Beziehungen und Entscheidungen bleiben über Neustart und Export erhalten. Keine Gewichtsänderung oder lokale Modellschulung: **„lernend“ bedeutet kontext- und erinnerungsbasiert**.
- Neue authentifizierte, limitierte Backend-Endpunkte `POST /v1/story/start` und `POST /v1/story/advance`. Bestehende Sitzungstokens, HTTPS-Vorgaben und ausdrückliche OpenAI-Kostenfreigabe gelten auch hier; gemeinsames Minuten-/Tageslimit. Kein OpenAI-Schlüssel in der App, keine Server-Schreibrechte auf Spielstände.
- **Sicherheitsgrenze:** NPC-Beziehungs- und Story-Status dürfen sich entwickeln; HP, Würfelergebnisse, Attribute, Questbelohnungen und Inventar nicht. Ein Angriff auf einen nicht regeltechnisch erfassten Gegner wird blockiert, nicht von der KI ausgewürfelt. Das sind noch keine vollständigen frei generierten Kämpfe.
- Demo/Story getrennt: Die KI-Kampagne kann niemals automatisch auf das Mooswacht-Schlüssel-/Schrein-Skript zurückfallen. Provider-Ausfälle erhalten den bestätigten lokalen Spielzug; misslungener Kampagnenstart speichert gar nichts.
- Neue Domain-, SQLite-Integrations- und Backend-Tests zur Story-Erzeugung, ID-Validierung, deterministischen Testantworten, persistierten Beziehungen, falschen Providerantworten, Rate-Limits und verlorener Verbindung. Bekannte CI-Widgettestprobleme aus `ea486481d288...` (zweimaliger Dialogtitel und spätes Tagebuch-Scrolling) korrigiert.
- GitHub-Ausgangsbasis `ea486481d28856228abf65dd209857028b3b3c45` (0.3.6+12, 117 Dateien). **Hier ausgeführt:** Strukturscan, 22 Python-Tests, isolierter TypeScript-Parser und TypeScript-Syntaxcheck. Flutter-SDK und vollständige npm-Abhängigkeiten fehlen; Flutter-, komplette Backend-, APK- und Geräteprüfungen stehen aus.

## 0.3.6+12 – 15.10.2026 – Dauerhaftes Kampagnengedächtnis

- Im Tagebuch drei neue Bereiche: Sitzungsrückblicke dauerhaft speichern, Handlungsstränge mit Offen/Gelöst/Aufgegeben verwalten und Veränderungen der NPC-Beziehungen samt Notiz dokumentieren.
- Rückblicke werden ausschließlich aus strukturierten, bestätigten Quests, NPCs, Fakten und Handlungssträngen gebildet; freie KI-Erzähltexte und rohe Nutzereingaben sind keine Faktenquelle. Einträge gelangen in die lokale Erinnerungssuche und den Kontext des optionalen Backend-Erzählers.
- Neue optionale Felder `sessionRecaps`, `storyThreads`, `npcRelationshipNotes` in der bestehenden Kampagnen-JSON-Struktur. Vorhandene Sicherungen bleiben mit dem Parser kompatibel, SQLite-Schema bleibt Version 1. Maximal 60 Rückblicke, 100 Handlungsstränge und 300 Beziehungsnotizen.
- Alle Notizänderungen werden mit Revision und überprüfbarem Ereignis-Checkpoint atomar gespeichert. Regelwerte, HP, Würfel- und Questbelohnungen werden durch diese Verwaltungsaktionen nicht verändert.
- Zusätzliche Domänen-, Widget- und SQLite-Tests mit Testcode für Altimporte, Begrenzungen, Wiederherstellung, Replay, Beziehungshistorie und Eingabevalidierung.
- Vorherigen GitHub-CI-Fehler im Test `ui_app_test.dart` (Button „Vervollständigen“ auf 360-px-Bildschirm überlagert) durch Scrollen vor der Interaktion korrigiert. Auf Basis-Commit `6e967080baba7de252fac378d51758a20f6556ae` waren 290 Flutter-Tests erfolgreich, einer fehlgeschlagen; Flutter-Analyse, Python und Backend bestanden, APK-Schritte übersprungen.
- **Prüfstatus dieser Version:** Projektstruktur und alle 22 Python-Tests lokal bestanden. Mangels Flutter-/Dart-SDK und offline nicht verfügbarer npm-Abhängigkeiten sind Flutter/Backend-/APK-Prüfungen für 0.3.6 noch offen. Erfolgreiche CI vor Verwendung als installierbare APK erforderlich.

## 0.3.5+11 – 15.10.2026 – Kampagnenrückblick und NPC-Reaktionen

- Im Abenteuer gibt es einen direkt erreichbaren Button **Rückblick**. Ein noch nicht abgesendeter Handlungstext bleibt unverändert; Spracheingabe/-ausgabe wird vor der Aktion kontrolliert gestoppt.
- Erinnerung an bestätigte Fakten, NPC-Zustände, Queststatus, Inventar und bekannte Orte aus SQLite. Bei gezielten Fragen („Was weißt du über Mira?“, „Erinnere dich an den Waldschrein“) werden **nur thematisch passende** Erinnerungen ausgegeben, niemals ungefragte, unrelated Ereignisse.
- Bei allgemeinen Rückblicken werden bis zu vier relevante bestätigte Einträge angezeigt; die Ausgabe ist begrenzt und liefert explizit „keine passende Erinnerung“, wenn keine bestätigten Fakten zur Frage existieren. Unbestätigte Erzähltexte, Nutzereingaben und externe KI-Antworten werden nicht als bestätigte Fakten gelesen.
- Mira spricht im Demo-Modus jetzt abhängig vom bestätigten Verlauf: Schlüssel bereits gefunden, Dornenwächter besiegt, Waldlicht wieder entzündet. Erledigte Aufgaben werden nicht erneut verlangt.
- Neue Domänen- und Widgettests für thematische Abfragen, unbekannte Fakten, Unveränderlichkeit von Charakter-/Kampfwerten und Questzuständen sowie den Rückblick-Button.
- Ausgangsbasis `ManuEtt/Dnd` main `239ee5f7d333a6388159e7d431039abb92e936b7` (0.3.4+10); keine Schema-, Backend-, API- oder Paketabhängigkeitsänderungen. Flutter-/Android-Abnahme für dieses Inkrement muss nach GitHub-Import erfolgen.

## 0.3.4+10 – 15.10.2026 – Widgettest-Fix und Attribut-Vorschau

- Behebt den fehlerhaften Scrollweg im Widgettest `ui_srd_class_selection_test.dart`, der nach einem blockierten Speicherversuch die Hausregel-Checkbox nicht mehr fand (`StateError: Bad state: No element`). Bei Rueckspruengen wird jetzt negativ gescrollt.
- Neuer Komfort: Sofortige, unverbindliche Modifikatoranzeige unter Attributwerten im Charaktereditor, ueber dieselbe `RulesEngine.abilityModifier` berechnet wie regelgebundene Proben; unbestaetigte/ungueltige Werte bekommen keinen fiktiven Modifikator.
- Widgettest zur Aenderung, negativen Modifikatoren und Leereingabe ergaenzt.
- Basis ist unveraendert der GitHub-main-Commit `3b91a9778abe14184f35ac1db16f5acf121a84b5`. Keine Aenderung am Datenbankschema, Backend, Charakter-Speicherformat oder an bestehenden Charakterwerten.
- **Pruefung:** Python-Pakettests und Backend-Tests nach Moeglichkeit lokal; Flutter/Dart und Android SDK sind in dieser Ausfuehrungsumgebung nicht installiert. Neuer GitHub-Actions-Lauf nach Import erforderlich.

# Änderungsprotokoll

## 0.3.3 – Klassenwahl, Fertigkeiten und Startausrüstung (14. Oktober 2026)

- CI-Korrektur (15. Oktober 2026): Ungebundenen Dart-Dokumentationskommentar am Dateianfang von `app/lib/domain/srd_character_classes.dart` in reguläre Kommentare umgewandelt. GitHub-Actions-Lauf 38675268449 scheiterte ausschließlich an `dangling_library_doc_comments`. Flutter-Tests und Android-Build für diesen korrigierten Stand stehen nach Upload noch aus. Keine Änderungen an Spielregeln, Charakterdaten oder SQLite.


- Neue Klasse `SrdCharacterClass` mit den zwölf SRD-5.2.1-Klassen: Trefferwürfel, beide Rettungswurf-Übungen, zulässige Fertigkeitslisten und Auswahlanzahl (2–4) sowie Startpakete bzw. Startgold.
- Neuer Assistent „D&D-Klasse und Fertigkeiten wählen“ im Charaktereditor für Stufe-1-Charaktere. Ungültige oder doppelte Fertigkeitswahlen können nicht übernommen werden.
- Charakterausrüstung mit Inventargegenständen und Startgold kann **optional nur bei neuen noch unversorgten Charakteren** explizit übernommen werden; Wahl wird weder automatisch wiederholt noch Rüstung direkt angelegt.
- Start-TP-Vorschlag aus 0.3.2 im Assistenten nutzbar; vorhandene TP werden nur auf ausdrückliche Bestätigung ersetzt. Bestehende Fertigkeiten und Rettungswürfe bleiben beim Ergänzen erhalten; vollständiger Ersatz ist eine bewusste Option.
- Im neuen Charaktereditor werden freihändige Startattribute bzw. nachträgliche manuelle Änderungen an einer regelkonformen Verteilung nur nach Kennzeichnung als Hausregel gespeichert. Leere noch unbestätigte Attribute und historische/importierte Charaktere bleiben zulässig.
- Neue Domänen- und UI-Tests für sämtliche Klassentabellen, Fertigkeitsvalidierung, Aliasnamen, Altcharaktere und neue UI-Flows.
- Kein neues Backend, keine neuen Laufzeitabhängigkeiten und **keine Änderung am persistenten Charakter-JSON-Schema**. Klasse, Fertigkeiten, Rettungswürfe, Gold und Gegenstände verwenden die bereits vorhandenen Felder.
- Neue 0.3.3-Funktionen in dieser Übergabe **nicht mit Flutter auf Android kompiliert oder auf einem Gerät geprüft**; GitHub Actions führt die verbindlichen Flutter- und Android-Prüfungen nach dem Import aus.


## 0.3.2 – Vorbereitung, 14. Oktober 2026 (Start-Trefferpunkte nach SRD 5.2.1)

- Regelklasse `StartingHitPoints`: maximaler Klassen-Trefferwürfel plus KO-Modifikator für Stufe 1; zwölf SRD-Klassen, mindestens 1 TP.
- Neuer Button „Start-TP nach D&D vorschlagen“ im Charaktereditor mit eigener Vorschau und ausdrücklicher Bestätigung.
- Bisherige, importierte oder historische Trefferpunkte werden nur nach Bestätigung ersetzt; keine automatische Neuberechnung bei höherer Stufe.
- 19 neue Dart-Domänentests und ein Flutter-Widgettest im Quellcode; **Flutter-Test und Android-Build für 0.3.2 noch nicht ausgeführt**.
- Vollständiger Quellstand aus GitHub-Commit `4a8cfe9` geprüft und in das direkt importierbare ZIP integriert. Strukturprüfung und 22 Python-Tests nach Integration bestanden.
- Kein zusätzlicher API-Aufruf, keine neue Laufzeitabhängigkeit, keine SQLite-Schemaänderung.


## 0.3.1 — 14. Oktober 2026 (Sprache und CI; Backend bleibt 0.2.0)

- Abgewiesene TTS-Kommandos (0/false) werden als Fehler behandelt. Fehlgeschlagene Stimmwahl speichert keine ungültige Auswahl; entfernte Stimmen fallen bei der Neusuche auf einen verfügbaren deutschen Standard zurück.
- Deutsche Stimm-IDs normalisiert verglichen, native IDs erhalten, doppelte/fehlerhafte und als nicht installiert gemeldete Einträge entfernt. Anbieter-Metadaten für lokale und Netzwerkstimmen sichtbar.
- Stimmensuche ohne Mikrofonzugriff, Anbieter- und Locale-Anzeige, verständliche Paket-/Verbindungsfehler und unterbrechbare Ausgabe. Auswahl auf 360 px mit bis zu doppelter Schriftgröße geprüft.
- Hängende Android-Sprachabfragen und Wiedergabe begrenzt; unvollständige Erkennungsliste erlaubt ausdrücklichen de-DE-Versuch. Fehler-/Abbruchcallbacks geben lokale Wartevorgänge frei; keine automatische Mikrofonwiederholung.
- App-Start wartet auf lokale Spielstände, während der Sprachdienst danach unabhängig geprüft wird. Startprüfung mit echter SQLite-Datenbank und offener nativer Stimmabfrage ergänzt.
- Repositorystand erstmals gelesen und mit 0.3.0 verglichen: Dateiinhalte identisch, vier Ausführungsrechte verschieden. GitHub-Job bestätigt fehlendes sdkmanager nach erfolgreichen Tests; explizite Commandline-Tools-Installation in CI ergänzt. Git- und Connector-Schreibversuche weiterhin403, daher ZIP-Übergabe.
- Benutzerbericht zum App-Betrieb auf Samsung Galaxy S26 Ultra dokumentiert. Genaue betroffene Sprache/Anbieterfunktion bleibt offen; Sprachkorrektur auf dem Gerät separat abnehmen. Hauptsprache weiterhin Deutsch.

254 Flutter-Tests einschließlich 31 Sprachcontroller-, 7 neuen Einstellungen-
und 1 Starttest sowie 22 Backend- und 22 Python-Tests bestanden. Analyse ohne
Befunde, Backend- und universeller Debug-Build erfolgreich. Kleine APKs und
Übergabenachweise: DEVELOPMENT_STATUS.md.

## 0.3.0 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Explizite Stufe-1-Attributshilfe mit Standardsatz und Punktekauf bis 27 Punkten im Charaktereditor ergänzt.
- Vier SRD-Hintergründe mit erlaubten +2/+1- beziehungsweise +1/+1/+1-Steigerungen. Grundwerte, Boni, Endwerte und Modifikatoren getrennt dargestellt; Boni einmal angewendet.
- Vorhandene Werte benötigen Bestätigung zum Ersetzen. Öffnen/Abbrechen erhält historische und noch ungespeicherte Angaben.
- Nur Attribute und die gewählte Hintergrundbezeichnung werden übernommen; Talente, Fertigkeiten, Ausrüstung und Klassenwerte bleiben gesonderte Aufgaben. Keine Schemaänderung.
- Regeln anhand offizieller englischer/deutscher SRD 5.2.1-Quellen geprüft; 24 Domain-, 7 echte SQLite- und 13 neue Widgettests ergänzt und gezielt bestanden. Gesamter Check mit 222 Flutter-, 22 Backend- und 22 Python-Tests sowie Analyse und universeller Debug-Build erfolgreich. Drei optimierte Alpha-APKs gebaut, Metadaten/ABI und gleiche lokale Testsignatur geprüft. Geräteabnahme bleibt offen.

## 0.2.3 — 14. Oktober 2026 (Übergabe und Download; Backend bleibt 0.2.0)

- Quell-ZIP wahlweise ohne äußeren Dnd-Ordner; Byte-Erhalt, Dateiausschlüsse und sichere Paketpfade durch sechs Tests abgesichert.
- Projektprüfung vor SDK-Installation für fehlende/verschachtelte Dateien, Lockdateien, beschädigten Gradle-Wrapper und falsche Zeilenenden; 16 Regressionstests ergänzt.
- Kleine optimierte Alpha pro ARM64, ARM32 und x86_64 mit normalem Buildcode 5 sowie gleicher lokaler Testsignatur gebaut. Kein Store-Release. Dateien liegen jeweils unter 25 MiB.
- Kleine Alpha-Artefakte zusätzlich zur universellen Debug-APK in CI vorbereitet; 30 Tage Aufbewahrung.
- GitHub-Zugriff erneut überprüft: richtiger Benutzer ManuEtt, keine sichtbare App-Installation, Repository404 und Git403. Uploadursache ohne konkreten Fehlertext nicht als bestätigt behandelt.
- Upload-, Download- und Verbindungsanleitungen für die tatsächlichen Einschränkungen ergänzt.

## 0.2.2 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Charaktere und Kampagnen direkt als JSON-Dateien über Androids Systemauswahl sichern und öffnen; keine allgemeine Speicherberechtigung.
- Austauschbare Datei-Schnittstelle mit 10-MiB-Grenze, striktem UTF-8, sicheren vorgeschlagenen Dateinamen und verständlichen Fehlern.
- Ausgewählte Importdatei vor ausdrücklicher Bestätigung nur als bearbeitbaren Text anzeigen; Abbruch und Fehler erhalten bestehende SQLite-Daten. Zwischenablage bleibt verfügbar.
- 21 Kanal-/Sicherheitstests und 13 Datei-Widgettests ergänzen die Prüfung: 178 Flutter-Tests und Codeanalyse bestanden; Android-Debug-Build 0.2.2+4 erfolgreich. 12 native JVM-Tests für begrenztes I/O, Namen, Streamschluss und Abbruch bestanden; CI-Schritt ergänzt. Echte Dateiauswahl auf einem Gerät noch offen.

## 0.2.1 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Relevante bestätigte Erinnerungen für Backend-Erzählungen nach deutschen Worttreffern, NPC-Lebenszuständen, Queststatus und Inventarmengen ausgewählt.
- Unabhängige kurze Fakten und Flags bleiben beim Deduplizieren erhalten; Texte werden Unicode-sicher auf den erlaubten Kontext begrenzt.
- 13 neue Abruf-/Konsistenztests und ein Controller-Test mit mehr als 100 irrelevanten Fakten ergänzen die Prüfung: 144 Flutter-Tests, Analyse und Android-Debug-Build erfolgreich.

## 0.2.0 — 14. Oktober 2026

- Optionalen HTTPS-Backend-Erzähler mit temporärem Sitzungstoken, ausdrücklicher Kostenfreigabe und Anfragenversuchslimit in die App integriert.
- Backend-Sitzung ohne Modellaufruf prüfbar; neue Server-CLI zur Ausstellung kurzlebiger Tokens und Einrichtungshinweise ergänzt.
- Lokale Regelaktionen bleiben maßgeblich. Nur freie Erzählung und zugehöriger Checkpoint werden ersetzt; Ausfall, Tokenablauf und unzulässige Antworten führen zur lokalen Demo zurück.
- Fehler beim Ereignis-Replay behoben: Die Reihenfolge von JSON-Objektschlüsseln beeinflusst die Duplikatprüfung nicht mehr. Veränderte Werte und Listen werden weiter abgewiesen.
- Backend-Einstellungen, kleine Displays, Kostenfreigabe, echte lokale Node-/Dart-Kommunikation und Geheimnisfreiheit im SQLite-Speicher zusätzlich geprüft.

130 Flutter-Tests einschließlich echtem lokalem Protokolltest, 22 Backend-Tests, Codeanalyse und Android-Debug-Build bestanden. Ausstehende Backendanfragen lassen sich sofort trennen. Gerätetests bleiben separat offen. Details stehen in `DEVELOPMENT_STATUS.md`.

## 0.1.0 — 13. Oktober 2026

Eigenständiger Alpha-Projektstand zur ZIP-Übergabe für `ManuEtt/Dnd`. Ein Vergleich mit bestehendem Repositorycode war mangels Zugriff noch nicht möglich.

- Flutter-/Android-App mit Fantasy-Farben, Navigation, Charaktereditor, Abenteuer, Journal, Kampfgrundansicht und Einstellungen ergänzt.
- Deterministischen lokalen Spielleiter sowie Demo „Das Licht von Mooswacht“ mit Liora, Schlüssel, Waldschrein und einfacher Begegnung implementiert.
- Historische Kampagne „Das Herz der Ewigkeit“ als importierbaren Zustand mit ausdrücklich unvollständigem Arescan-Bogen ergänzt. Werte 19, 14 und der ungeprüfte Modifikator +7 bleiben historische Daten.
- Würfelregeln mit getrennten natürlichen Ergebnissen und Gesamtergebnissen, Angriffen, Schaden, Heilung und Todesrettung ergänzt.
- SQLite-Transaktionen für Charaktere, Kampagnensnapshots, Ereignisse und Revisionsjournal sowie JSON-Export/-Import eingerichtet.
- Grundlegende Kurzzeit-, Sitzungs- und Langzeitkontexte sowie Ereignisrekonstruktion ergänzt.
- Deutsche Gerätespracherkennung, bearbeitbares Transkript und unterbrechbare TTS integriert; Geräteprüfung steht noch aus.
- Optionales Fastify-/TypeScript-Backend mit validierter Erzähl-API, signierten Read-only-Sitzungstokens, Nutzungslimits und kostenlosem Mock eingerichtet. OpenAI Responses ist serverseitig optional; die mobile App nutzt weiterhin den lokalen Spielleiter.
- GitHub Actions für Backend- und Flutterprüfungen sowie Debug-APK eingerichtet.
- Architektur-, Status-, Test- und Übergabedokumentation sowie die geforderte SRD-5.2.1-Namensnennung ergänzt.

Erfolgreich geprüft: Flutter-Analyse ohne Befunde, 74 Flutter-Tests, 17 Backend-Tests und ein Android-Debug-APK-Build. Eine Prüfung auf einem echten Android-Gerät steht noch aus.

Überprüfte Ergebnisse stehen in `DEVELOPMENT_STATUS.md`. Vollständige SRD-Charakterbaulogik, öffentlicher Mehrspielerbetrieb, mobiler Realtime-WebRTC-Pfad, vollständige Erinnerungsverdichtung und weitere Plattformabnahmen bleiben offen.

## 0.6.8+38 – SRD-Klassenmerkmalregister und Klassenressourcen (16.10.2026)

- Alle zwölf SRD-Grundklassen und die zwölf SRD-Unterklassen als stufenbezogener Merkmalkatalog, einschließlich Automatisierungskennzeichen und Mehrklassen-Stufenabgleich.
- Mehrere Klassenressourcen separat persistiert und hinsichtlich Kurz-/Langrastregeneration verarbeitet; Altspeicher kompatibel.
- Regelbasierte Berechnungen für Schurken-Schadenswürfel, Kampfrauschwerte, Mönchskampfkunst und bardische Inspirationswürfel; Champion-Krit-Bereich in Angriffsauflösung; passive Bewegung/Initiative ergänzt.
- Neue Dart-Domain-Tests; kein Anspruch auf vollständige Ausführung aller Merkmalswirkungen oder validierten Flutter-/APK-Build.

## In Vorbereitung – strukturierte Inventarwerte (18.10.2026)

- Individuelle, typisierte Werte für Waffen, Rüstungen, Schilde, Verbrauchs- und magische Gegenstände gespeichert (`InventoryItem.stats`). Bestehende Spielstände ohne diese optionalen Werte bleiben lesbar.
- Eigene Eingabefelder im Charaktereditor, Katalogwerte als getrennte Datensätze übernommen, kompakte Werte-Vorschau im Inventar.
- Validierung verhindert negative Preise/Gewichte, unmögliche Ladungen und unzulässige Reichweiten; unbekannte Angaben bleiben unbestimmt.
- Neue Tests für JSON, SQLite, Katalogübernahme und UI ergänzt; **Flutter-Tests und Android-Build für diesen Stand noch nicht ausgeführt**.
- Individuelle Werte dienen vorerst der Verwaltung; für Kampfmechaniken gilt weiterhin der geprüfte SRD-Katalog. Kein automatisches Ausführen von Freitext-Effekten.

## In Vorbereitung – neue Charaktere: Erfahrungspunkte und Kämpfer-Stufe 1 (18.10.2026)

- EP-Vorgaben aus den D&D-SRD-5.2.1-Stufengrenzen, inklusive manueller Werteprüfung bei der Neuerstellung.
- Kämpfer Stufe 1: Pflichtwahl von Kampfstil und drei unterschiedlichen Waffenmeisterschaften, Startausrüstung und Vorschlag für W10 + KO-Start-TP.
- Zweite Luft wird als dokumentiertes Merkmal mit zwei Anwendungen sichtbar; bestehende Spiele und importierte Charakterbögen bleiben unverändert.
- Neue Domain- und UI-Tests für die Charaktererstellung. CI- und Android-Ergebnisse sind erst nach einem Branch-Build bestätigt.

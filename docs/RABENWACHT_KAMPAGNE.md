# Das Flüstern der vergessenen Glocke — vorgefertigtes Solo-Abenteuer

**Sprache:** Deutsch · **Regelgrundlage:** bestehende lokale D&D-5e/SRD-5.2.1-Regelengine · **Charakter:** eigener Held, empfohlen Stufe 3 · **Zielumfang:** 2–3 Stunden bei ruhigem Rollenspiel, Erkundung und optionalen Gesprächen.

## Kampagnenidee (Spielleiterwissen – Spoiler)

Im Grenzdorf Rabenwacht läutet ein vor 41 Jahren zerstörter Glockenturm. Drei Menschen sind verschwunden. Vor der dreizehnten Tür liegt ein Erinnerungsritual: Die gebundene Seren hält die Vermissten in einem schützenden Kreis, während die vierzehnte Glocke ihre Erinnerungen aussaugt. Der silberne Schlüssel bietet mehrere Lösungen. Entscheidend ist, ob der Held dem Geist vertraut, das Siegel erneuert oder es zerschlägt.

Alle Schauplätze, NPCs, Handlungsschritte und Ergebnisse sind lokal in `app/lib/domain/rabenwacht_campaign.dart` definiert. Die Engine verwaltet bestätigte W20-Würfe, lokale Kampfwerte und den Spielstand. Externe KI ist zum Starten und Durchspielen **nicht erforderlich**.

## Dramaturgie / Pacing

| Akt | Schauplätze | Ungefähres Zeitbudget | Inhalt |
| --- | --- | ---: | --- |
| I. Der Fremde im Nebel | Handelsstraße, Dorfplatz, Gasthaus | 20–30 Min. | Erste Begegnung, schwarzer Handabdruck, Hinweis auf Vermisste, Gespräche |
| II. Die Spuren der Verschwundenen | Mühle, Kapelle | 20–30 Min. | Spuren und Gebetbuch, Oswins Erinnerung, Familie von Fina |
| III. Die Brandnacht | Chronistenhaus, Friedhof | 20–25 Min. | Schriftliche Beweise, Serens Motiv, Weg zur Ruine |
| IV. Unter dem Turm | Rabenschlucht, Ruine, Kryptatreppe, Wächterhalle | 30–45 Min. | Heimlichkeit, Runen, Athletik, Kampf/Umgehen des Wächters |
| V. Die dreizehnte Tür | Galerie, Siegelkammer | 20–35 Min. | Tür- und Ritualrätsel, Verhandlung, drei Enden |

Die Zeiten sind **Erzählziele, keine technische Mindestspieldauer**. Schnelle Textantworten und wenige Nebengespräche können die Kampagne deutlich verkürzen. Die tatsächliche Länge muss beim Testspielen geprüft werden.

## Erweiterungen ab 0.8.7+57

* **Spoilerfreier Ermittlungsstand:** Im laufenden Rabenwacht-Abenteuer auf „Hinweise und Aufträge“ tippen. Die Übersicht ist jederzeit auch während einer offenen Würfelprobe lesbar, verändert weder Würfel noch Spielstand und zeigt nur bereits bestätigte Hinweise.
* **Freie Eingabe:** Außerhalb einer offenen Probe genügt auch das Kommando `Hinweise` oder `Ermittlungsstand` im Erzählfeld.
* **Optionales Brunnengeheimnis:** Auf dem Dorfplatz den Brunnen oder die schwarze Feder untersuchen, dann das Spiegelbild prüfen (Wahrnehmung SG 12). Der Umweg lässt sich jederzeit verlassen; ohne tatsächlich abgelegte Probe bleibt sein Auftrag offen.
* **Lebendige Fortschrittsanzeige:** Die Suche nach Vermissten wird bei ihrem Auffinden markiert, das Schlüsselrätsel nach dem Öffnen der dreizehnten Tür. Gespräche mit Elda, Tarek, Joren und Oswin verändern deren Beziehungen. Gerettete NPCs sowie gelöste Handlungsstränge werden am Ende erfasst.
* **Speicherung:** Der neue Ort, die Zusatzquest, Hinweise und NPC-Beziehungen werden über das vorhandene Kampagnenformat gespeichert. Bestehende Spielstände benötigen keine Migration.
* **Tests:** `app/test/rabenwacht_progress_test.dart` prüft die Spoilerbegrenzung, einen erfolgreichen Brunnenwurf, einen übersprungenen Umweg, die Gesprächsbeziehungen sowie Questfortschritt und Persistenz.

## Erfahrungspunkte und Stufenaufstieg (0.8.8+58)

**Regelgrundlage:** Die offiziellen SRD-5.2.1-Schwellen beziehen sich auf die Gesamtstufe eines Charakters und nicht auf eine einzelne Klasse. Ein Held steigt nach Überschreiten der Schwelle **nicht automatisch** auf. Er kann den bestehenden regelgebundenen Aufstiegsdialog öffnen und selbst wählen, welche bereits bekannte Klasse er steigert. Trefferpunkte und bestätigte Klassenfähigkeiten werden dabei durch den bestehenden Klassenassistenten behandelt. Für neue Zweitklassen bleibt der Mehrklassen-Assistent maßgeblich.

**Szenenbelohnungen (Spielleiterfestlegung, keine offiziellen SRD-Gegner-EP):**

| Ziel | EP |
| --- | ---: |
| Brunnengeheimnis erfolgreich untersuchen (optional) | 100 |
| Alte Mühle erreichen | 200 |
| Kapelle erreichen | 220 |
| Chronistenhaus erreichen | 260 |
| Friedhof erreichen | 240 |
| Turmruine erreichen | 260 |
| Die dreizehnte Tür öffnen und Gefangene finden | 340 |
| Die Kampagne zu einem Ende führen | 900 |

Die Hauptziele vergeben insgesamt **2.420 EP**, mit freiwilliger Nebenquest **2.520 EP**. Ein Stufe-3-Charakter, der mit regulären 900 EP startet, erreicht bis zum Finale mindestens 3.320 EP und damit die offizielle Schwelle für Stufe 4 (2.700 EP). Höherstufige Figuren können abhängig von ihren EP eine längere Kampagne für den nächsten Aufstieg benötigen.

* Jede Belohnung wird **nur einmal pro Kampagne** mit einem persistenten `xpReward:`-Marker gutgeschrieben. Wiederholtes Betreten eines Ortes, das Laden alter Gesprächsstellen oder dieselbe Auflösung vergeben keine weiteren EP.
* Schleichen am Knochenwächter und dessen Besiegen führen zur selben Etappe; das Kampagnenziel und nicht die Zahl getöteter Gegner ist entscheidend.
* Ein unbekannter historischer EP-Stand wird **nicht erfunden**. Die App verlangt in diesem Fall, die bisherigen EP zuerst im Charakterbogen zu bestätigen.
* Der Abenteuerbildschirm zeigt EP-Stand und Fortschrittsbalken. Beim Erreichen der nächsten Schwelle erscheint **„Stufenaufstieg verfügbar“** als Einstieg in den Charaktereditor, in dem der vorhandene SRD-Aufstiegsassistent genutzt wird.
* `app/lib/domain/campaign_experience.dart` implementiert die Belohnungs- und Fortschrittslogik, `app/test/campaign_experience_test.dart` kontrolliert Schwellenwerte, einmalige Vergabe, Persistenz, unbekannte EP und einen tatsächlichen Klassenaufstieg.

## NPCs (eigene Inhalte)

Elda Weißdorn (Hebamme und Zeugin), Tarek Dorn (Wirt), Mara Voss (Vorsteherin), Bruder Oswin (Zeitzeuge), Fina Kessel (vermisste Tochter), Joren Kessel (Müller), Bram Eisfeld (vermisster Wächter), Alrik Nebel (Chronist), Seren (gebundener Geist). NPC-Dialoge und Hinweise sollen nur offengelegt werden, wenn sie im aktuellen Akt zugänglich sind.

## Vorgesehene Fertigkeitsproben

Wahrnehmung SG 12 (Schritte), Nachforschungen SG 13 (Mühle), Nachforschungen SG 12 (Archiv), Heimlichkeit SG 12 (Wald), Arkane Kunde SG 13 (Ruine), Athletik SG 12 (Treppe), Heimlichkeit SG 13 (Wächter), Arkane Kunde SG 14 (Tür), Überreden SG 14 (Seren). Die Charakterboni und etwaiger Fertigkeitsbonus kommen aus `CharacterRuleEngine`, Ergebnisse aus `DiceEngine`; natürliche Würfelzahlen werden nicht doppelt bonifiziert. Die Story bleibt auch nach einem Misserfolg prinzipiell lösbar.

Der Skelettwächter verwendet den bereits im `AdventureCatalog` definierten Gegnerdatensatz; die Kämpfe werden durch die vorhandene lokale Engine abgewickelt. Begegnungen für **einen** Stufe-3-Helden müssen vor Veröffentlichung geprüft werden.

## Enden

* **Das erneuerte Siegel:** Erinnerungen zurück, Vermisste frei, Gefahr gebannt.
* **Das zerbrochene Siegel:** Vermisste frei, aber ein uraltes Wesen kann erwachen.
* **Serens Erlösung:** Überreden oder bewusstes Vertrauen führt zur Auflösung des alten Opfers, ohne die Menschen erneut zu binden.

## Integration und Start

1. In der Android-App unter **Helden** einen eigenen Charakter anlegen.
2. Im Startbildschirm **Rabenwacht (Solo, 2–3 Std.)** wählen.
3. Den Helden aus der vorhandenen Auswahl auswählen.
4. Direkt die Eingangsszene spielen und in der Abenteueransicht freie Handlungen eintippen oder vorlesen.
5. Bei einer offenen Probe den W20 nach Aufforderung werfen. Spielstand und Entscheidungen werden im vorhandenen SQLite-Repository abgelegt.

Technischer Einstieg: `GameController.newRabenwachtCampaign` → `GameEngine.createRabenwacht` → `RabenwachtCampaign.create`.

## Grenzen der ersten Integration

* Die erste Fassung verwendet handgeschriebene Schlüsselwort- und Szenenpfade; sie ist **kein** vollständig improvisierender KI-Dungeon-Master.
* Einzelne in-world Handlungen sind erzählerisch aufgelöst. Nicht alle Sonderfälle (z. B. alle Werkzeuge, Zauber für Rätsel oder komplexe NPC-Reaktionen) haben regeltechnisch eigene Pfade.
* Bis eine vollständige Flutter-CI inklusive Analyse, Tests und APK erfolgreich war, ist die Umsetzung als **implementiert, noch nicht als getestet oder installierbar bestätigt** zu behandeln.
* Diese Fassung garantiert noch nicht zwei Stunden Spielzeit; der Zielumfang hängt von der individuellen Spieldauer ab. Mehr optionales Rollenspiel und weitere Mechanik können später ausgebaut werden.

## Tests

`app/test/rabenwacht_campaign_test.dart` prüft Kampagnenstart, eigener Held, erfolgreiche und erfolglose Würfe, Manipulationsschutz offener Würfe, Skelettbegegnung und verschiedene Enden. Zusätzlich müssen `dart format`, `flutter analyze`, `flutter test` und `flutter build apk --debug` erfolgreich sein, bevor eine APK bereitgestellt wird.

## Verzweigte Ermittlungen und reaktiver Epilog (Entwicklungsbranch, Oktober 2026)

**Neue optionale Ermittlungsroute:** Wer am Dorfplatz Mara Voss anspricht, betritt die Ratsstube. Drei konkrete Entscheidungen beeinflussen den weiteren Verlauf:

- **Verschwiegenheit versprechen:** Mara vertraut dem Helden einen versiegelten Brief und den Glockeneid an. Alrik öffnet das Chronistenhaus; Mühle und Kapelle bleiben als nachholbare Rechercheorte erreichbar. `maraTrust` und `maraLetter` werden gespeichert.
- **Offenlegung der Wahrheit fordern:** Mara verweigert die Ratsakten; der Held wird stattdessen auf Tarek im Gasthaus verwiesen. `maraDefied` und eine feindselige Beziehung werden gespeichert.
- **Gezielt nach Fina fragen:** Mara verrät den Weg zur Mühle; der ursprüngliche Ermittlungsweg bleibt erhalten.

**Reisen und freie Eingaben:** Die Szenenwechsel setzen nun `visited:<stage>`-Marker. Bereits besuchte Hauptorte sind durch explizite Reisebefehle wieder erreichbar, ohne dieselben Meilenstein-EP erneut zu erhalten. Neue, noch nicht entdeckte Hauptorte sind nicht frei teleportierbar. Maras Brief schaltet ausdrücklich auch eine nachträgliche Reise zu Mühle/Kapelle frei. Die vorhandene Schlüsselworterkennung bleibt insgesamt deterministisch; sie ist **kein vollwertiges Sprachverständnis**. Für den Skelettwächter starten jedoch nur explizite Angriffsverben einen Kampf, negierte Angriffe und das bloße Erwähnen von Schlüssel oder Wächter nicht.

**Persistente Konsequenzen:** Maras Vertrauen oder Konflikt beeinflusst ihre gespeicherte Beziehung und das Finale. Ein bei misslungener Heimlichkeit ausgelöster Krähenalarm wird beim Wächter erwähnt und erscheint im Epilog. Die Schwierigkeit der Würfelproben bleibt unverändert; die Komplikationen sind derzeit **erzählerisch**, kein neuer mechanischer Schaden oder SRD-Zustand.

**Spielerentscheidung im Finale:** Eine erfolgreiche Überreden-Probe bei Seren erzeugt jetzt zunächst `serenTrust` und führt zum finalen Entscheidungspunkt. Die App trifft das Erlösungsende nicht mehr ohne ausdrückliche Spielerhandlung. Auch die anderen beiden Enden bleiben wählbar.

**Tests und Grenzen:** Der Regressionstest `app/test/rabenwacht_branching_story_test.dart` überprüft Mara-Routen, Beziehungen, Rückreisen, EP-Schutz, unbeabsichtigte Kämpfe, bewusste Finalwahl und Alarm-Folgen. Dieser Branch muss mit `dart format`, `flutter analyze`, `flutter test` und einem Android-Build geprüft werden. Ohne durchgeführten CI-Lauf sind diese Prüfungen **nicht bestätigt**. Komplexe Zauberlösungen, wirklich frei improvisierte NPC-Dialoge, Nebenquests und dynamische Kampfpläne bleiben zukünftige Entwicklungsschritte.

## Erweiterung: Die ausgelöschten Namen (optionale Friedhofsquest)

Am Friedhof kann der Held den **Gedenkstein der Namenlosen** untersuchen. Unter dem Stein flüstern Stimmen, deren Namen der Glockenorden aus der Chronik getilgt hat. Das neue optionale Ziel `rabenwacht-memorial` und `memorialSeen` werden erst durch tatsächliches Entdecken angelegt. Die Hinweiseübersicht verrät vorher nichts davon.

Nach der Entdeckung kann der Held die Namen **bewahren** (nur mit einem belegten Hinweis aus Gebetbuch, Oswins Geständnis, Maras Brief oder den Chronistenakten), die Namen **verschweigen**, erst weitere Spuren suchen oder weiterreisen. Fehlende Beweise lösen keinen künstlichen Würfelwurf und kein automatisches Scheitern aus. Uneindeutige oder ausdrücklich verneinte Eingaben werden nicht als irreversible Entscheidungen übernommen.

Die Ausgänge sind eindeutig speicherbar: `graveOath=remembered` (Nebenquest abgeschlossen) oder `graveOath=hidden` (Nebenquest gescheitert). Die Wahl bestimmt einen zusätzlichen Abschnitt im Epilog aller drei vorhandenen Enden. Offen gebliebene freiwillige Aufträge blockieren die Haupthandlung nicht und werden beim Kampagnenende als gescheitert markiert. Das erneute Betrachten des Steins erzeugt keine doppelten Quests oder zusätzlichen Erfahrungspunkte.

**Tests:** `app/test/rabenwacht_memorial_test.dart`: spoilerfreie Entdeckung, Queststatus, Beweiserfordernis, Rückreise, Idempotenz, beide Ausgänge, Speicher-Roundtrip, Epilog über drei Enden, offener Auftrag und verneinte Eingaben.

**Grenzen:** Dieser zusätzliche Handlungszweig ist handgeschrieben und deterministisch. Er stellt noch keinen generativen Dialog, keine neuen Kampfregeln und keine SRD-Zauberinteraktion dar. Build/CI/Android-Gerätetest sind getrennt nachzuweisen.

## Erweiterung: Erinnernde NPCs und Tareks Geheimweg (Entwicklungszweig, Oktober 2026)

**Alternative Waldrouten:** Im Gasthaus kann der Held Tarek ausdrücklich um einen „Geheimweg“ oder „Schleichweg“ bitten. Erst dann wird `tarekSafeRoute` gespeichert; Tarek erklärt die markierten Kerben im Wald. In der Rabenschlucht kann der Held **bewusst Tareks Wegzeichen folgen**. Die Route führt ohne Würfelprobe zur Turmruine. Der normale Heimlichkeitsweg und das offene Voranschreiten bestehen unverändert fort. Die EP für die Turmruine gibt es pro Kampagne weiterhin nur einmal. Ein **bereits** ausgelöster Krähenalarm wird nicht gelöscht. `crowsBypassed` wird gespeichert und in Hinweisen sowie Epilog berücksichtigt.

**Alrik reagiert auf echte Beweise:** Erst wenn die Namen am Gedenkstein nachweislich bewahrt wurden (`graveOath=remembered`), kann der Held Alrik im Chronistenhaus mit den gelöschten Namen konfrontieren. Alrik gesteht die Fälschung der Abschrift und `alrikConfession` wird gespeichert. Vorher weigert er sich, ohne dass der Spieler das Geständnis vorweggenommen bekommt. Alriks Beziehung verändert sich zu `reumütig`.

**Mara kann ihre Position überdenken:** Erst nach Alriks Geständnis kann Mara in der Ratsstube mit seiner Aussage konfrontiert werden. Dann öffnet sie das alte Ratsbuch, verspricht eine öffentliche Berichtigung und der Spielstand erhält `maraReconciled`. Ihre Beziehung wechselt zu `versöhnt`, auch wenn zuvor ein Streit stattgefunden hat. Der Epilog ersetzt bei einer Versöhnung den offenen Konflikt durch eine glaubwürdige Folgehandlung.

Alle Fakten und NPC-Beziehungen nutzen das bestehende Campaign-JSON. Es gibt keine neuen Würfel-Proben, keine neuen SRD-Mechaniken, keine stillen Rücknahmen bestätigter früherer Ereignisse und keine externe KI-Abhängigkeit. Die Erweiterung ist deterministisch, nicht sprachlich universell; sie reagiert auf konkrete erkennbare Eingabeabsichten. Das Regressionstestpaket liegt unter `app/test/rabenwacht_npc_memory_test.dart`; Flutter-CI und APK sind für diesen Entwicklungszweig gesondert zu bestätigen.

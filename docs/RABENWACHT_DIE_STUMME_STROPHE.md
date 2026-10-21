# Rabenwacht – Die stumme Strophe
## Optionaler Handlungsbogen mit viertem Finale

**Spoilerwarnung:** Dieses Dokument beschreibt die vollständigen Verzweigungen der neuen Geschichte. Hinweise im Spiel werden erst nach tatsächlichem Auffinden angezeigt.

### Dramaturgische Idee

Die zerstörte Glocke ist nicht nur ein Gefängnis. Der Glockenorden entfernte die letzte Strophe eines alten gemeinschaftlichen Lieds. Dadurch geriet in Vergessenheit, dass die vierzehnte Glocke auch der Erinnerung dienen kann: Nicht ein einzelnes Opfer, sondern mehrere Menschen, die ihre Verantwortung eingestehen, können den Kreislauf unterbrechen.

Bruder Oswin bewahrte ein verstümmeltes Notenblatt. Sein Schweigen ist zugleich Schuld und Angst. Die neue Nebenhandlung führt eine moralische Entscheidung ein: **Der Held kann den letzten Vers bewahren oder vernichten**. Beide Entscheidungen werden von Oswin erinnert und verändern spätere Szenen.

### Szenenfolge

**Kapelle – Der Stein hinter dem Altar:** Wer nach Glockenlied, Melodie, Hymne oder einer verlorenen Strophe fragt, entdeckt eine fehlende Notenzeile. Erst dann entstehen der Auftragsmarker `rabenwacht-hymn`, der Fakt `hymnSeen` und die eigene Szene `hymn`. Ohne Entdeckung taucht die Nebenhandlung nicht im Ermittlungsstand auf.

**Oswins Dilemma – Das verbrannte Blatt:** Um die verlorenen Worte glaubhaft zu rekonstruieren, benötigt der Held das Gebetbuch, Oswins Aussage über die Brandnacht oder Maras Abschrift des Glockeneids. Fehlende Beweise lassen die Handlung offen; der Spieler kann zurückkehren. Wer die Strophe bewusst bewahrt, erhält `hymnChoice=kept`, einen abgeschlossenen Auftrag und Oswins Vertrauen. Wer das Blatt vernichtet, erhält `hymnChoice=burned`, einen gescheiterten Auftrag und Oswins Distanz. Negierte oder widersprüchliche Antworten gelten nicht als Entscheidung.

**Chronik und Friedhof – Wahrheit gegen Schweigen:** Der vierte Weg setzt die bestehenden Erzählhandlungen voraus: Am Gedenkstein müssen die Namen tatsächlich bewahrt (`graveOath=remembered`) und Alrik im Chronistenhaus mit Belegen zum Geständnis gebracht worden sein (`alrikConfession=true`). Diese Beweise werden nicht aus Dialogabsichten geraten.

**Siegelkammer – Serens eigener Wille:** Seren muss dem Helden nach der vorhandenen Überreden-Probe vertrauen (`serenTrust=true`). Ein gefundenes Lied ersetzt die regelkonforme Probe nicht. Bei wiedergefundenem Lied verweist die Erzählung auf die Strophe. Am Entscheidungspunkt darf der Spieler weiterhin jedes der drei ursprünglichen Enden wählen.

**Verstecktes viertes Finale – Der Namenchor:** Der Spieler entscheidet selbst, ob er den Namenchor anstimmt. Nur wenn alle vier Voraussetzungen vorliegen, folgt `end-chorus`: Der vierzehnte Glockenschlag gibt Erinnerungen zurück, die Gefangenen erwachen, das Siegel schließt ohne neue Opfer und Seren entscheidet sich, freiwillig Hüterin der Erinnerungen zu bleiben. Die Bewohner müssen fortan mit der offenbarten Schuld leben. Die Auflösung unterscheidet sich damit inhaltlich vom individuellen Erlösungsende.

### Technische Zusagen

- Die neue Szene und die Quest werden mit dem bisherigen `Campaign.storyBible`-, `facts`-, `quests`- und `npcs`-Schema gespeichert; bestehende Speicherstände bleiben gültig.
- Der finale Status beginnt weiterhin mit `end-`. Der vierte Abschluss erhält den **gleichen einmaligen** Meilenstein-EP-Satz wie die bisherigen Enden.
- Ungelöste optionale Strophenquests blockieren die Kampagne nicht und werden am Ende nicht fälschlich als abgeschlossen markiert.
- Das Lied ist ein **erzählerischer Ritualweg**, kein eigenmächtig gewirkter D&D-SRD-Zauber. Es erzeugt keine Zauberplätze, keine unsichtbaren Zustandsänderungen oder kostenlosen Kampfboni.
- Neue Regressionen in `app/test/rabenwacht_hymn_story_test.dart` prüfen Entdeckung ohne Spoiler, Belege, freie Rückkehr, doppelte Quests, Erinnerungen der NPCs, bewahren/verbrennen, negative Eingaben, Sperren, viertes Finale und die alten Enden.
- Spielzeit, Schwierigkeit und emotionale Wirkung sind **noch nicht empirisch getestet**. Ein Gerätetest mit einem echten Spieler bleibt erforderlich.

### Weiterer Ausbau

Mehr Reaktionen von Joren, Elda und Fina auf die offenbarten Namen; szenische Erinnerungsbilder aus der Brandnacht; die Frage, wer tatsächlich den vierzehnten Glockenschlag auslöste; und ein spielbarer Epilog in Rabenwacht am Morgen nach dem Finale.

# Aetheria 0.3.8+14 – spielbare KI-Abenteuer

## Spielablauf

1. Einen **vollständig bestätigten Charakterbogen** verwenden. Eine KI-Kampagne mit verbundenem Server starten.
2. Freie Spielerentscheidung eingeben. Der Erzähler kann optional eine **Begegnung** vorschlagen. Kein Vorschlag bedeutet keinen neuen Kampf.
3. Die neue Karte **„Neue spielbare Begegnung“** enthält Titel, Beschreibung, Gegner- bzw. Probeprofil und Quest. **„Anderen Weg wählen“** verwirft alles ohne Veränderungen an Regeln, Inventar und Quest.
4. **„Begegnung annehmen“** aktiviert erst auf dem Gerät die Quest und wählt die lokalen Profile: Wegelagerer, Wolf, Skelettwächter, Goblin oder Ork. Die Ork-Begegnung ist erst ab Stufe 2 zugelassen.
5. Der lokale Würfeldienst führt Initiative, Angriff gegen RK, Schaden, Flucht und Begegnungsende aus. Bei Sieg wird die Quest abgeschlossen und exakt einmal ein **nichtmagischer, erzählerischer Fund** aus der lokalen Profilzuordnung ins Inventar gelegt. Flucht lässt die Quest ohne Beute scheitern.
6. Statt eines Kampfes kann die KI **`investigation`** anbieten. Dann startet die App eine Wahrnehmungsprobe gegen SG 10 mit dem bestätigten Weisheitsmodifikator und gegebenenfalls Übungsbonus. Nur bei bestandenem Wurf erhält der Spieler eine Spurenkarte und die Quest wird als abgeschlossen vermerkt.
7. Der gesamte Ablauf – Angebot, angenommener Auftrag, aktiver Gegner, Würfelanfragen, Questabschluss, Beute – wird im bestehenden atomaren Kampagnenspeicher und JSON-Export gesichert. Der bestehende SQLite-Schema-Stand bleibt unverändert.

## Sicherheit und Grenzen

- Die KI sendet **ausschließlich narrativen Text, sechs begrenzte Felder und einen erlaubten Profilnamen**. Der Backend-Validator entfernt unbekannte Felder. Die App validiert die Felder erneut. Kein Provider darf HP, RK, Schaden, Würfe, EP, Gold oder Inventar bestimmen.
- Die lokalen Werte sind **begrenzte Aetheria-Hausregelprofile**, **keine vollständigen SRD-5.2.1-Monsterdaten**. Diese Version bietet einzelne Gegner und Wahrnehmungsaufgaben, **keine Gruppenbegegnungen, Zaubereffekte, vollständige Initiative-Reihenfolge für mehrere Helden, dynamische Kampfpläne oder automatische EP-/Gold-Vergabe**.
- Auszuführende KI-Vorschläge werden erst durch die Spielerbestätigung umgesetzt. Für Kosten gelten weiterhin die explizite Anbieterfreigabe und die gemeinsamen Backend-Anfragelimits. Der Mock-Provider generiert keine echten autonomen Geschichten, kann aber Kampf- und Erkundungsangebote demonstrieren (Spielaktion `Ich suche eine Begegnung` bzw. `Ich untersuche die Spuren`).
- Nach Neustart müssen laufende Kämpfe und offene Proben fortsetzbar bleiben. Alten Spielständen fehlt nur das optionale Feld `adventureOffer`; sie bleiben lesbar.
- KI-Spielstände enthalten geheime Storyinformationen im Export. Nicht öffentlich verteilen. Die App speichert keine API-Schlüssel.

## Testablauf

- `cd backend && npm ci && npm run typecheck && npm test`
- `cd app && flutter pub get && flutter analyze && flutter test`
- Root: `python3 scripts/verify_project.py . && python3 -m unittest discover -s scripts/tests`
- GitHub Actions muss anschließend den Android-APK-Build freigeben. **Ohne grünen Lauf keine Freigabeempfehlung.**
- Zusätzlicher Gerätestest: Story-Vorschlag erzeugen, annehmen, Würfeln, Quest abschließen, Inventar prüfen, speichern, App beenden, wieder öffnen, Spielstand exportieren und importieren. Gegenprobe: dasselbe Angebot ablehnen und sicherstellen, dass keine Belohnung entsteht.

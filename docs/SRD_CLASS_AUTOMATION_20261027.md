# SRD 5.2.1 – Klassenautomatik und nachweisbare Lücken

Stand: 27.10.2026 · Quelle: [Wizards of the Coast, SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0.

## Ziel und begrenzter Umfang dieses Pakets

Das Projekt enthält derzeit **282 katalogisierte Klassen-/Unterklassen-Freischaltungen** für **12 Basisklassen und ihre 12 SRD-Unterklassen**. Dies sind keine 282 vollständigen Wirkungsimplementierungen. Das Ziel einer vollständigen Automatik ist noch **nicht erreicht**.

Dieses Paket ergänzt eine einheitliche **Laufzeit-Abdeckungsschicht**:

- `app/lib/domain/srd_class_automation.dart` ordnet **jede katalogisierte Freischaltung** dynamisch ein: bereits berechnete Mechanik, bestätigte Regelaktion, Teilautomatik, notwendige Spielerwahl oder noch fehlende Wirkung.
- Anders als das bisherige Katalogfeld `FeatureAutomation.automatic` erfordert eine als **berechnet** markierte Fähigkeit einen expliziten Verweis auf die bestehende Regelengine. Neue/unbekannte Fähigkeiten werden standardmäßig **nicht** als automatisiert dargestellt.
- Für alle zwölf Klassen erscheinen **direkt aus vorhandenen Rechnern abgeleitete Werte** im Charakterbogen: u. a. Kampfrausch-Schadensbonus, Inspirationswürfel, zweite Luft, Anzahl der Angriffe, Mönchswürfel, Handauflegen-Vorrat, Hinterhältiger-Angriff-Würfel, Paktplatzgrad, Anrufungs-Auswahlplätze und gemeinsame Zauberplätze.
- Stufenwerte hängen von der **Klassenstufe** und den tatsächlich bestätigten Ressourcen ab. Bei Mehrklassencharakteren werden Werte unabhängig ermittelt. Zauberplätze bleiben ausdrücklich ein **geteilter** Mehrklassenpool.
- Freie Merkmals- und Unterklassenwahlen werden **nicht erfunden**. Bekannte Klassenaktionen verbrauchen Ressourcen weiterhin ausschließlich über die vorhandenen Bestätigungs-/Kampfaktionswege.
- Die neue Schicht ändert **kein** `HeroCharacter`-JSON, keine SQLite-Struktur und keine Kampagnendaten. Werte werden zur Anzeige neu berechnet.

## Zusätzlicher ausführbarer Klassenbaustein: Barde 5

Das SRD-5.2.1-Merkmal **Font of Inspiration** hat nun einen separat geprüften
Zwei-Phasen-Mechanismus unter `app/lib/domain/srd_bard_font_of_inspiration.dart`:
Ein ausdrücklich ausgewählter freier Zauberplatz (regulär oder, bei
Mehrklassencharakteren, ein ausdrücklich ausgewählter Paktplatz) wird in
derselben unveränderlichen Zustandsänderung abgebucht, in der **eine** verbrauchte
Bardic-Inspiration-Nutzung zurückgegeben wird. Vor dem Commit müssen
Barden-Klassenstufe 5, Ressourcengrenzen, passende Platzstufe und der vollständige
unveränderte Charakterzustand bestätigt sein. Dies benötigt **keine Aktion** im
Sinne der 2024-Regeln; das Ausgeben der Inspiration an ein anderes Wesen bleibt
eine gesonderte Handlung.

`app/test/srd_bard_font_of_inspiration_test.dart` prüft normalen Platz,
Paktplatz, Leerstand, erschöpften Vorrat, fehlende Klassenstufe, unbrauchbare
Figur und veraltete Vorschläge. Die Regel-API wird **noch nicht automatisch
aus dem Abenteuer-/Kampfcontroller heraus aufgerufen**: Der Funktionsstand
bleibt deshalb **Teilautomatik** und wird nicht als vollständig im Spiel
verfügbar angezeigt.

Das Status-Label **„Bestätigte Regelaktion“** bedeutet, dass bereits eine separate Engine-Funktion existiert, **nicht**, dass das Merkmal in jeder denkbaren Spielsituation automatisch ausgeführt wird. **„Teilautomatik“** umfasst z. B. angelegte Ressourcen, Würfel oder Sicherheitsvorprüfungen, aber keine vollständig geschlossene Aktion. Komplexe Effekte wie Reliability Talent mit Werkzeugen, Slow Fall mit allen Abläufen und Feral Senses mit bestätigter Sicht bleiben daher teilweise.

## Testverpflichtung

`app/test/srd_class_automation_test.dart` kontrolliert:

1. Jede der 282 Katalog-Freischaltungen besitzt eine explizite Laufzeitbewertung; unbekannte zukünftige Features bleiben unimplementiert.
2. Angaben, die eine Spielerwahl benötigen, werden niemals als vollständig automatisch ausführbar klassifiziert.
3. Champions kritische Treffer, Extra-Attack-Stufen, Kampfrressourcen und nicht implementierte Merkmale werden unterscheidbar.
4. Unterklassenspezifische Merkmale erscheinen nur bei passend bestätigter Unterklasse.
5. Mehrklassen-Figuren erhalten ihre Zahlenwerte aus der korrekten Klassenstufe (nicht der Gesamtstufe), auch bei Zweiter Luft, Mehrfachangriff und Hinterhältigem Angriff.
6. Alle zwölf Klassen liefern nachvollziehbare Skalierungswerte.

Ausführung:

```bash
cd app
flutter analyze
flutter test test/srd_class_automation_test.dart test/srd_class_feature_catalog_test.dart test/srd_bard_font_of_inspiration_test.dart
flutter test
```

**Bis GitHub Actions die neuen Commits geprüft hat, ist keine grüne CI-Abnahme behauptet.** Android-Echtgeräteprüfung bleibt gesondert offen.

## Noch ausstehend bis „vollständig“

- Die verbleibenden katalogisierten Merkmale erfordern einzeln **Regelquelle, Trigger, Voraussetzungen, Auswahl, Ziele, Wirkungsdauer, Verbrauch, Ereignis-/Speicherintegration sowie positive/negative Tests**.
- Eine eigenständige Engine für Expertise, Zauberauswahl/-vorbereitung, Kampf- und Zauberverstärkungen, Unterklassen-Spezialaktionen, Metamagie, Invocations, Feats, göttliche Interventionen und epische Gaben ist noch zu vervollständigen.
- Für einmal pro Zug/Rast/Nutzung begrenzte Effekte benötigen Kampfzustand und Rastverwaltung typisierte, persistente Zustände und eine atomare Commit-API. Ein bloßer Klick auf eine Katalogzeile darf nichts verbrauchen.
- Jede automatisierte Aktion braucht **SRD-5.2.1-Nachweis und Ende-zu-Ende-Tests** für Barbar, Barde, Kleriker, Druide, Kämpfer, Mönch, Paladin, Waldläufer, Schurke, Zauberer, Hexenmeister und Magier einschließlich Unterklassen.
- Die Benutzeroberfläche muss fehlende Entscheidungen aktiv im passenden Assistenten einholen; eine rein informative Anzeige genügt nicht.

Fachlicher Grundsatz: **Erst belegte ausführbare Mechanik, dann der Status „Berechnet“.** Ein Katalog und automatisch angezeigte Zahlen sind kein Ersatz für vollständige Klassenregel-Automation.

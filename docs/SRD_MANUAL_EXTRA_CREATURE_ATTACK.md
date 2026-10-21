# SRD 5.2.1 – Erster echter zusätzlicher Kreaturenangriff (0.8.29+79)

Quelle: [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0 (Combat / Attack Rolls, Damage, Critical Hits).

## Unterstützter, sicher begrenzter Kampfpfad

Die mit Version 0.8.28 eingeführte **manuelle Initiative-Zugfolge** kann nun eine **einzige bestätigte einfache Waffenangriffs-Aktion** pro manuellem Zug einer lebenden, SL-gesteuerten Zusatzkreatur ausführen. Das Ziel ist **eine andere** lebende, separat gespeicherte Zusatzkreatur. Es werden keine Monsterwerte aus dem Namen oder Erzähltext abgeleitet.

Vor dem ersten Würfelwurf bestätigt die Spielleitung:
- Vollständiger Angriffsbonus (einschließlich Übung, Attribute und situativer Werte), Waffenschaden als begrenzter Würfelausdruck, Schadensart und Grund-RK des Ziels.
- Reichweite, zulässiges Ziel, Handlungsfähigkeit des Angreifers, eventuelle Deckung aus Sicht des Angreifers und eventuellen Vorteil/Nachteil.
- Keine ungeklärten Angriffs- oder kritischen Sonderfähigkeiten, Zielreaktionen, Resistenz, Immunität, Anfälligkeit und anderen Schadensänderungen.

Der `SrdExtraCreatureAttackRules`-Resolver würfelt lokal den Angriffswurf, behandelt natürliche 1/20 nach SRD 5.2.1, berücksichtigt bestätigte Halb-/Dreivierteldeckung (+2/+5 RK) und verdoppelt bei einem kritischen Treffer **nur die Schadenswürfel**, nicht die statischen Boni. Bei Fehlschlag werden keine Schadenswürfel geworfen.

`GameEngine.manualExtraCreatureAttack` prüft zuerst den aktuellen manuellen Zug, den eindeutigen Angreifer und dessen noch freie Aktion, den gespeicherten Zielzustand und offene Kampfentscheidungen. Danach werden W20/Waffenschaden, neuer Ziel-HP-Stand und der **verbrauchte manuelle Angriff** in **einem revisionsgeschützten Commit** mit dem auditierbaren Event `combat.manualExtraCreatureAttack` gespeichert. `nextManualActor` setzt den manuellen Angriff erst beim Wechsel auf den nächsten Akteur zurück. Alte `schemaVersion=1`-Spielstände ohne `manualTurnQueue.actionUsed` behalten `false` als impliziten Default.

Die Aktion **„Zusatzkreatur-Angriff“** öffnet im Kampf einen Dialog für sämtliche bestätigten Werte und ist nur sichtbar, wenn ein lebender SL-gesteuerter Zusatzakteur am Zug ist und wenigstens ein anderes lebendes Zusatz-Ziel existiert.

## Grenzen

**Nicht als vollständige Mehrgegner-Kampfengine ausgeben:** Angriffe auf den Helden oder Hauptgegner bleiben ausgesperrt, weil deren Reaktionen, Konzentrations- und Todesrettungsregeln über den bestehenden `Encounter` laufen. Die manuelle Initiative ist weiterhin nur ein separater Cursor. Automatische KI-/Monster-Aktionen, Gruppeninitiative, Multiattack, magische Angriffe, besondere Kampfmerkmale, echte Positions-/Bewegungsprüfung, andere Aktionsarten, Siegbedingungen und eigenständige Begegnungsbeendigung fehlen. Die technische Begrenzung eines manuellen Angriffs je Zug ist **keine behauptete SRD-Regel für Monster**. Alle Anforderungsstatus bleiben entsprechend **partial**.

## CI-Gates

```bash
python3 -m unittest discover -s scripts/tests -v
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Merge nur bei erfolgreicher kompletter Android-Alpha-/Quellcode-CI. Echter Android-Gerätetest steht offen.

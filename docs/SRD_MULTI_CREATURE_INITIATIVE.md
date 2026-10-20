# SRD 5.2.1 – Initiative zusätzlicher Kreaturen (0.8.27+77)

Lizenzquelle: [D&D SRD 5.2.1, Combat / Initiative](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), CC BY 4.0.

## Funktion

Die bisherigen `Encounter.heroInitiative` und `Encounter.enemyInitiative` bleiben erhalten. **Zusätzliche** mit TP gespeicherte Kreaturen können nun optional ein vom Nutzer **explizit bestätigtes vollständiges Initiative-Ergebnis** speichern. Zulässige Werte liegen zwischen -30 und 100 (technisches Eingabelimit; keine SRD-Beschränkung). Die Kontrolle (`gm` oder `player`) muss gleichzeitig vorliegen; die Initiative wird nicht aus Erzählungen oder einem nicht bekannten Geschicklichkeitsbonus erraten. Beide neuen Felder sind beim Import alter `schemaVersion=1`-Kampagnen optional. Ein tatsächlicher Gesamtwert `0` ist vom fehlenden Feld `null` unterscheidbar.

`SrdInitiativeRosterRules.preview` liefert aus Held, Hauptgegner und **lebenden** zusätzlich verfolgten Kreaturen absteigend sortierte Initiativgruppen. **Gleichstände bleiben als Gruppe ungeklärt**, weil die Reihenfolge laut SRD bewusst von Spielleitung/Spielern entschieden werden muss. Fehlende Zusatz-Initiativen werden separat angezeigt. Die beiden bereits gespeicherten Hauptwerte können aus alten Kampagnen voreingestellte Nullen enthalten; deshalb muss deren tatsächliche Ermittlung für die Anzeige bestätigt werden. Der Nutzer erhält im Dialog eine Vorschau, bevor er eine Initiative für genau eine Zusatzkreatur erfasst oder korrigiert.

Die Engine-Aktion `confirmAreaCreatureInitiative` verifiziert ID, lebende Zusatzkreatur, erlaubte Zahl, Kontrolle, explizite Zustimmung und offene Spezialproben. Sie löst weder Würfel noch Kampfaktionen aus; im bestehenden revisionsgeschützten SQLite-Spielstand wird ein eigenes `combat.areaCreatureInitiativeConfirmed`-Event mit den Werten und der unveränderten Gegner-HP-Liste abgelegt.

## Grenzen (SRD-Status `partial`)

- **Keine automatische Mehrgegner-Zugfolge**. Der aktive `Encounter` steuert weiterhin nur den Hauptgegner. Die angezeigte Initiative ist **keine** Zugberechtigung.
- Noch keine bestätigten Gleichstand-Auflösungsentscheidungen, keine persistente geplante Zugreihenfolge oder pro-Kreatur-Aktions-/Reaktionsverwaltung.
- Noch keine vollständige Unterstützung identischer Monstergruppen mit gemeinsamem Initiativwurf, für die Initiative geltender Überraschungsnachteile oder angepasster Kampfende-Bedingungen.
- Zusatzkreaturen haben noch keine eigenen Angriffs-/Wirkungsprofile, Positionen oder automatischen Rettungswürfe. Die Säurespritzer-HP-Verwaltung bleibt unverändert funktional.

## Abnahme

```bash
python3 -m unittest discover -s scripts/tests -v
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Nach vollständig grünem CI folgen die mergefähige App, arm64/arm/x64-Alpha-APK und Quellcode-ZIP. Echter Android-Gerätetest bleibt ausstehend.

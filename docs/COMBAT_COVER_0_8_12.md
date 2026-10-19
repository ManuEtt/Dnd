# Würfelraunen 0.8.12+62 – Deckung im Solo-Kampf

## Quelle und Geltungsbereich

Deutsches D&D-Einsteigerset-Regelbuch, **Kapitel 2: Kampfregeln, S. 12, „Deckung“** (vom Nutzer bereitgestellte PDF). Würfelraunen verwendet weiterhin den SRD-5.2.1-Regelkern. Übernommen wird nur die mit dem bestehenden Regelstand kompatible Deckungsmechanik, **nicht** das ältere Überraschungs- oder Erschöpfungssystem des Einsteigersets.

## Regeln

| Bestätigte Deckung | RK gegen diesen Angreifer | Geschicklichkeitsrettungswurf gegen diesen Effekt | Direkter Angriff |
|---|---:|---:|---|
| Keine | +0 | +0 | möglich |
| Halb | +2 | +2 | möglich |
| Dreiviertel | +5 | +5 | möglich |
| Vollständig | kein numerischer Bonus | nicht automatisch erfolgreich | **nicht möglich** |

Nur Hindernisse zwischen Ziel und Ursprung von Angriff/Effekt zählen. Mehrere Deckungen werden nicht addiert; nur die höchste zählt. Vollständige Deckung verhindert auch einen natürlichen kritischen Angriffstreffer **bei direktem Anvisieren**. Ein Flächenzauber kann ein dahinter befindliches Ziel unter Umständen trotzdem erreichen: Solche Effekte werden weder auto-blockiert noch als automatisch bestanden erfunden.

## Anwendung in der App

Während eines aktiven Kampfes **„Kampf ansehen“** wählen. Im Abschnitt **„Deckung gegen diesen Gegner“** sind zwei Auswahlfelder sichtbar: **Held** und **Gegner**. Die vier möglichen Deckungsgrade lassen sich ohne Freitexteingabe setzen. Alternativ funktionieren:

- `Deckung: Held halb`
- `Deckung: Held dreiviertel`
- `Deckung: Held voll`
- `Deckung: Gegner halb`
- `Deckung: Gegner dreiviertel`
- `Deckung: Gegner voll`
- `Deckung: Held keine` / `Deckung: Gegner keine`
- `Deckungsstatus`

Diese Eingaben bestätigen nur die Umgebungsgeometrie **gegenüber dem jeweiligen Kampfgegner** und sind keine kostenlose Bewegung. Sobald du dich mit einer bestätigten Bewegung anders positionierst, verliert dein Held die vorher bestätigte Deckung; gegnerische Deckung bleibt bis zur nächsten ausdrücklichen Situationskorrektur bestehen.

Im Kampf verwendet jeder normale Haupt-/Nebenhandangriff des Helden die **effektive Gegner-RK**, der Gegnerzug nutzt die **effektive Helden-RK**. Die Mönchsfähigkeit **Schlaghagel** beachtet dieselben Werte und verlangt vor einer durch vollständige Deckung unmöglichen Aktion keinen Fokuspunkt.

### Geschicklichkeitsrettungswürfe

Deckung zählt nur bei einem ausdrücklich als **vom Kampfgegner ausgehend** bestätigten Effekt, z. B.:

`Rettungswurf: Geschicklichkeit SG 15 vom Gegner`

Dieser Befehl verlangt einen laufenden bestätigten Kampf. Der normale Befehl

`Rettungswurf: Geschicklichkeit SG 15`

nimmt **keine** fremde Wirkungsrichtung an und bekommt daher keinen Deckungsbonus. Weisheit und andere Attribute bekommen auch gegen den Gegner **keinen** Deckungsbonus. Bestätigte Klassen-Wiederholungswürfe (Fokus/Unbeugsam) behalten den zuvor berücksichtigten Wert, sofern der Zustand unverändert ist.

## Speicherung und Prüfbarkeit

Das bisherige `Encounter`-Speicherformat bekommt optional `heroCover` und `enemyCover`, je `half`, `threeQuarters`, `total`; nicht vorhandene Felder bedeuten **keine** Deckung. Ungültige Werte werden abgewiesen. Bei laufendem Angriff müssen gespeicherte gegnerische Deckung und effektive Angriffs-Schwierigkeit übereinstimmen; manipulierte Spielstände sind nicht gültig. Eine offene W20-Probe lässt keine nachträgliche Deckungsänderung zu. Kampfrunden, Ressourcen und Ereignisprotokolle bleiben erhalten.

## Grenzen

Keine automatisch berechneten Sichtlinien, Kartenkoordinaten, Gegenstände, Flächenformen oder unbestätigten Monsterpositionen. Auch situative Spezialfähigkeiten, Zauber, die Deckung umgehen, und Fernkampfziele außerhalb des vereinfachten Systems erfordern weitere Bestätigung. Deckung wird für beide Kämpfenden **nur** relativ zueinander gespeichert – nicht universell für jeden denkbaren Effekt.

## Automatische Tests

`app/test/cover_combat_rules_test.dart` überprüft AC/DEX, Mehrfachdeckungen, vollständiges Blockieren, Spieler-/Gegnerangriffe, Mönch-Fokus, manuelle Saves und Klassen-Wiederholungen, Kampffortsetzung, ungültige bzw. alte Spielstände, Manipulationsschutz und die Bewegung. Zusätzlich durchlaufen alle bisherigen Flutter- und Backendtests die CI; danach muss der Android-Build erfolgreich sein.

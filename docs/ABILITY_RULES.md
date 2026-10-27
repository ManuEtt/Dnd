## 27.10.2026 – Zusätzliche Herkunftspakete (Stack-PR #273)

Die vier SRD-Hintergründe erhalten ausdrücklich bestätigte
Fertigkeits-/Werkzeugübungen und die Wahl zwischen ihrem
A-Ausrüstungspaket und 50 GM. Die Attributerhöhungen werden
**nicht erneut angewendet**. Herkunftstalente werden nur als
noch nicht vollständig automatisierte Merkmale vermerkt.
Siehe [Charaktererstellungs-Audit](CHARACTER_CREATION_COMPLETE.md).

## 27.10.2026 – Bestätigte Ausgangswerte dauerhaft zuordnen

Mit dem neuen optionalen `HeroCharacter.startingAbilityOrigin` werden die
**sechs Ausgangswerte**, die gewählte SRD-Methode, der Hintergrund und die
konkret bestätigten Erhöhungen zusammen mit dem Helden gespeichert.
Würfelwerte enthalten zusätzlich ihre 24 Rohwürfel (6 × 4W6).
Beim Lesen wird der versionsgebundene Nachweis erneut validiert.
Der Nachweis ist historisch; spätere Stufen- und Hausregeländerungen
dürfen ihn nicht unbemerkt als aktuelle Erzeugung ausgeben.

**Keine Datenbankmigration**, alte Speicherstände ohne dieses Feld
bleiben unverändert; der Feldwert ist nicht als zusätzlicher Regelbonus
anzuwenden. Neue Tests für JSON/SQLite und Editor-Bestätigung liegen
auf einem gesonderten gestapelten PR; finale CI läuft noch nicht.
[Charaktererstellungsstatus](CHARACTER_CREATION_COMPLETE.md).

# Attributverteilung bei der Charaktererstellung

Die neue Attributverteilung implementiert eine ausgewählte Regelteilmenge des
SRD 5.2.1. Die Attribute werden ausdrücklich zugewiesen; Klasse, Spezies oder
historische Erzählungen erzeugen keine Werte. Bestehende Charakterbögen und
unbestätigte Arescan-Werte bleiben unverändert, bis der Benutzer eine neue
Verteilung übernimmt und den Charakter speichert.

## Dritte offizielle Methode: Würfeln (Entwicklungspaket #264)

SRD 5.2.1, S. 21: Sechsmal vier W6 werfen, jeweils den niedrigsten
Würfel streichen, die sechs Summen ausdrücklich auf die Attribute
verteilen. Die neue `AbilityRollSet`-Domäne zeigt alle 24 Würfelzahlen,
prüft 1 bis 6 pro W6 und die exakte Häufigkeit aller sechs Summen.
Die Würfelquelle ist für reproduzierbare Tests injizierbar. Ein Moduswechsel
erzeugt keinen zweiten Wurf. Die UI verlangt eine ausdrückliche
Werte-Zuordnung und weiterhin eine gültige Hintergrundwahl.

**Wichtige Grenze:** Die Attribut-Provenienz (Methode, Rohwürfel und
Hintergrundverteilung) wird noch nicht dauerhaft in älteren und neuen
Helden gespeichert. Der bisherige Editor übernimmt nur die bestätigten
Endwerte. Somit ist die Charaktererstellung insgesamt noch unvollständig.
Neue Tests sind geschrieben, aber ohne erfolgreiche finale CI noch
nicht als bestanden nachgewiesen. Siehe
[Teilabdeckung](CHARACTER_CREATION_COMPLETE.md).

## Geprüfte offizielle Quellen

Die folgenden offiziellen Dateien wurden am 14. Oktober 2026 geladen und
anhand ihrer Texte geprüft. Seitenzahlen beziehen sich auf die im PDF gedruckten
Seiten. Die PDFs werden nicht im Projekt gebündelt.

- [Englisches SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
  Seite 21, „Generate Your Scores“, „Ability Score Point Costs“ und
  „Adjust Ability Scores“; Seite 83, „Character Backgrounds“.
- [Deutsches SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/DE_SRD_CC_v5.2.1.pdf),
  Seite 24, „Deine Werte generieren“, „Attributswert-Punktkosten“ und
  „Attributswerte anpassen“; Seite 93, „Charakterhintergründe“.
- Die erforderliche Namensnennung und die Lizenz CC BY 4.0 stehen in
  [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

Der englische Wortlaut lautet: „Standard Array. Use the following six scores for
your abilities: 15, 14, 13, 12, 10, 8.“ Der deutsche Text nennt entsprechend den
„Standardsatz“. Jeder dieser sechs Werte muss genau einmal verwendet werden.

Beim Punktekauf steht: „You have 27 points to spend on your ability scores.“
Die deutsche Ausgabe formuliert „Du hast 27 Punkte, die du für deine
Attributswerte verbrauchen kannst.“ Der Text schreibt nicht ausdrücklich vor,
dass sämtliche Punkte verbraucht werden müssen. Diese Implementierung behandelt
27 deshalb als verfügbares Höchstbudget: Nicht verbrauchte Punkte bleiben
sichtbar; ein Budgetüberschreiten ist ungültig. Das ist eine dokumentierte
Auslegung, keine zusätzliche behauptete SRD-Vorschrift.

| Basiswert | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Punktekosten | 0 | 1 | 2 | 3 | 4 | 5 | 7 | 9 |

Die Kosten gelten vor den Hintergrunderhöhungen. Ein höherer Endwert wird nicht
erneut mit der Punktkostentabelle berechnet.

## Hintergrunderhöhungen

Seite 83 der englischen Ausgabe beziehungsweise Seite 93 der deutschen nennt
für jeden Hintergrund drei erlaubte Attribute. Davon erhält eines +2 und ein
anderes +1, oder alle drei erhalten jeweils +1. Zwei verschiedene Attribute sind
für +2/+1 erforderlich. Keine Erhöhung darf zu einem Wert über 20 führen.
Eine Überschreitung wird abgelehnt und nicht still auf 20 gekürzt.

| Hintergrund | Erlaubte Attribute |
| --- | --- |
| Akolyth | Intelligenz, Weisheit, Charisma |
| Krimineller | Geschicklichkeit, Konstitution, Intelligenz |
| Weiser | Konstitution, Intelligenz, Weisheit |
| Soldat | Stärke, Geschicklichkeit, Konstitution |

Die Auswahl bildet ausschließlich diese Attributsregeln ab. Herkunftstalente,
Fertigkeiten, Werkzeugübung, Ausrüstung und sonstige Charaktermerkmale eines
Hintergrunds werden dadurch nicht automatisch vergeben. Ebenso ist ein
Attributvorschlag noch kein vollständiger Charakterbogen. Die Oberfläche
verlangt vor der Übernahme eine ausdrückliche Hintergrund- und Bonuswahl.

## Domänenschnittstelle und Zustandsgrenzen

`app/lib/domain/ability_generation.dart` enthält keine UI, Datenbankzugriffe,
Zufallsquelle oder KI-Aufrufe:

- `AbilityAllocation` hält eine unveränderliche Basiszuweisung und eine Methode.
  `errors` und `isValid` prüfen genau die sechs vorhandenen Attribut-IDs,
  Standardsatz oder Punktekauf. Ungültige Entwürfe lassen sich anzeigen; eine
  Übernahme mit `compose` ist nur bei gültiger Zuweisung möglich.
- `pointCost`, `remainingPoints` und `usesFullBudget` machen das Budget prüfbar.
  Bei ungültigen Attribut-IDs oder Werten gibt es keinen irreführenden Punktpreis.
  Ein ansonsten gültiger, überzogener Entwurf zeigt negative Restpunkte.
- `BackgroundAbilityBoost` hält die ausgewählte Hintergrundregel und die
  ausdrücklichen Erhöhungen. `applyTo` validiert sechs Werte vor der Erhöhung
  sowie die Obergrenze 20.
- `compose(backgroundBoost: ...)` liefert ein unveränderliches
  `AbilityGenerationResult` mit getrennten `baseScores` und `finalScores`.
  Wiederholte Komposition beginnt immer bei den Basiswerten; Boni werden nicht
  erneut auf einen gespeicherten Endwert addiert.
- `compose()` ohne Hintergrund ist ausschließlich eine Basisvorschau und wird
  durch `backgroundApplied == false` gekennzeichnet. Die Oberfläche übernimmt
  nur Ergebnisse mit einem gewählten Hintergrundbonus.

Der bestehende Charakterbogen speichert bestätigte Endwerte. Seine allgemeine
Gültigkeitsgrenze 1 bis 30 bleibt erhalten; die Grenzen des Punktekaufs gelten
ausschließlich für neue Basiszuweisungen. Klassen-, Spezies-, Ausrüstungs- oder
Trefferpunktberechnungen sind nicht Teil dieses Moduls. Für Attributsmodifikatoren
bleibt die bestehende `RulesEngine` maßgeblich.

## Tests

`app/test/ability_generation_test.dart` prüft alle 720 Standardsatz-Zuweisungen,
die komplette Kostentabelle, ungenutzte und überschrittene Budgets, ungültige
Attribut-IDs, jede erlaubte +2/+1-Zuweisung und +1/+1/+1 bei allen vier
Hintergründen, die Grenze 20, unveränderliche Daten und wiederholte Komposition.
Die Integration mit dem bestehenden Charaktermodell und der Regelengine prüft
die aus Endwerten berechneten Modifikatoren ohne zusätzliche Bonusanwendung.

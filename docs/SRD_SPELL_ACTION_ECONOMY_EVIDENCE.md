# SRD 5.2.1 – getrennte Zauberaktion und Bonusaktion

Stand: 30.10.2026 · Quelle: Wizards of the Coast LLC, [SRD 5.2.1](https://www.dndbeyond.com/srd), *Playing the Game / Combat*, *Spells / Casting Time*, *Rules Glossary / Magic Action, Bonus Action, Action Surge, Rage* (CC BY 4.0).

## Funktion

`app/lib/domain/srd_spell_action_economy_rules.dart` enthält eine **rein lesende** Prüfung der aktuellen Kampf-Aktionsökonomie. Aus der **exakten** Wirkzeit eines Zaubers wird `SrdSpellTurnAction.magicAction` oder `SrdSpellTurnAction.bonusAction` abgeleitet. Die zugehörige bereits gespeicherte Aktionsressource wird separat geprüft:

| Tatsächliche Wirkzeit | Prüft in `Encounter` | Darf die andere Aktionsressource ersetzen? |
| --- | --- | --- |
| `Action`, `Action or Ritual` | `actionUsed == false`, außerdem `surgeReserved == false` und `surgeUsedThisTurn == false` | Nein |
| `Bonus Action` | `bonusActionUsed == false` | Nein |
| Ausgelöste Bonusaktion, Reaktion, Langzeit oder Sonderzeit | eigener Regelpfad erforderlich | Nein |

Bei Zaubern des Grades 1 bis 9 muss zusätzlich `spellSlotExpendedThisTurn == false` sein, wenn die vorhandene turnbasierte, slotverbrauchende Zauberaktion geprüft wird. Ein Zaubertrick benötigt diesen Slot-Check nicht; seine tatsächliche **Magic Action** muss trotzdem frei sein. Die herkömmlichen Übungs-, Vorbereitungs-, Komponenten-, Ziel-, Spellslot- und Wirkungsbestätigungen erfolgen weiterhin über andere Regeln.

Die Prüfung lehnt fremde/nicht laufende Züge, abgeschlossene Kämpfe, aktiven Kampfrausch, Tod, fehlende/0 TP oder Handlungsunfähigkeit ab. Das reine Auflösen eines Kampfes wird nicht erfunden. Ist kein `Encounter` vorhanden, benötigt der Aufrufer ausdrücklich die Bestätigung `noActiveEncounterConfirmed`, und `currentEncounterConfirmed` muss falsch sein. Bei vorhandenem `Encounter` muss der bestätigte Kampfsnapshot über `currentEncounterConfirmed` vorliegen. Widersprüche führen zu `FormatException`.

## Herkunft und Transaktionsgrenze

Der Rückgabewert `SrdSpellTurnActionEvidence` enthält die erforderliche Aktionsart und **vollständige JSON-Snapshots** des übergebenen Helden, der Wirkzeit-/Zaubermetadaten und des Kampfes. Vor einer eventuellen Ressourcen- oder Spielstandsänderung muss die aufrufende Transaktion `validateUnchanged(hero,spell,encounter)` erneut anwenden, einschließlich gesicherter Revision/Version und zugehöriger Effekt-/Zauberplatzbelege. Ein JSON-Snapshot ist **kein kryptographischer Authentizitätsbeleg**; er verhindert nur die versehentliche Wiederverwendung nach Änderungen innerhalb desselben bestätigten Vertrauenskontexts.

**Noch nicht implementiert:** Diese isolierte Prüfung bucht **keine** Aktion, Bonusaktion, Zauberplätze, TP, Konzentration oder Events und wird noch nicht von `SrdSpellPreflightRules.preflight` / `GameEngine` / `GameController` / SQLite verwendet. Eine Kopplung an den dortigen atomaren Commit ist Folgearbeit und hängt von Review und Integration des separaten PR #429 (kanonische Wirkzeiten) sowie von Koordination mit Chat D ab. Die alte allgemeine `actionAvailableConfirmed`-Schnittstelle bleibt vorerst unverändert: bestehende Pfade nutzen diese neue Prüfung also **nicht automatisch**. Diese Grenze darf nicht als bereits behobenes Gesamt-Engineproblem bezeichnet werden.

**Keine Migration:** `models.dart`, Kampf-/Kontroll-/UI-/Story-/Backend-Code, SQLite-/JSON-/Eventformat, SRD-Katalog-Asset und App-Version unverändert. Der Bedarf an echten Kampfdaten, Zeit/Trigger- und Extra-Aktionsregeln bleibt offen.

## Tests

`app/test/srd_spell_action_economy_rules_test.dart`: acht Gruppen zu (1) eigenständigen Aktionsressourcen, (2) bereits verbrauchtem Zauberplatz vs. Zaubertrick, (3) Action-Surge-Grenzen, (4) Zug, Kampfrausch, Handlungsfähigkeit und Kampfende, (5) nicht bestätigtem Kampfstatus, (6) Ritualoption/ausgelösten Zeiten, (7) manipulierten Wirkzeiten, (8) veralteter Helden-/Encounter-/Zaubermetadatenbestätigung inkl. JSON-Roundtrip. Diese Tests müssen auf dem endgültigen GitHub-Head grün sein, bevor die Implementierung als CI-abgenommen gilt. Ein echter Android-Gerätetest bleibt separat offen.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_action_economy_rules_test.dart
flutter test
flutter build apk --debug
```

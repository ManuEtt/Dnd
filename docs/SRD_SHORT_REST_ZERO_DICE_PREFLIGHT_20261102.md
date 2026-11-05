# SRD 5.2.1 – Kurzrast-Ressourcen vor Null-Trefferwürfelregeneration

## Quelle

Wizards of the Coast LLC, *System Reference Document 5.2.1*, „Rules Glossary / Short Rest“ und „Warlock / Pact Magic“, CC BY 4.0, https://www.dndbeyond.com/srd.

Der Einsatz von Hit Point Dice ist bei einer kurzen Rast optional. Separat wiederhergestellte Klasseneigenschaften und Paktzauberplätze müssen aber ihrem tatsächlichen, zuvor validierten Ausgangspool entsprechen. Der Regelstatus im Coverage-Register bleibt `partial`: reale Zeiterfassung und Unterbrechungen sind nicht vollständig automatisiert.

## Vorheriger reproduzierbarer Pfad

`GameEngine.act` wickelte zwei Sonderfälle vor `RestRules.shortRest` ab: bei vollen TP und einer regenerierbaren Ressource und bei erschöpften Trefferwürfeln mit regenerierbarer Ressource. `SpellcastingRules.afterShortRest` setzte gespeicherte Paktverbrauchszähler auf null, bevor `availablePactSlots` prüfen konnte, ob ein Kämpfer überhaupt Paktplätze besitzen darf. Der verwundete Würfelpfad besaß diesen Preflight bereits.

## Änderung und Akzeptanz

- `RestRules.validateShortRestResources` verwendet den unveränderten Helden und bestätigt Rastfähigkeit, Feature-/Klassenressourcen, Paktverbrauch und Trefferwürfelpool vor jeder Recovery.
- `RestRules.shortRest` nutzt den identischen Gate. `GameEngine.act` ruft ihn vor Wiederherstellungs-Sonderpfaden und vor den ersten möglichen RNG-Zugriffen auf.
- Fehler liefern den bestehenden deutschen `rules.blocked`-Kanal; Heldenressourcen, TP, Trefferwürfel und Würfe werden nicht verändert.
- Fünf gezielte Testfälle sichern beide Null-HD-Pfade, ungültige Klassenressourcen, gültigen Kämpfer/Hexenmeister, JSON-Wiederaufnahme, 0 RNG-Nutzung und Unveränderlichkeit. Positivfälle dürfen weiterhin Klassen-/Paktressourcen genau nach ihren bisherigen Regeln wiederherstellen.

## Grenzen

Es werden keine neuen Kurzrastentscheidungen, Daueruhren, Würfelressourcen oder Speicherfelder eingeführt. Schema 3 und äußeres JSON 1 bleiben unverändert. GitHub-CI auf PR #515 vor Integration gesondert abnehmen; keine Geräte- oder Altinstallationsabnahme behauptet.

## Korrektur der drei negativen Engine-Fixtures (03.11.2026)

Der erste Volltest (`7ae3aaf5a73e`) dokumentiert 2.854 erfolgreiche und drei fehlgeschlagene Flutter-Tests. Die drei Negativfälle gingen davon aus, ein strukturell ungültiger Spielstand könne noch ein serialisierbares `rules.blocked`-Ereignis erzeugen. Tatsächlich weist der vorhandene `_commit`-Validierungspfad einen solchen Zustand mit `FormatException` zurück. Der Testcode auf Commit `49745fc6232f7f8d3ddd711bbffd4aa1eaea52c0` erwartet diesen bestehenden Fail-Closed-Vertrag, überprüft unverändertes Held-JSON, die leere Eventliste und ausbleibende Zufallswürfe. Keine Produktionsfunktion oder Persistenzschnittstelle durch die Korrektur verändert. **Vollständige CI des finalen PR-Kopfs muss separat erfolgreich sein; kein APK-Gerätetest behauptet.**

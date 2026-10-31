# SRD 5.2.1 – gemeinsame Zauberplatz- und Kampfaktions-Buchung (Staging)

**Datum:** 31.10.2026 · **Anforderung:** `RULE-CORE-RULES-ACTION-ECONOMY`, `RULE-CORE-RULES-BONUS-ACTIONS`, `RULE-SPELLS-SPELL-SLOTS` (weiterhin **partial**, keine vollständig geprüfte Gesamtabdeckung). **Quellengrundlage:** Wizards of the Coast LLC, [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), *Playing the Game / Actions and Bonus Actions*, *Spells / Casting Time, Spell Slots*; CC BY 4.0.

## Problem

Bislang sind `SrdSpellPreflightRules.preflight` (Klasse, vorbereiteter Zauber, Ziel/Komponenten/Zauberplatz) und `SrdSpellActionEconomyRules.inspect` (eigener Kampfzug, Magic Action oder Bonus Action, genau ein verbrauchter Zauberplatz) unabhängige Module. Ein frei stehendes, boolesches `actionAvailableConfirmed` im Legacy-Preflight ist **kein belegter Kampfaktionszustand**. Die beiden Regelprüfungen müssen vor einer gemeinsamen Buchung ausgewertet werden, damit ein Zauber keinen Zauberplatz verbraucht, ohne zugleich die passende Aktion als verbraucht auszuweisen.

## Neuer geprüfter Ablauf

`app/lib/domain/srd_spell_turn_transaction_rules.dart` führt die vorhandenen Regeln ohne neue eigene Regeldefinition zusammen:

1. `SrdSpellTurnTransactionRules.prepare(...)` verlangt einen ausdrücklich bestätigten beabsichtigten Zauber, das Ziel, die notwendigen Komponenten, eine bestätigte Begegnung oder einen ausdrücklich bestätigten Nicht-Kampfzustand und den gültigen Heldenzug. `SrdSpellActionEconomyRules.inspect` prüft die richtige **Magic Action vs. Bonus Action** vor `SrdSpellPreflightRules.preflight`. Außerhalb eines Kampfes muss bei Grad-1+-Zaubern zusätzlich der auswärtig bestätigte Turn-Slot-Status vorliegen. Unbekannte Begegnung ≠ außerhalb des Kampfes.
2. Das private `SrdSpellTurnPlan` bündelt den Zauberplan und den exakten unveränderlichen Helden-/Zauber-/Encounter-Beleg. Weitere Zaubereffekte, Ziele und Materialbelege sind externe, eigenständig bestätigte Regeln.
3. `SrdSpellTurnTransactionRules.stageConfirmed(...)` lehnt veraltete Helden-, Encounter- und Zaubermetadaten ab, prüft den Zug **erneut** und ruft erst nach `effectResolvedSeparatelyConfirmed` die bestehende `recordConfirmedResourceUse`-Routine auf. Bei verbrauchtem Material muss die separat bestätigte Materialbuchung vorliegen.
4. Anschließend wird ein **neues, nicht gespeichertes Paar** zurückgegeben: `SrdSpellTurnStagedResult.hero` mit verbuchtem Slot und ggf. neuer Konzentration sowie `SrdSpellTurnStagedResult.encounter` mit genau dem passenden Aktionsflag und dem Turn-Slot-Marker. Ein Zaubertrick behält seinen Slotstatus unverändert. Beide Originalobjekte bleiben unverändert.

Diese reine Domainfunktion führt keine Flutter-UI, Erzählung, Würfel, SQLite-Transaktion oder Eventpersistenz aus. **Die aufrufende GameEngine-/Controller-/Repository-Transaktion muss Hero und Encounter gemeinsam mit den Events unter derselben bestätigten Revisionsnummer atomar speichern.** Der Stub `stageConfirmed` allein ist keine Persistenz- oder Genau-einmal-Garantie.

## Fachliche Sicherheitsgrenzen

- Benötigt die exakte gewöhnliche Wirkzeit `Action`, `Action or Ritual` oder `Bonus Action` aus dem geprüften Zauberkatalog. Reaktionen, ausgelöste Bonusaktionen, Rituale mit längerer Wirkzeit und Sonderzeiten sind weiterhin aus dem generischen Preflight ausgeschlossen.
- Action Surge berechtigt weiterhin nur zur dafür freigegebenen Attack Action, nicht zur Magic Action. Kampfrausch sperrt Zaubern. Nur bestätigte aktive Heldenzüge werden akzeptiert.
- Eine bereits ausgegebene normale Aktion verhindert keinen ansonsten freien Bonusaktions-Zauber; ein bereits ausgegebener Zauberplatz im Zug verhindert jedoch einen **weiteren slotverbrauchenden Zauber**. Ein Cantrip benötigt die Magic Action, aber keinen Zauberplatz.
- Nach Revisions-/Helden-/Kampfzustandsänderung wird ein vorbereiteter Plan unbrauchbar; nochmaliges Anwenden auf den bereits verbuchten Hero-/Encounter-Snapshot muss fehlschlagen.
- Außerhalb eines Kampfes existiert kein persistierter Turn-Zähler in diesem Modul. Die Bestätigung zur freien Turn-Slot-Grenze muss bei der Vorbereitung separat erfolgen und der Nicht-Kampfstatus beim Abschluss erneut bestätigt werden. Es wird keine unbekannte Zeitfolge geraten.
- Der externe Effektbestätigungswert ist **kein Effekt- oder Quellenprüfer**. Nur die zuständige verifizierte Zaubereffekt-Engine darf ihn setzen.

**Kompatibilität:** Kein bestehendes Verhalten des Legacy-`GameEngine` oder `SrdSpellPreflightRules.preflight` wird durch dieses neue, nur explizit aufrufbare Modul verändert. Es gibt weder eine Änderung des SQLite-/JSON-Schemas noch einen Versionswechsel. Eine spätere Integration in GameController/Repository benötigt einen koordinierten Integrations-PR und eigene Revisions-/Rollback-/Neustart-Tests.

## Tests / Abnahme

`app/test/srd_spell_turn_transaction_rules_test.dart` enthält **9 Testgruppen** zu Aktion+Slot, Bonusaktion+Slot, verbrauchter Aktion/Bonusaktion/Slot/Action Surge, Zaubertrick ohne zweiten Slot, unbestätigtem Effekt und Handlung, stale Hero-/Encounter-Belegen und JSON-Roundtrip, Nicht-Kampf-Zuggrenze, nicht erlaubten Triggern sowie neuer Konzentration nur im gestagten Hero.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_turn_transaction_rules_test.dart
flutter test
flutter build apk --debug
```

**Status:** Das Regel-Staging ist implementiert, die Tests wurden geschrieben. Als `tested` gilt erst die spezifisch erfolgreiche finale CI auf dem letzten Branch-Commit. Vollständige Zauberwirkungen, atomare Persistenz, Realgerät und eine automatisch aktivierte Legacy-Integration sind weiterhin **nicht implementiert**.

# SRD 5.2.1 – Vorbereitungstausch nach Rast oder Klassenaufstieg

**Chat A · 01.11.2026 · Basis-main** `5a88834c98f5aca40395088c20c7e1dc5b587868` ·
**Branch** `feat/chat-a/prepared-spell-exchange-triggers-20261101`.

## Offizielle Regelquelle

Wizards of the Coast LLC, *System Reference Document 5.2.1*,
**Spells → Preparing Spells → Spell Preparation by Class**, gedruckte
Seite **104**, [offizielle SRD-PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
[SRD-Einstieg](https://www.dndbeyond.com/srd), **Creative Commons CC BY 4.0**.

**Bestätigte Auslöser und Höchstzahl von Austauschvorgängen:**

| Eigene Klasse | Auslöser | Ausgetauschte Zauber der Stufe 1+ |
|---|---|---|
| Barde, Zauberer, Hexenmeister | Stufenaufstieg **in dieser Klasse** | 1 |
| Paladin, Waldläufer | abgeschlossene lange Rast | 1 |
| Kleriker, Druide, Magier | abgeschlossene lange Rast | beliebig viele, begrenzt durch die bestehende Liste |

Diese Tabelle betrifft **nur den Austausch bestehender vorbereiteter Zauber**,
nicht zusätzliche Zauber, die man durch einen Stufenaufstieg neu vorbereiten
darf. **Zaubertricks** folgen separaten Klassenregeln. Immer vorbereitete
Zauber aus Talenten/Unterklassen werden hier weder gezählt noch entfernt.

## Umsetzung und Akzeptanz

Neues, isoliertes `SrdSpellPreparationExchangeRules.preview` in
`app/lib/domain/srd_spell_preparation_exchange_rules.dart`.

- Reine lesende Prüfung mit `before`/`after`-Charakter,
  expliziter Spielerentscheidung, Trigger und Klasse;
  sie **bucht selbst weder Rast noch Stufe, Ressourcen, Zauber noch Event**.
- Verwendet den vorhandenen `findSrdClass`-Resolver und die
  klassenbezogene Zaubergradprüfung. Die offizielle Zauberklassenliste,
  Zaubergrad 1+ und bereits im eigenen jeweiligen `hero.spells`
  bestätigte Namen müssen auf **beiden Seiten** erfüllt sein.
  Für diese isolierte Teil-API sind nur amtliche **englische Katalognamen**
  zulässig; deutsche Altnamen werden nicht geraten oder überschrieben.
- Stufenereignis: Gesamtstufe exakt +1, Klassenstufe **nur in der
  ausgewählten eigenen Klasse** exakt +1; alle anderen bleiben gleich.
  Long-Rest-Ereignis: gleiche Klassen und Stufen plus separate ausdrückliche
  Bestätigung einer tatsächlich beendeten langen Rast.
  Neue Zweitklassen sowie nicht bestätigte Historie werden nicht erfunden.
- Ein Austausch ersetzt genau die gleiche Zahl bekannter Zauber:
  kein Nur-Umsortieren, keine Duplikate, keine Stufen-0-Zauber,
  keine zusätzliche Vorbereitung oder falsche Klassenberechtigung.
  Bei Barde/Zauberer/Hexenmeister/Paladin/Waldläufer genau ein
  Austausch; bei Kleriker/Druide/Magier mehrere möglich.
- Für **Magier** ist ein unabhängiger expliziter Nachweis gefordert,
  dass neu vorbereitete Zauber im eigenen Zauberbuch zugänglich sind.
  Es gibt in diesem Modul **keine** vorgetäuschte Zauberbuch-Datenquelle.
- Das zurückgegebene `SrdSpellPreparationExchangePlan` ist
  unveränderlich und enthält JSON-Snapshots der beiden
  Charakterstände. `verifyUnchanged` verhindert die versehentliche
  Übernahme nach einer Änderung; Snapshots sind **keine Signatur**.

## Regressionen

`app/test/srd_spell_preparation_exchange_rules_test.dart` enthält
elf positive/negative Testgruppen: alle acht Klassen und gegenteilige
Trigger, deutsche/englische Aliasnamen, Mehrfach- oder Einzelaustausch,
nicht bestätigte lange Rast und fehlendes Zauberbuch, unbekannte
Zauber und illegale Zaubergrade, Stufe 0, falsche/duplizierte
Klassen, Mehrklassen-Stufenaufstieg in die falsche Klasse,
unveränderte JSON-Snapshots und echte SQLite-Neustarts samt
idempotentem Retry und verweigertem veralteten Schreibstand.

Tatsächlichen CI-Teststatus nur nach dem finalen GitHub-Actions-Lauf
als erfolgreich dokumentieren.

## Grenzen und Integrationskoordination

**Kein Datenmodell-/DB-Upgrade:** `HeroCharacter`, Controller,
`GameEngine`, Repository, Spell Preflight und deren offenen
PR-Dateien bleiben unverändert; SQLite3, äußeres JSON1 und
App-Version bleiben erhalten. Die Belege zur persistierten
Klassenzuordnung aus [PR #463](https://github.com/ManuEtt/Dnd/pull/463)
und zur mehrdeutigen Freigabe aus
[PR #461](https://github.com/ManuEtt/Dnd/pull/461) sind **noch nicht**
in diesem Stand enthalten. Ihre Integration muss konfliktbewusst,
mit Speicher-/Rollback-Tests erfolgen.

**Nicht implementiert:** vollständige Tabellenzahl täglich
vorbereitbarer Zauber, klassenbasierte Zusatzzauber,
automatische Zauberbuchprüfung, Ritual-/Cantrip-Wechsel,
UI für Rast-/Level-up-Auswahl, Zustandstransaktion oder
Rückgabe neu vorbereiteter Zauber in der echten Engine.
Die SRD-Anforderungsmatrix ist weiterhin nur ein
Teilaudit und keine Fertigstellungsquote.

**Nächster unabhängiger Chat-A-Schritt:** Nach der koordinierten
Integration von PR #461 und #463 die unveränderlichen
Klassennachweise im echten Zauberpreflight verwenden und die
klassenspezifischen Tauschregeln mit dem bestätigten Rast-/
Level-up-Ereignis verbinden; insbesondere SQLite-/Revisions-
Rollback und Manipulationsfälle absichern.

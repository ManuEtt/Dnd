# Chat A – Distant Spell bei Berührungszaubern (SRD 5.2.1)

**Stand:** 02.11.2026 · **Basis-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`
· **Branch:** `feat/chat-a/distant-touch-metamagic-20261102`.

## Quelle und Problem

Wizards of the Coast LLC, *System Reference Document 5.2.1*,
**Sorcerer / Metamagic / Distant Spell** (CC BY 4.0),
[SRD auf D&D Beyond](https://www.dndbeyond.com/srd).
Distant Spell ist eine wählbare Metamagieoption ab Zaubererklasse Stufe 2,
kostet **1 Sorcery Point** und ändert die Reichweite eines
**Touch**-Zaubers auf **30 feet**. Das ist keine allgemeine
30-Fuß-Berührungsfähigkeit jeder Zauberklasse.

Der bisherige Rasterpfad [PR #472](https://github.com/ManuEtt/Dnd/pull/472)
darf keine scheinbar manuell bestätigten, tatsächlich fernen Berührungen
durchwinken. Eine echte SRD-Ausnahme benötigt eine getrennte, nachvollziehbare
Klassen-/Ressourcenprüfung, statt die konservative
Standardberührungsprüfung aufzuweichen.

## Implementiert und abgegrenzt

`app/lib/domain/srd_distant_touch_metamagic_rules.dart` führt
`SrdDistantTouchMetamagicRules.preview` und
`SrdDistantTouchPlan` als **separaten Domainvertrag** ein.

- Bestätigte eigene Klassenidentitäten und individuell zugeordnete Stufen:
  Zauberer/Sorcerer **mindestens Stufe 2**, auch als eigene Zweitklasse.
  Der vorhandene Klassen-Freischaltungskatalog muss `Metamagic`
  auf dieser Stufe bestätigen. Freie `hero.features`-Texte verleihen
  **keine** Metamagie.
- Eine tatsächliche Wahl von `Distant Spell`, die Vorbereitung/
  Zugehörigkeit zu einer tatsächlich eigenen Klasse, bestätigte Zielregeln
  und erlaubte Kombination anderer Metamagie müssen **jeweils gesondert**
  bestätigt sein. **Wichtig:** Der bestehende Charakter hat noch keinen
  dauerhaft versionierten Metamagie-Auswahlnachweis. Die Boolbestätigung
  ist ausdrücklich **keine** nachträgliche Rekonstruktion und kein
  manipulationssicherer Beleg; eine Integration muss sie durch
  eine dauerhaft bestätigte Auswahl ersetzen.
- Zauber werden nur über den bestehenden unveränderten
  SRD-5.2.1-Katalog gefunden, mit exaktem englischem Namen
  aus der eigenen `hero.spells`-Liste,
  `range == 'Touch'`, passender eigener Casting-Class,
  Klasse im SRD-Katalog und maximal vorbereitbarem
  Zaubergrad **dieser Klasse**, nicht bloß gemeinsamer Slotstufe.
  Talent-/Unterklassen-Zauber sind nicht pauschal freigegeben.
- Der vorhandene 5-Fuß-Rastervertrag liefert
  `SrdSpellGridMap` mit explizit bestätigter vollständiger
  Hindernisaufnahme. Ein freier Mittelpunktstrahl ist Pflicht;
  für **0–30 Fuß** ist die Vorschau möglich,
  für mehr als 30 Fuß oder unbekannte/blockierte Kartendaten nicht.
  Die Prüfung ist konservativ: ein blockierter Mittelpunktstrahl
  gilt nur hier als Ablehnung, **nicht** als allgemeiner Nachweis
  vollständiger Deckung in einer 3D-Welt.
- Bereits ausgegebene Klassenressourcen werden über
  `ClassResourceRules.remaining` gegen den tatsächlichen
  Zaubererpool kontrolliert; mindestens **ein** Punkt muss frei sein.
  Charakter mit unbestätigten TP, 0 TP oder Tod wird abgelehnt.
- Der schreibfreie Plan hält ein genaues
  `HeroCharacter.toJson()`-Snapshot, geprüfte Klasse,
  Zauber, Entfernung und Kosten fest.
  `verifyUnchanged` verweigert alte/umgeschriebene Zustände.
  `stageSorceryPointCost` erstellt **nur eine neue
  Heldenkopie**, wenn die übrigen Kosten und der Effekt separat
  ausdrücklich bestätigt wurden. Der alte Charakter bleibt
  unverändert, eine spätere zweite Ausgabe auf einer veralteten
  Ausgangskopie wird durch Snapshotprüfung abgewiesen.

## Verbindliche Integrationsgrenzen

Diese beiden neuen Domain-/Testdateien **ändern nicht**
`srd_spell_grid_target_rules.dart` aus PR #472,
`srd_spell_preflight_rules.dart` aus PR #461,
`models.dart` aus PR #463 oder Engine/Controller/Repository.
Der Plan wird ausdrücklich **noch nicht** in den echten
Zauberablauf integriert. Er ersetzt daher nicht
Ziel-/Zauberwirkungs-, Komponenten-, Slot-, Aktionsökonomie-,
Konzentrations- oder Ressourcenprüfungen.

Insbesondere dürfen die staged Zaubereipunkte **nicht allein
persistiert** werden. Sie müssen gemeinsam mit der bestätigten
Zauberauflösung und allen übrigen Kosten in **einer**
revisiongeschützten SQLite-Transaktion eingehen.
Ohne versionierte Metamagiewahl und koordinierte Integration
darf keine Anwendung den isolierten Plan als automatisierte
Zauberfreigabe benutzen. Eine wiederholte Vorschau kostet
nie Zaubereipunkte. Speichern und veraltete Revisionen werden
im Test nur als Repository-Vertragsprüfung simuliert,
nicht als vollendete Zaubertransaktion.

**Kompatibilität:** SQLite-Schema 3, äußeres JSON 1,
Character-`schemaVersion:1`, App-Version und Altspielstände
unverändert. Keine Fremdbranches/PRs bearbeitet.
Gemeinsame README-/Checkpoint-Zeilen dürfen erst bei
Integration durch Chat D konfliktfrei konsolidiert werden.

## Regressionen

`app/test/srd_distant_touch_metamagic_rules_test.dart`
enthält **zehn** deterministische Testgruppen:
positive Reichweite 0–30 Fuß; 35+ Fuß abgelehnt;
quellgebundene Klasse Stufe 2 vs. Stufe 1;
Mehrklassenquelle/Zauberquelle getrennt;
nicht ausgewählte Metamagie oder unbestätigte Ziel-/Klassenzuordnung;
falscher Zauber/Grad/Entfernung;
ausgegebene oder manipulierte Ressourcen/TP;
unbekannte, blockierte und außerhalb der Karte liegende
Rasterwege; unveränderte Hero-JSON-Snapshots;
echter SQLite-Neustart, idempotenter Retry und
abgewiesene veraltete Schreibrevision.

**Testergebnis:** nur dem finalen CI-Kommentar des zugehörigen
Pull Requests entnehmen, bis auf endgültigem Commit nachgewiesen.

**Nächster Schritt:** nach koordiniertem Merge von PR #461/#463/#472
einen persistierten, quellbestätigten Metamagie-Auswahlnachweis
implementieren und dann Touch-30-Fuß plus Sorcery Point und Slot
in einer einzigen revisionsgeschützten Cast-Transaktion testen.

# Chat A – versionierte Auswahl von Metamagie (SRD 5.2.1)

**Datum:** 02.11.2026 · **Ausgangs-main:** `885580202caeafc9787538b6dc1c833b3190a529` ·
**Branch:** `feat/chat-a/metamagic-choice-proof-20261102`.

## Regelquelle und Anforderung

Wizards of the Coast, **System Reference Document 5.2.1**,
*Sorcerer → Level 2: Metamagic → Metamagic Options*, CC BY 4.0,
https://www.dndbeyond.com/srd.

Eine Zaubererklasse/Sorcerer erhält auf **Klassenstufe 2 genau zwei**
Metamagieoptionen. Auf **Stufe 10** kommen zwei weitere dazu
(insgesamt vier), auf **Stufe 17** nochmals zwei (insgesamt sechs).
Bei jedem Aufstieg **in der Zaubererklasse** darf **höchstens eine**
bereits bekannte Option gegen eine bislang nicht bekannte ausgetauscht werden.
Ein Aufstieg in einer anderen Klasse verändert diese Auswahl nicht.
Optionen entstehen niemals aus einer KI-Erzählung oder der bloßen
Freischaltung des Klassenmerkmals.

## Implementiertes, konfliktfreies Domainpaket

Die isolierte neue Fachdatei
`app/lib/domain/srd_metamagic_choice_record.dart`
stellt `SrdMetamagicChoiceRecord` und
`SrdMetamagicChoiceRules` bereit:

- `confirm`: explizit bestätigte Auswahl, mit nachgewiesener
  echter Zaubererklasse, tatsächlicher Zauberer-Klassenstufe 2–20,
  SRD-Katalogfreischaltung und **exakt** 2/4/6 verschiedenen
  kanonischen SRD-Optionen. Keine falschen Namen,
  fremden Klassen, Doppelklassen-Aliase oder negativen Stufen.
- `advanceSorcererLevel`: genau **eine** bestätigte weitere
  Zaubererklasse-Stufe und genau eine Gesamtstufe; keine
  Änderung an den anderen Klassen. Bei normalen Aufstiegen
  bleiben die Anzahl der Optionen gleich und höchstens eine
  frühere Option darf getauscht werden. Beim Übergang auf 10
  und 17 sind **zwei zusätzliche** neue Optionen plus
  optional höchstens ein Austausch erlaubt.
- Die offiziellen SRD-Optionen sind
  `Careful Spell`, `Distant Spell`, `Empowered Spell`,
  `Extended Spell`, `Heightened Spell`,
  `Quickened Spell`, `Seeking Spell`, `Subtle Spell`,
  `Transmuted Spell`, `Twinned Spell`.
  Die Liste behauptet ausdrücklich **nicht**, alle zehn
  Optionen bereits als Spielfunktion zu simulieren.
- Ein unveränderliches Choice-Objekt trägt
  `schemaVersion:1`, die **rohen** beiden Klassenetiketten,
  den bestätigten Zaubererlevel sowie die explizite
  Optionsliste. `toJson/fromJson` prüft das
  **streng versionierte Datenformat**: keine fremden
  Felder, unbestätigten Optionen, doppelten Werte,
  falsche Auswahlzahl, unbekannten Klassen oder
  typfalschen Schemawerte.
- `matchesHero` prüft die **genaue Rohklassenidentität**
  und den persönlichen Zaubererlevel. Ein Trefferpunkte-/
  Ressourcenwechsel oder ein Aufstieg in einer
  **anderen** Klasse macht eine echte Metamagiewahl
  nicht ungültig. Änderungen der eigenen Zaubererklasse
  oder -stufe machen den Beleg ungültig, bis eine
  entsprechende neue Wahl bestätigt wurde.

## Sicherheit und Speichergrenzen

**Kein neues Feld in `HeroCharacter` und keine neue Migration.**
Der `SrdMetamagicChoiceRecord` ist nur ein **separates,
deterministisches JSON-Artefakt**, nicht bereits Teil der
bestehenden Kampagnen- oder Heldenpersistenz. Insbesondere
ist `fromJson` allein **kein** vertrauenswürdiger Nachweis
eines autorisierten Spielers – jedes manipulierbare JSON
muss später zusammen mit dem richtigen,
authentisierten Spielzustand und einem unabhängigen
bestätigten Auswahlereignis verifiziert werden.
`matchesHero` ersetzt nicht diese Bestätigung.
Der bestehende PR #478 zu `Distant Spell` kann
später mit diesem Auswahlbeleg verbunden werden,
wird hier aber bewusst nicht verändert.

Weder `models.dart` aus PR #463 noch
`srd_spell_preflight_rules.dart` aus #461,
`srd_spell_grid_target_rules.dart` aus #472
noch UI, Engine, Story, Controller oder Repository
werden verändert. Keine Ressourcenbuchung,
keine automatische Wirkung, keine SRD-
Fertigstellungsbehauptung.

**Kompatibilität:** SQLite-Schema **3**,
äußeres JSON **1**, Character-`schemaVersion 1`,
historische Kampagnen und App-Version unverändert.

## Regressionen und offene Integration

Neue Testdatei `app/test/srd_metamagic_choice_record_test.dart`:
zwölf deterministische Gruppen für Klassenstufen
1/2/9/10/16/17/20, kanonischen Optionenkatalog,
unbestätigte Wahl, Duplikate, falsche Namen,
eigenen Zweitklassenlevel, rohe Aliase,
immutable JSON-Roundtrip, manipulierte
Recordfelder, 1-Ersatz-/2-Zusatzregeln,
nicht erlaubte andere Klassenaufstiege,
stale Aufstiege, Legacy-Helden-JSON und
echten SQLite-Neustart mit Retry und
Stale-Revision. Diese Repositorytests zeigen
**nur**, dass ein **extern** gehaltener
Choice-Beleg nach dem Laden zu einem
Heldenstand passt – ausdrücklich **nicht**,
dass die SQLite-Datenbank den Beleg selbst
bereits speichert.

Vollständige CI- und APK-Ergebnisse
ausschließlich nach finalem GitHub-Actions-
Nachweis im PR dokumentieren.

**Nächster unabhängiger Schritt:** Nach
koordiniertem Merge von PR #463 und #478
diese versionierte Wahl als optionales
persistentes und von einer bestätigten
Spielerentscheidung gedecktes Heldenereignis
integrieren. Danach `Distant Spell` nur mit
einem gültigen gespeicherten Auswahlbeleg
freigeben und den kompletten Cast inklusive
Zauberplatz, Metamagiepunkt und Effekt
in einer einzigen SQLite-Revision buchen.

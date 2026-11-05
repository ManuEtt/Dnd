# Chat A – Berührungszauber: tatsächliche Rasterreichweite bestätigen

**Stand:** 02.11.2026 · **Ausgangs-`main`:**
`5a88834c98f5aca40395088c20c7e1dc5b587868`
· **Branch:** `fix/chat-a/grid-touch-range-20261102`.

## Regelquelle und Fehler

Wizards of the Coast LLC, *System Reference Document 5.2.1*,
**Spells → Casting Spells → Range: Touch**, CC BY 4.0,
https://www.dndbeyond.com/srd.
`Touch` erfordert tatsächliche Berührung einer Stelle **in Reichweite**,
nicht lediglich eine bestätigte Sichtlinie.

`SrdSpellGridTargetRules.factsFor` überprüfte bereits bekannte
Rasterkoordinaten und Hindernisse. Im Zweig `range == 'Touch'`
setzte es aber unabhängig von der Rasterentfernung einen
Berührungsmodus und gab die manuelle Bool-Bestätigung durch.
Damit konnte ein entferntes Ziel von z. B. 50 Fuß ohne
weitere Regelprüfung als berührbar gelten.

## Umsetzung

Im **konservativen aktuellen Standardmodus** werden nur die
eigene Zelle (0 Fuß) sowie acht angrenzende Zellen
(5 Fuß Chebyshev-Distanz) akzeptiert. Ein ausdrücklich
bestätigter Berührungsvorgang und eine vollständig
aufgenommene, blockierungsfreie Karte bleiben **weiterhin nötig**.
Bei bekannter Rasterdistanz über 5 Fuß wirft
`SrdSpellGridTargetRules.factsFor` vor der
Zaubervorprüfung eine `FormatException`; die
manuelle Berührungsbestätigung allein kann diese
geometrische Sperre nicht überschreiben.

**Scopegrenze:** Die offizielle SRD formuliert
`within their reach`, nicht allgemein eine fixe
5-Fuß-Obergrenze. Ein später ausdrücklich **nachgewiesener
größerer Berührungsradius** (Spezialfähigkeit, Zauberwirkung
etc.) braucht deshalb einen eigenen versionierten
Reichweiten-/Reichweitenquellen-Nachweis. Dieser
bestehende Rasterpfad unterstützt ihn bislang nicht.
Es wäre falsch, ihn aus einem Boolwert abzuleiten.
Manuelle Geometriefakten anderer Pfade werden in
diesem Paket nicht umgedeutet.

## Tests und Kompatibilität

Neue deterministische Tests in
`app/test/srd_spell_grid_touch_range_test.dart`:

- Eigenes Feld und alle acht Nachbarfelder mit bestätigter
  Berührung akzeptieren.
- Entfernte Felder bei 10, 25 und 100 Fuß trotz
  `withinTouchReachConfirmed=true` abweisen.
- Nicht bestätigte Berührung, unvollständige Kartenaufnahme
  und Hindernisse weiterhin abweisen.
- Selbstausgang und Fernzauber unverändert.
- `SrdSpellPreflightRules.preflight` für
  **Wunden heilen** (Kleriker) im Fernfall abweisen,
  unveränderte TP/Slots/Helden-JSON prüfen,
  bestätigte Nachbarberührung akzeptieren.
- Historisches JSON unverändert lassen; echten
  SQLite-Neustart, reine lesende Fehlprüfung,
  idempotente Speicherung und stale Revision
  absichern.

**Nur** Fachdatei `srd_spell_grid_target_rules.dart`
und neue Testdatei. Weder `models.dart`,
`game_engine.dart`, Controller, Repository,
Story-/UI-Pfade noch andere offene PR-Fachdateien
werden geändert. SQLite-Schema **3**,
äußeres JSON **1** und App-Version unverändert.

Teststatus und tatsächliche GitHub-Actions-Ergebnisse
nur am endgültigen PR-Head als bestanden bewerten.
Keine automatische Ausführung von Zaubereffekten,
kein RNG und keine Buchung durch diesen reinen Zielprüfer.

## Nächster unabhängiger Schritt

Eine ausdrückliche, prüfbare Reichweitenquelle für
**außergewöhnlich vergrößerte Berührungsreichweite**
als eigene Regel-API modellieren und gegen den
bestehenden Rasterpfad mit positiven, manipulierten
und SQLite-/Revisionsfällen validieren, bevor der
Standardradius erweitert wird.

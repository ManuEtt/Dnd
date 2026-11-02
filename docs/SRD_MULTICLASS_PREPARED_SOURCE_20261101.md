# SRD 5.2.1 – Mehrklassen-Zaubervorbereitung eindeutig bestätigen

**Chat A, 01.11.2026** · Branch:
`feat/chat-a/multiclass-prepared-source-20261101` · Basis-Main:
`5a88834c98f5aca40395088c20c7e1dc5b587868`

## Regelquelle und Ausgangsproblem

Wizards of the Coast, *System Reference Document 5.2.1*,
*Multiclassing – Spellcasting – Spells Prepared*, gedruckte S. 25,
[SRD 5.2.1](https://www.dndbeyond.com/srd), **CC BY 4.0**.
Mehrklassencharaktere bestimmen vorbereitbare Zauber für jede
Klasse **getrennt**, anhand ihrer tatsächlichen Klassenstufe;
gemeinsame Zauberplätze sind kein Nachweis der Vorbereitung.

Das bestehende `HeroCharacter.spells` ist eine ungetypte, historisch
gespeicherte Gesamtliste. `SrdSpellPreflightRules.preflight` überprüft
bereits eigene Klassenstufe, offizielle Zauberklassen-Metadaten,
bekannte/vorbereitete Namen, Ressourcen, Komponenten und Ziel. Wenn
beide eigenen Klassen denselben Zauber auf ihrer Liste haben und die
Klassenstufen ausreichen, kann diese Liste jedoch **nicht** belegen,
welche Klasse den Zauber vorbereitet hat. Der frei übergebene
`castingClass`-Wert allein reicht in diesem Fall nicht.

## Änderung und Akzeptanz

`SrdSpellPreflightRules.preflight` akzeptiert einen weiteren
expliziten, standardmäßig negativen Nachweis
`preparedForCastingClassConfirmed`. Dieser ist **nur dann
erforderlich**, wenn der Charakter zwei unterschiedliche, bestätigte
eigene SRD-Zauberklassen hat, **beide** den Zauber auf ihrer
Klassenliste führen und **beide unabhängig nach ihrer eigenen
Klassenstufe** den betreffenden Zaubergrad vorbereiten können.

- Ohne diesen Nachweis: verständliche `FormatException` **vor**
  etwaiger Ressourcenbuchung und ohne Würfel, Event oder Mutation.
- Nach ausdrücklicher Zuordnung: bestehende Prüfungen und
  Snapshots bleiben weiterhin verpflichtend; die Bestätigung
  erzeugt **keine** vorbereiteten Zauber und keine Wirkung.
- Wenn nur eine eigene Klasse den Zauber nach Liste und
  Klassenstufe vorbereiten kann, bleibt die bereits vorhandene
  eindeutige Zuordnung ohne neue Abfrage zulässig.
- Ein falsch gewählter Klassenname, eine zu niedrige individuelle
  Klassenstufe oder ein nicht bestätigter Zauber wird auch mit
  `preparedForCastingClassConfirmed: true` zurückgewiesen.
- Zaubertricks sind ebenfalls klassenbezogen, verbrauchen aber
  weiterhin keinen Zauberplatz.
- Ein bestehender `SrdSpellCastPlan` ist an den ursprünglichen
  `HeroCharacter.toJson`-Snapshot gebunden; nach einer Änderung
  seiner Zauber, Klasse oder Ressourcen ist er nicht mehr gültig.

## Grenzen / Kompatibilität

**Kein Datenmigration:** SQLite-Schema 3, äußeres
Kampagnen-JSON 1, historisches `HeroCharacter.spells` und
bestehende deutsche Zaubernamen bleiben unverändert.
Keine UI- oder Controlleränderung, keine erfundenen Zauberlisten
oder KI-bestätigte Vorbereitungen.

Eine ausdrückliche boolesche Klassenbestätigung ist eine **aktuelle
Spielerentscheidung**, kein versionierter dauerhafter Nachweis
einzelner vorbereiteter Zauber pro Klasse. Vollständige
Klassenlisten, tägliche Vorbereitungsgrenzen, automatisch
gewählte Pflichtzauber, Gradfreischaltungen durch Talente,
Unterklassen und Spezies sowie die mehrstufige
Aktions-/Persistenzintegration bleiben eigenständige Aufgaben.

Die Arbeitsregister-ID
`RULE-CHARACTER-CREATION-MULTICLASS-SPELLCASTING`
bleibt **unverified** im Basisaudit, bis weitere Klassen- und
Ressourcenwirkungen quellengeprüft sind. Ein erfolgreiches
Teilinrement belegt keine vollständige SRD-Umsetzung.

## Prüffälle

`app/test/srd_multiclass_prepared_source_test.dart` testet acht
deterministische Fälle: beide passenden Klassen ohne/mit
Bestätigung, falsche Stufe, unzweideutige Klassenlisten,
Zaubertrick, Einzelklasse, JSON-Neustart und echte
SQLite-Rekonstruktion ohne stille neue Vorbereitung.
Bestehende Zauber-/Material- und Snapshot-Regressionen laufen
zusätzlich in der vollständigen CI. Tests nur anhand ihrer
tatsächlichen GitHub-Actions-Ergebnisse als erfolgreich melden.

**Koordination:** Fachcode und neuer Test überschneiden sich nicht
mit den offen geprüften PRs #446–#458. Der alternative Chat-A-PR #448
bearbeitet den isolierten Turn-Transaktionshelfer und darf nicht
ungeprüft mit dieser Vorprüfung zusammengeführt werden.
README und zentraler Checkpoint sind gemeinsam bearbeitete
Dokumentation; Chat D soll sie bei Integration additiv konsolidieren.

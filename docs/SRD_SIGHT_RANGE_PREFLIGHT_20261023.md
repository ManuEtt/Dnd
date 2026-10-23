# SRD 5.2.1 – Reichweite „Sight“ als abgesicherte Vorprüfung

**Würfelraunen 0.8.35+85 · 23.10.2026 · CI-Abnahme ausstehend**

## Quelle und fachlicher Rahmen

Amtliche [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0,
Kapitel *Spells*: *Spell Range*, *Spell Targets*, *Clear Path to the Target*.
Der erfasste SRD-Zauberkatalog enthält als konkrete `Sight`-Angabe
**Mirage Arcane** (10 Minuten Wirkzeit). `Sending` besitzt dagegen
`Unlimited`, `Dream` die Reichweite `Special`; die zwei letztgenannten
Sonderfälle erfordern eigene Zauberregeln.

## Eingeführte Vorprüfung

- `SrdSpellTargetFacts.visibleOriginConfirmed` kennzeichnet eine **vom
  Nutzer ausdrücklich bestätigte** Sichtverbindung; Vorgabe `false`.
- `SrdSpellGridTargetRequest.originVisibleConfirmed` transportiert
  dieselbe separate Bestätigung vom verifizierten Kartenraster zur
  Regelprüfung, ebenfalls standardmäßig `false`.
- Für `Sight` sind eine räumlich entfernte Ursprungsart, die ausdrücklich
  bestätigte Sicht und ein bestätigter freier Weg gemeinsam erforderlich.
  Die Entfernung wird nur als nachgewiesener Wert gespeichert, ohne eine
  erfundene numerische Obergrenze.
- Ein unvollständig aufgenommenes Raster, ein Vollhindernis oder eine bloße
  klare Linie **ohne** Sichtbestätigung reicht nicht aus.
- `Unlimited` und `Special` lösen weiter `UnsupportedError` aus.
  Keine automatische Zielberechtigung, Treffer-/Schadensberechnung,
  Wirkungsfreigabe, Slotabbuchung oder KI-Regelentscheidung wird eingeführt.
- Der Katalogeintrag `Mirage Arcane` bleibt wegen seiner 10-minütigen
  Zauberzeit von der bestehenden Single-Turn-Preflight gesperrt. Diese
  Änderung **führt den Zauber nicht aus**.

## Regressionstests

- `app/test/srd_spell_target_rules_test.dart`: alle 339 katalogisierten
  Reichweiten weiterhin klassifiziert, `Sight` nur bei bestätigten
  Fakten zulässig; unverifizierte Sicht/Deckung, negative Entfernungen
  und falsche Ursprungstypen abgewiesen.
- `app/test/srd_spell_grid_target_rules_test.dart`: bestätigtes
  Raster und separat bestätigte Sicht müssen vorliegen; Mauern und
  unvollständige Blocker-Erfassung verhindern die Freigabe.

```bash
cd app
flutter test test/srd_spell_target_rules_test.dart
flutter test test/srd_spell_grid_target_rules_test.dart
flutter analyze
flutter test
flutter build apk --debug
```

Gesamte GitHub-Android-CI und die Android-Geräteabnahme bleiben separat
zu prüfen. Status bleibt **partial** im maschinenlesbaren SRD-Register.
SQLite-Schema 2 und Spielstands-JSON-`schemaVersion=1` bleiben unverändert.

# SRD 5.2.1 – Zauberindex und sichere Vorprüfung (Zwischenstand)

**Regelquelle:** [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0. Aktuell verwendetes Namen- und Metadatentranskript: [omni-5e, Spells](https://github.com/azemoning/omni-5e/blob/main/data/raw/5.2.1/spells.md); vollständige Kontrolle jedes Textes mit dem amtlichen SRD steht noch aus.

## Dieser Entwicklungsschritt

- `app/assets/srd_5_2_1_spells.json` erfasst **339** unterschiedliche Zauber (Grad 0–9), Schule, Klassenliste, Zauberzeit, Reichweite, verbale/gestische/materielle Komponenten, Wirkungsdauer, Konzentrationskennzeichen und Ritualkennzeichen. Enthält die Provenienz und die Kennzeichnung `official_full_reconciliation_complete=false`.
- `SrdSpellCatalog` validiert alle Daten beim Einlesen, lehnt Dubletten und widersprüchliche Komponenten-/Dauerangaben ab; `SrdSpellCatalogLoader` lädt das JSON als Flutter-Asset, ohne die Domänenklasse an Flutter zu binden.
- `SrdSpellPreflightRules` prüft einen *im Charakter bestätigten Zauber*: eigene Klasse (auch Mehrklassen), klassenspezifische Lernstufe statt bloßer verfügbarer hoher Plätze, Zauber- und Paktplätze, Stufe 0, Ziel- und Komponentenbestätigung, explizit bestätigte Aktion und die im aktuellen Zug erlaubte Platzanzahl.
- Die Vorprüfung verändert **keinen** Spielzustand. Erst `recordConfirmedResourceUse` verbucht Ressourcen und gegebenenfalls Konzentration, nachdem eine separate, regelgeprüfte Effektauflösung ausdrücklich bestätigt wurde. Ein JSON-Snapshot schützt gegen veraltete Vorprüfungen. Ein gebuchter Zauber ist **kein** automatisch berechneter Zaubereffekt.

### Sicherheitsgrenzen

Generische **Reaktionen, ausgelöste Bonusaktionen und mehrzügige Zauberzeiten** werden abgewiesen, bis ein eigener Trigger-/Aktionsablauf existiert. Ein Ritual-Tag ist **keine** Erlaubnis, kostenlos zu zaubern: Es ist nur die normale *Action*-Variante für `Action or Ritual` wählbar. Materialbestätigung umfasst Verfügbarkeit und eventuellen Verbrauch; die Engine berechnet derzeit keine Materialkosten. Für die manuelle Platzbuchung muss das externe Ziel-/Effektregelwerk weiterhin explizit bestätigt werden.

Die bisherigen spezialisierten Heil-, Schild- und Magisches-Geschoss-Regelpfade werden **nicht ersetzt oder still umgestellt**. Die bisherige Freitexteingabe wird aus Kompatibilitätsgründen noch nicht automatisch zu einer autoritativen SRD-Zauberbibliothek. Deutsche Aliasnamen werden nur für die bereits projektseitig eindeutig definierten fünf Zauber berücksichtigt.

## Technische Abnahme

```bash
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_catalog_preflight_test.dart
flutter test
flutter build apk --debug
```

Neue Tests: 339 Einträge, doppelte/ungültige Metadaten, bestätigte Klassen- und Stufengrenzen, Material-/Zielprüfung, kein Verbrauch bei fehlender Wirkungsbestätigung, Konzentration, Paktmagie und Ablehnung unerledigter Reaktions-/Langzeitfälle.

**Weitere Reihenfolge:** offizieller Vollabgleich aller 339 Einträge; echte Ziele/AoE/Positionsdaten, Komponentenverbrauch, Aktionstracking, Interruption/Reactions und Wirkungsmodule; danach komplette Klassenfähigkeiten 1–20, Monsterstatblocks und die übrigen SRD-Regeln. Keine Behauptung einer fertig implementierten Zauberengine.

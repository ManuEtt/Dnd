# SRD 5.2.1 – Materialkomponenten: prüfbare Teilimplementierung

Stand: 21.10.2026. **Regelquelle:** [D&D System Reference Document 5.2.1](https://www.dndbeyond.com/srd), *Spells → Casting Spells → Components*, CC BY 4.0, Wizards of the Coast LLC. Zauber-Metadaten aus dem im Asset deklarierten, **noch nicht vollständig amtlich abgeglichenen** Transkript. Keine vollständige SRD-Konformitätsbehauptung.

## Regelentscheidungen (ohne Story-Abhängigkeit)

- `SrdSpellComponentRules.requirements` liest nur die Materialzeile des katalogisierten Zaubers. Erfasst explizit aufgeführte Geldwerte (z. B. „50+ GP“, „1 Copper Piece“) und verbrauchbare Materialien („consumes“). Nicht zuverlässig lesbare Materialzeilen werden abgewiesen.
- `SrdSpellMaterialSource` trennt tatsächlich bereitgestellte Originalmaterialien von Komponentenbeutel und Zauberfokus. Ersatz durch Beutel/Fokus ist **nur zulässig**, wenn **kein angegebener Preis und kein Verbrauch** vorliegt. Für den Fokus ist eine separat bestätigte Berechtigung nötig.
- `SrdSpellPreflightRules.preflight` prüft weiterhin die bereits bestätigten V-/S-/M-Voraussetzungen; bei teuren Originalkomponenten müssen deren Verfügbarkeit und bei Verbrauch die reservierten Einheiten zusätzlich ausdrücklich bestätigt werden. Der Plan ist unveränderlich und enthält nur einen Hinweis, **ob** ein Materialverbrauch nachgewiesen werden muss.
- `recordConfirmedResourceUse` lässt bei verbrauchbaren Materialien die Verbuchung des Zauberplatzes nur nach Bestätigung zu, dass die Komponenten **außerhalb dieser Teilengine regelgerecht verbraucht** wurden. Der bestehende Charakter-Snapshot verhindert weiterhin das Wiederverwenden veralteter Freigaben.

## Grenzen und bekannte Restarbeiten

**Noch nicht implementiert:** Inventartransaktionen, Abzug konkreter Materialien und Geldwerte, Gleichzeitigkeit/Reservierung über Spielstände, genaue Auswertung komplexer Mischkomponenten, automatisches Hand-/Fokus-Ausrüstungs- und Klassenprivilegien-Tracking, Zauberwirkungsauflösung, Reichweiten-/Zielprüfung, Aktionsökonomie und vollständige amtliche Metadatenkontrolle. Bestätigungsflags sind **keine** selbständig gemessenen Belege aus dem Inventar. Diese Teilregel ist nur in der konservativen *Preflight-API* angebunden; bestehende spezialisierte Heil-/Shield-/Magic-Missile-Pfade bleiben unverändert.

Die vorhandene `materialComponentConfirmed`-Bestätigung bleibt für einfache Materialien kompatibel; für kostspielige oder verbrauchte Materialien reichen die alten Flags nicht mehr aus. Ein Ja zur regeltechnischen Materialprüfung ist nicht gleichbedeutend mit der automatischen Persistenz eines Materialabzugs.

## Eindeutige IDs und Tests

- `RULE-SPELLS-SPELL-COMPONENTS`: **partial** (vorhandene V/S-Bestätigungen, neue Materialquelle, fehlende automatische Hand-/Zustandskontrolle).
- `RULE-SPELLS-MATERIAL-COMPONENTS`: **partial** (Kosten-/Verbrauchserkennung, Fokus-/Beutelrestriktion, sichere Ressourcenbuchung; keine Inventarabwicklung).

Code: `app/lib/domain/srd_spell_component_rules.dart`, `app/lib/domain/srd_spell_preflight_rules.dart`; Test: `app/test/srd_spell_material_components_test.dart`.

Validierung vor Merge:

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_material_components_test.dart
flutter test test/srd_spell_catalog_preflight_test.dart
flutter test
flutter build apk --debug
```

**Abnahmestand:** Neuer Quellcode und Tests eingereicht. Ohne erfolgreichen CI-Lauf sind die Tests **noch nicht bestanden**. Android-Geräteabnahme offen. Der globale SRD-Gesamtfortschritt bleibt **nicht berechenbar**, siehe `docs/SRD_5_2_1_COVERAGE_AUDIT.md`.

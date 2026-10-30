# SRD 5.2.1 – separat bestätigte Mindestwerte von Zaubermaterialien

**Stand:** 30.10.2026 · **Quelle:** Wizards of the Coast LLC, [SRD 5.2.1](https://www.dndbeyond.com/srd), Kapitel `Spells / Casting Spells / Components`, CC BY 4.0.

## Umfang und genaue Regelgrenze

`SrdSpellMaterialValueRules` ergänzt die bereits geprüften vier Mehrkomponenten-Rezepte um eine **optionale, strengere** Einzelwertprüfung. Die verbrauchte oder behaltene Komponente muss anhand ihrer Katalog-Anforderungs-ID, konkreten Inventarstapel-ID, bestätigten Stückzahl sowie des **unabhängig bestätigten Wertes pro Einheit** zugeordnet werden. Ein selbst gesetzter Preis, Inventarname oder KI-Erzähltext ist kein Wertnachweis. Der Prüfer kann externe Nachweise nicht selbst authentifizieren: Die beiden unabhängigen Bestätigungsflags müssen von einer vertrauenswürdigen vorgeschalteten Regel-/Prüfinstanz gesetzt werden.

Für diese vier exakt auditieren Katalogtexte gelten die folgenden Mindestwerte (1 GM/GP = 100 Kupferstücke/CP):

| Zauber | Material-ID | Mindestwert pro Einheit | Verbrauch |
| --- | --- | ---: | --- |
| Astral Projection | astral-jacinth | 1.000 GP | pro Ziel 1 |
| Astral Projection | astral-silver-bar | 100 GP | pro Ziel 1 |
| Clone | clone-diamond | 1.000 GP | 1 |
| Clone | clone-vessel | 2.000 GP | keiner |
| Legend Lore | legend-incense | 250 GP | 1 |
| Legend Lore | legend-ivory-strips | 50 GP | keiner; 4 einzelne Streifen |
| Secret Chest | secret-large-chest | 5.000 GP | keiner |
| Secret Chest | secret-tiny-replica | 50 GP | keiner |

Der eigentliche Identitäts-, Stapel-, Anzahl- und Inventarverbrauchscheck erfolgt weiterhin in `SrdSpellAuditedInventoryRules.consumedQuantities`; eine beliebige Gesamtsumme aus billigen Einzelstücken ersetzt **nicht** die je Stück vorgeschriebenen Mindestwerte. Optional vorhandene `InventoryItemStats.priceCp` müssen mit dem unabhängig bestätigten Stückwert übereinstimmen, gelten aber **für sich genommen nicht** als Nachweis.

## API und Abnahme

- `SrdSpellMaterialValueRules.validatedConsumption`: rein lesender Preis-/Bindungs-Check für die vier ausdrücklich geprüften Rezepturen, ohne Ausführung einer Zauberwirkung.
- `SrdSpellMaterialValueRules.commitConfirmedCast`: führt erst den strengen Preis-/Bindungs-Check aus, danach den bestehenden atomaren Slot-/Material-Commit mit frisch erzeugtem `SrdSpellCastPlan`. Unbestätigte Effekte, fehlende Materialien und veraltete Pläne werden abgelehnt, statt Ressourcen teilweise zu verbrauchen.
- `app/test/srd_spell_material_value_rules_test.dart`: gültige und um 1 CP zu niedrige Werte beider Positionen aller vier Rezepte, Identitäts-/Preisbestätigung, unzulässige/zueinander falsche Belege, optionale Inventarpreis-Abweichungen, zielabhängige Mengen, unbekannte Rezepte, JSON-Roundtrip, erneute Bestätigung nach frischem Preflight, veraltete Pläne und unveränderte Ressourcen nach Ablehnung.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_material_value_rules_test.dart
flutter test
flutter build apk --debug
```

## Nicht implementiert und Kompatibilität

Die **bisherigen booleschen Legacy-APIs bleiben für vorhandene Aufrufer unverändert**. Es erfolgt **keine stillschweigende Migration** aller Zauberpfade auf den neuen strengen Wertbeleg: Vor einer Freigabe in Controller, UI, Story oder Regel-Fassade sind nachweisfähige externe Wertbestätigungen und ein koordinierter Integrations-/Persistenzschritt erforderlich. Der neue Baustein behauptet weder echte Provenienzprüfung noch vollständige SRD-5.2.1-Zauberabdeckung. Außerhalb der vier auditierten Rezepte wird nichts erfunden.

Keine SQLite-/JSON-/Event-Schema- oder Versionsänderung, kein Speichern oder Überschreiben historischer Werte, keine KI-Schlussfolgerungen über Materialidentität und keine echte Geräteabnahme. Anforderungsregister `RULE-SPELLS-MATERIAL-COMPONENTS` bleibt **partial**.

**CI-Status:** Bis die GitHub-Actions-Abnahme für den endgültigen PR-Commit erfolgreich vorliegt, dürfen Tests und Android-Build nicht als bestanden deklariert werden.

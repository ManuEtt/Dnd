# SRD 5.2.1 – Atomarer Inventarverbrauch für Zauber (Teilimplementierung)

**Stand:** 21.10.2026 · **Quelle:** [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), Kapitel `Spells / Casting Spells / Components`, CC BY 4.0.

## Neu: Regeltransaktion ohne Zwischenzustand

`SrdSpellInventoryRules.commitConfirmedCast` ergänzt den bestehenden, vorab geprüften `SrdSpellCastPlan`. Für Zauber mit im SRD-Katalog ausdrücklich als verbrauchbar gekennzeichnetem Material werden konkrete Inventarinstanzen und Stückzahlen angegeben. Die Engine validiert vor jeglicher Änderung:

1. Zauberwirkung extern durch eine *Regelimplementierung* aufgelöst (nicht durch KI-Prosa).
2. Identität und erforderliche Anzahl aller verbrauchten Materialien ausdrücklich bestätigt.
3. Material-ID einmalig und im Heldeninventar eindeutig, Stückzahl positiv und ausreichend.
4. Kein verbrauchter Gegenstand ist als Waffe, Schild oder Rüstung angelegt.
5. Der ursprüngliche Preflight ist nicht veraltet und der Zauberplatz ist noch verfügbar.

Erst dann erstellt die Engine **einen einzigen neuen, unveränderlichen** `HeroCharacter`, der Zauberplatzverbrauch und Materialabzug gemeinsam enthält. Aufgebrauchte Stapel verschwinden, Reststapel behalten ID, Katalogbezug und Metadaten. Der bisherige Charakter wird nicht verändert. Ein erneuter Commit mit derselben Vorprüfung wird durch die vorhandene Snapshot-Prüfung abgewiesen.

**Wichtig:** Dieser reine Domain-Übergang erzeugt noch **keine eigenständige SQLite-Transaktion oder Ereignis-ID**. Der Controller muss das zurückgegebene Charakter-/Kampagnensnapshot samt Audit-Ereignis weiterhin in einer einzigen bestehenden Repository-Transaktion persistieren. Die neue Funktion wird nicht ungeprüft aus Storytext ausgelöst.

## Grenzen / keine falschen Sicherheitsversprechen

- Der Abgleich des Inventargegenstands mit der *inhaltlich exakt erforderlichen* Materialbeschreibung, dem Wert (GP) und der Verbrauchsmenge erfolgt noch durch ausdrücklich bestätigte, externe Regellogik. Inventarnamen und Beschreibungen sind **keine vertrauenswürdigen Regelbelege**. Die Engine rechnet weder Diamantenpreise noch Rezepturen aus Freitext.
- Einzelne Zauberwirkungen (z. B. Wiederbelebung) werden durch dieses Modul **nicht** implementiert. Bei `Revivify` demonstrieren Tests ausschließlich den nach separat bestätigter Wirkung möglichen Ressourcen-/Material-Commit.
- Nicht verbrauchbare, aber kostspielige Komponenten werden weiterhin nur auf Verfügbarkeit geprüft und verbleiben unverändert im Inventar. Geldeinheiten, Ersatz-Fokus, Handbelegung und mehrstufige Ausführung benötigen weitere Regelimplementierungen.
- Noch keine UI-Steuerung für Materialauswahl, automatische Ziel-/Inventarabgleiche, persistiertes transaktionales End-to-End-Ereignis, Android-Gerätetest oder offizieller Komplettabgleich aller Katalogzeilen.

## Belege

- `app/lib/domain/srd_spell_inventory_rules.dart`
- `app/test/srd_spell_inventory_rules_test.dart`: erfolgreicher Teil-/Gesamtverbrauch, Slotverbrauch, JSON-Roundtrip, Stale Snapshot, fehlende/doppelte IDs, ungenügende Menge, ausgerüstete Gegenstände und Fehlerrücknahmen.
- `app/lib/rules/rules_api.dart` exportiert den Baustein ohne Story-Kopplung.
- SRD-Anforderung `RULE-SPELLS-MATERIAL-COMPONENTS` bleibt **partial** und nicht `tested`, bis die vollständige Materialsemantik und End-to-End-Integration abgenommen sind.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_inventory_rules_test.dart
flutter test
flutter build apk --debug
```

**CI-Status:** bis zum erfolgreichen Workflow für diesen Branch nicht als bestanden deklarieren.

# SRD 5.2.1 – Getypter Schaden, Resistenz, Anfälligkeit und Immunität

**Entwicklungsstand:** 0.6.5+35 (16.10.2026)

**Ausgangspunkt:** `ManuEtt/Dnd`, `main`, Commit `49c8c39af045c6d0e3a78eba23e95383c3c31a84`

**Quelle:** [D&D 2024 – Playing the Game / Damage and Healing](https://www.dndbeyond.com/sources/dnd/br-2024/playing-the-game), SRD 5.2.1 (CC BY 4.0).

## Regelanforderungen

- **DND-GRU-0096:** 13 Schadensarten als eigene Typen statt Freitext.
- **DND-GRU-0097:** Passende Resistenz halbiert die Schadenskomponente, Abrundung nach unten.
- **DND-GRU-0098:** Passende Anfälligkeit verdoppelt die Schadenskomponente.
- **DND-GRU-0099:** Passende Immunität verhindert die Schadenskomponente vollständig.
- **DND-GRU-0100:** Mehrere passende Resistenz-/Anfälligkeitsquellen wirken nur einmal. **Reihenfolge:** vorherige Schadensmodifikatoren → Resistenz → Anfälligkeit. Beispiel: 23 Feuer → 11 bei Resistenz → 22 mit zusätzlicher Anfälligkeit.

## Implementierung

- `app/lib/domain/damage_rules.dart`: `DamageType`, `DamageComponent`, `DamageDefenses`, `DamageRules.resolve`, `DamageResolution` mit Teilbeträgen und Gesamtbetrag. Ein gemischtes Schadenspaket wird nach Schadensart zerlegt und jede Komponente separat behandelt.
- `RulesEngine.damageWithDefenses(...)`: wendet das berechnete Ergebnis über die bisherige TP-/Todesregel an. Verteidigungsprofil und Schadensarten müssen **explizit bestätigt** sein. Diese API ersetzt die bisherige untypisierte `RulesEngine.damage(...)` nicht.
- `app/test/damage_rules_test.dart`: Fälle für alle Arten, Abrundung, fehlendes Stapeln, Reihenfolge, Immunität, gemischte Typen, Fehlerbehandlung und Integration in TP/Todesrettungen.

**Noch nicht implementiert:** Charakter- und Monster-Defensivprofile in UI/Savegame, automatische Übergabe aller Monster- und Zauberangriffe, Schadensmodifikationen durch Quellenmerkmale und vollständige Konzentrationsrettungen bei jeder Schadensquelle. Die Funktion kann diese Daten nicht erfinden. Die neue API ist somit eine getestete *fachliche Teilkomponente*, noch keine vollständig angeschlossene Kampfengine.

## Gleichzeitig behobene Fehler

1. Charakterbogen: Bewegungsanzeige zeigt `9 m` statt `9.0 m` und bewahrt `7.5 m` bei Erschöpfung. Der bisherige GitHub-Widgettest erwartete `9 m` und scheiterte wegen der Doppelwert-Formatierung.
2. Konzentrations-SG: `max(10, floor(Schaden/2))`, gedeckelt auf 30. Die bisherige obere Grenze fehlte. Siehe [SRD 5.2.1 Glossary / Concentration](https://www.dndbeyond.com/sources/dnd/br-2024/rules-glossary).

## Prüfstatus

- Python-Projekt- und Regressionstests lokal: **38/38 bestanden**.
- Flutter-SDK lokal nicht vorhanden: **Flutter Analyze, neue Dart-/Widgettests und Android-/APK-Build nicht ausgeführt**.
- GitHub-Branch/Push wurde nicht vorgenommen (Repository-Integration meldete HTTP 403 „Resource not accessible by integration“).
- Vollständiger CI-Lauf ist nach Übernahme auf einen Branch erforderlich.

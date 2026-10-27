# Chat A – SRD 5.2.1 Mönch „Sanfter Fall“ / Slow Fall

Stand 27.10.2026; Ausgangsbranch: `main` bei `07bd27db1c9141a4fa9482aab97c2be7c842e8c5`.

## Quelle und Status

- Offizielle D&D-SRD-5.2.1-Regel, Mönch **Stufe 4, Slow Fall**, [D&D Beyond SRD](https://www.dndbeyond.com/srd), Wizards of the Coast, CC BY 4.0.
- Der Mönch darf als **Reaktion beim Sturz** den durch den Sturz erlittenen Schaden um **5 × seine Mönch-Klassenstufe** reduzieren.
- Arbeitsmatrix `CLASS-M-NCH-4-BASE-SLOW-FALL-1` bleibt bewusst **partial**, bis die Reaktion atomar im Kampf-/Spielstand verbucht wird.

## Implementiert

- `app/lib/domain/srd_monk_slow_fall_rules.dart`: read-only Ermittlung der freigeschalteten Schadensreduktion aus **Klassenstufe**, inklusive korrekt bestätigter Zweitklasse. Reine Vorprüfung: Spielerentscheid, bestätigter Sturzschaden, Reaktionsverfügbarkeit und bestehender Kampf-Reaktionsverbrauch werden überprüft. Reduktion unter 0 wird ausgeschlossen. Lebenspunkte, Encounter, Würfe und Events werden nicht verändert.
- `app/lib/rules/rules_api.dart`: Export der Regel über die öffentliche Rule-Fassade.
- `app/lib/ui/fantasy_character_sheet.dart`: Nur freigeschaltete Mönche sehen unter Verteidigung den entsprechenden Höchstwert für „Sanfter Fall (Reaktion)“.
- `app/test/srd_monk_slow_fall_rules_test.dart`: Stufe 3 vs 4/5/10/20, mehrere Schadenshöhen, bestätigte Mehrklasse, fehlende Zustimmung/Würfelzahl, Reaktion bereits verbraucht, Handlungsunfähigkeit, JSON und keine Mutation.
- `app/test/srd_monk_slow_fall_sheet_test.dart`: 360px-Oberfläche und fehlende/verfügbare Freischaltung bei Haupt- und Zweitklasse.

## Grenzen / weiterer Integrationsschritt

- Keine automatische Würfelberechnung für einen vom KI-Spielleiter erwähnten Fall.
- Keine automatische Reaktionsbuchung oder TP-Schadensbuchung. Eine spätere `GameEngine`/`GameController`-Operation muss den aktuellen Event-/Revisionstand neu prüfen, Reaction und die **tatsächlich zugefügten** TP in *einer* Repository-Transaktion aktualisieren und Spielstandneustart/Race testen. Die derzeitige Funktion liefert ausschließlich einen prüfbaren Plan.
- Charakterlevel allein und das Vorhandensein eines Klassenkatalogeintrags verleihen den Effekt nicht.
- CI-Aussagen erst nach grüner GitHub-Prüfung auf dem letzten PR-Commit; APK-Build, signierte Veröffentlichung und echter Android-Gerätetest sind unterschiedliche Nachweise.

## Folgearbeit

Nach erfolgreicher CI und Review kann dieses Paket ohne Schemaänderung in `main` integriert werden. Für eine vollständige Slow-Fall-Automatik folgt ein *separater*, revisionssicherer Integrations-PR mit Reaktions- und HP-Commit.

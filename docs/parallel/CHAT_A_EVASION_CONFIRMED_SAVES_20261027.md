# Chat A: Entrinnen / Evasion für Mönche und Schurken (SRD 5.2.1)

Stand: 27. Oktober 2026. Ausgangspunkt: `main` bei `8239f5e71ec6b229a2a0883500adaf431bb70087`.

## Regel und Provenienz

Offizielles Wizards-of-the-Coast-[SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.pdf), CC BY 4.0, Monk 7 und Rogue 7: **Evasion / Entrinnen**. Ein Effekt, bei dem ein GE-Rettungswurf gewöhnlich die Hälfte des Schadens erlaubt, fügt beim erfolgreich bestätigten Rettungswurf stattdessen **0** Schaden zu und bei Misserfolg **die Hälfte**. Kein Vorteil bei der Bedingung **Handlungsunfähig**.

## Umfang

- `app/lib/domain/srd_evasion_rules.dart` exportiert den nur lesenden `SrdEvasionRules.previewConfirmedDexteritySave`.
- Klassenschwelle gilt für Mönch-/Schurke-**Klassenstufen** und legal bestätigte Mehrklassen, niemals bloß für Gesamtstufe. Eine doppelte Freischaltung stapelt nicht.
- Der Effekt und die Regel **GE-Rettungswurf gegen normalerweise halben Schaden** müssen ausdrücklich feststehen; die Wurfentscheidung, die **unhalbierte** Schadenssumme sowie die Bestätigung ihrer Quelle müssen vorliegen.
- Positiver Rettungswurf: 0 Schaden; negativer Rettungswurf: abgerundete Hälfte (z. B. 23 → 11). Unbekannte Werte, ungültige Zahlen, Handlungsunfähigkeit und 0 oder unbekannte TP werden **abgewiesen**; keine automatische Figurmutation.
- `app/lib/rules/rules_api.dart`: SRD-Regelfassade. `app/lib/ui/fantasy_character_sheet.dart`: erklärende Fähigkeit im Verteidigungsabschnitt ab jeweiliger Stufe 7.
- Automationskatalog und die beiden IDs `CLASS-M-NCH-7-BASE-EVASION-0` und `CLASS-SCHURKE-7-BASE-EVASION-0` auf **partial** statt „vollautomatisch“ gesetzt.
- `app/test/srd_evasion_rules_test.dart` deckt Regelgrenzen, Fail-Closed-Verhalten, Multiclassing, Wurfkonstellationen, JSON und Katalog ab. `app/test/srd_evasion_sheet_test.dart` deckt schmale Android-Ansicht und Freischaltung ab.

## Bewusste Grenzen

- Diese PR **verbucht keine** HP, Reaktionen, Flächenschaden, Zauberziele oder Konzentrationsfolgen; sie nimmt keine Würfe und deduziert keinen Schaden aus Erzählungen. Für echten Spielstand-Commit sind eine bestätigte Schadensquelle, Saveresultat, ggf. Schadenskomponenten, andere Schadensmodifikatoren sowie Revision/SQLite-Transaktion nötig.
- Die 0-/Halbschaden-Entscheidung darf nicht automatisch auf Zauber mit anderer Rettungswurf-Folge angewandt werden. **Keine** Hochstufung des gesamten Features auf `tested`, bevor die tatsächliche Wirkung in den Spielstand eingebunden und getestet ist.
- Dart-Analyse, Flutter-Tests und Android-CI sind erst bei **grünem finalen PR-Lauf** bestanden; APK im CI ist kein Realgerätetest.

Hinweis: Die historische SRD-Abdeckungsmatrix ist ein Arbeitsregister und keine geprüfte globale Fertigstellungsquote.

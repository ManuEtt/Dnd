# SRD 5.2.1 – Kegelförmige Zauberflächen, konservative Rastervorschau

Stand 21.10.2026. Fachquelle: [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), *Rules Glossary / Area of Effect / Cone* und *Cover*, CC BY 4.0.

## Neu implementiert

`app/lib/domain/srd_cone_area_rules.dart` ergänzt die bereits vorhandene Kugelvorschau um eine **read-only 2D-Kegelvorschau** auf bestätigten 5-Fuß-Feldern.

- Ausdrücklich gewählte Himmelsrichtung: Nord, Nordost, Ost, Südost, Süd, Südwest, West, Nordwest. Andere freie 2D-Winkel und 3D-Ausrichtungen werden **nicht** approximiert oder freigegeben.
- Die durch den Effekt **separat bestätigte** Kegellänge muss ein Vielfaches von 5 Fuß zwischen 5 und 120 Fuß sein. Die Kegelbreite wächst proportional zur Entfernung (am Ende so breit wie der Kegel lang ist). Ein Dreieck in der horizontalen Ebene dient nur der möglichen Kandidatenauswahl; es ersetzt **keinen** dreidimensionalen Zauberkegel.
- Mit einer inklusiven Dreieck-Rechteck-Schnittprüfung werden auch Felder erfasst, deren **Rand oder Ecke** den projizierten Kegel berührt. `centerWithinCone` ist eine gesonderte geometrische Aussage zum Zellmittelpunkt; weder Feldrand noch Mittelpunkt implizieren regelrecht betroffene Kreaturen.
- `originCellRequiresReview` markiert das Feld mit dem Ursprung, statt pauschal das gesamte Feld auszuschließen. Der **Ursprungspunkt** selbst wird standardmäßig nicht als getroffen betrachtet; er darf nur nach explizitem `includeOriginPointConfirmed` ausgewählt werden. Das gesamte Ursprungsfeld ist nicht mit dem Ursprungspunkt identisch.
- Bekannte vollständig blockierende Felder werden nicht als frei begehbare Zielfelder gelistet. Blockierte Mittelpunktstrahlen werden als `requiresCoverReview` markiert, **nicht** als nachgewiesene vollständige Deckung oder Immunität. Das Feld kann auf anderem Weg vom Flächeneffekt erreicht werden.
- `previewConfirmedSpell` überprüft vorab die bereits implementierte Katalogreichweite zum Ursprung und verlangt eine **separate** Bestätigung, dass der jeweilige Zaubereffekt einen Kegel erzeugt und welche Länge gilt. Beispielsweise bedeutet `Self` bei `Burning Hands` nur, dass der Ursprung beim Zaubernden liegt; die Kegellänge folgt nicht aus dieser Reichweite.
- Sämtliche Ergebnisse sind unveränderlich; unbestätigte Kartenerhebung, blockierte/ungültige Ursprünge oder falsche Kegellängen werden gesperrt.

## Grenzen – keine behauptete Vollautomatik

Der Renderer berechnet weder 3D-Höhen/Ebenen noch die tatsächliche SRD-Feldbedeckung, den offiziellen Ziel-/Kreaturentyp, Bewegungen, Sichtbarkeit, alternative Linien um Deckung, Rettungswürfe oder Schaden. Keine Geschichte, KI-Erzählung oder Grafikangabe allein autorisiert eine Spielzustandsänderung. Acht vorgegebene Himmelsrichtungen sind **kein** vollständiges beliebig ausrichtbares 3D-Kegelmodell. Keine generische Ressourcenbuchung/SQLite-Migration und keine automatische Kampfausführung in diesem Inkrement.

Die bestehenden Module `SrdSpellGridTargetRules` und `SrdSphereAreaRules` werden wiederverwendet; der neue Rule-API-Export liegt in `app/lib/rules/rules_api.dart`. Die maschinenlesbaren SRD-Anforderungen zu Flächen, Zielen und Cover bleiben ausdrücklich `partial`.

## Testabdeckung

`app/test/srd_cone_area_rules_test.dart` umfasst Richtungstrennung, Proportionen, unsichere Randfelder, Ursprungspunkt vs. Ursprungfeld, blockierte Felder und Deckungsunsicherheit, ungültige Daten, Kartenrand, unveränderliche Vorschau und den aus dem SRD-Katalog geladenen Zauber `Burning Hands` mit `Self` und gesondert bestätigter Kegellänge.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_cone_area_rules_test.dart
flutter test
flutter build apk --debug
```

Ein erfolgreich generierter CI-APK-Artifact belegt noch **keine** Installation oder Nutzung auf einem realen Android-Endgerät.

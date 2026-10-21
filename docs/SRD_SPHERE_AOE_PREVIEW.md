# SRD 5.2.1 – Kugelförmige Flächen: konservative 2D-Vorschau

Stand: 21.10.2026 · Quellen: [D&D Beyond SRD](https://www.dndbeyond.com/srd), SRD 5.2.1 *Rules Glossary / Area of Effect / Sphere* und *Cover*, CC BY 4.0.

## Funktion

Der neue regelreine Baustein `app/lib/domain/srd_sphere_area_rules.dart` erzeugt ein **unverbindliches Kandidatenfeld-Overlay** für einen Kugelwirkungsbereich:

- Ausgangsdaten: ausdrücklich bestätigte 2D-5-Fuß-Karte, freie Ursprungszelle, vollständige Erfassung aller relevanten vollen Hindernisfelder und bereits anhand des einzelnen SRD-Zaubertextes bestätigter Kugelradius. Unterstützt Radien von 5–120 Fuß in 5-Fuß-Schritten. Kein Auslesen einer beliebigen Reichweite als Effektradius.
- Ein Feld wird als **möglicher** Kandidat aufgenommen, wenn der geschlossene 2D-Feldumriss den projizierten Kreis auch nur berührt; dadurch werden grenzwertige Randfelder absichtlich nicht fälschlich ausgeschlossen. `centerWithinRadius` kennzeichnet separat die strengere rein geometrische Mittelpunktbedingung.
- Ein bestätigtes blockierendes Feld wird nicht als freies Bodenfeld ausgegeben. Ein blockierter Mittelpunktstrahl zu einem sonst möglichen Kandidaten ergibt **`requiresCoverReview`**, keine behauptete vollständige Deckung, keine behauptete Immunität. Ein freier Mittelpunktstrahl ergibt **`clear`**, aber keine garantierte Sicht, keine effektive Deckungsstufe oder Trefferentscheidung.
- Die Liste ist unveränderlich. Karten-/Ursprungs-/Radiusmanipulationen und fehlende Terrainbestätigungen werden abgewiesen.
- `previewConfirmedSpell(...)` ruft zunächst die vorhandene SRD-5.2.1-Kontrolle des Zauberursprungs (`SrdSpellGridTargetRules.validateOrigin`) auf. Die tatsächliche Kugelform und ihr Radius müssen **separat** aus dem Effekt bestätigt sein. Beispiel: Bei Fireball sind Zauber-Reichweite und Kugel-Radius unterschiedliche Angaben.

## Wichtig: keine automatische Schadenswirkung

Ein Rasterkandidat ist **kein** als getroffen bestätigtes Ziel. Das SRD beschreibt dreidimensionale Kugeln, wirkliche Hindernisse und die erforderliche Beurteilung, welche vollständigen Wege ein Effekt erreicht. Diese Vorschau berücksichtigt nur die horizontale Projektion und bekannte Vollhindernisfelder. Unbekannte Höhe, Flächenschwellen des Grid-Regelmoduls, Geschoss-/LoS-Regeln, Deckungswinkel, diagonale Ränder, alternative Strahlen, Zauberspezialregeln, Weiterleitung um Ecken, betroffene Objekte, Kreaturengrößen, Deckung und Rettungswürfe bedürfen ausdrücklich anderer Prüfungen. Der Algorithmus berechnet **keine** tatsächliche 3D-Kugel, kein offizielles vollständiges Flächenraster und keine Schadensauswirkung.

Die bestehende persistente Material-/Slotbuchung wird durch diese Vorschau **nicht** ausgelöst; KI-Narration bleibt ohne Autorität für regelrelevante Effekte.

## Tests, Dokumentation und Grenzen

`app/test/srd_sphere_area_rules_test.dart`: Radiusgrenzen, Zentrum, diagonale Rand-/Eckkandidaten, Blocker, Prüfbedarf statt Immunitätsbehauptung, Kartengrenzen, unveränderliche Listen, unbekannte Karte, blockierter Ursprung, separate Zauberreichweite vs. bestätigten Effektradius.

`app/lib/rules/rules_api.dart` exportiert die neue Regel-API. Auditpunkte `RULE-SPELLS-SPELL-AREAS-OF-EFFECT`, `RULE-SPELLS-SPELL-TARGETS` und `RULE-SPELLS-SPELL-ATTACK-COVER` bleiben **partial**.

Abnahme:

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_sphere_area_rules_test.dart
flutter test
flutter build apk --debug
```

Die GitHub-CI muss nach dem letzten Commit vollständig erfolgreich sein. Eine CI-APK ist keine manuell getestete Android-Geräteinstallation.

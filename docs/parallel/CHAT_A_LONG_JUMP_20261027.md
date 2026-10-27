# Chat A – SRD-5.2.1-Weitsprung-Vorprüfung (27.10.2026)

## Ausgangszustand / Konfliktprüfung

- Ausgangs-`main`: `e7736bfc99427bfa6a1d0fd3ff887252c75c9413`.
- Eigener Branch: `feat/chat-a/long-jump-preflight-20261027`.
- Vor Beginn geprüfte offene PRs: #282 (Hochsprung), #283 (Waldläufer Blindsicht), #280/#276/#278 (Gelände, Schwimmen, Klettern) sowie #271/#274/#277 (Zaubermaterialien), #259/#266 (Klassenmerkmale), #255/#269 (UI), #261/#270 (Story).
- Die Fachänderungen sind bewusst auf **eine neue Datei in `app/lib/domain` plus einen neuen Test** begrenzt. Kein `rules_api.dart`, `game_engine.dart`, `game_controller.dart`, `models.dart` oder Requirements-JSON wird verändert.

## Regelquelle und Akzeptanzkriterien

- Offizielles **SRD 5.2.1**, *Rules Glossary – Long Jump*, gedruckte Seiten **184–185**, Wizards of the Coast LLC; **CC BY 4.0**. [Amtliche PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf).
- Maximum bei **mindestens 10 Fuß unmittelbar vor dem Sprung zurückgelegter Bewegung**: bestätigter Stärke-Wert in Fuß. Ohne diesen Anlauf ist nur die halbe Entfernung erlaubt.
- Jede zurückgelegte Fußstrecke kostet einen Fuß Bewegungsbudget. Projektkonvention: 1 Fuß = 30 cm; halbe Fußstrecken bleiben als 15 cm erhalten. Das Budget enthält nur die **noch verfügbare** Bewegung; der Anlauf wird nicht erneut berechnet oder abgebucht.
- **Schwieriges Gelände bei der Landung** benötigt eine bereits ausdrücklich bestätigte Geschicklichkeitsprobe (Akrobatik) gegen **SG 10**, sonst ist der Probenstatus `pending`. Misslingt die bestätigte Probe, liefert der read-only Plan `wouldLandProne=true`; **kein Zustand wird gesetzt**.
- Für **niedrige Hindernisse bis einschließlich 1/4 der Sprungweite** kann die Spielleitung ausdrücklich einen **Stärke-(Athletik)-Wurf SG 10** verlangen. Unbekannte Entscheidung oder unbekannte Hindernishöhe wird zurückgewiesen. Bei fehlendem Wurf bleibt das Ergebnis ausstehend; bei Misslingen ist das Hindernis nicht überwunden. Für höhere Hindernisse wird **keine** automatische Freigabe behauptet.
- Unbekannter Stärke-Wert, Laufanlauf oder Landegelände, ungültige Distanz, zu wenig Bewegung, manipulierte oder widersprüchliche Hindernisangaben und unnötige Proben scheitern ohne Zustandsänderung.
- Beim Prüfen der Vierteldistanz wird ein Ganzzahlvergleich statt potenziell überlaufender Multiplikation verwendet.

## Umsetzung

- `app/lib/domain/srd_long_jump_rules.dart`: `SrdLongJumpRules.maximumDistanceCentimeters`, `preflight`, `SrdLongJumpAssessment` und `SrdLongJumpCheckOutcome`.
- `app/test/srd_long_jump_rules_test.dart`: positive 10-Fuß-Grenze, 9-Fuß- und stehende Halb-Weite (ungerader Stärke-Wert), exakte cm-Reste, unbelegte/negative Eingaben, fehlende Bewegungsreste, Landung SG 9/10 bzw. ausstehend, optionale Hindernis-SG 9/10, unzulässige Hindernishöhen, große Werte (Overflow), widersprüchliche Bestätigungen, deterministische Wiederholung ohne Doppelbuchung.
- Reiner Domaincode ohne Story-, UI- oder Providerimport. Keine Würfelquelle und kein Eingriff in Live-Spielstände.
- Bezug `COMBAT-TERRAIN-MAP` bleibt wegen fehlender vollständiger SRD-Bewegungsintegration **missing** im zentralen Register. Kein globaler Fortschrittsprozentsatz und keine unbelegte `tested`-Kennzeichnung.

## Gezielte Prüfbefehle

```sh
python3 scripts/verify_project.py
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py --json
python3 -m unittest discover -s scripts/tests -v
cd backend && npm ci && npm run typecheck && npm run build && npm test
cd ../app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_long_jump_rules_test.dart
flutter test
flutter build apk --debug
```

GitHub-Actions-Resultat ist **erst nach Abschluss auf finaler Commit-SHA**
gültig; Testdateien allein sind kein Testnachweis. Geräteinstallation,
Touch-/Sprachprüfung und Veröffentlichung bleiben getrennt.

## Kompatibilität / bewusst nicht implementiert

- Keine SQLite-/JSON-Migration (SQLite 2, JSON 1), keine Änderung an `app/pubspec.yaml` (0.8.42+92).
- Keine Eingriffe in Kampfzug, Zustand, Revisions-/Ereignisjournal oder bestätigte Würfelproben. Noch keine automatische Probe, keine Prone-Buchung, kein Positionswechsel.
- Für die spätere Anbindung müssen turn ownership, bestätigte Bewegung, Terrain, einmalige Event-ID, Stale Revision, Save/Restart und Hindernisse im GameController/Repository separat geprüft und koordiniert werden.

## Genau ein nächster Schritt

Nach bestandener finaler PR-CI eine **koordiniert bestätigte Weitsprung-Ausführung mit revisions- und speichersicherer Bewegungs-/Prone-Buchung** konzipieren, ohne laufende Gelände-Integrations-PRs zu überschreiben. Abnahme: korrekter einmaliger Verbrauch, nur bestätigte SG-Ergebnisse, fail-closed bei veralteter Revision sowie persistenter Neustart.

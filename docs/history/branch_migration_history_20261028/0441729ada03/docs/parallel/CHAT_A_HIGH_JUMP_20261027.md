# Chat A – SRD 5.2.1 Hochsprung-Vorprüfung (27.10.2026)

## Ausgangsproblem und Regelbeleg

Eine isolierte, deterministische Regelentscheidung für **High Jump** fehlte in
`app/lib/domain/`. Die bisherige Bewegungsberechnung behandelt normale,
liegende und kriechende Bewegung, aber keine bestätigte Hochsprunghöhe. Diese
Vorprüfung darf die laufende Entwicklung der Kletter-/Schwimmbewegung
(#276/#278/#280) sowie die Klassenmerkmale (#259/#266) nicht überschreiben.

- **Anforderungsbezug:** `COMBAT-TERRAIN-MAP` (noch nicht vollständig);
  isolierter Unterfall `RULES-GLOSSARY-HIGH-JUMP`. Kein neues
  `tested`-Flag im kollisionsanfälligen Requirements-Register.
- **Amtliche Regel:** SRD 5.2.1, *Rules Glossary – High Jump*, Druckseite 183;
  [Original-SRD als PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf).
- **Lizenz:** Wizards of the Coast LLC, SRD 5.2.1, CC BY 4.0;
  bestehende Attribution in `THIRD_PARTY_NOTICES.md` bleibt bestehen.

## Implementiert

`app/lib/domain/srd_high_jump_rules.dart` enthält eine rein lesende
`SrdHighJumpRules.preflight` und `maximumHeightCentimeters`:

- Bei bestätigten **mindestens 10 Fuß Anlauf zu Fuß unmittelbar vorher**:
  Höchstwert `max(0, 3 + floor((Strength - 10)/2))` Fuß.
- Bei weniger als 10 Fuß: genau die Hälfte der Höhe, ohne vorzeitiges Runden.
- Einheit im bestehenden App-Modell: 1 Fuß = 30 cm. Ein Zentimeter
  Sprunghöhe kostet einen Zentimeter **bereits verbleibender** Bewegung.
  Der vor dem Sprung verbrauchte Anlauf wird nicht erneut abgezogen.
- Explizite Höhe erforderlich; zu große Sprünge, unbekannte Stärke,
  unbestätigter Anlauf und fehlendes Bewegungsbudget scheitern ohne Mutation.
- Optionale Reichhöhe bei bestätigter Körpergröße:
  Sprunghöhe + 1,5 × Körpergröße, intern exakt in halben Zentimetern.
- Auch negative **ungerade** Attributsmodifikatoren werden abgerundet
  (z. B. Stärke 9 → −1). Bei sehr niedriger Stärke ist Höhe 0.
- Keine automatischen Gratis-Sprünge oder angenommene Extrahöhe durch KI.

## Akzeptanz- und Regressionstests

`app/test/srd_high_jump_rules_test.dart` enthält positive und negative
Fälle: 10-Fuß-Grenze, 9-Fuß-Anlauf, halbe Fußhöhe, negative ungerade
Stärkeboni, 0-Höhe, Überschreitung der Distanz/des Bewegungsbudgets,
fehlende Bestätigungen, unplausible Körpergröße und deterministische
Wiederholung ohne doppelte Ressourcenbuchung.

**Status vor CI:** Testdatei auf GitHub vorhanden, lokal **nicht
ausgeführt**, da Dart und Flutter in der zugänglichen Umgebung fehlen.
Die Existenz der Tests ist kein Erfolgsnachweis.

## Abgrenzung und Kompatibilität

Nur lesendes Domainmodul plus Tests; kein `GameEngine`-, Controller-,
UI-, JSON-, SQLite- oder Event-Eingriff. Bereits bestätigte Spielstände,
SQLite 2, Kampagnen-JSON 1 und App-Version 0.8.42+92 bleiben erhalten.
Kein eigenmächtiger Sprung im Kampf: fehlende Prüfung von Zugrecht,
Zuständen, Anlaufkontinuität und Bewegungs-/Revisionspersistenz wird
ausdrücklich **nicht** als vollständig implementiert behauptet.
Aufwendige DM-Sonderregeln und Zauber-/Klasseneffekte bleiben gesperrt,
bis ein gesondertes bestätigtes Integrationspaket existiert.

## Befehle für Abnahme

```sh
python3 scripts/verify_project.py
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py --json
python3 -m unittest discover -s scripts/tests -v
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_high_jump_rules_test.dart
flutter test
flutter build apk --debug
```

Der vollständige Backend-/JVM-/APK-Check bleibt ebenfalls erforderlich
bei der späteren Integration. GitHub-CI und reales Android-Gerät sind
getrennte Nachweise.

## Nächster unabhängiger Schritt

Nach grüner CI: das **nur lesende** SRD-Weitsprung-Limit als separates
Regelpaket mit Schwierig-Gelände-Landung, bestätigten SG-10-Proben und
ausdrücklicher Trennung von tatsächlicher Zustandsmutation prüfen.
Kein direkter Wechsel auf bestehende offene Kletter-/Schwimm-PR-Dateien.

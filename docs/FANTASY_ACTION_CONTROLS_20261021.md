# Fantasy-Aktionsflächen: zweiter Entwicklungszyklus (21.10.2026)

## Ausgangszustand

`main` enthält den integrierten PR #93 mit 30 transparenten,
reproduzierbar erzeugten Button-Varianten und gemeinsamen
`FantasyButton`-Widgets. Bei den vier unten fixierten Abenteuer-
Schnellaktionen wurde bislang die gleiche optionale WebP-Dekoration
für alle Zustände genutzt; die Aktion selbst war bereits korrekt
über `InkWell` an den Controller angebunden.

## Dieses Arbeitspaket

- `FantasyButtonSurface` ist jetzt ein wiederverwendbarer,
  nicht-interaktiver Artwork-Baustein für Rechteck-Buttons und
  Schnellaktionen mit unverändertem 9-Slice-Hintergrund.
- `FantasyShortcutTile` bewahrt Portrait-/Runensymbole, Touch-Flächen,
  bestehende Labels und ValueKeys, steuert aber die Zustände
  `normal`, `hover` (auch Tastaturfokus), `pressed`,
  `active` und `disabled` und animiert das Drücken.
- Die vier fixierten Aktionen nutzen spezifische Materialien:
  Stimme = Holz/Gold, Untersuchen = Arkane, Angriff = rotes
  Siegelwachs, W20 = Arkane. `listening` aktiviert den
  persistierenden `active`-Zustand für Stimme; `busy`
  deaktiviert alle vier Aktionen, ohne versteckte Klickauslösung.
- Der W20-Proben-Dialog, freie Würfel-Dialog und die
  Bestätigung unwiderruflicher Löschungen verwenden gemeinsame
  `FantasyTextButton` mit differenzierten Materialien
  (Gold/Arkane/Gusseisen/Siegelwachs). Eingabeprüfung,
  natürlicher W20-Wert, Bonus-/Gesamtergebnis-Unterscheidung,
  Löschbestätigung und Callback-Semantik bleiben unverändert.
- Neue Widgettests überprüfen Materialzuordnung, Hover,
  Druck, aktives Mikrofon, Deaktivierung und echte Callback-
  Zählung. Die bestehenden Pinned-Action-Tests für 320/360/400 dp,
  große Schrift und eingeblendete Tastatur bleiben maßgeblich.

## Nicht verändert

`domain/`, `story/`, `data/`, `services/`, SQLite,
SRD-Berechnungen und Android-Manifest bleiben unverändert.
Keine neue Geschichte, kein Monster-Lexikon und keine
bloß optischen Scheinaktionen.

## Abnahme

```bash
python3 scripts/generate_fantasy_buttons.py
python3 -m unittest discover -s scripts/tests -v
cd app
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/fantasy_action_controls_test.dart
flutter test test/fantasy_pinned_actions_test.dart
flutter test
flutter build apk --debug
```

Die Ergebnisse sind erst nach konkretem CI-Lauf belastbar.

# Fantasy-Button-Grafiken

Die 30 PNG-Dateien werden deterministisch und ohne Zusatzbibliotheken erzeugt:

```bash
python3 scripts/generate_fantasy_buttons.py
```

Sechs Bildtypen (`wood_gold`, `rune_arcane`, `iron`, `wax`, `dice`,
`icon_gold`) besitzen jeweils fünf Zustände:
`normal`, `hover`, `pressed`, `active`, `disabled`.

Breite Buttons: **192 × 64 px**, mit geschützten 24 px Rändern links/rechts
sowie 20 px oben/unten (`centerSlice: Rect.fromLTWH(24,20,144,24)`).
Icon/Würfel: **64 × 64 px**, ohne `centerSlice`.

Bezeichnungen, Symbole, Fokus, Drücken und Zustandswechsel liegen als echte
Flutter-Widgets darüber; die Bitmaps fangen keine Eingaben ab. Das System ist
auch dann benutzbar, wenn das erzeugte Grafikpaket in einem Checkout fehlt:
ein gezeichneter, kontrastreicher Fallback wird gezeigt.

Text und interaktive Logik werden **nicht** in die PNGs eingebrannt.
Die PNGs sind eigene, prozedural erstellte Projektgrafiken.

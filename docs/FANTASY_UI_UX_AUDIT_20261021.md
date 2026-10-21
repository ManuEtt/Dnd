# Würfelraunen: UI/UX-Bestandsaufnahme und Fantasy-Button-System (21.10.2026)

## Tatsächlich geprüfte Architektur auf main

Basis für dieses Arbeitspaket: `cab20cf3f299c7dc18da121f3c2c16bfb382548b`.
Flutter-App unter **`app/`** (nicht Repositorywurzel); Einstieg
`app/lib/main.dart`, Seitenumschaltung `app/lib/ui/app.dart` mit
`_page` 0 bis 4. Keine deklarativen GoRouter-Routen.
Fünf Hauptbereiche: **Start, Abenteuer, Helden, Tagebuch, Optionen**.
Mobile `NavigationBar` unter 920 logischen Pixeln, sonst `NavigationRail`.

`GameController` erweitert `ChangeNotifier`; `LivingGameApp`
verwendet `AnimatedBuilder` auf GameController, VoiceController
und Narrator. Persistenz per SQLite-Repository; keine Hive-/Provider-
Architektur. `app/pubspec.yaml` meldet Version 0.8.30+80.

Zusätzliche modale Ansichten/Widgets:
- Helden: Charaktereditor, Portraitauswahl, Charakterbogen, Eigenschafts-
  zuweisung, Klassenauswahl, Mehrklassen, Aufstieg, Ausrüstung und Inventar;
- Abenteuer/Kampf: Kampfansicht, manuelle Würfel, freie Würfel, manuelle
  Zugfolge, Initiative, Kreaturenregistrierung, Angriffe, Zustände,
  Reaktionen, Rettungs-/Todesschutz und Zauber-Dialoge;
- Story: Kampagnenauswahl, Chronik, Erinnerungsbereich, Quests;
- Optionen: Sprach- und Backend-Einstellungen, JSON-Import/Export.
Ein eigenständiges Monster-Handbuch bzw. eine vollständige Weltkarten-Seite
ist gegenwärtig **nicht** als Hauptansicht implementiert.

## Inventur der interaktiven Bedienelemente

Relevante bestehende UI-Dateien (`app/lib/ui/` enthält 37 Dart-Dateien):

| Ort | Interaktionen | Neue Asset-Familie |
| --- | --- | --- |
| `app.dart` – Start | Demo, Soloabenteuer, Kampagne, KI, Helden, Chronik, Import, Löschen | wood_gold, iron, wax |
| `app.dart` – Navigation | 5 Tabs, Einstellungen im AppBar | icon_gold, rune_arcane |
| `app.dart` – Abenteuer/Kampf | Aktion senden, Sprache, Beobachten, Angreifen, W20, Zugverwaltung | dice, rune_arcane, wood_gold |
| `app.dart` – Helden | Held wählen/bearbeiten, Charakterbogen, Inventar | wood_gold, icon_gold |
| `app.dart` – Tagebuch/Optionen | Tagebuchaktionen, Einstellungen, Datenexport | iron, icon_gold |
| `character_editor.dart`, `fantasy_character_sheet.dart` | Editieren, Speichern, Eigenschaften, Ausrüstung, Aufstieg | wood_gold, wax |
| `campaign_memory_panel.dart` | Chronik, Auswahl/Bestätigen | wood_gold, iron |
| `fantasy_experience.dart`, `fantasy_art.dart` | illustrierte Karten, Schnellzugriffe, Löschen | wood_gold, wax |
| Zauber- und Kampf-Dialoge | Ziele/Slot/Aktion wählen, Wirken/Bestätigen, Abbrechen | rune_arcane, wood_gold, iron |
| Auswahl-/Inventar-/Backup-Dialoge | Hinzufügen, Entfernen, Importieren, Zurück | wood_gold, wax, iron |

Bereits genutzte Interaktionsklassen: `FilledButton`,
`OutlinedButton`, `TextButton`, `IconButton`, `InkWell`,
`GestureDetector`, `NavigationDestination`,
`NavigationRailDestination`, `SimpleDialogOption`,
eigene `FantasyJourneyCard`, `FantasyShortcutTile` und
`FantasyPinnedActionBar`. Weitere Formularauswahlen verwenden
standardmäßige Flutter-Controls. Diese Liste benennt **Familien und
Action-Gruppen**; ein vollständiger Callsite-zu-Asset-Migrationsnachweis
steht nach dem ersten Inkrement noch aus.

Vorhandene Grafiken: `app/assets/art/` mit Landschafts-/Item-WebPs,
`app/assets/fantasy/` mit Nacht, neun Porträts, Rahmen, UI-Atlas.
`fantasy_ui.dart` bietet bereits `FantasyPalette`, `FantasyBackdrop`,
`FantasyPanel` und optionalen Kunst-Fallback. Bestehende WebPs sind
**keine** sicheren Nine-Slice-Quellen: nicht per `centerSlice` dehnen.

## Verbindlicher Stilguide

- **Materialien:** dunkles Eichenholz, genarbtes Leder, antikes Metall,
  gealtertes Pergament, Messing-/Goldkante, sanfte arkanblaue Akzente.
- **Palette:** Nacht `#09121F`, Tinte `#0D1927`, Gold `#DDB96C`,
  Elfenbein `#F4EAD6`, Arkane `#79B8DD`, Warnrot `#D76D72`.
- **Text:** lesbare echte Flutter-Schrift (serif für Titel); keine Texte
  in dekorativen Bildern. Labels skalieren und sind vorlesbar.
- **Touch-Ziel:** mindestens 48 logische Pixel, Fokus sichtbar,
  deaktivierte Aktionen nicht auslösbar; `pressed` verkleinert auf 96,5 %.
- **Visuelle Zustände:** `normal`, `hover` (auch Tastatur-Fokus),
  `pressed`, `active` (Toggle/Auswahl), `disabled`.
  Keine Änderungen an Regeln, TP/RK/EP, SQLite oder KI-API.

## Grafikmanifest: geplante pro-Screen Assets

| Ebene | Derzeit verwendbar | Eigene Grafik für spätere Asset-Etappe |
| --- | --- | --- |
| Start | `art/ruins.webp`, `fantasy/night_sky.webp`, Rahmen | `bg_start_keep.webp`, `frame_menu_parchment.png` |
| Abenteuer | vorhandene Landschaften, `FantasyBackdrop` | `bg_adventure_tavern.webp`, `panel_narrator_scroll.png` |
| Helden | neun Porträts, Porträtrahmen | `bg_hero_armory.webp`, `frame_character_scroll.png` |
| Tagebuch | Landschaft, Panels | `bg_journal_grimoire.webp`, `frame_journal_page.png` |
| Optionen | Panel- und Nachtgrafik | `bg_settings_workbench.webp`, `panel_settings_wood.png` |
| Kampf (im Abenteuer) | Szenengrafiken, HUD | `panel_initiative_iron.png`, `frame_enemy_card.png` |
| Zauber/Inventar (Dialoge) | vorhandene Karten, Item-WebPs | `panel_spell_rune.png`, `frame_inventory_leather.png` |

Dies ist eine **Bedarfsliste**, keine Behauptung, dass alle rechts
genannten Bilddateien bereits vorliegen.

## Produktions-Prompts für Einzelgrafiken

Gemeinsame Negativvorgaben: *no UI text, no typography, no watermark, no
logos, no characters with readable letters, no fake statistics, no game data,
no screenshot/mockup frame*. Originale eigenständige Fantasywelt; keine
geschützten fremden Marken/Charaktere.

**Start – `bg_start_keep.webp` (9:16):**

> Vertical mobile fantasy game background, a distant medieval fortress
> under moonlight, misty dark pines, weathered oak ornamental architecture,
> antique bronze lantern glow, deep blue night, central negative space
> for accessible overlay menu, premium hand-painted fantasy key art,
> layered depth, subtle parchment grain, no text, 9:16 composition.

**Abenteuer – `bg_adventure_tavern.webp` (9:16):**

> Low-contrast atmospheric dark fantasy tavern interior, old wooden
> beams, ancient vellum map table, flickering candles, blue arcane
> reflections, atmospheric background reserved for live chat and combat
> interface; restrained details in center for readability, no text,
> vertical 9:16.

**Helden – `bg_hero_armory.webp` (9:16):**

> Fantasy adventurer armory with aged leather, polished sword silhouettes,
> dark wooden shelves, warm brass details, soft mist, no faces or
> precreated heroes, open composition for dynamic portrait and real
> character statistics, vertical 9:16.

**Tagebuch – `bg_journal_grimoire.webp` (9:16):**

> Dark fantasy scholar's desk with closed embossed leather grimoire,
> parchment sheets and quill, soft candle light, mysterious restrained
> runic ambience, generous clean central space for dynamic journal text,
> no legible handwriting, vertical 9:16.

**Optionen – `bg_settings_workbench.webp` (9:16):**

> Detailed enchanted artisan workbench, ebony wood, engraved brass,
> simple gemstones, antique gears and wax seals, symmetrical subtle
> peripheral detail, empty middle for UI controls, no text,
> vertical 9:16.

**Breite Schaltfläche – pro Material und Zustand (3:1):**

> One single isolated fantasy UI button plate, exact rectangular
> horizontal frame, weathered dark oak and finely engraved antique
> gold edge, completely EMPTY center for dynamic Flutter text, strong
> symmetry, perfectly straight unbroken 24px left/right edge sections,
> flat orthographic front view, separate transparent alpha background,
> no lettering or icons, no perspective, game-ready, 3:1.
> Variant NORMAL: calm brass highlights; HOVER: delicate golden
> rim-glow; PRESSED: depressed dark center and strong inner rim;
> ACTIVE: persistent warm luminous border; DISABLED: matte grey metal
> with no glow. Keep geometry pixel-identical across all variants.

Materialänderungen: `rune_arcane` = blue arcane metal and sapphire runes;
`iron` = graphite forged steel; `wax` = red sealing wax and brass;
`dice` = circular D20 medallion; `icon_gold` = square gold-rimmed
metal badge. Für quadratische Ikonen **1:1**, nicht 3:1. DALL-E/Flux:
transparent background; Midjourney zusätzlich `--ar 3:1 --no background`
bzw. `--ar 1:1 --no background` (Transparenz anschließend prüfen).

## Implementierte erste Komponente auf Feature-Branch

- `app/lib/ui/fantasy_buttons.dart` enthält `FantasyButton`,
  `FantasyTextButton`, `FantasyIconButton`, `FantasyDiceButton`,
  `FantasyToggleButton`. `InkWell` bleibt aktiver Flutter-Button;
  Hover, Fokus, Pressed, Toggle und Disabled steuern Bitmap/Fallback.
- `scripts/generate_fantasy_buttons.py` erzeugt **30 transparente
  PNG-Dateien** offline und reproduzierbar, ohne KI-Dienst und ohne
  Drittbibliothek: 6 Materialien × 5 Zustände.
- Breite Bilddateien: 192×64, `centerSlice:
  Rect.fromLTWH(24, 20, 144, 24)`; quadratische: 64×64 ohne Slice.
  Die dynamische Beschriftung bleibt stets echter Flutter-Text.
- `pubspec.yaml` enthält `assets/fantasy/buttons/`. CI generiert
  die Pixelgrafiken vor Prüfung und APK-Build. Bei fehlenden PNGs in
  lokalen Checkouts greift eine gezeichnete Fallback-Schaltfläche.
- Konkrete Startseiten-Aktionen „Neue Kampagne“, „Helden verwalten“
  und das Einstellungs-Icon verwenden schon die Widgets.
- `app/test/fantasy_buttons_test.dart` prüft Button-Aktionen und
  320/360/920-dp-Layouts; `scripts/tests/test_generate_fantasy_buttons.py`
  prüft 30 PNGs und deterministische Generierung.

## Weitere Arbeit

Alle Standardbuttons in Unterdialogen schrittweise auf dieselben
Komponenten umstellen, mit goldenem Fokus, Größen-/TalkBack-/Keyboard-
Abnahme und Regressionstests pro Screen. Erst anschließend gesonderte
Hintergründe exportieren und als Offline-Assets einbinden. Bei Aktionen
immer die bestehende Controller-Funktion übernehmen, **keine** neuen
Scheinaktionen für noch nicht implementierte Ansichten erstellen.

# Würfelraunen – Fantasy-UI: Repository-Audit, Designsystem und Asset-Plan

**Stand:** 21.10.2026 · **Ausgangsbasis:** `main` (SHA `1596d1c3fb47181eb8d4578f2769cdd046fef5de`) · **Phase:** Analyse und erstes Integrationsinkrement

> Der Plan dokumentiert **tatsächlich geprüfte Dateien** getrennt von **zukünftigen Konzepten**. Er ist keine Aussage, dass alle geplanten Screens/Grafiken bereits implementiert sind.

## 1. Repository-Audit (IST)

- Flutter-Anwendung: `app/`; Einstieg: `app/lib/main.dart`; zentrale UI/Navigation: `app/lib/ui/app.dart`.
- 38 Dart-Dateien direkt in `app/lib/ui/`, davon Haupt-UI, spezialisierte Panels, Charaktereditor, Charakterbogen, Zauber- und Kampf-Dialoge.
- Zustand: `GameController` extends `ChangeNotifier` (`app/lib/services/game_controller.dart`); die Hauptansicht beobachtet Controller, Sprache und Erzähler via `AnimatedBuilder(Listenable.merge(...))`. Lokales `_page`-State steuert fünf Tabs.
- Persistenz: `SqliteCampaignRepository`; Regeln und Modelle in `app/lib/domain/`; Story in `app/lib/story/`. UI-Grafiken dürfen diese Schichten nicht verändern.
- Navigation: fünf Tabs per `NavigationBar` auf Telefonen bzw. `NavigationRail` ab 920 dp; Unterseiten durch `MaterialPageRoute`; diverse `showDialog`-Workflows. Kein separater deklarativer Router für die Hauptnavigation.
- `app/pubspec.yaml` registriert `assets/`, `assets/art/`, `assets/fantasy/`, `assets/fantasy/buttons/`; die vorhandene Registratur ist korrekt und muss nicht unnötig geändert werden.
- Existierende UI-Bausteine: `FantasyBackdrop`, `FantasyPanel`, `FantasyOptionalImageFrame`, `FantasyChapterHeading`, `FantasyJourneyCard`, `FantasyCampaignCard`, `FantasyPinnedActionBar`, `FantasyButton`, `FantasyTextButton`, `FantasyIconButton`, `FantasyDiceButton`, `FantasyToggleButton`, `CharacterSheetPage`.
- Vorhandene Bildserien: `app/assets/art/*.webp` für Szenen und Gegenstände; `app/assets/fantasy/*.webp` für Nachtlandschaft, Porträts, Atlas, Ornament- und Kartenrahmen.
- **Wichtig:** `assets/fantasy/buttons/` enthält nur eine README. Der CI-Workflow erzeugt 30 transparente PNGs vor `flutter pub get` via `scripts/generate_fantasy_buttons.py`. Lokale Entwickler müssen den Generator ebenfalls ausführen. Flutter stellt bei fehlenden optionalen PNGs bereits einen zeichnerischen Fallback dar.

### 1.1 Echte Hauptebenen

| Navigation | Code | Bestehende Komponenten | Interaktionen |
|---|---|---|---|
| Start | `_HomePage` in `app.dart` | bebilderter Banner, JourneyCards, Heldenkarte, Kampagnenkarten | Demo starten/fortsetzen, Rabenwacht, neue/ KI-Kampagne, Held öffnen, importieren, Kampagne löschen |
| Abenteuer | `_AdventurePage`, `_CombatView` in `app.dart` | Geschichtenansicht, Abenteuer-HUD, angeheftete Schnellaktionen, Kampfpanel | Sprache, untersuchen, angreifen, W20, Spieleraktion, Zauber, Kampf- und Zustandseingriffe |
| Helden | `_CharactersPage` in `app.dart` | Heldenliste, Porträts, `CharacterEditor`, `CharacterSheetPage` | erstellen, importieren, bearbeiten, Bogen öffnen, Klassen-/Ausrüstungsdialoge |
| Tagebuch | `_JournalPage`, `CampaignMemoryPanel` | Chronik, Erinnerungen, Quest- und Ereignisseiten | Einträge lesen, Notizen/Erinnerungen verwalten |
| Einstellungen | `_SettingsPage`, `BackendSettingsPanel` | Audio-/Sprachpanel, Backups und Erzähleroptionen | Stimme/Optionen wählen, Verbindung verwalten, Backup/Import/Export |

Weitere **existierende Unterdialoge** umfassen Würfelwürfe, Auswahl von Zauberzielen, Flächeneffekte, Heilung, Klassenwahl, Aufstieg, Mehrklassenwahl, Ausrüstung, Initiativreihenfolge und Zustandsverwaltung. Ein eigenständiger Monster-Handbuch-Tab ist im geprüften 5-Tab-Routing **nicht vorhanden** und wird daher nur als zukünftiger Ausbau eingeordnet.

### 1.2 Inventar der Bedienelemente

Die statische Inventur der 38 `app/lib/ui/*.dart`-Dateien zeigt:
- `FantasyTextButton`, `FantasyIconButton`, `FantasyDiceButton`, `FantasyToggleButton`, `FantasyButton`; `FantasyShortcutTile` verwendet dieselbe Zustandsoberfläche.
- Material-Aktionsfamilien `FilledButton`, `TextButton`, `OutlinedButton`, `IconButton`; zusätzlich `InkWell`, `SimpleDialogOption`, `FilterChip`, `ChoiceChip` und Navigationselemente.
- Klicks kommen oft aus Dialogen mit Validierung. Ihre `onPressed`-Logik darf bei UI-Austausch nicht verändert werden. `onPressed: null` muss die Aktion zuverlässig deaktivieren.
- `FantasyButtonState`: `normal`, `hover`, `pressed`, `active`, `disabled`; die Zustandsauflösung ist bereits implementiert. Aktiv (ausgewählt) ist vom temporären Pressed-Zustand getrennt.
- `FantasyButtonStyle`: `woodGold`, `arcane`, `iron`, `wax`, `dice`, `iconGold`; alle 6×5 Grafikpfade sind bereits definiert.

## 2. Designsystem (SOLL)

**Leitidee:** „Eine lebende Chronik auf dem Tisch eines Erzmagiers“. Dekorative Bildschichten liegen **hinter** echten Flutter-Controls, damit Text lesbar und bedienbar bleibt. Kein vorgerendertes Screenshot-UI mit nicht-interaktiven Pseudo-Buttons.

### Farb- und Material-Tokens

| Token | Farbwert / Material | Verwendung |
|---|---|---|
| Nacht / Holzschatten | `#09121F`, `#261A15` | Hintergrund und Lesekontrast |
| Dunkles Mahagoni | `#452919` | primäre Holzplaketten |
| Pergament | `#E9D4A9` | hellere Chronikseiten und Karten |
| Pergament-Tinte | `#31251C` | Text auf hellen Karten |
| Gold / Messing | `#DDB96C`, `#B78949` | Ornamente, Fokusrahmen |
| Elfenbein | `#F4EAD6` | Text auf dunklen Schichten |
| Arkane Energie | `#79B8DD` | Magie, Hover, Fokus |
| Siegelrot | `#D76D72` | Kampf, Gefahr, destruktive Aktionen |
| Jade | `#64C4A1` | Heilung und bestätigte Erfolge |

Die vorhandene dunkle `FantasyPalette` bleibt zunächst die Basis; Pergament wird schrittweise für Tagebuch, Charakterbogen und Dialog-Container eingeführt. Keine globale Umfärbung ohne Kontrasttests.

**Typografie:** ornamentale Serifenschrift für Kapitel- und Kartentitel; gut lesbare Schrift für Werte, Listen, Buttons und Formulare. Text als echtes Flutter-`Text`, nie in den Bilddateien. Buttons mindestens 48×48 logische Pixel, sichtbarer Tastaturfokus, Semantics/Tooltip, skalierbarer Text, verständliche Fehlermeldungen.

**Zustandsvertrag:**
- `normal`: ruhige Textur, matte Messingkante.
- `hover`/`focus`: dezenter Glanz, keine Aktion ohne Klick.
- `pressed`: schmaleres Schattenband und 0,965-Skalierung, optionales nur vom Auslöser gestartetes Sound-Signal.
- `active`: dauerhaft sichtbares Leuchten für ausgewählte Modi; nicht mit `pressed` verwechseln.
- `disabled`: reduzierte Sättigung, klare Lesbarkeit, keine Eingabe/kein Sound.
- Mobilgeräte haben keinen erwartbaren Hover; Pointer-/Tastatur-Unterstützung ergänzt Touch.

### Layout

Telefon: Single-Column, SafeArea, Hauptnavigation unten; die vier `FantasyPinnedActionBar`-Schnellaktionen bleiben im Abenteuer am unteren Rand, auch bei Tastaturöffnung. Breite Geräte: Rail links, max. Inhaltsbreite 1100 dp. Bildornamente dürfen weder über System-Navigation noch über Input/Scrollbereiche gelegt werden. `InkWell` und echte Callback-Semantik bleiben immer über Dekorschichten.

## 3. Asset-Matrix pro vorhandener Ebene

| Bereich | Neue/geplante Assets | Bestehende Basis |
|---|---|---|
| Start | `bg_home_ruined_citadel.webp`, `frame_campaign_wood_gold.webp`, `divider_compass.webp` | `art/ruins.webp`, `FantasyJourneyCard`, `FantasyCampaignCard` |
| Abenteuer | `bg_adventure_moonlit_road.webp`, `frame_story_scroll.webp`, `hud_turn_brass.webp` | `fantasy/night_sky.webp`, `FantasyAdventureStatusHud`, `FantasyPinnedActionBar` |
| Kampf-Unterbereich | `bg_combat_battlemap.webp`, `frame_initiative_iron.webp`, `overlay_hit_glow.webp` | `_CombatView`, bestehende Kampfaktionen |
| Heldenübersicht | `bg_heroes_guildhall.webp`, `frame_hero_leather.webp` | vorhandene Porträts und Helden-Medaillons |
| Charakterbogen/-editor | `bg_character_parchment.webp`, `frame_stat_gold.webp`, `divider_ability.webp` | `CharacterSheetPage`, `CharacterEditor` |
| Tagebuch | `bg_journal_parchment.webp`, `frame_chronicle_scroll.webp`, `separator_ink.webp` | `CampaignMemoryPanel`, `art/forgotten_woods.webp` |
| Einstellungen | `bg_settings_workbench.webp`, `frame_settings_leather.webp` | `_SettingsPage`, `BackendSettingsPanel` |
| Dialoge/Zauber/Würfel | `frame_dialog_wax.webp`, `frame_spell_arcane.webp`, `frame_dice_iron.webp` | existierende Dialoge mit Material-Buttons |

Dies sind **geplante Dateinamen**, nicht bereits vorhandene Binärdateien. Das optionale Grafiksystem muss fehlende Assets abfangen.

### Button-Paket (bereits durch Python-Generator definiert)

| Stil | Bildname-Präfix | Motiv | Basisformat |
|---|---|---|---|
| Holz + Gold | `btn_wood_gold_` | gravierte Eichen-/Mahagoniplakette | 192×64 |
| Arkan | `btn_rune_arcane_` | Runenring und kaltes magisches Glimmen | 192×64 |
| Eisen | `btn_iron_` | geschwärztes, genietetes Eisen | 192×64 |
| Wachssiegel | `btn_wax_` | rotes Siegellackrelief | 192×64 |
| Würfel | `btn_dice_` | Würfelsiegel in breiter Trägerplatte | **192×64** |
| Icon + Gold | `btn_icon_gold_` | kompaktes goldgraviertes Symbolfeld | 64×64 |

Für jeden Präfix: `normal.png`, `hover.png`, `pressed.png`, `active.png`, `disabled.png` — **30 Dateien**. Bei 192×64 wird `centerSlice: Rect.fromLTWH(24,20,144,24)` verwendet. Der beschriftete Würfelbutton wird im ersten Codeinkrement auf breit umgestellt, weil das bisherige 64×64-Quadrat sonst auf Textbutton-Breite verzerrt wurde.

## 4. KI-Bildprompts (Flux / DALL-E / Midjourney)

**Gemeinsamer Negativprompt** für sämtliche Assets: `no lettering, no words, no labels, no numbers, no watermark, no modern HUD, no game screenshot, no embedded icons unless explicitly specified`. Bildgeneratoren können keine technisch perfekte Transparenz oder 9-Slice-Randgeometrie garantieren. Entwürfe vor Integration freistellen, auf konsistente Maße bringen, Randzonen manuell schützen und auf Mobilgröße testen.

**Start-Szene (16:9, `--ar 16:9`)**

```text
Environment art only for a premium dark fantasy game-master mobile app.
Ancient ruined citadel beyond a moonlit valley; mist and subtle aurora;
rich engraved walnut side ornaments and understated antique brass insets;
central negative space for REAL Flutter text and controls; deep midnight
palette, warm amber window lights, sophisticated oil-painting realism,
cinematic lighting, 4k, no people, no text, no buttons, no watermark --ar 16:9
```

**Abenteuer (9:16, `--ar 9:16`)**

```text
Decorative vertical background texture only: moonlit ancient forest road,
distant torchlit tavern and scattered runestones, charcoal blue night,
soft arcane blue motes, ornate but low-contrast edges, generous dark
negative space in the middle for a readable interactive story, realistic
hand-painted medieval fantasy, no typography, no interface, no buttons,
no watermark --ar 9:16
```

**Kampf (16:9, `--ar 16:9`)**

```text
Low-contrast fantasy combat-board background for a functional battle HUD,
weathered slate and iron, subtle scratches and compass markings only at
outer edges, restrained ember sparks, amber and scarlet accent lighting,
empty clear center for initiative and character data, not a screenshot,
no text, no tokens, no characters, no watermark --ar 16:9
```

**Helden / Charakterbogen (3:4, `--ar 3:4`)**

```text
Medieval adventurer guildhall ledger background, aged parchment over dark
embossed leather, antique brass filigree in corners, subtle faded cartography
and quill marks, large clean central writing area, warm diffuse candlelight,
high material realism, no text, no portraits, no fields, no watermark --ar 3:4
```

**Chronik / Tagebuch (3:4, `--ar 3:4`)**

```text
Open ancient chronicle page made of beautiful natural parchment, worn edges
and faint watermarks, thin engraved border, tiny magical blue ink glints,
extraordinary legibility with a spacious blank central area, no written
words, no legible symbols, no buttons, no watermark --ar 3:4
```

**Einstellungen (9:16, `--ar 9:16`)**

```text
Quiet medieval alchemist's workbench background, dark walnut, muted
burnished brass, leather bookbinding, tiny magical inlays on the far
edges, vertically tiled composition, soft vignette, calm low contrast,
large uncluttered area for real controls, no text, no icons, no buttons,
no watermark --ar 9:16
```

**Holz-Messing-Button in fünf Varianten (einzeln generieren, `--ar 3:1`)**

```text
A single isolated front-facing elongated ornate game UI button plate,
aged dark oak and walnut grain, symmetrical antique brass edge frame,
24 pixel equivalent unchanging end caps, ample perfectly plain central
area for an external software label, realistic miniature texture,
transparent alpha background, strict orthographic straight-on view,
no lettering, no glyphs, no text, no shadow outside alpha --ar 3:1
```

Für `hover`: `slightly luminous polished brass rim and gentle cyan sparkle`; für `pressed`: `recessed plate, compressed inner shadows, stronger edge glow`; für `active`: `persistent engraved arcane glow`; für `disabled`: `desaturated matte gray brass, low contrast but readable silhouette`. Für Arkan/Eisen/Wachs/Würfel/Icon die Materialphrase entsprechend ersetzen, die Abmessungen und Zustandsdefinition unverändert lassen. **Längliche 9-Slice-Bilder vor der App-Integration unbedingt auf skalierbare Mittelzonen kontrollieren.**

**Icon-Button (`--ar 1:1`)**

```text
Isolated single square medieval brass icon socket, dark iron inset,
tiny symmetrical corner filigree, blank middle reserved for external
Flutter icon, transparent background, orthographic centered flat plate,
photorealistic PBR material, crisp at 64px, no icon, no lettering --ar 1:1
```

**Wachssiegel (`--ar 3:1`)**

```text
Single isolated horizontal fantasy confirmation button plate, red sealing
wax inset into dark weathered iron, rounded polished bronze end caps,
subtle relief texture only in the perimeter, large clear center for
software text, transparent background, strict front view, no text --ar 3:1
```

## 5. Flutter-Integrationsvertrag

- Vorhandene `FantasyButton`-Familie weiterverwenden: Hintergrund per `FantasyButtonAssets.path(style,state)`, zentrierter Text/Icon, `InkWell` für Touch/Keyboard/Hover, `AnimatedScale(.965)` bei Druck, optionale `onSound`-Callback, und deaktivierte `onPressed: null`-Semantik.
- Für breite Buttons 9-Slice mit `Rect.fromLTWH(24,20,144,24)`, für reine Iconbuttons 64×64 ohne 9-Slice.
- Buttons und Story-/Regellogik getrennt halten: bestehende Callback-Körper, Busy-Gates, Bestätigungsdialoge, Werte und lokale Speicherung nicht verändern.
- Migration in kleinen überprüfbaren Schritten: **A)** Startaktionen; **B)** Würfeldialoge und pinned action bar; **C)** Charaktereditor/-bogen; **D)** Tagebuch; **E)** Einstellungen und Spezialdialoge. Nicht blinde globale Widget-Ersetzung.
- Vorhandene `pubspec.yaml`-Assetregistrierung ist ausreichend. Neue zukünftige Unterordner müssen explizit aufgenommen oder unter bereits registrierten Ordnern abgelegt werden.

## 6. Abnahme und Nachweise

1. `python3 scripts/generate_fantasy_buttons.py` erzeugt 30 PNGs in definierten Größen.
2. `python3 -m unittest discover -s scripts/tests -v` prüft die Generator-Kontrakte.
3. `flutter analyze`, `flutter test`, `flutter build apk --debug` und Android-Geradichteprüfungen auf 320 / 360 / 920 dp.
4. Interaktion: Hover/Fokus/Pressed/Selected/Disabled, Offline-Fallback, keine durch Dekorgrafiken blockierten Pointer, keine Überläufe bei Textskalierung.
5. Datenintegrität: bestehende Charakter-, Kampf-, Story- und Backup-Regressionstests erfolgreich.

**Stand dieses PRs (22.10.2026):** dokumentierte IST-Analyse, Asset-/Prompt-Matrix, 9-Slice-Korrektur für beschriftete Würfelaktionen, Umstellung der ersten vier Startaktionen und **neun zusätzlicher Kampf-/Zauberdialoge** auf die existierenden zustandsabhängigen Fantasy-Texturen (Feuerpfeil, Heilige Flamme, Säurespritzer, Heilzauber, Magisches Geschoss, Schildreaktion, zusätzlicher Kreaturenangriff, Kreaturregistrierung und Initiative). Abbrechen/Schließen nutzt dabei Eisen, Magie arkanes Blau, Angriff Wachsrot, Registrierung Holz/Messing und Feuerpfeil die breite Würfelplatte. Bestehende Handler und ValueKeys bleiben erhalten; alte Widget-Typ-Assertions wurden migriert. Der alte Python-Test für Würfelgrafiken wurde an das neue 192×64-Format angepasst.

**Noch nicht enthalten:** vollständige neue Screen-Hintergründe, Austausch **aller** Dialogbuttons, fertig erzeugte KI-Produktionsgrafiken, vollständige manuelle Android-Geräteabnahme. **Kein Merge in `main` vor erfolgreicher CI.**

## 7. Phase 2 – bildgestützte Screens und Material-Panels (22.10.2026)

**Implementiert im Branch:**
- Neues `FantasyBackdropScene` mit `home`, `adventure`, `combat`, `heroes`, `journal` und `settings`. Die Zuordnung verwendet bereits lizenzierte/eingecheckte Artworks, keine erfundenen Asset-Pfade und keine externen Anfragen: Schattenwald für Abenteuer, Blutberge für Kampf, Burg für Helden, Vergessene Wälder für Tagebuch sowie Nachthimmel für Einstellungen. Die Startseite behält den vorhandenen mondbeschienenen Look.
- Je Szene unterschiedliche Farbverläufe; bestehende Bilder werden gedämpft und nach unten ausgeblendet, sodass Text und echte Widgets weiterhin lesbar bleiben. Ein eigener Vektor-Painter zeichnet dezente, skalierbare Messing-/Arkan-Rahmen. Alle Ebenen sind `IgnorePointer`, die verwendeten Bilder `ExcludeSemantics`.
- Die Hauptnavigation in `app/lib/ui/app.dart` wählt das Szenenbild anhand des tatsächlichen Tabs. Die Kampfübersicht bekommt einen eigenen Kampfhintergrund; der eigenständige Charakterbogen nutzt das Heldenmotiv.
- `FantasyPanelMaterial` ergänzt `midnight`, `parchment`, `leather` und `iron`, ohne bestehende `FantasyPanel`-Aufrufer zu brechen. Der Abenteuerkopf verwendet Leder, die Tagebuchabschnitte gedämpftes Pergament mit vorhandener Ornamentkarte. Text bleibt weiterhin echtes Flutter-Textwidget, nie in Bitmap gerendert.
- Abenteuerinteraktionen `Handlung senden`, `Rückblick` und `Wurf durchführen` verwenden die vorhandene zustandsbasierte Fantasy-Button-Familie. Alle Callback- und Busy-Gates bleiben identisch.
- `app/test/fantasy_backdrop_scenes_test.dart` überprüft die Szene-Asset-Zuordnung, die Funktion von Aktionen auf allen sechs Hintergründen und die Bedienbarkeit aller vier Materialvarianten.

**Abgrenzung:** Die neuen Kompositionen **verwenden bereits eingecheckte Bilddaten**; maßgeschneiderte neue KI-generierte Illustrationen pro Screen werden in einem gesonderten, bildorientierten Schritt eingebunden. Diese Phase liefert integrierte Level-Stile und grafische Vektorrahmen, aber keine neuen extern generierten Binärdateien. `pubspec.yaml` braucht deshalb keine zusätzliche Asset-Registrierung.

**Build-Nachweise:** Das unmittelbar vorherige Inkrement war im GitHub-Actions-Lauf `39710113996` erfolgreich, einschließlich `flutter analyze`, `flutter test`, Android-Debug-APK, nativen Tests und Alpha-Artefakten. Für die **neuen Szenenänderungen** ist ein neuer CI-Lauf nötig und getrennt zu prüfen.

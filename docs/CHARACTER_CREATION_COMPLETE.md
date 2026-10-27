# Charaktererstellung – überprüfbare Teilabdeckung

Stand 27.10.2026, Version **0.8.43+93**, Branch
`feat/character-roll-provenance-20261027`, [PR #297](https://github.com/ManuEtt/Dnd/pull/297).
**Die gesamte Charaktererstellung ist nicht vollständig.** Dieser Dateiname
bezeichnet das Ziel, keinen erreichten Abschluss. Frühere Fassungen liegen unter
`docs/history/character_rolls_20261027T031103Z/` mit SHA256-Nachweis.

## Quelle und tatsächliche Basis

Offizielles [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), Wizards of the Coast
LLC, CC BY 4.0. Amtliche englische PDF:
https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf
(SHA256 `8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87`).
Erneut geprüft: gedruckte S. 21 Attributmethoden/Bonusgrenzen, S. 83 Hintergründe,
S. 84–86 Spezies einschließlich ihrer verpflichtenden Herkunftswahlen.
Lizenznachweis bleibt in `THIRD_PARTY_NOTICES.md` erhalten.

Main `4c2ad0ab8e00d22fac645c6f885c9f9cfcff2267` enthält bereits den über #279
integrierten Charakterstack #264/#272/#273/#275 und spätere Regelergänzungen.
Diese Funktionen werden verwendet, nicht erneut implementiert. Offene parallele
Klassen-/Story-/Material-PRs bleiben separat. Normale Main-Integration im eigenen
Branch, kein Main-Direktpush, kein Force-Push und keine fremde Branchlöschung.

## Paket: sicherer Attributentwurf und lesbare Herkunft

1. Die drei vorhandenen offiziellen Methoden bleiben erhalten: Standardsatz,
   27-Punkte-Kauf und sechsmal 4W6, jeweils drei höchste Würfel. Grundwerte,
   Hintergrundbonus und spätere aktuelle Werte sind getrennt.
2. Beim Wurf wird zuerst ein vollständiger gültiger Satz erzeugt. Fehlgeschlagene
   Zufallsquellen lassen Methode, Punktentwurf und Charakter unverändert;
   deutsche Live-Fehlermeldung und neuer Versuch sind möglich. Ein erfolgreicher
   Satz bleibt während desselben Dialogs auch beim Methodenwechsel erhalten.
   Abbruch und erneutes Öffnen sind kein dauerhaftes Würfelprotokoll.
3. `StartingAbilityOrigin.rolledScores` liefert unveränderliche aufgezeichnete
   Summen ohne erneutes Würfeln. `fromJson` verlangt Version als int 1 und prüft
   weiterhin Methoden, Würfel, Multiset, zulässige Boni und Obergrenze 20.
   Die Struktur ist ein validierter Importdatensatz, kein kryptografischer
   Echtheitsbeweis fremder Würfe.
4. `StartingAbilityOriginPanel` im echten `CharacterSheetPage` zeigt Basis +
   Hintergrund = Startwert sowie sämtliche Rohwürfel. Ein Stufe-5-Charakter darf
   heute STR 20 haben und historisch STR 19 anzeigen. Öffnen/Schließen und
   Scrollen ändern keine JSON-Daten. Altcharaktere erhalten kein neues Feld.
5. Tatsächlich gefundene Überläufe im Fantasy-Theme bei 200 % Schrift repariert:
   Attributkartenhöhe und Panelüberschriften/-navigation, Touchflächen ≥48 dp.
   Schnellaktionen anderer Bereiche werden nicht verändert.

Code: `app/lib/domain/starting_ability_origin.dart`,
`app/lib/ui/ability_assignment_dialog.dart`,
`app/lib/ui/starting_ability_origin_panel.dart`,
`app/lib/ui/fantasy_character_sheet.dart`,
`app/lib/ui/fantasy_character_overview.dart`.

## Ist-Soll-Matrix

Die Statusgruppen sind **vollständig implementiert und getestet** (nur enger
benannter Teilmechanismus), **teilweise implementiert**, **vorhanden, aber ohne
funktionierende Regelwirkung**, **fehlend** und **blockiert**. Nicht geprüftes
Material bleibt ausdrücklich offen; ein Katalog oder Dateiname ist kein Beleg.

| Anforderung / bestehende Register-ID | Ist-Zustand | Konkrete Pflichtlücke |
| --- | --- | --- |
| Attribute / `RULE-CHARACTER-CREATION-ABILITY-SCORES` | teilweise; alle drei Methoden, bestätigte Herkunft und Anzeige vorhanden | Gesamt-Audit, persistenter unbestätigter Entwurf und endgültige CI-Abnahme |
| Historische Anzeige / `CHAR-ABILITY-SOURCE-DISPLAY` | enger Teilmechanismus lokal getestet | endgültige Branch-CI und Realgerät getrennt offen |
| Klassen/Herkunft / `RULE-CHARACTER-CREATION-CLASS-AND-ORIGIN` | teilweise | vollständige Spezies-/Klassen-/Talententscheidungen |
| Ausrüstung / `RULE-CHARACTER-CREATION-EQUIPMENT-CHOICES` | teilweise | vollständiger klassenübergreifender Herkunfts-/Doppelwahl-Nachweis |
| Start-TP / `RULE-CHARACTER-CREATION-STARTING-HIT-POINTS` | teilweise | vollständige Kombination mit Spezies-/Talentmodifikatoren |
| Stufenaufstieg / `RULE-CHARACTER-CREATION-LEVEL-ADVANCEMENT` | teilweise | sämtliche verpflichtenden Feature-/Unterklassenentscheidungen |
| Mehrklassen / `RULE-CHARACTER-CREATION-MULTICLASS-REQUIREMENTS` und `-PROFICIENCIES`, `-SPELLCASTING` | teilweise | vollständige kombinierte Pflichtwahl-/Ressourcenabnahme |
| Charakterbogen / `RULE-CHARACTER-CREATION-CHARACTER-SHEET` | teilweise | vollständiger abschließender Legalitätsnachweis |
| Origin-Feat-Vermerke | teilweise; einzelne Wirkungen bereits vorhanden | insbesondere Magic Initiate mit zwei Tricks, Grad-1-Zauber und Attributwahl |
| Vollständiger Schrittassistent mit Entwurf | fehlend als durchgehender Ablauf | Navigation, dauerhafter Entwurf, finale atomare Bestätigung |
| Umfassender Audit mit sieben Zuständen | teilweise: drei vorhandene Statuswerte | ungültig/abhängig/Hausregel/nicht-SRD; keine Bestätigung allein durch Zeichenfolgen |
| Echte Android-/TalkBack-Abnahme | blockiert | kein Gerät in dieser Sitzung |

Die ergänzenden `CHAR-*`-IDs stehen in `CHARACTER_CREATION_COVERAGE.json`;
übergeordnete `RULE-*`-IDs behalten ihre bisherige Bedeutung. Kein globaler
SRD-Fertigstellungsprozentsatz und keine Aussage, die Quelleninventur sei beendet.

## Alle zwölf Klassen

Gemeinsame Grundlage: `srd_character_classes.dart`, Klassen-/Fertigkeitsdialog,
`starting_hit_points.dart`, `srd_class_level_up.dart`, `multiclass_rules.dart`.
Vorhandene Fachtests sind in der JSON-Matrix verlinkt; sie beweisen keine
vollständige Ende-zu-Ende-Erstellung aller Klassen. Quelle jeweils SRD *Classes*.

| Klasse | Verifizierter Rahmen | Für vollständige Startentscheidung offen |
| --- | --- | --- |
| Barbar | Katalog, TP, Übungen, Ausrüstung; teilweise Features | vollständige Merkmals-/Ressourcen-/Waffenmeisterschafts-Abnahme |
| Barde | Katalog, TP, Übungen, Ausrüstung, Magiegrundlagen | Instrumente, vollständige Trick-/Zauberwahl und Startmerkmale |
| Kleriker | Katalog, TP, Übungen, Ausrüstung, Magiegrundlagen | vollständige Göttlicher-Orden-/Zauber-/Fokusentscheidungen |
| Druide | Katalog, TP, Übungen, Ausrüstung, Magiegrundlagen | vollständige Urorden-/Zauber-/Fokusentscheidungen |
| Kämpfer | zusätzlicher Stufe-1-Dialog für Stil, Meisterschaften und TP | vollständige kombinierte Herkunfts-/Talent-/Regelwirkung und E2E-Abnahme |
| Mönch | Katalog, TP, Übungen, Ausrüstung; einzelne Aktionen | vollständige Werkzeug-/Startmerkmalsintegration |
| Paladin | Katalog, TP, Übungen, Ausrüstung, Magiegrundlagen | vollständige Meisterschafts-/Zauber-/Fokusentscheidungen |
| Waldläufer | Katalog, TP, Übungen, Ausrüstung; spätere Features vorhanden | vollständige Stufe-1-Meisterschafts-/Zauberentscheidungen |
| Schurke | Katalog, TP, Übungen, Ausrüstung; einzelne Kampfregeln | vollständige Expertise-/Meisterschafts-/Startmerkmalsentscheidungen |
| Zauberer | Katalog, TP, Übungen, Ausrüstung, Magiegrundlagen | vollständige Tricks/Zauber, Fokus und Startressourcen |
| Hexenmeister | Katalog, TP, Übungen, Ausrüstung, Paktgrundlagen | vollständige Anrufungs-/Zauber-/Startentscheidungen |
| Magier | Katalog, TP, Übungen, Ausrüstung, Magiegrundlagen | Zauberbuch, Ritual-/Vorbereitungs-/Fokusentscheidungen vollständig |

Alle zwölf Klassen bleiben **teilweise implementiert**. Unterklassen werden
auf ihrer vorgeschriebenen Klassenstufe benötigt, nicht pauschal auf Stufe 1.
Einzelne spätere Kampfmerkmale ersetzen keine vollständige Charaktererstellung.

## Vier Hintergründe

Quelle SRD S. 83. Die bereits integrierten Module `srd_background_package.dart`
und `srd_background_package_dialog.dart` erzeugen Fertigkeiten, Werkzeugübung,
Talentvermerk und ausdrücklich gewählte Ausrüstung oder 50 Gold. Die gesonderten
Attributboni kommen aus dem Attributdialog. Pakete sind nicht automatisch
vollständige Talente; bestehende Charaktere werden nicht ungefragt geändert.

| Hintergrund | Vorhandene Paketwahl | Offene Entscheidung / Wirkung |
| --- | --- | --- |
| Akolyth | Übungen, Kalligrafie, Heiliges Symbol A oder Gold B | Magieinitiierter (Kleriker) vollständig wählen und regeltechnisch anwenden |
| Krimineller | Übungen, Diebeswerkzeug, Paket A / Gold B | vollständige Wachsam-Anbindung einschließlich zulässiger Initiativewahl nachweisen |
| Weiser | Übungen, Kalligrafie, Paket A / Gold B | Magieinitiierter (Magier) vollständig wählen und regeltechnisch anwenden |
| Soldat | Übungen, ausdrückliches Spielset, Paket A / Gold B | Wilder-Angreifer-Wirkung im tatsächlichen bestätigten Spielablauf vollständig anbinden |

## Neun Spezies und amtliche Varianten

Quelle SRD S. 84–86. Aktuell Bewegungsvorschläge und freie Identitätsangaben;
**keine** vollständige strukturierte Speziesauswahl mit allen Startmerkmalen.
Auch vorhandene allgemeine Resistenz-/Zaubermodule beweisen die Vergabe nicht.

| Spezies | Erforderliche amtliche Auswahl / Merkmale | Status |
| --- | --- | --- |
| Drachenblütiger | 10 Ahnen: Black, Blue, Brass, Bronze, Copper, Gold, Green, Red, Silver, White; passende Resistenz/Atemressource | teilweise, Merkmalswahl offen |
| Zwerg | Dunkelsicht, Giftwiderstand/-rettung, TP pro Stufe, Steingespür | teilweise, strukturierte Merkmale offen |
| Elf | Drow / High Elf / Wood Elf; Zauberattribut, Sinnesskill, Trance und Herkunftszauber | teilweise, Variantenentscheidungen offen |
| Gnom | Forest / Rock Gnome, Zauberattribut, Dunkelsicht, Gnomische Gerissenheit | teilweise, Variantenentscheidungen offen |
| Goliath | Cloud / Fire / Frost / Hill / Stone / Storm; Ressource, Powerful Build | teilweise, Herkunftsentscheidung offen |
| Halbling | Brave, Nimbleness, Luck, Naturally Stealthy | teilweise, Merkmalsvergabe/-wirkung offen |
| Mensch | Small / Medium, Fertigkeit, zusätzliches Herkunftstalent, Inspiration | teilweise, verpflichtende Auswahl offen |
| Ork | Adrenaline Rush, Dunkelsicht, Relentless Endurance | teilweise, Merkmalsvergabe/-ressourcen offen |
| Tiefling | Abyssal / Chthonic / Infernal; Small / Medium; Zauberattribut, passende Resistenz/Zauber | teilweise, Variantenentscheidungen offen |

## Tatsächlicher Testnachweis und Grenzen

92 gezielte Tests gemeinsam bestanden (Log
`/workspace/validation/20261027-character-combined.log`):
`ability_generation_test.dart`, `ability_random_generation_test.dart`,
`starting_ability_origin_test.dart`, `ability_storage_integration_test.dart`,
`ui_ability_assignment_test.dart`, `ui_random_ability_assignment_test.dart`,
`starting_ability_origin_panel_test.dart`, `fantasy_character_sheet_test.dart`,
`fantasy_character_reference_design_test.dart`, `fantasy_character_ornaments_test.dart`.

Das Paket prüft auch die echte Navigator-Route mit Fantasy-Theme, 320/360 dp,
200 % Schrift und unverändertes Charakter-JSON; Würfeldialog mit Tastatur.
Kein vollständiger Ende-zu-Ende-Assistent für alle zwölf Klassen behauptet.
Gesamtabnahme, finale CI und aktuelle APK-Nachweise werden im
[operativen Checkpoint](CODEX_CHECKPOINT.md) fortgeschrieben. Echtes Gerät,
TalkBack, Produktivsignatur und historisches Geräteupgrade bleiben offen.

## Genau nächster Implementierungsschritt

Nach grüner Abnahme von #297 den bestehenden `SrdCharacterCreationAudit`
überprüfbar erweitern: tatsächliche strukturierte Herkunft und verpflichtende
Auswahlen statt bloßer Spezies-/Hintergrundnamen bestätigen; sieben Zustände
modellieren, deutsche Fehlermeldungen und Negativ-/Legacy-Tests anbinden.
Danach Magic-Initiate- und Speziesentscheidungen als gesonderte vollständige
Pakete im geführten Entwurf. Vorher aktuelle Main-/PR-Arbeit erneut abgleichen.

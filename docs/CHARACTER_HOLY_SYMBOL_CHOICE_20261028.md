# Klassenstart: ausdrückliche Wahl des Heiligen Symbols

Stand 28.10.2026, Alpha 0.8.47+97; Arbeitsbranch
`feat/character-holy-symbol-choice-20261028`, Main-Basis
`37a6142ea791a607c78065b50aa66fda90acda5c`.

Regelquelle: [offizielles SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
Core Cleric Traits S.36, Core Paladin Traits S.53 und Holy Symbol S.97,
CC BY 4.0; Namensnennung in THIRD_PARTY_NOTICES.md unverändert.
Die Quelle wurde mit dem lokalen amtlichen Volltext abgeglichen; der amtliche
PDF-Endpunkt war am 28.10.2026 erneut mit HTTP200 erreichbar.

## Auswahl und Bestätigung

Kleriker/Paladin wählen für Klassenpaket A ausdrücklich Amulett, Emblem oder
Reliquiar. Kein Symbol ist vorausgewählt. Nur die drei bestehenden exakten
Katalog-IDs `item-holy-symbol-{amulet,emblem,reliquary}` sind zulässig; andere
Foki, Werkzeuge und unbekannte IDs werden vor Änderung des Entwurfs abgewiesen.
Die vorhandene deutsche Klassendialog-UI zeigt die zusätzliche Pflichtauswahl.
Vor der abschließenden Editor-Speicherung gibt es keine Persistenzänderung.

Typisiertes Inventar speichert den konkreten Katalogeintrag, Menge 1, Preis 500 KM,
Gewicht 1 lb/ungeklärt/2 lb und vorhandene Beschreibung. Der Preis wird nicht vom
Startgold abgezogen: das Symbol gehört zum Paket. Paket A enthält 7 GM beim
Kleriker und 9 GM beim Paladin. Paket B enthält 110/150 GM und keine Gegenstände.
Hintergrundausrüstung bleibt eine eigene Quelle, insbesondere das bestehende
Akolythensymbol. Beide erlaubten Quellen dürfen je ihr Symbol vergeben.

Ein echter Paket-/Klassenwechsel verwirft die unbestätigte Symbolwahl.
Erneute Auswahl desselben Pakets bewahrt die bereits getroffene Auswahl.
Erneute Klassenbestätigung nach Paketübernahme gewährt kein zweites Paket.

## Versionierung und Bestandsschutz

`StartingClassChoice.confirmed` erzeugt jetzt Version 2. JSON-Version 1 wird mit
ihrem ursprünglichen Vertrag eingelesen und unverändert ausgegeben. Alte
Symbole bleiben unbestimmte historische Gegenstände; sie werden weder geraten
noch nachträglich hinzugefügt. Der Audit berücksichtigt die Belegversion und
weist ungelöste v1-Symbole weiter als `notAutomated` aus. Ein v2-Paket-A-Beleg
benötigt dagegen die konkrete Auswahl. Unbekannte Versionen, unpassende IDs
und zusätzliche Fremdwahlen werden abgewiesen.

Die gekapselte Aktualisierung der Klassenentscheidungen erhält historische
Paketwahl und Version. Spätere Ausrüstungsausgaben/-verkäufe werden im Audit als
abweichend ausgewiesen, niemals zurückgesetzt. SQLite bleibt 3, äußeres JSON 1;
keine Datenbankmigration, kein Schreibzugriff beim Lesen.

## Nachweismatrix

| Teilanforderung | Register | Code/UI | Testnachweis | Status |
| --- | --- | --- | --- | --- |
| Beide Klassen, drei Symbolformen | EQUIP-CHOICES / CHAR-CLASS-HOLY-SYMBOL-CHOICE | starting_equipment_import.dart, srd_class_selection_dialog.dart, character_editor.dart | class_holy_symbol_choice_test.dart, srd_class_holy_symbol_dialog_test.dart, character_start_class_ui_test.dart | lokal gezielt geprüft; finale CI separat |
| Strenge v2-/kompatible v1-Belege | EQUIP-CHOICES | starting_class_choice.dart, srd_character_creation_audit.dart | alle zwölf historischen Klassen/Kits, falsche/fehlende IDs, Audit/Invarianz | lokal gezielt geprüft |
| SQLite/JSON/Revision/Retry/Bestand | EQUIP-CHOICES | vorhandener Controller/Repositoryvertrag | character_start_class_storage_test.dart | lokal gezielt geprüft |
| Android 320/360 dp, 200 % + IME/Semantik | EQUIP-CHOICES | bestehender scrollbarer Klassendialog | srd_class_holy_symbol_dialog_test.dart | Widgetprüfung; Realgerät offen |
| Vollständige Charaktererstellung/Zauberfokuswirkung | bestehende getrennte Anforderungen | Wizard/Klassen-/Zauberengine | zusätzliche Pakete nötig | teilweise/offen |

## Abnahme und Fortsetzung

Aktuelle Suite-/Build-/CI-Ergebnisse und Commit-SHAs werden im
[CODEX_CHECKPOINT](CODEX_CHECKPOINT.md) geführt. Frühere Tests/CI werden nicht
als Prüfung dieses neuen Produkts ausgegeben. Ein APK-Build ist kein Gerätetest.

Nächster begrenzter Charakter-Schritt: die im Mönch-Paket A gewählte
Werkzeug-/Instrumentausrüstung an die ausdrückliche Werkzeugübung koppeln.
Zuerst SRD S.49 prüfen; eigene versionierte Entscheidung, Bestandsverträglichkeit,
keine Nachvergabe, doppelte Übungen und SQLite-/UI-Gegenfälle nachweisen.
Bestehende Klassenbelege der Versionen 1 und 2 dürfen dabei nicht nachträglich
um neue Pflichtfelder verschärft werden. Vollständiger Wizard, Spezies-/Klassen-/
Talent-/Zauberpflichtwahlen bleiben offen.

# SRD 5.2.1 – Versionierter Klassen-Zaubervorbereitungsnachweis

**Chat A · 01.11.2026 · Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`
**Branch:** `feat/chat-a/class-prepared-spell-record-20261101`

## Quelle, Problem und Sicherheitsziel

Wizards of the Coast, *System Reference Document 5.2.1*,
*Multiclassing – Spellcasting – Spells Prepared*, gedruckte S. 25,
[offizielle SRD](https://www.dndbeyond.com/srd), CC BY 4.0.
Mehrklassenfiguren bestimmen erlaubte vorbereitete Zauber anhand der
jeweiligen **eigenen Klassenstufe**, nicht anhand der höheren
gemeinsamen Zauberplätze.

Bisher ist die historische `HeroCharacter.spells`-Liste ungetrennt.
Ein offener Chat-A-Vorläufer [#461](https://github.com/ManuEtt/Dnd/pull/461)
fordert daher bei Mehrdeutigkeit eine ausdrückliche Klassenbestätigung.
Damit bei zukünftigen bestätigten Vorbereitungen diese Zuordnung
**über einen Spielstandneustart erhalten** bleibt, benötigt die
Domäne eine strukturierte, versionierte Nachweisspur.

## Implementiert

- `SrdPreparedSpellRecord`: streng versioniertes Schema `1` mit
  **rohem** Haupt-/Zweitklassennamen, Gesamt-/Zweitklassenstufe,
  unveränderlichem Snapshot der bisherigen Zauberliste und
  expliziten Zuordnungen `spellsByClass` nach kanonischen
  SRD-Zauberklassen. Keine Alias-Normalisierung der *alten* Felder.
- `SrdClassPreparedSpellRules.confirm`: nur mit der ausdrücklich
  bestätigten Auswahl; **beide** eigenen Zauberklassen müssen
  bei Mehrklassenfiguren jeweils vertreten sein, selbst wenn
  eine leere Vorbereitung gewählt wurde. Der vorhandene
  SRD-Katalog liefert Klassenliste und Zaubergrad; die eigene
  Klassenstufe bestimmt den erlaubten Grad. Unbekannte Zauber,
  falsche Klassen, doppelte Alias-Namen, neue Namen außerhalb der
  vorhandenen `hero.spells`, unbekannte Zweitklassen und
  gefälschte Klassenkombinationen werden abgewiesen.
- `isPreparedForClass`: rein lesende, erneut gegen den
  Katalog geprüfte Antwort; **kein** Zauberausführungs-,
  Slotabbuchungs- oder automatischer Spell-Learn-Pfad.
- `HeroCharacter` speichert das optionale Feld
  `preparedSpellRecord` im **bestehenden** JSON-Schema 1.
  Fehlt es in einem älteren Spielstand, bleibt dessen JSON
  beim Lesen und Schreiben unverändert. Eine Änderung an
  Zauberliste/Klassen/Stufen über `copyWith` verwirft den
  veralteten Nachweis; reine TP-/Zauberressourcen-Änderungen
  erhalten ihn. Ein importierter widersprüchlicher Snapshot
  wird vor der Speicherung abgelehnt.
- Der vorhandene SQLite-Repository-Pfad speichert das
  Charakter-JSON ohne Schemawechsel; alte Revisionen, idempotente
  Wiederholungen und veraltete Schreibstände bleiben geschützt.

## Begrenzungen

Ein gespeicherter Vorbereitungsnachweis ist **keine fälschungssichere
Unterschrift** und ersetzt nicht die tatsächliche Spielerinteraktion.
Eine Wiederherstellung aus Legacy-Zaubern ohne ausdrückliche Auswahl
ist bewusst untersagt. *Noch nicht umgesetzt*: vollständige
tages-/klassenabhängige Anzahl vorbereitbarer Zauber,
Unterklassen-/Spezies-/Talentzauber, Wahlzeitpunkte,
externer Editor sowie die direkte Kopplung an
`SrdSpellPreflightRules.preflight` und die atomare Controller-/
SQLite-Aktionsbuchung. Gerade die Preflightdatei wird in
offenem PR #461 bearbeitet und darf hier nicht parallel
überschrieben werden.

Die Register-ID
`RULE-CHARACTER-CREATION-MULTICLASS-SPELLCASTING`
bleibt deshalb **unverified**. Keine neue globale
SRD-Vollständigkeitsquote ableiten.

## Regressionen und Koordination

Neun neue deterministische Testgruppen in
`app/test/srd_class_prepared_spell_record_test.dart`:
Bestätigen/Abbrechen, Aliase, Quellklassen, Dubletten, Stufengrenze,
schreibgeschützte Nachweise, Legacy-JSON, manipuliertes JSON,
SQLite-Neustart, idempotenter Retry und Revisionskonflikt.
Vollständige Projekt-/Flutter-/Android-Prüfungen ausschließlich
anhand des tatsächlich abgeschlossenen finalen
GitHub-Actions-Laufs als bestanden melden.

**Geänderte Domänenmodule:** neues
`srd_prepared_spell_record.dart`, neues
`srd_class_prepared_spell_rules.dart`, additiver optionaler
Charakterfeld-/JSON-Vertrag in `models.dart`, neue Tests.
**Nicht berührt:** bestehende Story-, UI-, Controller-,
Repository-, Engine- und Preflightdateien anderer offener PRs.
Gemeinsame README und Checkpoints sind bei Integration durch
Chat D additiv zusammenzuführen.

**Nächster unabhängiger Schritt:** die gespeicherte
Klassenzuordnung nach Integration von PR #461 im
Zauberpreflight statt einer einmaligen Bool-Bestätigung
prüfen, mit Revisions-/SQLite-/Mehrklassen-Gegenfällen.

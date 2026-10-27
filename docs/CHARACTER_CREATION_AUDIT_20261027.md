# Charakter-Audit mit belegten Teilentscheidungen

Stand 27.10.2026, Version 0.8.44+94. Gesamt-Charaktererstellung **unvollständig**.
Quelle: offizielles [SRD 5.2.1](https://www.dndbeyond.com/srd), Wizards of the
Coast LLC, CC BY 4.0; *Character Creation* S. 21, Hintergründe S. 83,
Spezies S. 84–86 und jeweilige Klassenanforderungen. Die amtliche PDF wurde
bereits anhand SHA256 `8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87`
gesichert; Namensnennung unter THIRD_PARTY_NOTICES.md bleibt erhalten.

## Abnahme dieses Pakets

Der alte Audit bestätigte ausgefüllte Felder: z. B. Speziesname, beliebiges
Inventar oder Gold 0. Diese Werte beweisen keine regelkonforme Startentscheidung.
Die Prüfung liest jetzt vorhandene versionierte Herkunfts-/Hintergrunddaten.
Sie gewährt keine Boni, speichert keinen abgeleiteten Auditstatus und erzeugt
kein Gesamt-SRD-Erfolgssiegel. SQLite 2 / JSON 1 brauchen keine Migration.

| Prüfzustand | Bedeutung |
| --- | --- |
| Bestätigt | Genau die benannte Teilentscheidung ist anhand der vorhandenen Daten belegt |
| Fehlt | Erforderliche Angabe oder Auswahl fehlt |
| Ungültig | Vorhandene Daten widersprechen sich oder verletzen geprüfte Grenzen |
| Weitere Auswahl nötig | Eine andere Entscheidung oder ein Nachweis wird zuerst benötigt |
| Nicht automatisiert | Angaben sind vorhanden, der vollständige Regelnachweis fehlt |
| Hausregel | Ausschließlich ausdrücklich aktivierte manuelle Attributwahl des aktuellen Entwurfs |
| Nicht im SRD | Keine Zuordnung zur unterstützten SRD-Auswahl, nicht still als offizielle Wahl bestätigt |

Auch eine bekannte Klassenbezeichnung bleibt ohne ausdrücklichen
Entscheidungsnachweis nicht automatisiert. Eine Editor-Vorauswahl ist keine
bestätigte Klassenwahl. Klassenfertigkeiten und Rettungswürfe
werden ohne quellengetrennten Nachweis nicht pauschal grün. Doppelte Übungen
(einschließlich Medizin-/Heilkunde-Alias) werden erkannt. Aus Hintergrundübungen
werden keine zusätzlichen Klassenübungen. Hintergrundausrüstung belegt kein
Klassenpaket. Ein bekannter Speziesname belegt keine Größe, Herkunft oder Talente.

Stufe-1-Attribute mit gültigem StartingAbilityOrigin müssen zum aktuellen
Entwurf passen. Ursprungswerte höherer Charaktere bleiben historisch; heutige
Attribute werden daraus nicht zurückgerechnet. Ohne Herkunftsnachweis wird
keine Erzeugungsmethode und ohne ausdrückliche Hausregelwahl kein Hausregelstatus
erfunden. Englische Hintergrundnamen werden für den lesenden Abgleich zugeordnet,
aber nicht im gespeicherten Charakter umgeschrieben.

## UI und Datenfluss

Der bestehende Editor-Button öffnet den neuen SrdCreationAuditDialog auf einem
lokalen Snapshot der **aktuellen ungespeicherten Felder**. Auch noch nicht gespeicherte
bestätigte Attributnachweise werden geprüft. Ungültige Zahlen melden einen Fehler,
statt null oder Standardwerte zu erfinden. Halbmeterschritte wie 10,5 m bleiben
in den vorhandenen Geschwindigkeitsfeldern erhalten. Der Dialog ist scrollbar,
alle sieben Zustände besitzen deutsche Semantik; Schließen ist bei 320/360 dp,
200 % Schrift und geöffneter Tastatur erreichbar.

Code: app/lib/domain/srd_character_creation_audit.dart,
app/lib/ui/srd_creation_audit_dialog.dart und CharacterEditor._inspectSrdCreation.
Übergeordnete Requirements: RULE-CHARACTER-CREATION-CHARACTER-SHEET und
RULE-CHARACTER-CREATION-CLASS-AND-ORIGIN bleiben **partial**. Ergänzende
CHAR-AUDIT-EVIDENCE-STATUSES in CHARACTER_CREATION_COVERAGE.json ist kein
Ersatz des bestehenden vollständigen Arbeitsregisters.

## Tatsächliche Prüfung

- srd_character_creation_audit_test.dart: alle zwölf Klassen, belegte Attribute,
  fehlende/inkonsistente Werte, unbekannte Namen, Alias-Doppelübungen,
  zweite Klasse auf Stufe 1, ungültige Aufteilung, spätere historische Werte.
- character_creation_audit_ui_test.dart: sieben Zustände/Semantik, kleine Displays,
  große Schrift, Tastatur, echte Editorentwürfe, halbmetergenaue Werte,
  fehlerhafte Zahlen, bestätigte noch nicht gespeicherte Attribute und Hausregel.
- character_creation_audit_persistence_test.dart: sechs SQL-Tabellen,
  Revisionen/Events, Archiv, Outbox, null Controller-Benachrichtigungen;
  SQLite-Neustart, JSON-Export/-Import und unveränderte historische Metadaten.

24 gezielte Fälle und vollständige lokale Suite mit **1.949 Flutter-, 164 Python-, 72 Backend- und zwölf native Android-Tests**
bestanden. Analyse/Format, Backend-Build und geprüfte Debug-APK grün.
Finale CI/Alpha-Artefakte im CODEX_CHECKPOINT bzw. PR #318 nachlesen.
Testdateiname allein ist kein bestandener Nachweis. Reales Android/TalkBack,
installiertes Upgrade und produktive Signatur bleiben offen.

## Ausdrücklich noch offen

Audit bleibt lesende Teilprüfung. Kein vollständiger geführter Assistent,
keine endgültige SRD-Freigabe und keine komplette Spezies-/Talent-/Zauberauswahl.
Nächster Baustein: konkrete erste Klassenentscheidung versioniert speichern,
vorhandene Dialoge wiederverwenden und mit SQLite/JSON-/Stale-Tests absichern.
Die vorhandene grobe HeroCharacter.isComplete-Eigenschaft ist kein vollständiger
SRD-Charaktererstellungsnachweis und wird nicht in diesen umgedeutet.

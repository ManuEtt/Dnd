# Ausdrücklich bestätigte Klassenstartentscheidungen

Stand: 27.10.2026. Dieses Paket ergänzt den bestehenden Charaktereditor um
einen dauerhaften, begrenzten Entscheidungsnachweis. **Die gesamte
SRD-Charaktererstellung ist weiterhin unvollständig.**

## Quelle und Geltungsbereich

Regelquelle ist das offizielle [D&D SRD 5.2.1](https://www.dndbeyond.com/srd)
von Wizards of the Coast LLC unter CC BY 4.0. Die geprüfte
[amtliche PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf)
hat SHA256
`8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87`.
Die Seiten unten wurden im PDF-Text anhand der Formfeed-Seitentrennung und
des jeweils gedruckten Fußzeilentitels „System Reference Document 5.2.1“
abgeglichen. Die Namensnennung in `THIRD_PARTY_NOTICES.md` bleibt erhalten.

*Character Creation / Step 1: Choose Class*, S. 19, verlangt die Klassenwahl
und verweist auf die Klassenregeln. Die jeweiligen *Core … Traits*-Tabellen
führen Klassenfertigkeiten, Rettungswurfübungen und Startpakete auf. Dieses
Paket dokumentiert die tatsächliche Bestätigung dieser vorhandenen Auswahlen;
es ist keine neue Implementation sämtlicher dort genannten Klassenmerkmale.

Ergänzende Requirement-ID: `CHAR-CLASS-START-CHOICE-EVIDENCE`.
Übergeordnete Anforderungen
`RULE-CHARACTER-CREATION-CLASS-AND-ORIGIN` und
`RULE-CHARACTER-CREATION-CHARACTER-SHEET` bleiben **partial**.
Die bestehenden SRD-Register werden dadurch nicht ersetzt; aus den zwölf
Klassenfällen folgt kein globaler SRD-Fertigstellungsgrad.

## Nachweistabelle der zwölf Klassen

„Belegt“ bezeichnet hier ausschließlich die ausdrücklich bestätigte Klasse,
die vorgeschriebene Klassenfertigkeitswahl, die dazugehörigen
Rettungswurfübungen und eine gegebenenfalls bestätigte Paketentscheidung.
Automatische Kampf-, Zauber-, Werkzeug- oder Klassenmerkmalwirkungen sind
dadurch nicht vollständig nachgewiesen.

| Klasse | SRD-Seite: Core Traits | Klassenfertigkeiten | Rettungswurfübungen | Paketnachweis und verbleibende Grenze |
| --- | ---: | --- | --- | --- |
| Barbar | 28 | 2 aus der Klassenliste | Stärke, Konstitution | A-Ausrüstung oder B-Gold; strukturierte Gegenstände und Gold lesend prüfbar |
| Barde | 31 | 3 unterschiedliche Fertigkeiten | Geschicklichkeit, Charisma | A mit ausdrücklich gewähltem Instrument oder B-Gold; drei Instrumentenübungen sind ein eigener offener Startumfang |
| Kleriker | 36 | 2 aus der Klassenliste | Weisheit, Charisma | A oder B-Gold; „Heiliges Symbol“ in Klassenpaket A hat noch keine konkret gespeicherte Variantenwahl |
| Druide | 41 | 2 aus der Klassenliste | Intelligenz, Weisheit | A oder B-Gold; „Druidischer Fokus (Kampfstab)“ ist noch kein aufgelöster strukturierter Kataloggegenstand |
| Kämpfer | 47 | 2 aus der Klassenliste | Stärke, Konstitution | A/B-Ausrüstung oder C-Gold; bestätigter Kampfstil und drei Waffenmeisterschafts-IDs werden zusätzlich gespeichert, ihre vollständigen Kampfwirkungen sind damit nicht implementiert |
| Mönch | 49 | 2 aus der Klassenliste | Stärke, Geschicklichkeit | A mit ausdrücklich gewähltem SRD-Handwerkszeug oder Instrument oder B-Gold; vollständige Werkzeugübungen und übrige Startmerkmale bleiben getrennt zu prüfen |
| Paladin | 53 | 2 aus der Klassenliste | Weisheit, Charisma | A oder B-Gold; „Heiliges Symbol“ in Klassenpaket A bleibt als Variantenwahl offen |
| Waldläufer | 57 | 3 aus der Klassenliste | Stärke, Geschicklichkeit | A oder B-Gold; „Druidischer Fokus (Mistelkraut)“ bleibt strukturell unaufgelöst |
| Schurke | 61 | 4 aus der Klassenliste | Geschicklichkeit, Intelligenz | A-Ausrüstung oder B-Gold; Expertise und sämtliche weiteren Startmerkmale sind kein Bestandteil dieses Nachweises |
| Zauberer | 64 | 2 aus der Klassenliste | Konstitution, Charisma | A-Ausrüstung oder B-Gold; Zauberauswahl, Zauberressourcen und weitere Startmerkmale bleiben eigenständige Anforderungen |
| Hexenmeister | 70 | 2 aus der Klassenliste | Weisheit, Charisma | A-Ausrüstung oder B-Gold; Paktmagie und weitere Pflichtentscheidungen sind dadurch nicht vollständig belegt |
| Magier | 77 | 2 aus der Klassenliste | Intelligenz, Weisheit | A oder B-Gold; „Zauberbuch“ im Klassenpaket bleibt strukturell unaufgelöst; Buchinhalt, Zauberauswahl und Vorbereitung bleiben separate Entscheidungen |

Die Domainfälle durchlaufen alle zwölf Klassen und deren vorhandene
Startpakete. Die Mönch-Paketwahl ist auf die 17 SRD-Handwerkszeuge und zehn
Musikinstrumente begrenzt (Werkzeug-/Instrumentenregeln S. 93–94); Diebes-, Kräuterkunde- und Navigationswerkzeug
sind dafür keine zulässigen Ersatzwahlen. Bei unaufgelösten Gegenständen bleibt der Ausrüstungs-Audit
**nicht automatisiert**. Ein passender Freitextname genügt nicht, um das Paket
als vollständig strukturiert vorhanden zu bestätigen. Insbesondere ist die
bereits vorhandene Symbolwahl des **Akolythen-Hintergrunds** keine Lösung der
separaten Heiligen-Symbol-Wahl in den Klassenpaketen von Kleriker und Paladin.

## Code, UI und Zustandsänderung

`app/lib/domain/starting_class_choice.dart` enthält die unveränderliche
`StartingClassChoice`. Sie prüft den kanonischen Klassennamen, die genaue
Anzahl unterschiedlicher zulässiger Klassenfertigkeiten, den Paketindex,
zulässige konkrete Ausrüstungs-IDs und die Kämpferentscheidungen. Andere
Klassen dürfen keine Kämpferentscheidungen mitführen.
`StartingEquipmentImport.optionsFor` verwendet für die Mönchwahl eine
explizite Handwerkszeug-Whitelist statt aller Gegenstände der Werkzeugkategorie. Ohne gewähltes Paket
dürfen auch keine konkreten Paketgegenstandswahlen gespeichert werden.

`SrdClassSelectionDialog._accept` erstellt den Nachweis ausschließlich nach
ausdrücklicher Bestätigung einer **neuen Stufe-1-Erstellung**. Die Auswahl
einer bekannten Klasse im Katalog oder ein voreingestellter Editorwert
erzeugen ihn nicht. Bestehende historische Charaktere erhalten beim erneuten
Bestätigen des Dialogs keinen erfundenen ursprünglichen Startnachweis.

`CharacterEditor._configureSrdClass` bereitet die vollständige Übernahme zunächst
lokal vor. Erst nach erfolgreicher Prüfung werden die betreffenden
Editorfelder gemeinsam aktualisiert. Abbruch erzeugt weder Nachweis noch
Ausrüstung oder Gold. Die vorhandene Vergabelogik für Fertigkeiten,
Rettungswürfe, optionale Start-TP und Ausrüstung wird weiterverwendet.
`StartingClassChoice` selbst vergibt **keine** Werte oder Gegenstände.

Die erneute Bestätigung derselben Klasse bewahrt eine bereits gewählte
Paketquelle und vergibt sie nicht erneut. Bei einer neuen Fertigkeitswahl
werden die zuvor dieser Klassenquelle zugeordneten Übungen ersetzt, statt
sie unbegrenzt anzusammeln; eigenständige Hintergrundübungen bleiben erhalten. Ein bereits übernommenes Paket
darf in diesem Paket nicht einer anderen Startklasse zugeordnet werden;
die UI weist darauf hin, den Entwurf für eine andere Startklasse neu zu
beginnen. Die sichere nachträgliche Rücknahme und der Austausch einer
kompletten Startausrüstung sind damit noch nicht umgesetzt.

Beim Speichern eines neuen Entwurfs müssen Klasse, Stufe und bestätigte
Klassenübungen weiterhin zum Nachweis passen. Bestätigte Klassen- und
Hintergrundfertigkeiten dürfen sich nicht überdecken. Eine spätere
Charakteränderung behält den historischen Nachweis, ohne daraus neue
Vergaben oder eine Rückrechnung heutiger Werte auszulösen.

Der lesende `SrdCharacterCreationAudit` kann die genau passenden
Teilentscheidungen bestätigen. Fehlende Übungen oder eine widersprüchliche
Startklasse werden sichtbar. Für Ausrüstung werden die erwarteten
Katalog-IDs, typisierten Werte, Mengen und das Paketgold gegen den aktuellen
Charakter geprüft. Abweichungen durch Verbrauch oder spätere Änderungen
werden nicht rückgängig gemacht. `class.choices` und `origin.feat` bleiben
separat **nicht automatisiert**; ein Gesamt-SRD-Erfolgssiegel gibt es nicht.

## Speicherung und Kompatibilität

Das neue optionale Feld `HeroCharacter.startingClassChoice` ist Teil des
bestehenden Charakter-JSONs. Beispiel eines ausdrücklich gewählten
Barbaren-Goldpakets:

```json
{
  "startingClassChoice": {
    "version": 1,
    "className": "Barbar",
    "skills": ["Athletik", "Wahrnehmung"],
    "kitIndex": 1,
    "equipmentChoices": {}
  }
}
```

`kitIndex: null` bedeutet, dass dieser Beleg noch keine Startpaketwahl
enthält. `fighterChoices` enthält beim Kämpfer zusätzlich `styleId` und
genau drei `masteryWeaponIds`. `version` und Paketindex müssen echte
Ganzzahlen sein; unbekannte Versionen und manipulierte Wahlwerte werden
abgewiesen. Das ist eine Struktur-/Regelprüfung gespeicherter
Spielerentscheidungen, keine kryptografische Herkunftsbestätigung.

Ältere JSONs ohne das Feld bleiben unverändert ladbar. `copyWith` bewahrt
einen vorhandenen Beleg, solange er nicht ausdrücklich ersetzt oder gelöscht
wird. Der Beleg bleibt historisch: spätere Klassen-, Attribut-, Gold- oder
Inventaränderungen führen beim Laden zu keiner erneuten Anwendung.

Es gibt **keine SQLite-Schemaänderung oder neue Datenbankmigration**.
Die bestehende Datenbankversion 2 und JSON-`schemaVersion: 1` bleiben
unverändert. Das optionale Feld wird in den vorhandenen JSON-Snapshots
gemeinsam mit dem Charakter gespeichert. Kampagne, Heldenarchiv,
Revisionssnapshot und Ereignisse nutzen die bestehende Transaktion.

## Automatisierte Nachweise und deren Grenzen

| Testdatei | Konkret abgedeckter Umfang | Nachweis beim Schreiben dieses Fachstands |
| --- | --- | --- |
| `app/test/starting_class_choice_test.dart` | zwölf Klassenfälle mit allen vorhandenen Paketen und JSON; unveränderlicher Beleg ohne Vergabe; strenge Version/Wahlprüfung; konkrete Instrumentwahl, unzulässige Mönchwerkzeuge; Widersprüche, Hintergrundüberschneidungen und Freitextgegenstände | 17 Fälle lokal erfolgreich; finale CI separat |
| `app/test/character_start_class_storage_test.dart` | Archiv/Kampagne/Revision/SQLite-Neustart und beide JSON-Roundtrips; spätere historische Änderungen; Alt-JSON; sechs Manipulationen jeweils als Helden- und Kampagnenimport; identischer Snapshot-Retry und veraltete Repositoryrevision; tatsächlicher später SQLite-Archivfehler mit vollständigem Rollback | sechs Fälle lokal erfolgreich ausgeführt; scoped Dart-Analyse ohne Befund |
| `app/test/character_start_class_ui_test.dart` | echte Editorbestätigung, Gold-/Ausrüstungspaket ohne Doppelvergabe, Klassenwechselkonflikt, manueller Widerspruch, Abbruch, Legacy und 320/360 dp mit 200 % Schrift, Tastatur und Semantik; Gegenfälle zur Übungsansammlung bei neuer Fertigkeitswahl und beim Klassenwechsel vor der Paketwahl | elf Fälle lokal erfolgreich; finale CI separat |

Neue Testdateien allein beweisen keine erfolgreiche Gesamt-CI.
Vollständige Flutter-/Python-/Backendprüfungen, APK-Build, native Android-Tests
und der endgültige GitHub-Actions-Lauf sind getrennt im aktuellen
`docs/CODEX_CHECKPOINT.md` und Pull Request zu dokumentieren. Ein Erfolg
früherer Charakterpakete gilt nicht als Abnahme dieses neuen Stands.

**Editor-CAS ist nicht gelöst:** `GameController.saveHero` nimmt derzeit keine
erwartete ursprüngliche Editorrevision entgegen. Der Storage-Test belegt die
vorhandene Repositoryprüfung veralteter Kampagnenrevisionen; er beweist nicht,
dass ein lange geöffneter alter Editorheld nicht später über den aktuellen
Controllerstand gespeichert werden kann. Dafür ist ein eigenes kleines
Integrationspaket erforderlich. Auch das alleinstehende Heldenarchiv besitzt
hier keinen neuen Compare-and-Swap-Vertrag.

Nicht durch dieses Paket abgenommen sind ein echter Android-Gerätetest,
TalkBack auf dem Gerät, ein installiertes Altversionsupgrade und produktive
Signierung. Die vollständige Führung durch sämtliche Spezies-, Klassen-,
Werkzeug-, Talent-, Zauber- und Ausrüstungsentscheidungen bleibt offen.
Der separate [PR #317](https://github.com/ManuEtt/Dnd/pull/317) bearbeitet
Magieinitiierter-Auswahlen für Akolyth/Weiser; dessen Änderungen werden hier
weder unabhängig neu entwickelt noch als Bestandteil dieses Nachweises
ausgegeben. Der nächste fachliche Ausrüstungsbaustein ist die konkrete,
typisierte Klassenstartwahl bislang unaufgelöster Symbole und Foki; ein
vorhandener Katalogname darf diese Prüfung nicht ersetzen.

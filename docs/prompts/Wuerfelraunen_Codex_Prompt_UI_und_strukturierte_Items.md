Codex-Entwicklungsauftrag – Würfelraunen: Abenteuer-Schnellaktionen und vollständig strukturierte Item-Werte
Repository: https://github.com/ManuEtt/Dnd
Sprache: Deutsch für UI, Meldungen und Dokumentation
Zielplattform: Android / Flutter / Dart
Ausführung: Im nächsten Codex-Lauf dieses Repositorys, ohne Rückfragen bei gewöhnlichen technischen Entscheidungen
0. Vorbereitung und Arbeitsregeln
Lies zuerst AGENTS.md, die Projektdokumentation, den aktuellen Branch/Commit und, soweit vorhanden, docs/prompts/Wuerfelraunen_Codex_Masterprompt_Autonome_Entwicklung.md sowie CHECKPOINT.md.
Analysiere den tatsächlichen Quellcode, bevor du Klassen oder Dateien veränderst. Vorhandene Funktionalität erweitern, nicht doppelt implementieren.
Bewahre Spielstände, Backend-Verträge, Domain-/Regellogik, vorhandene Katalogeinträge und das dunkle Fantasy-Design.
Bevorzugt auf einem Entwicklungsbranch arbeiten. main nicht ungeprüft überschreiben.
Diese beiden Arbeitspakete sind verbindlich. Implementiere sie tatsächlich, ergänze Tests und überprüfe ihre Integration.
A. Schnellaktionsleiste nur auf der Abenteuer-Hauptansicht
Die zusätzliche Abenteuer-Schnellaktionsleiste (Würfeln, Sprache/Mikrofon, Untersuchen, Interagieren und sonstige Abenteueraktionen) darf ausschließlich in der eigentlichen Abenteuer-Hauptansicht vorhanden sein.
Dort ist sie dauerhaft unten fixiert, auch während die Erzählung scrollt.
In allen anderen Ansichten darf sie weder sichtbar sein noch in einem übergeordneten Layout mitgeführt werden: Start, Helden, Charakterbogen, Kampagnenverwaltung, Tagebuch, Einstellungen, separate Kampf-/Initiativeansichten, Würfel, Zauber, Monster, Gegenstände, Regelkompendium sowie Detailansichten und Dialoge.
Nicht verwechseln: Die normale untere Hauptnavigation bleibt bestehen; ebenso bildschirmbezogene Aktionen wie „Charakter bearbeiten“. Nur die zusätzliche Abenteuer-Schnellaktionsleiste wird eingeschränkt.
Prüfe app/lib/ui/app.dart, _AdventurePage, FantasyPinnedActionBar, Navigation und app/lib/ui/fantasy_ui.dart.
Behalte die Leiste im Scaffold.bottomNavigationBar der Abenteuerseite statt in der globalen App-Shell. Falls sie bereits korrekt ausschließlich dort aufgebaut wird, bewahre diese Architektur und schreibe Regressionstests statt sinnlose Umbauten vorzunehmen.
Nutze bei Bedarf ValueKey('adventure-quick-actions'), um die Leiste eindeutig zu testen.
SafeArea, Android-Gestenleiste, Bildschirmgrößen 320/360/400 dp, Querformat, große Systemschrift und Bildschirmtastatur dürfen weder die Eingabe noch die Aktionsleiste unbedienbar machen.
Belasse alle echten Action-/Busy-/Disabled-Zustände mit Anbindung an die Domain-Engine. Keine bloß dekorativen Schnellaktionen.
B. Items: Jeder regelrelevante Wert als eigenes, typisiertes Feld
Sehr wichtige neue Vorgabe: Für alle Gegenstandskategorien (Waffen, Rüstungen, Schilde, Munition, Werkzeuge, Ausrüstung, Tränke, Verbrauchsgegenstände, magische Gegenstände usw.) müssen sämtliche vorhandenen regelrelevanten Einzelwerte als getrennte, typisierte Datenfelder gespeichert und im UI separat dargestellt und, soweit sinnvoll, separat bearbeitet werden.
Der Beschreibungstext darf keine Ersatz-Datenbank für Werte sein. Er enthält nur Fließtext wie Herkunft, Aussehen, Geschichte, atmosphärische Beschreibungen oder erklärende Hinweise. Es dürfen insbesondere nicht ausschließlich als Fließtext im Beschreibungsfeld stehen: Schaden, Würfel, Schadensart, Reichweite, Eigenschaften, Waffenmeisterschaft, Rüstungsklasse, Bonus, Gewicht, Preis, Stückzahl, Seltenheit, Aufladungen, Heilung, Voraussetzungen, Wirkungsdauer oder ähnliche mechanische Werte.
1. Vorhandene Architektur korrekt nutzen
Prüfe insbesondere:
app/lib/domain/srd_equipment_catalog.dart (EquipmentEntry mit bereits vorhandenen Feldern wie priceCp, weightLb, damage, damageType, twoHandDamage, properties, mastery, rangeNormal, rangeLong, ammunitionType, armorBaseAc, dexCap, strengthMin, stealthDisadvantage, note).
app/lib/domain/models.dart (InventoryItem enthält bisher insbesondere id, name, quantity, description, catalogId).
app/lib/domain/equipment_rules.dart, Gegenstandslisten/-details, Charaktereditor, Inventar, Ausrüstungsvorschau, Speicher- und Import-/Exportpfade.
Wichtig: Der Katalog hat bereits mehrere einzelne Felder; diese Daten dürfen nicht wieder in eine freie Textbeschreibung zusammengezogen werden. EquipmentEntry.detail baut aktuell eine kombinierte Textzeile zusammen: Die Benutzeroberfläche soll stattdessen die zugrunde liegenden Werte als einzeln beschriftete Felder/Karten rendern. Ein zusammenfassender, rein lesbarer Anzeigetext darf optional bestehen bleiben, darf aber niemals Datenquelle der Regelengine sein.
2. Datenmodell und Speicherung
Baue ein erweiterbares, typisiertes Itemmodell mit gemeinsamen Basisfeldern und kategoriespezifischen Wertegruppen. Verwende konsistente Dart-Klassen/Enums, validierte JSON-Serializer und klare Einheiten. Vermeide eine einzige untypisierte Map<String, dynamic> oder ein Feld wie sonstigeWerte, in dem alle eigentlichen Regeln versteckt werden.
Gemeinsame Felder: stabile ID, Katalogreferenz, Name, Kategorie, Anzahl, Preis mit Währung/Einheit, Gewicht mit Einheit, Quelle/SRD-Referenz, Seltenheit (falls relevant), Beschreibung als ausschließlich narrativer Text.
Waffen: Schadensausdruck getrennt vom Schadensart-Enum, alternativer Schaden (z. B. vielseitig), Nah-/Fernkampf, Waffenklasse, Waffenmerkmale als strukturierte Liste, Meisterschaft, normale/maximale Reichweite und Einheit, Munitionstyp/-verbrauch, magischer Angriffs- und Schadensbonus, Anforderungen/Handhabung.
Rüstung und Schilde: Rüstungskategorie, Basis-RK oder Schildbonus separat, Begrenzung des GE-Bonus, Stärkeanforderung, Heimlichkeitsnachteil, ggf. magischer RK-Bonus, Anlege-/Ablegezeit soweit die verwendete SRD-Datenquelle sie enthält, Anforderungen.
Verbrauchs- und magische Gegenstände: Verbrauch pro Anwendung, Heil-/Effektwürfel separat, Nutzungen/Ladungen, maximale Ladungen, Aufladebedingung, Dauer, Rettungswurf-SG falls angegeben, Einstimmung (Bool/Anforderungen), Magie-Boni, verknüpfte strukturierte Effekte mit Wirkungstyp/Parametern. Keine Wirkungen frei aus Beschreibungstext ableiten.
Sonstige Gegenstände: Alle tatsächlich vorhandenen tabellarischen oder regelwirksamen Größen als eigene Felder, ggf. in geeigneten Untertypen (z. B. Kapazität, Lichtreichweite, Traglast, Mengen-/Maßeinheit); nicht jedes Feld für jedes Item erzwingen.
Verwende für unbekannte Angaben null/unknown statt ausgedachter Nullen oder frei erfundener Werte.
Unterscheide offizielle Katalogwerte, Instanzzustand (z. B. verbleibende Ladungen, Stückzahl) und individuelle Overrides bei benutzerdefinierten Gegenständen. Ändere nicht unbeabsichtigt den globalen SRD-Katalog, wenn ein Spieler seinen Gegenstand anpasst.
Bewahre bestehende catalogId-Referenzen; übernimm bestätigte Katalogwerte in die Anzeige, ohne duplizierte Widersprüche zu erzeugen.
Erhalte ältere Spielstände und JSON-Backups. Implementiere idempotente Migration bzw. rückwärtskompatibles Deserialisieren. Vorhandene Beschreibungen niemals ersatzlos löschen. Nur eindeutig und zuverlässig erkennbare Altwerte in strukturierte Felder übernehmen, keine unsichere Interpretation von freiem Text.
Regelberechnungen müssen die strukturierten Werte nutzen, niemals Texte mittels Regex o. ä. als Regelquelle auslesen.
3. Neue Darstellung und Bearbeitung in der App
Jedes Item erhält eine klar gegliederte Detailansicht im dunklen Fantasy-Stil: Allgemein, Kampfwerte / Schutzwerte, Eigenschaften / Effekte, Beschreibung.
Jeder regelrelevante Wert wird als separat beschriftete Zeile, Chip oder Eingabefeld angezeigt, etwa:
Langschwert: Schaden 1W8, Schadensart Hieb, vielseitiger Schaden 1W10, Eigenschaften Vielseitig, Meisterschaft Sap, Gewicht 3 lb, Preis 15 GM (nur soweit diese Daten tatsächlich im Katalog bestätigt sind).
Rüstung: Basis-RK, GE-Maximum, Stärkeanforderung, Heimlichkeitsnachteil, Gewicht, Preis jeweils getrennt.
Magischer Gegenstand: Seltenheit, Einstimmung, Ladungen, Bonus und Effektparameter getrennt; Beschreibung separat.
Such-, Sortier- und Filterfunktionen sollen strukturierte Attribute verwenden können (z. B. Kategorie, Preis, Gewicht, Seltenheit, Schadensart, Rüstungstyp).
Für eigene Items gibt es dynamische Formulare, die nur für die Kategorie sinnvolle Attribute anbieten. Einheiten und Werte validieren. Kein Platzhaltertext als gespeicherter Wert.
Unterstütze deutsche Bezeichnungen, Formatierung, Barrierefreiheit, Smartphone-Layouts und große Schrift. Tabellenwerte sollen auch auf schmalen Geräten ohne Abschneiden lesbar sein.
Unbekannte bzw. noch nicht implementierte magische Effekte sichtbar als „Regelwirkung noch nicht implementiert“ kennzeichnen, statt eine funktionierende Automatik vorzutäuschen.
4. Alle vorhandenen Items abgleichen
Gehe den gesamten vorhandenen und rechtmäßig verwendbaren SRD-/Projekt-Gegenstandskatalog systematisch durch. Dokumentiere:
Welche Items bereits korrekt strukturierte Werte besitzen,
welche noch unstrukturierte Werte in Anzeigen oder freien Notizen enthalten,
welche Daten aus der Quelle bestätigt sind,
welche regelwirksamen Attribute/Automatiken noch fehlen.
Keine zusätzlichen nicht-lizenzierten offiziellen Inhalte kopieren und keine Werte erfinden. Halte den Umfang des SRD 5.2.1 und dessen CC-BY-4.0-Nachweispflichten ein.
C. Tests und verbindliche Abnahme
Ergänze automatisierte Tests mindestens für:
Nur Abenteuer: FantasyPinnedActionBar genau einmal auf der Abenteuerseite, auf allen anderen Seiten nullmal, auch nach Navigationswechseln und in Detailansichten.
Layout: Kleine Displays, große Schrift, Tastatur, Scrollbereich; keine verdeckten Aktionen.
Katalogwerte: Jede vorhandene Waffen-/Rüstungsangabe wird aus dem eigenen Modellfeld und nicht aus description gewonnen.
JSON-Roundtrip: Typisierte Werte und Instanzzustand gehen beim Speichern, Laden, Backup, Import und Export nicht verloren.
Alt-Spielstände: Frühere InventoryItem-Datensätze (id, name, quantity, description, catalogId) bleiben gültig; Beschreibungen bleiben unverändert.
Formulare: Neue und benutzerdefinierte Waffen, Rüstungen, Verbrauchs- und magische Gegenstände lassen sich mit getrennten Werten anlegen, ändern und anzeigen; ungültige Werte werden zurückgewiesen.
Regelanbindung: Schaden, RK, Boni und andere schon unterstützte Effekte lesen strukturierte Attribute und funktionieren unverändert.
Konsistenz: Alte/frei formulierte Beschreibungen überschreiben niemals bekannte strukturierte Katalogwerte.
SRD-Abdeckungsbericht: Report zu vorhandenen Itemkategorien, Feldabdeckung, fehlenden Fakten und wirklich automatisierten Wirkungen; keine unbewiesene „100 % umgesetzt“-Behauptung.
Führe dart format, flutter analyze, flutter test und, falls möglich, einen Android-Debug-Build aus. Behebe auftretende Fehler. Erfolg nur nach tatsächlich ausgeführter Prüfung behaupten.
D. Autonome Entwicklung, Sicherungen und Übergabe
Arbeite die beiden Themen eigenständig bis zur bestmöglichen funktionierenden Version ab. Wähle eine sichere Reihenfolge: zuerst bestehende Strukturen prüfen, Tests als Regression absichern, dann Modelle/Anzeige/Migration integrieren.
Sichere regelmäßig vollständige Projekt-ZIPs, insbesondere vor erkennbaren Zeit-/Kontextlimits. Ein harter Abbruch kann danach keine Datei mehr erzeugen.
Erzeuge Wuerfelraunen_LATEST_Vollprojekt.zip, eine versionierte ZIP, eine .patch-Datei, CHECKPOINT.md und SHA256SUMS.txt.
ZIP muss den gesamten importierbaren Quellcode und relevante Assets/Tests enthalten, nicht nur geänderte Dateien; Secrets, .env-Zugangsdaten, Caches und Build-Artefakte ausschließen.
Commit auf Entwicklungsbranch, soweit Schreibzugriff besteht; main nicht ungetestet überschreiben. Bei GitHub-403 ein geprüftes Patch- und Vollprojektpaket liefern.
Übergabebericht: tatsächlich implementierte Funktionen, genaue Dateiliste, Testausgaben, offene Risiken und konkrete Fortsetzungsschritte. Keine vorgetäuschten Tests oder Uploads.
Beginne jetzt mit der Analyse des aktuellen Repositorys und setze danach beide Änderungsanforderungen in ausführbaren Code um.

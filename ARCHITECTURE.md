# Architektur

Die Alpha trennt Oberfläche, Regelentscheidungen, Erzählung und Speicherung. Android ist die zuerst unterstützte Plattform. Der Quellcode soll später weitere Flutter-Plattformen tragen; Windows- und iOS-Projekte beziehungsweise deren Builds sind in dieser Übergabe noch kein abgenommenes Ergebnis.

## Zuständigkeiten

- **Flutter-Oberfläche:** Material 3, deutsche Beschriftungen, Charakterverwaltung, Kampagnenauswahl, Abenteuerverlauf, Würfeln, Kampf, Journal und Einstellungen.
- **Domänenmodelle:** Typisierte Charaktere, Kampagnen, Ereignisse, Würfe und bestätigte Zustände; JSON-Serialisierung für Speicherung und Export.
- **Regelengine:** Berechnet Modifikatoren, Übungsbonus, Angriffsergebnisse und Schaden. Historische Angaben werden getrennt von neuen regeltechnischen Ergebnissen behandelt.
- **Spielleiter:** Ein austauschbarer Dienst liefert Erzähltext und strukturierte Vorschläge. Der kostenlose Demo-Dienst benötigt keine externen Modelle.
- **Persistenz:** SQLite speichert lokale Daten. Snapshot und Ereignisprotokoll werden zusammen in einer Transaktion geschrieben.
- **Sprache:** Gerätesysteme übernehmen deutsche Spracherkennung und TTS. Sie erhalten keine Befugnis, den Spielzustand zu verändern.
- **Backend:** Fastify validiert und autorisiert Anfragen, hält dauerhafte Anbieter-Geheimnisse serverseitig und begrenzt Nutzung. Der Demo-Provider ist kostenfrei testbar.

## Verbindliche Grenze zwischen Erzählung und Regeln

Erzähltext ist kein Datenbankbefehl. Ein Spielleiter darf keine Trefferpunkte, Boni, Gegenstände oder Charakterwerte frei überschreiben. Ein Ablauf führt von einer Spielerhandlung über die validierte Regelentscheidung zum bestätigten Ergebnis; erst danach werden Zustand und Ereignis gemeinsam gespeichert. Die Erzählung darf dieses Ergebnis erklären, aber nicht erweitern.

Natürliche Würfelwerte und Gesamtwerte werden getrennt modelliert. Bei einer manuell eingegebenen Gesamtsumme dürfen Modifikatoren nicht erneut addiert werden. Für Tests wird die Zufallsquelle kontrolliert. Unvollständige Charaktere dürfen nicht mit erfundenen Werten in neue Regelproben gelangen.

## SQLite und Wiederherstellung

Die Datenbank verwendet eine Schema-Version. Änderungen an einem veröffentlichten Schema benötigen eine Migration und einen Test mit bestehendem Datenbestand. Importdateien besitzen ebenfalls eine Formatversion und werden vor dem Speichern geprüft. Ein ungültiger Import darf den bestehenden Zustand nicht überschreiben.

Ein bestätigtes Ereignis enthält seine Identität, die Kampagnen- und Sitzungszuordnung, einen Zeitstempel, seinen Typ und strukturierte Daten. Ereignisse werden idempotent verarbeitet: Eine bereits bestätigte Ereignis-ID wird nicht erneut angewendet. Die gemeinsame Transaktion von Snapshot und Ereignis verhindert, dass nach einem Abbruch nur eine Hälfte einer Aktion sichtbar ist. Beim Neustart wird ausschließlich der letzte bestätigte Zustand geladen. Ein Revisionsjournal ermöglicht das Lesen früherer bestätigter Revisionen. Der Export enthält den aktuellen bestätigten Zustand und Ereignisse, aber nicht sämtliche historischen Revisionssnapshots. Ein Import legt diesen Zustand als neue Ausgangsrevision an und überschreibt keine bestehende Kampagne. SQLite-Verschlüsselung ist noch nicht implementiert.

Die Alpha bewahrt Verlauf und strukturierte Weltinformationen lokal. `MemoryEngine.context` liefert drei getrennte Bereiche: aktuelle Szene und die letzten sechs Nachrichten, eine Sitzungsübersicht aus bestätigten Fakten sowie langfristige Fakten, Quests, NPCs und Inventar. Diese einfache Sitzungsübersicht ist noch keine eigenständige intelligente Verdichtung. `MemoryEngine.replay` kann bestätigte Checkpoint-Ereignisse rekonstruieren und prüft Identität sowie Revisionsreihenfolge. Eine umfassende semantische Suche, automatisch verdichtete Sitzungserinnerungen und eine entfernte Mehrspielersynchronisierung sind weitere Ausbauschritte. Ein Gesprächskontext ersetzt den lokalen Speicher nicht.

## Arescan als historischer Import

Der Testspielstand hält die bekannte Erzählung und markiert fehlende Charakterwerte. Der historische Gesamtangriff 19 und der erzählte Schaden 14 werden nicht nachträglich als beweiskräftige Würfelergebnisse einer vollständigen Charakterberechnung umgedeutet. Der alte, ungeprüfte Modifikator +7 darf keine Grundlage neuer Würfe sein. Die Charaktervervollständigung ist eine ausdrückliche Benutzereingabe; neue Werte verändern die vorhandene Geschichte nicht rückwirkend.

## Sprache und externe KI

Push-to-Talk erkennt Sprache auf Deutsch und zeigt sie vor dem Absenden als bearbeitbaren Text. TTS liest Erzählungen vor und lässt sich stoppen. Verfügbarkeit und Offlinebetrieb hängen von Android und den installierten Sprachanbietern ab. Dauerhafte Audioaufzeichnungen sind in der Alpha nicht vorgesehen; Kampagnengedächtnis besteht aus Text und strukturierten Daten.

Die mobile Oberfläche verwendet in dieser Alpha ausschließlich den lokalen Demo-Spielleiter. Die Backend-Erzählung ist noch nicht in den mobilen Spielablauf integriert. Externe KI ist optional. Dauerhafte OpenAI-Schlüssel werden ausschließlich vom Backend verwendet. Das Backend stellt ein eigenes kurzlebiges, signiertes Token mit dem Geltungsbereich `narration:read-only` aus. Dieses ist kein OpenAI-Realtime-Token. Ein kurzer Sitzungstoken ist kein Ersatz für die serverseitige Autorisierung. Die App muss beim Ausfall eines Anbieters verständlich reagieren und den Demo-Modus verfügbar halten. Realtime-WebRTC ist als spätere Integration vorgesehen; ein vollständig geprüfter mobiler Realtime-Sprachpfad gehört noch nicht zu dieser Übergabe.

## Mehrspieler und Betrieb

Kampagnen und Sitzungen erhalten eigene IDs, damit spätere Synchronisierung ergänzt werden kann. Lokale Solo-Daten gelten nicht als fertiges Mehrspieler-Autorisierungssystem. Der öffentliche Betrieb benötigt vorab Kontenverwaltung, dauerhafte serverseitige Mitgliedschaften, PostgreSQL-Migrationen, Rollenprüfung, TLS-Bereitstellung und eine Sicherheitsprüfung. API-Schlüssel, Sitzungsgeheimnisse und persönliche Exportdateien gehören niemals ins Repository. Die bestehenden Backendquoten liegen im Arbeitsspeicher und werden bei Neustart zurückgesetzt; sie sind Anfragelimits und kein Euro-Kostendeckel.

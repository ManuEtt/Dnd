# Spielstände als JSON-Dateien sichern

Ab App 0.2.2 können Charaktere und Kampagnen direkt in Android-Dokumente
geschrieben werden. Die Dateiauswahl ist Teil des Betriebssystems. Die App
fordert keine allgemeine Speicherberechtigung an und merkt sich keine
Zugriffsrechte auf den gewählten Ordner.

## Sichern

1. Im Abenteuer den Exportknopf oder unter Einstellungen **Aktuelle Kampagne
   exportieren** öffnen. Für einen einzelnen Charakter unter Helden
   **Exportieren** wählen.
2. **Als Datei speichern** drücken und im Android-Systemdialog den Ordner und
   Dateinamen auswählen. Vorgeschlagen wird ein Name mit der Endung `.json`.
3. Auf die Erfolgsmeldung warten und die Datei außerhalb der App prüfen.
   Ein Abbruch ist keine bestätigte Sicherung; er verändert die Kampagne nicht.
   Bei einem Schreibfehler versucht die App, das neu angelegte Dokument zu
   entfernen. Manche Anbieter verweigern dies. Nach einem Aktivitätsende kann
   auch eine vollständig geschriebene Datei vorhanden sein, obwohl die
   Erfolgsantwort nicht mehr ankommt. Prüfe die gewählte Datei vor dem Entfernen.

Die Datei enthält den bestätigten Charakter beziehungsweise Kampagnenzustand
einschließlich Ereignissen. Sie enthält keine Sitzungstokens, API-Schlüssel oder
Audioaufnahmen. Frühere vollständige Revisionssnapshots der Datenbank sind
nicht Teil des Exports. Sicherungsdateien sind nicht verschlüsselt; der von dir
gewählte Speicherort entscheidet, wer Zugriff erhält. Ein Cloud-Dateianbieter
kann die Datei an seinen Dienst übertragen und Internet benötigen.

## Wiederherstellen

1. Auf der Startseite **Kampagne aus JSON importieren** oder unter Helden
   **Importieren** wählen.
2. **Datei wählen** drücken und das gewünschte JSON-Dokument öffnen. Der
   geladene Inhalt erscheint im Textfeld; bis hierhin ist nichts gespeichert.
3. **Importieren** drücken. Die App prüft das versionierte Format und die
   Daten, bevor sie diese transaktional speichert.

Bestehende Kampagnen mit derselben ID werden nicht überschrieben. Soll eine
Sicherung wiederhergestellt werden, sichere zunächst den aktuellen Zustand
separat und lösche anschließend nur das gewünschte lokale Testexemplar.
Ungültige oder nicht unterstützte Daten werden ohne Teiländerung abgewiesen.

Die Dateischnittstelle verarbeitet höchstens **10 MiB UTF-8-Daten**; ein
optionales UTF-8-BOM am Dateianfang wird akzeptiert. Binärdaten, ungültiges
UTF-8 und größere Dateien werden abgewiesen. Die Datenbank prüft zusätzlich
das Importformat und sämtliche unterstützten Charakter- und Kampagnenwerte.

## Fallback und Prüfstand

JSON-Anzeige, **Kopieren** und manuelle Texteingabe funktionieren weiterhin.
Damit lassen sich Sicherungen auch ohne verfügbaren Android-Dokumentanbieter
über eine selbst angelegte `.json`-Datei übertragen. Windows- und iOS-Dateidialoge
sind noch nicht implementiert.

Kanal- und Widgettests simulieren Dateiinhalt, Erfolg, Abbruch und Fehler.
Native JVM-Tests prüfen Dateinamen und begrenztes Lesen. Die tatsächliche
Android-Systemauswahl, Provider-Schreibfehler und ein Aktivitätsende müssen
separat auf einem Gerät abgenommen werden. Aktuelle Testergebnisse stehen in
[DEVELOPMENT_STATUS.md](../DEVELOPMENT_STATUS.md).

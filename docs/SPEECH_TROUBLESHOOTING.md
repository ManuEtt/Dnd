# Sprachfunktionen auf Android prüfen

Die App verwendet derzeit **Deutsch** für Spieltexte, Erkennung und Vorlesen.
Die Auswahl einer Stimme ist keine Übersetzung der App. Weitere Spielsprachen
sind noch nicht implementiert. Spracherkennung und Sprachausgabe sind zwei
getrennte Android-Dienste; ein funktionierender Dienst beweist nicht die
Verfügbarkeit des anderen.

## Rückmeldung zum Samsung Galaxy S26 Ultra

Der Benutzer berichtet, dass die App auf diesem Gerät funktioniert, einige
Sprachen jedoch nicht. Dies ist ein Benutzerbericht zum App-Betrieb, kein von
der Entwicklungsumgebung durchgeführter Gerätetest. Android-/One-UI-Version,
installierte App-Version, Sprachdienst und betroffene Sprache beziehungsweise
Stimme sind noch unbekannt. Eine konkrete Geräteursache ist daher nicht
bestätigt.

## Vorlesen prüfen

1. In den Android-Einstellungen nach **Sprachausgabe** beziehungsweise
   **Text-in-Sprache** suchen. Die genaue Menüposition hängt von der
   Systemversion ab. Den verwendeten Anbieter und dessen deutsche Sprachdaten
   prüfen; sofern angeboten, ein deutsches Sprachpaket installieren.
2. In der App **Einstellungen → Stimmen neu prüfen** wählen. Dieser Schritt
   fordert keinen Mikrofonzugriff an. Er übernimmt die aktuell vom Anbieter
   gemeldeten deutschen Stimmen.
3. **Systemstandard** oder eine angebotene deutsche Stimme wählen und
   **Stimme testen** drücken. Netzwerkabhängige Stimmen benötigen eine
   Verbindung. Eine vom Anbieter als lokal gemeldete Stimme ist keine Garantie
   für vollständig offline funktionierende Spracheingabe.
4. Die Ausgabe mit **Wiedergabe stoppen** unterbrechen. Nach einem Fehler die
   angezeigte Meldung lesen und die Stimmensuche erneut ausführen. Die
   Textdarstellung bleibt verfügbar.

Die App filtert ungültige, doppelte und ausdrücklich als nicht installiert
gemeldete Stimmen. Manche Anbieter liefern unvollständige Metadaten oder
melden Sprachdaten vor deren tatsächlicher Nutzbarkeit. Fehlende Stimmen
können deshalb eine Installation beziehungsweise einen Anbieterwechsel in den
Android-Einstellungen benötigen. Die App installiert keine Sprachpakete selbst.

## Spracheingabe prüfen

1. Mikrofonzugriff erst durch Drücken des Mikrofonbuttons freigeben.
2. Einen kurzen deutschen Satz sprechen, die Aufnahme stoppen und das
   Transkript vor dem Senden prüfen beziehungsweise korrigieren.
3. Bei fehlenden deutschen Erkennungsdaten den Android-Erkennungsdienst und
   dessen Sprachpakete prüfen. Bei einer Verbindungs- oder Zeitüberschreitung
   die Aufnahme ausdrücklich erneut starten; die App öffnet das Mikrofon
   nicht automatisch wieder.
4. Mit und ohne Netzwerk getrennt testen. Die vom Dienst gemeldete Sprachliste
   kann nur dessen lokale Modelle enthalten. Scheitert ihre Abfrage, versucht
   die App nach einer begrenzten Wartezeit Deutsch (`de-DE`); dessen tatsächliche
   Unterstützung wird erst beim Erkennungsversuch sichtbar.

Es werden keine Audioaufzeichnungen dauerhaft von der App gespeichert.
Android-Anbieter können Sprache zur Verarbeitung übertragen. Das Textspiel
und die lokal gespeicherten Charaktere/Kampagnen benötigen keinen Sprachdienst.

## Für einen überprüfbaren Fehlerbericht

App-Version, Android-/One-UI-Version, Name des Sprachdienstes, gewählte Stimme
beziehungsweise Sprache, Netzwerkstatus und genaue App-Fehlermeldung
festhalten. Unterscheiden, ob **Vorlesen**, **Spracheingabe** oder beides
betroffen ist. Keine API-Schlüssel oder persönlichen Spielstände als
Diagnosedaten veröffentlichen.

## Geprüfte Schnittstellen

Die Korrektur beruht auf den tatsächlich festgehaltenen Paketversionen und
deren veröffentlichtem Dart-/Android-Code:

- [flutter_tts 4.2.3](https://pub.dev/packages/flutter_tts/versions/4.2.3):
  Android liefert bei `setLanguage`, `setVoice` und `speak` Ergebnisse von
  1 beziehungsweise 0; Stimmmetadaten enthalten `network_required` und
  `features`. Bei einem Fehler kann die native Wiedergabe-Future offen bleiben.
- [speech_to_text 7.3.0](https://pub.dev/packages/speech_to_text/versions/7.3.0):
  `listen` liefert keinen verwendbaren Erfolgs-Boolean an den Aufrufer.
  Die Android-Sprachabfrage kann bei nicht verfügbarer lokaler Erkennung
  beziehungsweise Supportfehlern offen bleiben. Die App begrenzt diese Abfrage,
  ohne daraus eine vollständige Liste aller Online-Sprachen abzuleiten.

Automatisierte Tests prüfen die App-Reaktion mit Mocks. Sie ersetzen keine
Abnahme mit Samsung-, Google- oder anderen realen Android-Sprachdiensten.

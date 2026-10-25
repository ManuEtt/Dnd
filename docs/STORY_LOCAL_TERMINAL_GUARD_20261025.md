# Lokale KI-Grenze: geschlossene Story-Handlungsstränge schützen

Datum 25.10.2026; [PR #165](https://github.com/ManuEtt/Dnd/pull/165), gestapelt auf Integrations-[PR #164](https://github.com/ManuEtt/Dnd/pull/164).

## Verifizierter Fehlerpfad

Der Backend-Endpunkt verweigert seit PR #161 generierte Statusänderungen von `resolved` oder `abandoned` nach `open`. Der separate, lokale Flutter-Validator `app/lib/story/ai_story.dart::AiStoryStep.fromJson` prüfte hingegen bei `threadUpdates` nur zulässige Statuswerte und bekannte Thread-IDs. Damit war es über andere Antwortquellen oder zwischenzeitlich geänderte lokale Spielstände möglich, einen durch den Spieler abgeschlossenen Handlungsstrang beim Anwenden einer KI-Antwort zu überschreiben.

## Implementierung

- Lokale Statusmap aus dem **aktuellen** `Campaign.storyThreads`: Ein `open`-Thread darf seine bisher zulässigen Statusänderungen behalten.
- Der Erzähler darf einen bereits `resolved`- oder `abandoned`-Thread nur mit **demselben** Status kommentieren. Eine KI-generierte Wiederöffnung und auch das Umklassifizieren zwischen den zwei Terminalzuständen werden mit `FormatException` abgewiesen.
- Die ausdrückliche Spieleraktion `GameEngine.saveStoryThread` bleibt der autorisierte Weg, einen Terminalstatus wieder auf `open` zu setzen; danach sind normale KI-Fortsetzungen wieder erlaubt.
- `StoryCampaignEngine.applyAiStoryStep` validiert beim tatsächlichen Commit bereits erneut über `AiStoryStep.fromJson`. Damit greift der neue Schutz auch bei einer bereits früher positiv geparsten, inzwischen veralteten KI-Antwort. Keine Migration, keine neue Datenbank-/Eventstruktur.

## Regressionstests

`app/test/ai_story_test.dart`: Beide Terminalzustände, verbotene Wiederöffnung und Wechsel auf den anderen Terminalstatus; erlaubte idempotente Notiz; JSON-Roundtrip des geschlossenen Zustands; ausdrücklich manuelle Wiederöffnung; erfolgreicher erneuter KI-Abschluss mit invarianten Helden-/Questdaten; unveränderte Event-Checkpointdaten; bereits vorher validierte, aber inzwischen veraltete KI-Antwort wird beim Anwenden verworfen, ohne den bestehenden Zustand zu ändern.

**Abnahme:** Die kombinierte Basis [CI #40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457) für Integrations-PR #164 war erfolgreich. Sie ist ausdrücklich kein Testnachweis für den neuen Flutter-Fix. Die neue vollständige CI für [PR #165](https://github.com/ManuEtt/Dnd/pull/165/checks) muss Dart-Format, Flutter-Analyse und Volltests, Python, Backend, Android-Debug, native Tests und ABI-Alpha-Pakete auf dem exakten PR-HEAD bestehen.

## Grenzen und Integrationsweg

Die Prüfung kennt nur explizit gespeicherte Story-Threadstatus und kann keine Erzählung semantisch auf geheime Beweise hin auswerten. Durch den Benutzer bestätigte Handlungs-/Regelentscheidungen stammen weiterhin ausschließlich aus der lokalen Engine. SRD 5.2.1 ist nicht vollständig; keine zusätzliche Regelwirkung behauptet. Android-App `0.8.38+88`, SQLite `2`, Kampagnen-JSON `1` bleiben kompatibel.

Dies ist ein **Stacked PR auf dem HEAD des Integrationsbranches #164**. Erst #164 reviewen und nach entsprechender Projektfreigabe übernehmen. Danach die Basis dieses PR auf das dann aktuelle `main` ändern und die CI erneut prüfen. Keine Änderung an `main` und keine automatische Löschung/Schließung offener PRs.

**Nächster Schritt:** [CI #165](https://github.com/ManuEtt/Dnd/pull/165/checks) auswerten und nötige Fehler korrigieren, danach Review-Freigabe und sichere spätere Integration nach #164.

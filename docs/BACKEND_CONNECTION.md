# Optionalen Backend-Erzähler verbinden

Die App startet weiterhin mit der kostenlosen lokalen Demo. Ab Version 0.2.0
kann ein eigener Backenddienst die Erzähltexte ausgestalten. Der Server erhält
Charaktername, die eingegebene Handlung, die aktuelle Szene, das lokale
Erzählergebnis und bis zu 20 relevante Ausschnitte bestätigter Erinnerungen.
Seit App 0.2.1 werden passende Namen und wichtige NPC-/Quest-/Inventarzustände
vor unwichtigen Fakten ausgewählt. Audio wird
nicht übertragen oder gespeichert.

Würfelproben, Kampfergebnisse, Trefferpunkte, Inventaränderungen und
Questabschlüsse bleiben bei der lokalen Regelengine. Solche Aktionen werden
nicht an den externen Erzähler geschickt. Eine externe Antwort darf nur den
neuen Erzähltext ersetzen; der zugehörige Ereignis-Checkpoint bleibt konsistent.

## Server vorbereiten

1. Backend-Abhängigkeiten installieren und `backend/.env.example` als `.env`
   auf dem Server konfigurieren. Einen zufälligen `LOCAL_ACCESS_TOKEN` mit
   mindestens 32 Zeichen festlegen. Dieser Serverzugang und ein optionaler
   `OPENAI_API_KEY` gehören ausschließlich auf den Server.
2. Mit `AI_PROVIDER=mock` beginnen. Für OpenAI zusätzlich ausdrücklich
   `ALLOW_PAID_AI=true`, einen serverseitigen Schlüssel und `OPENAI_MODEL`
   konfigurieren. Die App benötigt keinen OpenAI-Schlüssel.
3. Backend bauen und starten: `npm ci`, `npm run build`, `npm start`.
4. Für Android eine direkte HTTPS-Adresse mit gültigem TLS-Zertifikat und
   Reverse-Proxy bereitstellen. Die App akzeptiert weder unverschlüsseltes HTTP
   noch Weiterleitungen. Öffentliche Bereitstellung und TLS sind nicht im ZIP
   eingerichtet; ein lokaler Server ohne HTTPS genügt nur für Entwicklungstests.

## Kurzlebige Sitzung ausstellen

Im Backendverzeichnis auf dem **Server** ausführen:

```bash
node --env-file-if-exists=.env scripts/issue-session.mjs
```

Das Hilfsprogramm spricht den lokalen Server an und gibt ausschließlich den
kurzlebigen Sitzungstoken aus. Bei abweichendem Port muss `PORT` in `.env`
entsprechend gesetzt sein. Der dauerhaft gültige Serverzugang wird nicht
ausgegeben. Sitzungstokens nicht im Repository, in Bildschirmfotos oder im Chat
teilen. Standardgültigkeit: fünf Minuten; die Serverkonfiguration erlaubt
höchstens 15 Minuten. Eine automatische Token-Erneuerung ist noch nicht vorhanden.

## In der App verbinden

Unter **Einstellungen → KI & Kosten → Backend verbinden** HTTPS-Adresse und
kurzlebigen Sitzungstoken eingeben. Ein lokales Limit von 1 bis 100
Anfragenversuchen je Verbindung begrenzt zusätzliche Anfragen; Standard ist 20.
Die Prüfung der Sitzung selbst ruft kein KI-Modell auf. Ein Backend mit
kostenpflichtigem Anbieter benötigt außerdem die ausdrückliche Kostenfreigabe
im Dialog. Diese Freigabe ersetzt keinen Euro-Kostendeckel des Anbieters.

Nur Adresse und Anfragenlimit werden gespeichert. Token und Kostenfreigabe
bleiben im Arbeitsspeicher und werden nach einem Neustart erneut benötigt.
**Backend trennen** verwirft die aktive Sitzung. Bei Ablauf, Serverausfall,
ungültiger Antwort oder ausgeschöpftem Limit führt die lokale Demo die Handlung
fort. Eine fehlgeschlagene Anfrage wird nicht automatisch wiederholt. Bereits
gesendete Anfragen können beim Anbieter trotzdem Kosten verursachen.

Die neue Verbindung ist mit Transport-Mocks und einem lokalen Testserver
prüfbar. Ein echter OpenAI-Aufruf und der HTTPS-Ablauf auf einem Android-Gerät
müssen separat abgenommen werden. Realtime/WebRTC und Benutzerkonten sind
weitere Entwicklungsschritte.

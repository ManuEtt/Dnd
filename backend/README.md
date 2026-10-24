## Backend-Limits – sichere Kapazitätsgrenze (24.10.2026, PR #162)

Die In-Memory-Quoten des lokalen Erzählers bewahren bei vollständig belegtem Schlüsselspeicher jetzt aktive Zähler; nur abgelaufene Fenstereinträge werden verdrängt. Sind weiterhin alle Plätze belegt, wird ein neuer Schlüssel **abgelehnt**, statt die Quote eines bestehenden Schlüssels vorzeitig freizugeben. Dies kann bei sehr vielen gleichzeitig aktiven Clients konservativ zu `429` führen. Bestehende Limits pro Minute/Tag und `Retry-After` bleiben unverändert.

Der Fix verhindert keine Umgehung über mehrere Backendinstanzen oder einen Prozessneustart; dafür wäre ein gemeinsamer externer Limitspeicher erforderlich. [PR #162](https://github.com/ManuEtt/Dnd/pull/162) · [Details](../docs/BACKEND_LIMITER_CAPACITY_20261024.md).

---

## 0.3.1 – bestätigbare Abenteuerangebote

`POST /v1/story/advance` antwortet zusätzlich mit `turn.adventure: null` oder einem narrativen Vorschlag `{id,title,description,archetype,questTitle,questDescription}`. Zulässige Profile sind `bandit`, `wolf`, `skeleton`, `goblin`, `orc`, `investigation`; sämtliche Monsterwerte und Beute stammen von der **lokalen App**. Der neue Rückgabetyp erfordert aktualisierte Android-/Flutter-App 0.3.8+14. Backend liest/schreibt keine Kampagnendaten. Kostenzustimmung und Sitzungs-Ratelimits bleiben erhalten.

# Spielleiter-Backend

Optionaler Fastify-/TypeScript-Dienst für **Würfelraunen – Der lebendige Spielleiter**. Die App kann ihren lokalen Demo-Spielleiter ohne diesen Dienst verwenden. Der Server liefert Erzähltext und **validierte, unverbindliche Story-Vorschläge**; er hat keinen Datenbankzugriff und darf weder Trefferpunkte noch Inventare oder andere bestätigte Regelzustände verändern. Die lokale App nimmt nur erlaubte erzählerische Änderungen selbst an.

## Lokal starten

Voraussetzung: Node.js 22.14 oder neuer. CI verwendet Node 22.14.0; die lokalen Prüfungen liefen mit Node 22.14.0 und 24.19.0. Pakete sind über `package-lock.json` festgelegt.

```bash
cd backend
npm ci
cp .env.example .env
openssl rand -hex 32
```

Den lokal erzeugten Wert in `.env` als `LOCAL_ACCESS_TOKEN` eintragen. `.env` ist vom Git-Tracking ausgeschlossen. Zugang und KI-Schlüssel gehören weder ins Repository noch in eine APK.

```bash
npm run dev
```

Alternativ: `npm run build` und `npm start`. Standardadresse: `http://127.0.0.1:3000`. Ohne `LOCAL_ACCESS_TOKEN` ist nur `/health` verfügbar; die Tokenausstellung bleibt gesperrt. Ein nicht gesetztes `SESSION_SECRET` wird beim Start zufällig erzeugt, sodass frühere Sitzungen nach einem Serverneustart ungültig sind.

## Schnittstellen

| Methode / Pfad | Authentifizierung | Ergebnis |
| --- | --- | --- |
| `GET /health` | Keine | Status, aktiver Provider, Version |
| `POST /v1/session` | `Authorization: Bearer <LOCAL_ACCESS_TOKEN>` | Kurzlebiger signierter Sitzungstoken |
| `GET /v1/session` | `Authorization: Bearer <Sitzungstoken>` | Prüft Sitzung, Provider und Ablauf ohne Modellaufruf |
| `POST /v1/narrate` | `Authorization: Bearer <Sitzungstoken>` | Deutscher Erzähltext mit `stateChanges: []` |
| `POST /v1/story/start` | `Authorization: Bearer <Sitzungstoken>` | Kampagnenplan mit Titel, Welt, Auftakt, geheimem Plot, NPCs, Orten und Handlungssträngen |
| `POST /v1/story/advance` | `Authorization: Bearer <Sitzungstoken>` | Neue Szene, Handlungsstrang-Status und NPC-Beziehungs-Vorschläge, **keine Regeländerungen** |

`POST /v1/session` erwartet den JSON-Body `{}`. Die Antwort enthält `token`, `tokenType`, `expiresAt`, `expiresIn`, `provider` und `scope: "narration:read-only"`. Standardlaufzeit: fünf Minuten, maximal 15 Minuten. Das ist ein eigenes Token für dieses Backend; es ist **kein OpenAI-Realtime-Token**.

`GET /v1/session` liefert `provider`, `expiresAt` und `scope: "narration:read-only"`. Seit App 0.2.0 ist die optionale mobile Anbindung vorhanden; Einrichtung: [BACKEND_CONNECTION.md](../docs/BACKEND_CONNECTION.md). Der Server-CLI-Befehl `node --env-file-if-exists=.env scripts/issue-session.mjs` stellt auf dem Backendhost einen kurzlebigen Token aus.

`POST /v1/narrate` akzeptiert folgende Eingabe:

```json
{
  "campaignId": "das-herz-der-ewigkeit",
  "playerName": "Arescan",
  "action": "Ich untersuche das rote Amulett, ohne es zu berühren.",
  "scene": "Marktplatz von Silberhain. Der verletzte Schattenritter liegt am Boden.",
  "memories": ["Arescan hat die Elfenmagierin vor einem Angriff gewarnt."]
}
```

```json
{
  "text": "Arescan, du richtest deine Aufmerksamkeit auf die Gestalt und das rote Amulett. Das Licht pulsiert im gleichen Rhythmus wie ein fernes Echo. Noch hast du den Gegenstand weder genommen noch verändert. Was möchtest du genauer untersuchen?",
  "provider": "mock",
  "stateChanges": []
}
```

Felder sind begrenzt: `campaignId` 128 Zeichen aus Buchstaben, Ziffern, `_`, `-`; `playerName` 80; `action` 2.000; `scene` 4.000. Optionales verbindliches `outcome` bis 4.000 Zeichen: Der Mock gibt dieses lokale Ergebnis exakt zurück; OpenAI darf es nur umformulieren. Bis zu 20 Erinnerungen mit je 400 Zeichen. Unbekannte Felder werden abgewiesen. Der Client muss Erinnerungen aus seinem bestätigten Speicher beziehen; der Server bestätigt deren Echtheit nicht selbst.

Fehler: `400` ungültige Eingabe, `401` fehlender oder abgelaufener Token, `413` zu großer Body, `429` Nutzungslimit, `502` Providerfehler, `503` fehlende lokale Zugangskonfiguration. Bei `401` kann der Client erneut eine Sitzung anfordern. Bei `502` steht weiterhin der lokale Demo-Modus zur Verfügung. Providerdetails und Eingabetexte werden nicht protokolliert oder in Fehlermeldungen zurückgegeben.

## Eigenständige KI-Kampagnen (0.3.0)

Der bestehende Zugang und das Anfragelimit gelten auch für die beiden neuen Endpunkte. Zum Einstieg sendet der Client:

```json
{"heroName":"Arescan","heroClass":"Waldläufer","theme":"Dunkle Fantasy und politische Intrigen"}
```

Antwort `POST /v1/story/start`: `{ "provider": "openai", "stateChanges": [], "story": { ... } }`. Das vollständige `story`-Objekt besteht aus `title`, `world`, `opening`, `premise`, `secret`, `goal`, `threads`, `npcs`, `places`. Diese Felder werden vor der Aufnahme im Client erneut validiert. Die geplante geheime Wendung bleibt lokal und ist im Export sichtbar.

An `POST /v1/story/advance` sendet der Client `campaignId`, `heroName`, `action`, `scene`, `premise`, `goal`, `secret`, `threads` (IDs, Titel, Beschreibungen, Status), `npcs` (IDs, Namen, Beziehungen), passende bestätigte `memories` und höchstens acht `recentActions`. Die Antwort enthält `{ "provider": "openai", "stateChanges": [], "turn": { "narration": "...", "threadUpdates": [], "newThreads": [], "npcUpdates": [] } }`. IDs müssen bekannt oder bei neuen Fäden eindeutig sein. Nur die App kann die bestätigte Revision ändern; Backend-Anfragen verändern nie Datenbanken oder Regelwerte.

Im Offline-Testmodus (`AI_PROVIDER=mock`) sind der Plot und die Reaktionen **regelbasiert und nicht frei generiert**. Der OpenAI-Modus ruft `POST /v1/responses` mit `text.format.type=json_schema`, `strict=true` und `store=false` auf; strukturierte Ausgaben werden zusätzlich server- und clientseitig geprüft. Beide Endpunkte teilen sich das Minuten- und Tageslimit mit `/v1/narrate`. **Ein Anfragelimit ist kein Euro-Kostenlimit.**

## Optionale OpenAI-Anbindung

Default ist `AI_PROVIDER=mock`: keine externe KI-Verbindung, keine Kosten. Ein echter Aufruf benötigt gleichzeitig:

```dotenv
AI_PROVIDER=openai
ALLOW_PAID_AI=true
OPENAI_API_KEY=<nur auf dem Server setzen>
OPENAI_MODEL=<im eigenen Konto verfügbares Responses-Textmodell auswählen>
```

Der Provider verwendet `POST https://api.openai.com/v1/responses`, `instructions`, Textinput und `store=false` (klassische Erzählung maximal 600 Tokens; strukturierter Story-Vorschlag maximal 2400 Tokens). Keine Tools, keine Zustandsänderungen, 20 Sekunden Timeout. HTTP-Weiterleitungen werden abgewiesen, bevor Zugangsdaten oder POST-Anfragen erneut gesendet werden. `store=false` deaktiviert die Speicherung einer abrufbaren Responses-Antwort; es ersetzt keine Prüfung der Datenschutz- und Aufbewahrungsbedingungen des API-Anbieters. Nutzereingaben werden bei diesem Provider an OpenAI übertragen. Die Modellantwort ist Erzähltext; die lokale Regelengine bleibt allein für Zustandsänderungen zuständig.

Die offiziellen [Text-Dokumentation](https://developers.openai.com/api/docs/guides/text), [OpenAPI-Spezifikation](https://github.com/openai/openai-openapi/blob/master/openapi.yaml) und [Realtime-WebRTC-Dokumentation](https://developers.openai.com/api/docs/guides/realtime-webrtc) wurden am 13.10.2026 gelesen. Der dokumentierte Realtime-Endpunkt für ephemere Credentials lautet `/v1/realtime/client_secrets`; WebRTC und dessen Tokenausstellung sind hier **noch nicht implementiert**.

## Grenzen und Hosting

- Ein lokales gemeinsames Spielerprofil. Keine Benutzerverwaltung, Kampagnenfreigaben oder Mehrspieler-Autorisierung. Der Bootstrap-Zugang ist ausschließlich für einen privaten Entwicklungsserver gedacht; er darf nicht in einer öffentlichen App verteilt werden.
- Standardmäßig Loopback-HTTP. Andere Bind-Adressen verlangen eine HTTPS-`PUBLIC_ORIGIN` in der Konfiguration. Für Remote-Betrieb ist ein TLS-Reverse-Proxy erforderlich; der Backendport darf dann nur im internen Netz erreichbar sein. `PUBLIC_ORIGIN` selbst richtet kein TLS ein. Kein CORS für Browser aktiviert; native Clients benötigen kein CORS.
- In-Memory-Limits: zehn Anmeldeversuche pro Minute/IP; standardmäßig 15 Erzählanfragen pro Minute und 100 pro 24-Stunden-Fenster für das lokale Spielerprofil. Neue Sitzungstokens umgehen die Erzählquote nicht. Limits zählen auch fehlgeschlagene Provideraufrufe und werden beim Serverneustart zurückgesetzt. Anfragelimits sind kein exakter Euro-Kostendeckel. Öffentliche Nutzung benötigt persistente gemeinsame Quoten und ein externes Kontobudget.
- Keine dauerhafte Speicherung von Text, Audio oder Spielständen im Backend. Keine Sprachtranskription, TTS oder Realtime-Übertragung. Die lokale Flutter-Datenbank verwaltet den bestätigten Zustand.

## Verifikation

```bash
npm ci
npm run typecheck
npm test
npm run build
npm audit
```

**Historisch GETESTET am 13.10.2026 (0.1.0):** TypeScript-Typecheck, Produktionskompilierung und 17 deterministische Tests mit Fastify-HTTP-Injection: Authentifizierung, Tokenmanipulation und Ablauf, Validierung, Mock-Erzählung, Read-only-Ergebnisse, Erinnerungsinput, Minuten-/Tageslimits, Anmeldebegrenzung, sichere Providerfehler, Responses-Request und Auswertung mit gemocktem Fetch, Konfiguration und begrenzter Limiter. Zusätzlich wurde der kompilierte Server auf Loopback gestartet und `/health`, `/v1/session` und `/v1/narrate` über echte HTTP-Anfragen geprüft. `npm ci` reproduziert die Installation; `npm audit` meldete null bekannte Schwachstellen. Alle 17 Tests, Typecheck und Build bestanden auch mit der CI-Version Node 22.14.0. Keine bezahlten API-Aufrufe.

**NICHT GETESTET:** echter OpenAI-Account, ausgewähltes Live-Modell, Android-Client-zu-Backend-Verbindung, öffentlicher HTTPS-Reverse-Proxy, Mehrspielerbetrieb und Realtime.

**0.2.0:** Typecheck, Build und 22 Tests erfolgreich unter Node.js 22.14.0 und 24.19.0. Ein zusätzlicher echter Node-/Dart-Protokolltest prüft die Server-CLI, Sitzung, Erzählung und den lokalen Fallback. Keine bezahlten API-Aufrufe.

**0.3.0:** Zwei strukturierte Story-Endpunkte neu. Isolierte Validatoren und Mock-Laufzeitprüfung sind lokal bestanden; vollständige Fastify-/TypeScript-Tests erst nach `npm ci` und CI, echte OpenAI-Responses nicht abgenommen.

**GETESTET am 16.10.2026:** `npm ci`, Typecheck, Produktionsbuild und alle 31 Backendtests erfolgreich mit Node.js 22.14.0 (CI-Version). Ergänzte Regressionen prüfen Journal-Handlungsstränge ohne Beschreibung und einen echten lokalen HTTP-307-Redirect: Erzählung und Story-Anfrage brechen ab, ohne die Anfrage am Umleitungsziel zu wiederholen. Der Mock setzt bei leeren Handlungsnotizen keine erfundene Ersatzbeschreibung ein. Keine bezahlten API-Aufrufe; keine echte OpenAI-/HTTPS-Geräteabnahme.

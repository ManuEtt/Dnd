# Architektur

## Grenzen

- `lib/domain/`: typisierte Charakter- und Kampagnenmodelle, berechenbare Regeln, testbare Würfelquelle.
- `lib/data/`: persistente SQLite-Datenbank (Version 1), Transaktionen und idempotenter Startdatenimport.
- `lib/services/`: narrativer, deterministischer Mock-Adapter; Android Speech-to-Text und TTS.
- `lib/ui/`: Material-3-Ansichten und Interaktion.
- `backend/`: Fastify-/TypeScript-Dienst, derzeit lokal auf Loopback und ausschließlich Mock-API.

## Autorität

Der Erzähler kann frei beschreiben, aber niemals selbst einen Treffer, Ausrüstungswechsel oder eine HP-Änderung festschreiben. Diese Änderungen benötigen später validierte Commands und ausschließlich die Regelengine. Das Eventlog speichert bislang bestätigte Textinteraktionen und Würfelergebnisse; eine vollständige Event-Sourcing-Rekonstruktion einschließlich Kampfzuständen ist noch offen.

## Persistenz

SQLite-Schema Version 1:

- `characters`: JSON-Datensatz je Charakter
- `campaigns`: JSON-Datensatz + optimistische Rundennummer je Kampagne
- `events`: ID (UNIQUE), Kampagne, Sitzung, Typ, Zeitpunkt, strukturierter JSON-Payload, Text

`appendTurn` aktualisiert die Kampagnenrundennummer und schreibt Spieler- und Erzählerereignis in **einer** Transaktion. Der erwartete alte Rundenzähler verhindert unbeabsichtigte doppelte Turns. Bei parallelen Geräten sind Serverautorität und vollständige Konfliktauflösung zusätzlich nötig.

## Voice

Mikrofon: `speech_to_text`, locale `de_DE`. Audio: `flutter_tts`, Sprache `de-DE`. Die Integration verwendet Gerätefunktionen; Offline-Verfügbarkeit kann von Android-Version, Erkennungsdienst und heruntergeladenen Sprachmodellen abhängen. Es werden keine Audiodateien gespeichert.

## Spätere KI-Schnittstelle

Abstraktion mit Provider- und Rules-Command-Verträgen ergänzen. Externe KI soll nur narrativen Text + strukturierte Aktionsvorschläge liefern, die vor Persistenz gegen Regeln und Berechtigungen geprüft werden. Kurzlebige Tokens ausschließlich vom authentifizierten Backend ausstellen; Browser-/Mobile-Client bekommt niemals langfristige Provider-Schlüssel.

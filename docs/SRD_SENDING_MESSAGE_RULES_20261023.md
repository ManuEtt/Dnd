# SRD 5.2.1 – Sending: bestätigte Nachricht und Empfänger

**Entwicklungsstand 23.10.2026 · Würfelraunen 0.8.36+86 · Neue CI ausstehend**

## Regelquelle und Lizenz

Amtliche [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), Seite **161**, Abschnitt *Sending*;
Lizenz CC BY 4.0. Die SRD verlangt für diesen Zauber eine Nachricht mit
höchstens 25 Wörtern an eine bestätigte Kreatur, die der Zaubernde
persönlich getroffen hat oder die ihm eine Person beschrieben hat,
welche die Zielkreatur getroffen hat. Bei bestätigter anderer Existenzebene
besteht eine Chance von 5 %, dass die Nachricht nicht ankommt.
Ein Empfänger kann eine weitere Kommunikation für acht Stunden sperren.

## Technischer Vertrag

`app/lib/domain/srd_sending_rules.dart` und das öffentliche
`app/lib/rules/rules_api.dart` stellen nun einen **lesenden** Vertrag bereit:

- `SrdSendingRules.prepare`: strikt **nur** für den katalogisierten
  SRD-Zauber `Sending` (Grad 3, Reichweite `Unlimited`, Wirkzeit
  `Action`). Der eindeutige Empfänger, bestätigte Kreatur,
  persönliche Bekanntschaft oder Zeugenaussage und 1–25
  durch Leerraum getrennte Wörter sind ausdrücklich erforderlich.
- `SrdSendingRules.assessDelivery`: unterscheidet bestätigte
  Empfängerblockade, bestätigte gleiche Ebene, bestätigte andere Ebene
  und unbestätigte Fakten. Der prozentuale W100-Wert wird nur im
  **bestätigten anderen Ebenenfall** entgegengenommen. Ergebnisse 1–5
  sind Nichtzustellung, 6–100 wären zustellbar. Fehlende Informationen
  führen zu `unresolved`, nicht zu erfundener Zustellung.
- Die Regelauswertung erzeugt **keine** Nachricht im Story-Verlauf,
  **keinen** externen Nachrichtenversand, **keine** automatische
  Charakter-/Kampagnenmutation, **keinen** Würfelwurf und **keinen**
  Zauberplatzverbrauch. Ein anderes Feature muss zuvor auch
  Zauberbereitung, Klasse, Fokus/Kupferdraht, Komponenten,
  Aktionsökonomie, bestätigten Würfel, Revision und SQLite-Commit prüfen.
- Der Acht-Stunden-Ablauf einer Empfängersperre wird **nicht**
  automatisch mit einer Weltuhr modelliert. Blockstatus und Ebenenstatus
  sind deshalb explizit bestätigte Eingaben. Bei unbestätigtem Status
  ist die Zustellung nicht beweisbar. Keine Schätzung der Identität oder
  Kommunikation über externe KI.
- `Unlimited` ist weiterhin **in der generischen
  Zauberreichweiten-Engine gesperrt**; `Special` ebenso. Alle anderen
  Zauber mit solchen Reichweiten benötigen eigene Regeln.
- Das Modell der Wortzahl nutzt Leerraum-getrennte Tokens, nicht
  automatische sprachliche Segmentierung; verschachtelte Satzzeichen,
  Sprachausgabe und längere Übersetzungen müssen später zusätzlich
  anhand des endgültigen Texts bestätigt werden.

## Neue Regressionstests

`app/test/srd_sending_rules_test.dart` testet nachgewiesene
Empfängerbeziehung, 25-Wörter-Grenze (und 26-Wörter-Ablehnung),
unbekannte Ziele, andere Zauber, Nichtvorliegen von Kreatureigenschaft,
W100-Grenzen 1/5/6/100, unzulässige Würfelwerte, gleiche/andere/
unbekannte Ebene und bestätigte Acht-Stunden-Blockade. Es werden
keine bezahlten Provider, lokalen Geräteberechtigungen oder Netzwerke
benötigt.

```bash
cd app
flutter test test/srd_sending_rules_test.dart
flutter analyze
flutter test
flutter build apk --debug
```

**Offen:** vollständige CI des **finalen PR-HEAD**, echte Android-Abnahme,
effektiver, bestätigter Spellcast mit Komponenten/Slots/Persistenz,
Weltzeit-/Sperrablauf, KI-Erzähler-/Dialoganbindung, automatische
Empfängerantwort und offizielle vollständige SRD-Inventur.
SQLite-Schema 2 und Kampagnen-JSON-Schema 1 werden nicht verändert.

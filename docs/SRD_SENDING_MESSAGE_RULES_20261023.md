# SRD 5.2.1 – Sending: bestätigte Nachricht und Empfänger

## Technische Ergänzung 24.10.2026 – Unicode-Formatzeichen (PR #155)

Die Sending-Eingabevalidierung verwirft zusätzlich U+00AD, U+034F, U+061C, U+180E, U+2061–U+206F und U+FFF9–U+FFFB in Nachrichten und Empfängerkennungen. Dadurch werden weitere unsichtbare Operator-, Bidi- und Annotationszeichen beim Spielerreview abgefangen. Domain-Regressionen prüfen außerdem 26 durch U+2063 verbundene Wörter und den unveränderten, rein lesenden Casting-Preview. **Keine zusätzliche SRD-Regel:** Die 25-Wort-Grenze bleibt maßgeblich, das technische UTF-16-Limit bleibt unverändert. Tests auf dem finalen Branch-Head sind erst nach erfolgreicher eigener GitHub-CI belegt. Keine Schema-/Versionserhöhung, keine Slot-/Aktionsbuchung.


## Regelverbund: Sending-Nachricht und Zauberressourcen (24.10.2026)

**GitHub-Abnahme:** Der ausführbare Commit `efed3d732459478b072452ab8e92ef3c674e39fd` ist in der vollständigen [CI #40071729227](https://github.com/ManuEtt/Dnd/actions/runs/40071729227) erfolgreich geprüft (Python/Backend, Dart/Flutter, native Android-Tests, Debug- und Alpha-APKs). Acht neue Testgruppen einschließlich Dry-run-Handlungsfähigkeit und manipulierter Klassenlisten. Der bestätigte Sending-Spellcast mit Slot-/Action-Persistenz bleibt offen; keine Geräteinstallation durchgeführt.

**Arbeits-ID:** `SPELL-ENTRY-SENDING`, vorerst **partial**; keine vollständig
automatisierte Zauberwirkung. Fachquelle: SRD 5.2.1, *Sending* (S. 161;
CC BY 4.0), *Casting Spells / Components* sowie *Spell Slots*.

`SrdSendingCastPreflightRules.preview` in
`app/lib/domain/srd_sending_cast_preflight_rules.dart` verbindet die
vorhandenen, **unveränderten** Rule-Dienste
`SrdSendingRules.prepare`, `SrdSpellPreflightRules.preflight` und
`SrdSendingRules.assessDelivery`. Die Vorprüfung verlangt ausdrücklich:

- Katalogeintrag `spell-sending` mit allen originalen Metadaten
  (Grad 3, Divination, Action, Unlimited, V/S/M, Kupferdraht,
  Instantaneous). Manipulierte Metadaten werden abgewiesen.
- Bekannte und vorbereitete Zauberwahl für Barde, Kleriker oder Magier
  sowie Stufe/Slot 3 oder höher mit tatsächlich verfügbarem Slot.
- Bestätigte verfügbare Aktion, Slot-pro-Zug-Sperre, verbale, somatische
  und materielle Komponenten. Fokus statt Kupferdraht nur mit
  eigenständig bestätigter Nutzungsberechtigung.
- Eindeutige Empfänger-ID, bestätigte Kreatureigenschaft und persönliche
  Begegnung beziehungsweise Zeugenschilderung, endgültiger Nachrichtentext
  mit höchstens 25 Wörtern und den zuvor ergänzten Unicode-Sicherungen.
- Getrennte bestätigte Blockade-/Ebenenfakten. Bekannte andere Ebene
  erfordert den nachweisbaren W100-Wert; unbekannte Lage bleibt
  `unresolved`, bestätigte Blockade `blocked`.

Das Ergebnis ist eine **rein lesende Vorschau**, einschließlich
hypothetisch verbleibender Zauberplätze. Für `Unlimited` wird keine
Entfernung erfunden: Die Sending-spezifische Empfängerprüfung erfüllt die
zielbezogene Vorprüfung; die generische Reichweitenengine bleibt
unverändert auf `Unlimited` gesperrt. Es gibt **keine**
Controller-Aktion, keine Ressourcenbuchung, kein Ereignis, keine
echte Zustellung und keine Antwortsimulation.

Neue Tests: `app/test/srd_sending_cast_preflight_test.dart` (sieben
Gruppen für Klassenwahl, vorbereitete Zauber, Klasse/Stufe/Slots,
Action/V/S/M, Fokusberechtigung, Empfänger/Unicode/25 Wörter,
W100-Grenzen und manipuliertes SRD-Metadatum). Keine Datenmigration,
DB-Schema 2, Export-JSON 1 und Version 0.8.37+87 unverändert.

**Abnahme:** Dieser neue Source-Commit braucht eine eigene vollständige
GitHub-CI. Insbesondere ist noch kein ausführbarer, atomar gespeicherter
Sending-Spellcast implementiert; das ist ein späteres eigenständiges
Integrationspaket.

---

## Eingabeintegrität – 24.10.2026

**Neue lokale Sicherheitsprüfung:** `SrdSendingRules.prepare` verwirft
vor der Zählung unsichtbare Unicode-Worttrenner/-Steuerzeichen (u. a.
U+200B, U+200D, U+2060, U+202E, U+2066), eingebettete Steuerbytes und
Nachrichten über 2048 UTF-16-Codeeinheiten. Diese **2048-Grenze ist eine
technische Schutzmaßnahme der App**, keine zusätzliche Regel im SRD.
Die offizielle **25-Wörter-Grenze** bleibt unverändert und zählt weiterhin
Whitespace-Tokens. Umlaute, normale Interpunktion, Zeilenumbrüche und Tabs
bleiben zulässig. Empfängerkennungen mit internen Leerzeichen oder verdeckten
Steuerzeichen werden abgelehnt; äußeres Whitespace-Trim bleibt kompatibel.

**Regressionen:** 25 reguläre Wörter mit deutschen Umlauten/CRLF, 26
durch versteckte Zeichen verbundene Wörter, Bidi-/Null-/ESC-Steuerzeichen,
2048/2049-Einheiten sowie manipulierte Empfänger-IDs. Keine Story-/
Zauberzustandsänderung, Slot-Verbrauch, Nachrichtenzustellung oder
Datenmigration. Teststatus neuer CI noch offen.

---


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

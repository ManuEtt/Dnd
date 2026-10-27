# Charaktererstellung – Arbeits- und Abnahmenachweis (NICHT vollständig)

**Stand:** 26.10.2026 · Branch `feat/character-random-ability-rolls-20261026` · Draft-PR #264.

Dieser Dateiname kennzeichnet den geplanten Endzustand. **Weder die
Charaktererstellung noch der SRD-5.2.1-Audit sind bereits vollständig.**
Der jeweils letzte GitHub-Commit und dessen CI müssen gesondert geprüft werden.

## Quellen und Regelgrenze

Verbindlich ist das offiziell lizenzierte D&D SRD 5.2.1,
https://www.dndbeyond.com/srd, *Character Creation*, S. 21,
„Generate Your Scores“ und „Assign Ability Scores“ (CC BY 4.0).
Aus den drei Methoden werden nun Standard Array, Point Cost und Random
Generation als separate, validierte Startwertquellen angeboten.

## Implementierungspaket 1: Würfelergebnisse für Attribute

- `app/lib/domain/ability_generation.dart`: `AbilityRollSet.generate`
  würfelt exakt sechsmal vier W6, verwirft pro Durchgang den niedrigsten
  Würfel, enthält alle 24 Würfelzahlen unveränderlich. Die Würfelquelle
  ist injizierbar und daher ohne Zufall testbar. Der Attribut-Entwurf
  ist nur gültig, wenn seine sechs Werte genau dem gewürfelten Multiset
  entsprechen. Hintergrundboni werden nur aus den Basiswerten komponiert.
- `app/lib/ui/ability_assignment_dialog.dart`: Dritte Auswahlmethode,
  transparente Würfelhistorie, Tauschzuweisung aller sechs Ergebnisse
  und obligatorische ausdrückliche Bestätigung. Der Benutzer muss
  zusätzlich weiterhin Hintergrund und Erhöhungen selbst wählen.
- `app/test/ability_random_generation_test.dart`: Anzahl, Gesamtsummen,
  Duplikate, ungültige Würfelzahlen, unveränderliche Daten,
  fehlende Würfelbelege und die einmalige Bonusanwendung.
- `app/test/ui_random_ability_assignment_test.dart`: die sichtbare
  Würfelmethode und die Bestätigungssperre mit festgelegter Würfelquelle.
- Es wurde kein Speicherschema geändert. Der vorhandene Editor übernimmt
  weiterhin nur die **ausdrücklich bestätigten Endwerte**; die 24
  Würfelzahlen werden noch nicht dauerhaft mit dem Helden gespeichert.
  **Dauerhafte Provenienz von Basiswerten/Bonusentscheidungen bleibt offen.**

## Ist-Soll-Matrix (konservativ)

| Bereich | Stand nach Paket 1 | Für Vollständigkeit offen |
| --- | --- | --- |
| Attribute – Standardsatz | vorhanden; bestehende Tests | finale CI auf Integrationsstand |
| Attribute – Punktekauf | vorhanden; bestehende Tests | finale CI auf Integrationsstand |
| Attribute – 4W6 | Code + Tests auf Draft-Branch | grüne CI, Persistenz der Würfel-Provenienz |
| Hintergründe – vier SRD-Einträge | **teilweise**: Attributboni | Talente, Übungen, Ausrüstung, Entscheidungen |
| Spezies – neun Basisfamilien | **teilweise/ungeprüft** | Varianten, Pflichtentscheidungen, Mechaniken, Persistenz |
| Zwölf SRD-Klassen | **teilweise**: Katalog und Startpakete | sämtliche Startmerkmale, Zauber, Auswahlen, Tests |
| Talente/Zauber | **nicht vollständig automatisiert** | Herkunftstalente, zulässige Klassenauswahl, Ressourcen |
| Ausrüstung | **teilweise** | echte Paketübergabe, Doppelwahl-Verhinderung |
| Stufenaufstieg/Mehrklassen | **teilweise** | vollständige verbindliche Pflichtentscheidungen |
| Audit / Character Wizard | **teilweise** | echte SRD-Vollständigkeits-Validierung und geführter Ablauf |
| SQLite/JSON/Android | bisherige Formate erhalten | Realgerät, persistente Entwürfe und End-to-End-Abnahme |

**Keine der Gruppen gilt durch diesen Eintrag als vollständig getestet.**

## Implementierungspaket 2: Versionierter Attribut-Herkunftsnachweis (Stack-PR)

- `app/lib/domain/starting_ability_origin.dart` speichert die **Ausgangswerte**
  vor Hintergrundbonus, Methode, bestätigte Hintergrunderhöhungen und bei
  4W6 alle sechs Würfe mit jeweils vier Würfelzahlen. Die Struktur ist
  unveränderlich, versioniert (`version: 1`) und wird beim JSON-Import
  **regelkonform validiert**.
- `HeroCharacter.startingAbilityOrigin` ist ein **optionales Feld** im
  bestehenden Charakter-JSON `schemaVersion: 1`. Wenn es in alten
  Daten fehlt, entsteht kein neuer Standardwert. Es ist **keine**
  SQLite- oder Kampagnen-Schemaänderung notwendig.
- Der bestehende Attributdialog übergibt erst nach expliziter Bestätigung
  die Herkunft; der Charakter-Editor überträgt sie ausschließlich
  beim Speichern passender, bestätigter Stufe-1-Werte.
- `app/test/starting_ability_origin_test.dart`,
  `app/test/ability_storage_integration_test.dart`,
  `app/test/ui_ability_assignment_test.dart`: JSON-/Editor-Nachweis,
  ungültige Quelle und Würfelwerte, vollständiger SQLite-Neustart sowie
  Helden-Export/-Import.
- Ein Herkunftsnachweis ist **historisch**: spätere Stufensteigerungen
  dürfen ihn erhalten, ohne die heutigen Werte rückwirkend auf die
  Anfangswerte zurückzusetzen. Der Nachweis selbst gewährt keine
  erneuten Boni. Alte Charaktere erhalten keinen fingierten Wurf.
- Weitere separate Verbesserung nötig: unveränderliche Änderungs-
  bzw. Stufenaufstiegshistorie für **nachträglich ersetzte** Startwerte.
  Die aktuelle Metadatenstruktur enthält einen bestätigten Anfangsstand,
  noch kein vollständiges revisionssicheres Änderungsjournal.

**Abnahme:** Neue Tests wurden erstellt und als nächster GitHub-CI-Schritt
vorgesehen; vor deren Erfolg kein vollständig getestetes Paket behaupten.

## Qualitäts- und Abnahmegrenze

Die neuen Tests und die bestehende CI sollen auf der **letzten**
Branch-SHA ausgeführt werden. Weder das Schreiben eines Tests noch eine
frühere grüne CI ist ein neuer bestandener Testnachweis.
Der lokale Ausführungsrechner verfügt nicht über Flutter/Dart- oder
Android-SDK; echte Android-Geräteprüfung ist weiterhin offen.

## Nächster Implementierungsschritt

Nach Abnahme des Attribut-Herkunftsnachweises die vier SRD-Hintergründe
mit Herkunftstalenten, Übungs- und Ausrüstungsentscheidungen als eigene
prüfbare Domain-/UI-Pakete einbinden. Anschließend die Speziesvarianten.

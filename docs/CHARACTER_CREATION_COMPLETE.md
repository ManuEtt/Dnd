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

## Qualitäts- und Abnahmegrenze

Die neuen Tests und die bestehende CI sollen auf der **letzten**
Branch-SHA ausgeführt werden. Weder das Schreiben eines Tests noch eine
frühere grüne CI ist ein neuer bestandener Testnachweis.
Der lokale Ausführungsrechner verfügt nicht über Flutter/Dart- oder
Android-SDK; echte Android-Geräteprüfung ist weiterhin offen.

## Nächster Implementierungsschritt

Versionierte, rückwärtskompatible Speicherung von Attribut-Basiswerten,
Methode und Hintergrundbonus als getrennte bestätigte Provenienz
einführen. Dabei bestehende Helden nicht neu berechnen. Danach die
vollständigen vier Hintergrundpakete mit Talenten, Fertigkeiten,
Werkzeugübung und Ausrüstung als explizite Entscheidungen einbinden.

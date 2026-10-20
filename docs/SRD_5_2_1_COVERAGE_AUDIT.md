# SRD 5.2.1 – Zählbare, noch NICHT vollständige Regel-Anforderungsmatrix

**Stichtag:** 20.10.2026; geprüftes Ausgangs-Repository: `ManuEtt/Dnd`, `main` bei `b965efc3e9d337a4ce406b5e3380b79147918c66`.

**Verbindliche Quelle:** [System Reference Document 5.2.1](https://www.dndbeyond.com/srd), Wizards of the Coast LLC, CC BY 4.0. Nur diese Version und lizenziertes Material zählen; unveröffentlichte Regelbuchinhalte werden nicht ergänzt.

Die **maschinenlesbare Arbeitsmatrix** besteht aus [`docs/srd_5_2_1_requirements.json`](srd_5_2_1_requirements.json) (475 Kernpunkte) und [`docs/srd_5_2_1_entities.json`](srd_5_2_1_entities.json) (944 zusätzliche benannte Entitäten, ohne doppelte IDs). 
`docs/SRD_5_2_1_REQUIREMENTS_MATRIX.md` bleibt als **historisches Änderungsjournal** erhalten, dessen frühere Einträge teilweise bereits von neueren Entwicklungen überholt sind.

## Exakt zählbare Baseline (kein Fertigstellungsprozentsatz)

| Kennzahl | Wert | Bedeutung |
| --- | ---: | --- |
| Einmalige Arbeitsanforderungen | **1.419** | Zwei eindeutige JSON-Register; noch nicht jeder einzelne SRD-Mechanismus |
| Klassenfreischaltungen | **282** | Identische ID-Menge zum bestehenden 12-Klassen-/12-Unterklassen-Katalog |
| Weitere Prüfaufträge | **1.137** | 193 Querschnitts-/Altprüfungen plus 944 zusätzliche benannte Zauber-, Monster-, Gegenstands- und Talent-Entitäten |
| Historisch als getestet dokumentiert | **8** | Nachweis nur für spezifische Inkremente, nicht für das gesamte betroffene Kapitel |
| Als teilweise dokumentiert | **11** | Nur benannter Teilbereich implementiert/geprüft |
| Explizit als fehlend dokumentiert | **7** | Alte Matrix als Ausgangspunkt; vor Umsetzung aktuellen Code erneut prüfen |
| Noch nicht verifiziert | **1.393** | Weder als vollständig noch als fehlend behauptet |
| Offene Quellen-Inventurlücken | **9** | Namensverzeichnisse erfasst; amtlicher Vollabgleich und Aufspaltung mechanischer Effekte bleiben offen |

**WICHTIG:** 1.419 ist die Anzahl derzeit aufgelisteter Prüfaufträge, **kein offiziell vollständiger SRD-Nenner** und kein Quotient zur Schätzung des regeltechnischen Fertigstellungsgrads. Sogar 14 im älteren Klassenkatalog als `automatic` gekennzeichnete Freischaltungen sind noch kein Beleg für die tatsächliche Wirkung, End-to-End-Tests und Android-Abnahme.

## Arbeitsweise und Prüfkriterien

**Provenienz und Grenzen:** Die Entity-Namensregister sind aus [omni-5e / SRD-5.2.1-Markdown](https://github.com/azemoning/omni-5e/tree/main/data/raw/5.2.1) übernommen, nicht als amtlich vollständig gegengeprüft. Benannt sind **339 Zauber** (337 zusätzliche + 2 bereits erfasste), **235 Monster-Statblocks**, **95 Tier-Statblocks**, **260 Magiegegenstands-Einträge** und **17 Talente**. Transkriptionsfehler, Varianten-/Gruppeneinträge oder fehlende Einträge sind mit der [amtlichen SRD-PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf) zu bereinigen. Die mechanischen Effekte sind ausdrücklich **nicht** aus den Namen implementiert. Somit existiert noch kein offizieller vollständiger SRD-Nenner.

Jede Requirement-ID besitzt genau einen Quellbereich, Bereichskategorie, Status und Belegverweise auf Code und Tests, soweit bekannt. Das statusführende Feld `rule_implemented` verwendet `tested`, `partial`, `missing` oder `unverified`; eine reine Level-Freischaltung zählt **nicht** als `tested`. Der Feldwert `unlocks_catalogued` beschreibt ausdrücklich nur die Katalogisierung.

Die 282 Klassenpunkte sind stabile Scope-/Level-/Feature-Einheiten: gleiche Fähigkeit auf einer späteren Stufe zählt als neue Verbesserung, nicht doppelt auf derselben Stufe. Für **vollständige** Klassenregeln müssen diese Punkte jeweils zusätzlich in konkrete Trigger, Ressourcen, Zielregeln, Ausnahmen, Auswahl-UI, Zustandsänderung, Persistenz und Tests zerlegt werden.

Jeder magische Effekt und jede Begegnungsregel darf nur nach serverunabhängiger Validierung mechanische Werte ändern. Der KI-Erzähler ist **keine** bestätigte Regelquelle.

### Kontrolle in CI

```bash
python3 scripts/srd_coverage.py
python3 scripts/srd_coverage.py --json
python3 -m unittest discover -s scripts/tests -v
```

Der neue Regressionstest `scripts/tests/test_srd_requirements_matrix.py` läuft über den bereits vorhandenen Python-Testschritt der Android-CI. Die Prüfung verhindert doppelte IDs, ungültige Stufen, erfundene Klassenkatalogeinträge und globale Fertigstellungsbehauptungen bei offenen Lücken.

Um in Zukunft eine wirklich **vollständige Quelleninventur** zu verlangen:

```bash
python3 scripts/srd_coverage.py --require-complete-inventory
```

Dieser Aufruf schlägt **absichtlich fehl**, bis die neun Inventur- und Mechanik-Aufspaltungslücken nach Seite und SRD-Einzelregel aufgelöst, gegengeprüft und der Abschluss explizit dokumentiert sind. Der wesentlich strengere `--require-fully-tested`-Schalter setzt darüber hinaus vollständige bestandene Tests für jede Anforderung voraus.

## Entwicklung in vereinbarter Priorität

1. **Zauberengine zuerst:** amtlichen Abgleich des erfassten Zauberindex aus *Spells / Spell Descriptions* (S.107–175) mit individuellen IDs anlegen. Danach Vorbereitung, Klassenlisten, bekannte Zauber, Aktionszeit, Komponenten, Zielauswahl, Reichweite, Wirkungsdauer, Konzentration, Upcasting, Rettungswürfe, Angriffswürfe, Schutzwirkungen und Regel-Ereignisjournal testen. `Magic Missile` und `Shield` haben nur nachgewiesene Teilmechaniken.
2. **Klassenstufen 1–20:** Für alle 282 bereits katalogisierten Freischaltungen den Engine-Nachweis je konkreter Fähigkeit führen; Unterklassen nur im tatsächlich enthaltenen SRD-Scope.
3. **Monster:** Offizielle SRD-Statblocks einzeln mit Fähigkeiten erfassen; kein KI-generierter AC/HP/Angriff als autoritativ. Mehrere Gegner, Angriffsprofile, Traits, Reaktionen und begrenzte Ressourcen abtesten.
4. **Kampf/Erkundung/Magiegegenstände:** Spielablauf, Räume/Ziele, Reiseregeln, Gegenstandsladungen, Aktivierungsbedingungen, Rettungswürfe und Persistenz abrunden.

## Nächster zählbarer Meilenstein

Zuerst **GAP-SPELL-DESCRIPTIONS** schließen: 339 aus einer SRD-Transkription erfasste Zaubernamen (davon Magic Missile und Shield bereits in der Kernmatrix) anhand der amtlichen PDF vollständig abgleichen und pro Zauber einen Unique-Key, SRD-Seitenzahl und minimalen Integrationstest verlangen. Die Anzahl der SRD-Zauber darf **nicht geraten** werden. Anschließend jede einzelne Klasse und Monstergruppe analog inventarisieren; erst danach lässt sich eine belastbare Gesamt-SRD-Abdeckungsquote bilden.

Android-Gerätetest weiterhin offen; GitHub-CI muss für diese neue Branchänderung erst laufen.

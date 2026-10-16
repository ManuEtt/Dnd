# Würfelraunen 0.7.4+44 — ausführbare Klassenregeln und manuelle Rettungswürfe

**Regelgrundlage:** D&D SRD 5.2.1, CC BY 4.0. Ziel ist die regelgeleitete Ausführung von bestätigten Aktionen. Ein Merkmal, das nur im Katalog steht, gilt **nicht** als vollständig implementiert.

## Paladin 1: Handauflegen

- Der verfügbare Heilpunktevorrat ist `5 × Paladin-Klassenstufe`. Mit `Handauflegen: 7` werden nach expliziter Auswahl sieben Punkte ausgegeben; tatsächliche Heilung ist durch die maximalen Trefferpunkte begrenzt. Ungenutzte Überheilung wird nicht zurückgebucht.
- `Handauflegen: Vergiftung` entfernt den Zustand `vergiftet` für fünf Punkte, ohne TP zu heilen. Bei fehlendem Zustand oder unzureichendem Vorrat wird nicht abgebucht.
- Beide Anwendungen sind im aktiven Kampf eine Bonusaktion; der Rest der Aktion bleibt verfügbar. Die Kampf-UI zeigt einen Heilknopf (bis zum aktuell fehlenden TP-Wert) und bei Vergiftung eine gesonderte Entgiftungsaktion. Außerhalb eines Kampfes sind die expliziten Textkommandos verwendbar.
- Kurze Rast stellt den Vorrat **nicht** wieder her; lange Rast schon. Der Zähler wird über das bereits vorhandene `spentClassResources`-JSON persistiert. Die Implementierung richtet sich derzeit ausschließlich auf den bestätigten *eigenen* Charakter. Gruppenmitglieder, Berührung und Reichweitenprüfungen sind noch nicht abgebildet.

## Mönch 15: Perfekter Fokus

Beim Initiativewurf werden verbrauchte Fokuspunkte soweit regeneriert, dass vier verfügbar sind, wenn vorher höchstens drei verblieben sind. Bei vier oder mehr Punkten passiert nichts. Die Funktion wird genau einmal bei der Erzeugung einer bestätigten Begegnung ausgeführt, sowohl bei Demo- als auch bei KI-Abenteuern. Die optionale **Uncanny-Metabolism**-Entscheidung ist noch nicht implementiert; es wird keine Verwendung davon unterstellt.

## Manuelle Rettungswürfe und zwei Klassenwiederholungen

Beispiele der ausdrücklich vom Spieler/Spielleiter gewählten Schwierigkeit:

```text
Rettungswurf: Weisheit SG 15
Rettungswurf wiederholen: Fokus
Rettungswurf wiederholen: Unbeugsam
```

- Der ursprüngliche W20-Wurf wird über `CharacterRuleEngine.savingThrow` durchgeführt und das Ergebnis mit dem manuell eingegebenen SG verglichen. Eine automatische Schwierigkeit aus KI-Text wird **nicht** angenommen.
- Nach einem fehlgeschlagenen Wurf kann der Mönch ab *Mönch-Klassenstufe* 14 für einen Fokuspunkt erneut würfeln. Der Kämpfer ab *Kämpfer-Klassenstufe* 9 kann eine Nutzung von **Unbeugsam** ausgeben; zum normalen neuen Rettungswurfbonus kommt die Kämpfer-Klassenstufe hinzu. Die Nutzungen skalieren 1/2/3 bei Kämpfer-Klassenstufen 9/13/17, regenerieren erst bei einer langen Rast und werden als Ressource `indomitable` gespeichert.
- Das neue Wurfergebnis ist verbindlich, auch wenn es schlechter ist. Im vereinfachten manuellen Workflow kann **nur das unmittelbar vorangehende** Ereignis `saving.roll` einmal wiederholt werden; spätere Erzählungen oder Aktionen beenden diese Möglichkeit.
- Der Ablauf schreibt `saving.roll` und `saving.rerolled` mit Würfelergebnissen, Attributen, SG und Ressourcenverbrauch in die Ereignischronik. Es werden keine unbekannten Zustände oder Zauberwirkungen erfunden.

## Prüfung und Einschränkungen

- Keine Migration des Speicherschemas erforderlich; die zusätzliche Ressource `indomitable` wird in der bestehenden validierten Klassenressourcenkarte gespeichert.
- Die bisherigen **38 Python-Projekttests** liefen erfolgreich, die neuen **Dart-Tests** sind geschrieben, aber mangels Flutter/Dart-SDK hier nicht ausgeführt.
- Insbesondere fehlen weiterhin: automatisch vom Spielleiter gestellte Rettungswürfe aus allen Zauber-/Monsteraktionen, Wiederholungsoptionen direkt in der automatisch abgewickelten Konzentrationsprobe, Ziel-/Gruppenverwaltung, übrige Zaubereffekte, vollständige Monster-/Gegenstandsmechanik, alle Stufen- und Unterklassenfunktionen. **Die gesamte 1.247-Zeilen-Regelanforderungsmatrix ist damit nicht erledigt.**

## Belegbare Quellen

- SRD-Text: https://pages.roll20.net/hubfs/SRD_CC_v5.2.1.pdf
- Paladin: https://5e24srd.com/classes/paladin.html
- Mönch: https://5e24srd.com/classes/monk.html
- Kämpfer: https://app.roll20.net/compendium/dnd5e/Other%20Options%20and%20Features%3AIndomitable%20Feature

Lizenzhinweise: siehe bestehende `THIRD_PARTY_NOTICES.md`.

# Rabenwacht – Die vierzehnte Stimme

**Erweiterung der Handlung / Story-Bibel v0.1**  
Anschlussabenteuer zu „Das Flüstern der vergessenen Glocke“, geplant für Charaktere ab Stufe 4. Die Spielzeit ist erst nach Spieltests bestimmbar.

> **Status:** Erzählkonzept und Implementierungsvorlage, noch keine spielbare Integration in den Game-Engine-Zustandsautomaten. Die Handlung muss später mit vorhandenen Entscheidungen, Quests, NPC-Gedächtnis, SRD-Proben und Savegame-Migration verbunden werden.

## Kerngeheimnis

Die dreizehn Namen im ursprünglichen Glockeneid waren keine bloßen Zeugen. Jeder Name verankerte eine Erinnerung an die Wirklichkeit. Der vierzehnte Name gehörte dem **Chronisten**, einem Wesen, das nicht die Zeit selbst, sondern die von Menschen geteilte Erinnerung verändert. Seren war eine Hüterin des Eids, nicht dessen Urheberin.

Als der Glockenkreis geöffnet, erneuert oder umgeschrieben wurde, entstand eine Lücke zwischen den Erinnerungen der Dorfbewohner. Diese Lücke erlaubt dem Chronisten, einen vergessenen Namen wieder in die Welt einzutragen. Das ist die Ursache von Lioras widersprüchlicher Existenz. Ihre Menschlichkeit ist echt, auch wenn ihre Geschichte manipuliert wurde.

**Spielerwissen und Autorenwissen müssen getrennt bleiben.** Der Chronist wird in Akt VI nur angedeutet, in Akt VII als handelnde Figur enthüllt und in Akt VIII als Gegner oder Verhandlungspartner verständlich. Vorzeitige Hinweise sollen nicht behaupten, dass die Erinnerungsversion eines einzelnen NPC objektiv wahr ist.

## Prolog – Der vierte Teller

Am Morgen nach der Glockennacht findet Elda vier Teller auf ihrem Tisch, obwohl sie sich nur an drei Gäste erinnert. Im Kirchenbuch steht unter frischer Tinte: „Als die dreizehnte Tür geöffnet wurde, erwachte die vierzehnte Stimme.“ Tarek findet einen Brief mit seiner Unterschrift, der ihn vor einem Haus ohne Türen warnt. Eine Fremde namens Liora wird von manchen Einwohnern wie eine Tochter des Dorfes begrüßt, von anderen wie eine Einbrecherin verfolgt.

**Eröffnungstext:**

> Die Glocke schweigt. Zum ersten Mal seit Wochen hören die Menschen von Rabenwacht wieder die Vögel. Doch als Elda die Frühstückstür öffnet, hält sie vier Teller in den Händen. „Für wen ist der letzte?“, fragst du. Ihre Lippen bewegen sich, aber für einen Atemzug fällt ihr dein Name nicht ein. Hinter dir steht eine junge Frau im grauen Mantel. „Du hast mich gestern gerettet“, sagt sie. „Nur erinnerst du dich noch nicht daran.“

Der Spieler darf frei entscheiden, ob er Liora schützt, sie befragt oder zunächst andere Zeugenaussagen sucht. Keine Option darf allein wegen Misstrauens in eine Sackgasse führen.

## Akt VI – Die Namenlosen

### Szene VI-1: Dorfplatz

**Konflikt:** Liora kennt einen Satz aus dem Glockenritual, den sie nicht gehört haben dürfte. Zwei Dorfbewohner behaupten, sie sei Eldas Tochter; Elda selbst ist unsicher.

**Mögliche Ansätze:** Überzeugen oder Einsicht im Gespräch, Nachforschungen in Ratsbüchern, Wahrnehmung an Lioras Stiefeln. Die konkreten SG werden erst in der Regelimplementierung festgelegt; Fertigkeiten müssen zum tatsächlich beschriebenen Vorgehen passen.

**Konsequenzen:**
- Wer Liora öffentlich schützt, gewinnt ihr Vertrauen, riskiert aber Tareks Skepsis.
- Wer sie offen beschuldigt, erhält Zugang zu den Zweiflern, verliert aber zunächst Lioras Vertrauen.
- Wer zunächst Belege sucht, hält beide Wege offen, während ein weiterer Bewohner einen Namen vergisst.

### Szene VI-2: Drei Spuren, frei kombinierbar

**Eldas vierter Teller:** In ihrem Haus gibt es Kinderzeichnungen mit einer Gestalt, deren Gesicht immer wieder ausradiert wurde. Beweis: `memorySketch`. Elda erinnert sich nicht an eine zweite Tochter, sondern an das Gefühl, jemanden verloren zu haben.

**Tareks Brief:** Der Brief trägt zwei verschiedene Tintenalter und nennt den „Eid der Raben“. Beweis: `splitInkLetter`. Falls Tarek in der ersten Kampagne Vertrauen gefasst hat, übergibt er das Original freiwillig; sonst muss der Held ihn überzeugen oder eine Abschrift finden.

**Lioras Fußspuren:** Sie führen zum Friedhof und enden an einem Grab ohne Namen. Beweis: `namelessGrave`. Liora kann eine Erinnerung erzählen, die mit einem tatsächlich gefundenen Beleg abgeglichen werden kann; ihre Aussage ist nicht automatisch wahr.

Jede Spur zeigt einen anderen Aspekt des Geheimnisses. Zwei unabhängige Belege eröffnen die Suche nach dem Haus ohne Türen; alle drei ermöglichen später eine zusätzliche Lösung des Eids.

### Szene VI-3: Die erste Auslöschung

Der Totengräber vergisst den Namen seiner verstorbenen Frau. Der Held kann ihre Identität anhand von Grabstein, Kirchenbuch und Erzählungen rekonstruieren. **Keine magische Wiederherstellung allein durch einen Fertigkeitswurf:** Der Wurf kann Hinweise und Widersprüche erschließen, aber keine SRD-Zauberwirkung ersetzen.

**Aktabschluss:** Im Nebel hinter dem Friedhof erscheint das Haus ohne Türen.

## Akt VII – Das Haus ohne Türen

### Szene VII-1: Dreizehn Porträts

Die Porträts zeigen die Eidträger in verschiedenen Lebensaltern. Ein leeres vierzehntes Bild füllt sich mit dem Gesicht des Helden. Es ist eine **mögliche Zukunft**, keine unvermeidliche Prophezeiung.

Der Spieler kann die Bilder mit Archivbelegen vergleichen, die Reihenfolge rekonstruieren oder die Illusion als Täuschung behandeln. Scheitern kostet Zeit oder verändert das Vertrauen der Begleiter, verrät aber nicht die richtige Reihenfolge.

### Szene VII-2: Die Bibliothek der ungelebten Tage

Der Chronist bietet an, einen Verlust aus der Vergangenheit des Helden zu „löschen“. Dafür soll ein anderer Mensch aus dem Gedächtnis der Welt verschwinden.

**Entscheidungen:**
1. Angebot ablehnen: Der Chronist wird zum offenen Gegenspieler, Lioras Vertrauen steigt.
2. Verhandlung verlangen: Der Held darf Bedingungen prüfen, ohne sofort einen Namen zu opfern.
3. Angebot scheinbar annehmen: Täuschungsweg, der ein späteres Beweisrisiko schafft; keine garantierte erfolgreiche Täuschung.
4. Angebot annehmen: nur nach ausdrücklicher Bestätigung und transparenter Benennung des Preises; kein automatisches Überschreiben von Spielerbiografie oder Charakterdaten.

### Szene VII-3: Das fehlende vierzehnte Blatt

Die Gruppe entdeckt, dass die dreizehn Namen als gegenseitige Zeugen fungierten. Der Chronist konnte den Eid nicht brechen, solange jeder Name von mindestens einem anderen Eidträger erinnert wurde. Die Vergangenheit wurde nicht rückgängig gemacht; nur die kollektive Beweiskette wurde beschädigt.

**Aktabschluss:** Der Held erhält einen Namen, den niemand laut aussprechen kann, und muss entscheiden, wem er ihn anvertraut.

## Akt VIII – Der Eid der Raben

### Szene VIII-1: Der Rat der Zeugen

Die überlebenden Zeugen und ihre Nachkommen werden versammelt. Je nach Beziehungen aus Kampagne I stehen Elda, Tarek, Mara, Alrik und gegebenenfalls Seren unterschiedlich zur Verfügung. Keine Figur erscheint ohne Erklärung, wenn ihr vorheriges Ende das ausschließt.

**Ziel:** Mindestens drei voneinander unabhängige Erinnerungsbelege verbinden, um die ursprüngliche Eidformel zu rekonstruieren. Ein fehlender Beleg kann durch eine riskante öffentliche Zeugenaussage ersetzt werden; das schafft ein alternatives Finale.

### Szene VIII-2: Die vierzehnte Glocke

Der Chronist versucht, die Erinnerung an den Helden auszulöschen. Statt eines zwangsläufigen Kampfes gibt es drei Konfliktwege:

- **Eid erneuern:** Namen und Belege öffentlich verankern. Das schützt das Dorf, bindet aber einige Erinnerungen an den Ort.
- **Chronisten entmachten:** Sein Archiv zerstören, nachdem die echten Erinnerungen gesichert wurden. Liora bleibt ein eigenständiger Mensch; ihre Geschichte kann offenbleiben.
- **Neuen Eid verhandeln:** Die Bewohner entscheiden selbst, welche Erinnerungen sie teilen. Höchstes soziales Risiko, aber kein vorgeschriebenes Opfer.

Kampf ist eine mögliche Eskalation, jedoch erst nach gesonderter Erstellung regelkonformer Gegnerwerte, Initiative, Aktionsökonomie und Tests spielbar. Der Chronist darf nicht allein durch eine freie Texteingabe oder einen einzigen gelungenen sozialen Wurf endgültig besiegt werden.

## Abhängigkeit vom ersten Finale

| Vorheriges Ende | Konsequenz im neuen Kapitel |
| --- | --- |
| Siegel erneuert | Der Chronist spricht durch Risse im alten Eid. Seren bleibt an die Grenzen des Siegels gebunden; Informationen kommen über Spuren oder Träume. |
| Siegel gebrochen | Der Chronist kann unmittelbarer wirken. Die Bewohner sind gefährdeter; der Held erhält dafür einen direkteren Zugang zum verlorenen Archiv. |
| Seren erlöst | Seren kann als Erinnerung oder eigenständige Erscheinung Hinweise geben, aber nur, soweit ihre Erlösung im bestehenden Spielstand diese Möglichkeit zulässt. |

Diese Tabelle ist **eine Implementierungsanforderung**, kein Beweis, dass die aktuelle App diese Zustände bereits auswertet.

## Zustands- und Questentwurf

Vorgesehener separater Modus `rabenwacht-voice-v1` oder explizite Erweiterung mit Savegame-Migration. Die bestehende `rabenwacht-v1`-Kampagne darf beim Laden nicht stillschweigend in Akt VI springen.

**Quests:** `voice-main` (Hauptgeheimnis), `voice-witnesses` (Beweiskette), `voice-liora` (Vertrauen), `voice-gravedigger` (optionale Rekonstruktion). Optionale Quests werden bei einem Finale nicht pauschal als abgeschlossen markiert.

**Fakten:** `memorySketch`, `splitInkLetter`, `namelessGrave`, `lioraTrust`, `tarekTrust`, `chronistOffer`, `chronistBargain`, `witnessChain`, `voiceEnding`. Vertrauensänderungen müssen auf tatsächlich gespielte Handlungen zurückgehen.

**Story-Threads:** `whoIsLiora`, `fourteenthName`, `chronistBargain`, `brokenOath`. Nur gefundene Informationen erscheinen im spoilerfreien Hinweisprotokoll.

## Abnahmekriterien für die spätere Implementierung

1. Alle drei ursprünglichen Enden führen zu logisch unterschiedlichen Einstiegen ohne Retcon.
2. Die drei Spuren können in beliebiger Reihenfolge verfolgt werden; mindestens zwei sind für den Fortgang erforderlich.
3. Negative oder misslungene Würfe ändern nachvollziehbare Zustände, ohne das Abenteuer unspielbar zu machen.
4. NPC-Vertrauen wird gespeichert und nach Laden identisch wiederhergestellt.
5. Kein Zauber, keine Klassenfähigkeit, keine Gegnerstatistik und keine Erfahrungspunkte werden ohne geprüfte SRD-Regelaktion vergeben.
6. Ein abgeschlossenes Kapitel verändert nicht automatisch den Status unbesuchter Nebenquests.
7. Keine zukünftige Wendung wird durch Hinweise, Journal oder Questtitel vor ihrer Entdeckung verraten.
8. Für jeden Abschlussweg gibt es einen vollständigen automatisierten Test und einen Android-Gerätetest vor einer Releasefreigabe.

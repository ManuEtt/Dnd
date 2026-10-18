# Todesrettungen 0.7.9+49

Regelquelle: offizielles [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0, Kapitel Damage and Healing (S. 17–18), Fighter: Indomitable auf Klassenstufe 9 und Monk: Disciplined Survivor auf Klassenstufe 14. Attribution: THIRD_PARTY_NOTICES.md. Anforderungs-ID EFFECT-DEATH-SAVE, ergänzend COMBAT-TURN-END / CLASS-MONK / CLASS-FIGHTER.

## Ausführbarer Umfang

`DeathSavingThrowRules` berechnet Todesrettungen ohne Attributsmodifikator. Ein Mönch mit mindestens 14 tatsächlichen Mönchsstufen erhält den Übungsbonus der Gesamtstufe; Erschöpfung wird einmal abgezogen. Ab Gesamtwert 10 Erfolg, natürliche 1 immer zwei Fehlschläge, natürliche 20 immer 1 TP und Rücksetzen der Todesrettungen. Drei Erfolge stabilisieren; drei Fehlschläge töten.

Disciplined Survivor ersetzt einen fehlgeschlagenen Wurf für einen Fokuspunkt; Indomitable ersetzt ihn bei mindestens neun Kämpferstufen für einen Einsatz und addiert die tatsächliche Kämpferstufe. Der Ersatzwurf ist verbindlich, auch bei schlechterem Ergebnis. Keine Aktion/Reaktion erforderlich. Der Ressourcenverbrauch bei 0 TP ist eng auf diese Regel begrenzt; die allgemeine Ressourcensperre bleibt bestehen. Keine Verkettung mehrerer Wiederholungen im implementierten Ablauf.

Die erste misslungene Rettung wird bei verfügbarer Wiederholung **nicht** auf die Figur angewandt. `Campaign.pendingDeathSave` speichert Naturwurf und validierten Bonus; der Held bleibt im Zustand vor dem Wurf. Die deutsche Auswahl erscheint im tatsächlichen Spiel. Annehmen braucht keine neue Zufallszahl und keinen Einsatz; Wiederholen bucht genau eine Ressource und das endgültige Ergebnis. So bleibt auch ein vorläufiger dritter Fehlschlag ersetzbar.

Im aktiven Solokampf ist die Rettung nur im eigenen Zug möglich. Nach Bestätigung schützt `Encounter.deathSaveResolvedThisTurn` vor weiteren Rettungen im gleichen Zug. Bei 0 TP darf der Spieler anschließend ausdrücklich seinen Zug beenden; eine natürliche 20 lässt den restlichen Zug zu. Der nächste eigene Zug setzt die Markierung zurück. Stabile Figuren benötigen keine Rettung.

## Speicherung und Validierung

Snapshot und Ereignis werden atomar über den vorhandenen Controller bestätigt, einschließlich Ressourcen und Auswahl. Die Oberfläche sendet Kampagnen-ID und erwartete Revision; veraltete Entscheidungen werden verworfen. Solange die Entscheidung offen ist, sind fremde Aktionen und externe Charaktereffekte gesperrt. Eine ausdrückliche Charakterbearbeitung verwirft überholte offene Würfe/Entscheidungen.

Schema 1 bleibt kompatibel: alle neuen Felder sind optional. Alte Todesrettungsanfragen mit Modifikator 0 bleiben importierbar; die endgültige Berechnung verwendet den bestätigten Charakter. Neue Anfragen sind durch `deathSaveRulesVersion: 1` erkennbar und müssen den aktuellen Bonus tragen. Die vorläufige Auswahl darf nur einen tatsächlich misslungenen Wurf mit verfügbarer Ressource enthalten. Gleichzeitiger offener Wurf und Auswahl, falscher Bonus, falscher Zug, bereits verbuchte Rettung und ungültige Typen werden beim Import abgelehnt.

## Verifikation und Grenzen

19 Domänentests und 18 Integrationsfälle decken natürliche 1/20, Mehrklassen, Erschöpfung, echten Einsatzverbrauch bei 0 TP, niedrigere Ersatzwürfe, fatalen Ausgang, Zugwechsel, Altimporte/Manipulation, Ereigniswiederherstellung, reale SQLite-Neustarts, späten Transaktionsabbruch, veraltete Revision und die echte Spieloberfläche ab. Eine 320-dp-Auswahl mit Textskalierung 1,8 wurde geprüft. Dazu 20 Zuggrenzenregressionen, einschließlich dauerhaftem Kampfrauschende bei externem KO oder bestätigter Handlungsunfähigkeit; aktueller Gesamt- und Buildstatus in CHECKPOINT.md.

Keine allgemeine Weltzeit außerhalb des Solokampfs, Gruppenmitglieder, Quellen für beliebige Rettungswurfboni oder Verkettung verschiedener Wiederholungsmerkmale implementiert. Allgemeine quellgebundene Zustände/Dauern bleiben Entwurf. Emulator und reales Androidgerät sind gesonderte Abnahmen.

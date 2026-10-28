## 27.10.2026 – Lesender Entscheidungs-Audit

Der bestehende Klassen-/Charaktereditor zeigt sieben deutsche Prüfzustände.
Bekannte Namen bestätigen nur die benannte Teilzuordnung; Klassenmerkmale,
Fertigkeiten und Ausrüstung benötigen eigene Entscheidungsbelege. Insbesondere
belegen Gold 0 und Hintergrundpakete kein Klassenstartpaket. Bestehende
Spielstände werden nicht neu berechnet. [Aktueller Fachstand](CHARACTER_CREATION_AUDIT_20261027.md).
Die älteren Abschnitte unten beschreiben die schrittweise Entwicklung.

# Klassenwahl und Startpakete – Aetheria 0.3.3

Quelle: SRD 5.2.1, Abschnitt „Classes“: https://www.dndbeyond.com/srd

## Verwendung auf Android

1. **Neuen Helden erschaffen** öffnen. Name, Spezies und Stufe 1 eintragen.
2. Über **Attribute ermitteln** die offiziellen Grundwerte bestimmen (Standardsatz, 27-Punkte-Kauf oder 4W6 mit gestrichenem niedrigsten Würfel); Hintergrundboni ausdrücklich zuweisen.
3. **D&D-Klasse und Fertigkeiten wählen** öffnen und eine der zwölf unterstützten Klassen auswählen.
4. Die vorgeschriebene Anzahl unterschiedlicher, für diese Klasse erlaubter Fertigkeiten wählen. Die zwei passenden Rettungswurf-Übungen werden angezeigt.
5. Optional den Start-TP-Vorschlag einschalten, sobald ein bestätigter KO-Wert vorliegt. Bei einer neuen, noch nicht ausgestatteten Figur kann auch die SRD-Startausrüstung oder ein Startgoldpaket gewählt werden.
6. **Klasse und Fertigkeiten übernehmen** bestätigen, danach **Charakter speichern** wählen.

Auf Stufe 2–20 ist der neue Klassenauswahlassistent **nicht** als Stufenaufstiegs- oder Mehrklassen-Funktion verwendbar.

## Sicherer Umgang mit alten Charakteren

- Der Assistent verändert den Charakter erst nach Bestätigung. Abbruch lässt alles unverändert.
- Vorhandene Fertigkeiten und Rettungswurf-Übungen werden standardmäßig um neue ergänzt. **Bestehende Übungen ersetzen** überschreibt die Listen ausdrücklich und kann eingetragene Hintergrundübungen entfernen.
- Vorhandene Trefferpunkte werden nur dann überschrieben, wenn die entsprechende Checkbox bewusst aktiviert wird.
- Vorhandene Ausrüstung und Gold werden bei bestehenden Charakteren nicht angetastet. Startpakete sind nur für neu angelegte Charaktere verfügbar, solange noch keine Gegenstände oder Gold ausgewählt wurden.
- Ein Ausrüstungsgegenstand im Inventar wird nicht automatisch angelegt. Eine Rüstungsklasse wird nicht aufgrund dieses Pakets gesetzt.
- Fremde und alte Klassenbezeichnungen bleiben beim Öffnen des bestehenden Charakters erhalten. Die Auswahl einer SRD-Klasse ist freiwillig.

## Attributregeln

Bei neuen Charakteren schützt der Editor die durch den Standardsatz oder den Punktekauf einschließlich Hintergrundboni ermittelten Endwerte vor stillen manuellen Änderungen. Wer direkt eigene Attributwerte eintragen will, muss **Manuelle Attribute als Hausregel zulassen** aktivieren. Für historische Charaktere gilt diese neue Einschränkung nicht. Eine dauerhafte Herkunfts-/Regelversion-Metadatenerfassung steht noch aus.

## Unterstützter Umfang und Grenzen

Der Assistent setzt die Startlisten aus dem SRD 5.2.1 um: zwölf Klassen, Rettungswurf-Übungen, Klassenfertigkeiten, Trefferwürfel und optionale Ausrüstung/Startgold. Er implementiert noch **keine** Charaktermerkmale, Werkzeugauswahl, Hintergrund-Fertigkeiten, Talente, Zauberauswahl, automatische Rüstungsberechnung, Mehrklassenregeln oder automatische Stufenaufstiege.

Regeltexte sind für die Benutzeroberfläche vereinfacht und in eigene deutsche Bezeichnungen übersetzt. Vorrang hat das zitierte SRD. Automatische Python-Projektprüfungen sind kein Ersatz für Flutter-Analyse und Android-Gerätetests.

## Neu: EP und Kämpfer-Startwerte (Entwicklungsstand)

- Neue Charaktere starten auf Stufe 1 mit **0 EP**. Bei Änderung der
  Gesamtstufe wird die SRD-5.2.1-Untergrenze (1–20) eingetragen, solange die
  EP nicht ausdrücklich manuell bearbeitet wurden. Ein Neucharakter darf
  nur eine zum eingetragenen Level passende EP-Zahl speichern. Der Übungsbonus wird
  gemäß Gesamtstufe berechnet (+2 bis +6) und nicht doppelt gespeichert.
- Für einen neu angelegten **Kämpfer auf Stufe 1** verlangt der Klassenassistent
  bestätigte Konstitution, genau zwei Klassenfertigkeiten, einen der vier
  in SRD 5.2.1 publizierten Kampfstile, drei unterschiedliche Waffenarten mit
  Meisterschaftseigenschaft und eine der SRD-Startausrüstungen A/B/C.
- Nach Bestätigung werden **10 + KO-Modifikator** als maximale und aktuelle
  Trefferpunkte (mindestens 1), Übung in Stärke-/Konstitutionsrettungen,
  Kampfstil, Waffenmeisterschaftsauswahl und die Beschreibung von **Zweite Luft
  (2 Anwendungen)** übernommen. Die Startausrüstung/Goldauswahl bleibt wie bisher
  ausdrücklich gewählt; Rüstung wird nicht automatisch angelegt.
- Kampfstil- und Meisterschaftsauswahl wird im bestehenden Feature-Listenformat
  abgelegt. Sie beweist **keine automatische Umsetzung** der entsprechenden
  Kampfeffekte; diese dürfen nur durch bestätigte Regelengine-Mechaniken wirken.
- Alte importierte Charaktere behalten ihre bisherigen EP (auch `null`), TP,
  unvollständigen Daten und Geschichte. Kein rückwirkendes Überschreiben.

Regelquellen: https://www.dndbeyond.com/srd, SRD v5.2.1:
*Character Creation/Level Advancement*, *Classes/Fighter* und
*Feats/Fighting Style Feats* (CC BY 4.0).

## Ergänzung 26.10.2026 – 4W6-Attributmethode, PR #264

Die neue Methode ist auf einem Draft-Branch implementiert und besitzt
deterministische Domain- und UI-Tests. Noch nicht als vollständig
abgenommen: CI des letzten PR-Commits, lokale Flutter-/Android-Prüfung,
Persistenz der einzelnen Würfel und der Attribut-Provenienz,
übrige Pflichtentscheidungen. Details:
[Charaktererstellung](CHARACTER_CREATION_COMPLETE.md).

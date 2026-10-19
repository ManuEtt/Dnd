# Würfelraunen 0.8.11+61 – Passive Wahrnehmung

## Quelle und Regelstand

Referenz: Vom Projektauftrag bereitgestelltes deutsches **D&D-Einsteigerset-Regelbuch**, Kapitel 1, Seite 6, Abschnitt **„Verstecken und Sehen“**, Unterabschnitt „Passive Wahrnehmung“. Die Quelle nennt 10 plus Weisheits-/Wahrnehmungsmodifikatoren und ±5 bei Vorteil bzw. Nachteil. Die allgemeine Vorteil-/Nachteil-Aufhebung steht auf Seite 5.

**Wichtig:** Das Einsteigerset beschreibt die ältere D&D-5e-Regelfassung. Würfelraunen verwendet für Klassen, Erschöpfung und andere Mechaniken weiterhin **SRD 5.2.1 (2024)**. Diese Erweiterung übernimmt nur die passende grundlegende Rechenregel; sie ändert **nicht** das Überraschungs-, Erschöpfungs-, Deckungs- oder Zauberregelwerk und importiert **keine** Seiten oder urheberrechtlich geschützten Texte aus der hochgeladenen PDF.

## Implementierung

- Reine Funktion `CharacterRuleEngine.passivePerception(hero, situationalAdvantage:, situationalDisadvantage:)`: **10 + berechneter Modifikator für Wahrnehmung**; berücksichtigt bestätigte Weisheit, Wahrnehmungsübung, Bardenmerkmal Alleskönner sowie Erschöpfung.
- Vorteil bzw. Nachteil verändern den passiven Wert um +5 bzw. −5. Mehrere Quellen stapeln nicht; entgegengesetzte Effekte heben sich auf. Ein im Charakter gespeicherter Nachteil (z. B. Vergiftung) wird berücksichtigt.
- Bei fehlender Weisheit, Tod, 0 TP oder Bewusstlosigkeit liefert die Funktion **keinen erfundenen Wert**, sondern `null`.
- Der **Fantasy-Charakterbogen** zeigt den passiven Wert sichtbar in einer kompakten Zeile direkt nach den vier Kernwerten. Unbekannte Werte werden als „–“ erklärt.
- Die **Offline-Spielleitung** beantwortet die Formulierung `passive Wahrnehmung` bzw. `passiven Wahrnehmung`, ohne W20 zu würfeln. Der Wert wird im Ereignisprotokoll vermerkt.
- Eine solche Abfrage **öffnet keine versteckten Türen**, **erfindet keine Monsterpositionen**, **löst keine Geschichte aus** und **ersetzt keine bereits offene aktive Probe**. Ob Wahrnehmung überhaupt möglich ist, ob ein Gegner in Sicht/Hörweite ist und welchen SG seine Heimlichkeit hat, muss aus einer bestätigten Szene stammen.

## Beispiele

- Weisheit 12 (+1), Wahrnehmung geübt, Charakterstufe 1 (+2 Übung): **13**.
- Der gleiche Charakter mit bestätigtem situativem Vorteil: **18**, mit Nachteil: **8**.
- Ungeübter Barde Stufe 2, Weisheit 12: **12** (10 +1 Weisheit +1 halber Übungsbonus).
- Ein Kämpfer 7 / Barde 2 nutzt **den Übungsbonus aus der Gesamtstufe 9**; Barden-Stufe 2 schaltet Alleskönner frei.

## Prüfungen

`app/test/passive_perception_test.dart` enthält Rechentests für Übung, Alleskönner/Mehrklassen, situative Vorteile und Nachteile, Vergiftung, Erschöpfung, fehlende Werte, bewusste Blockierung bei 0 TP, gespeicherte Ereignisse, die Unveränderlichkeit der Kampagne und den Charakterbogen bei 320/360/400 dp. Die vollständige bestehende Flutter-/Backend-Test-Suite und die Android-Builds müssen vor Integration grün sein.

Die Einsteigerset-PDF wird **nicht** in das Repository hochgeladen. Das Regelbuch bleibt eine vom Nutzer bereitgestellte Referenz.

# Würfelraunen 0.8.10+60 – automatisierte Barden- und Schurkenfähigkeiten

**Regelbasis:** D&D SRD 5.2.1 / D&D 2024, CC BY 4.0; https://www.dndbeyond.com/srd.

## Neu in der tatsächlich ausführenden Regelengine

- **Alleskönner (Jack of All Trades), Barde Klassenstufe 2:** Bei einer benannten Fertigkeitsprobe, in deren Fertigkeit der Charakter **nicht** geübt ist, wird die Hälfte des Übungsbonus auf Basis der **gesamten** Charakterstufe abgerundet addiert. Keine zweite Anrechnung bei vorhandener Fertigkeitsübung; die 2024-Regel gilt nicht pauschal für Initiative, Rettungswürfe, Angriffe oder eine unspezifische Attributsprobe.
- **Verlässliches Talent (Reliable Talent), Schurke Klassenstufe 7:** Bei einer tatsächlich geübten, benannten Fertigkeitsprobe gilt ein natürlicher W20-Wurf unter 10 für die Wertung als 10. Der **tatsächlich gewürfelte** Wert bleibt im Protokoll unverändert gespeichert. Die Probe kann mit Vorteil oder Nachteil erfolgen; erst der gewählte natürliche Würfel wird gegebenenfalls aufgewertet. Manuell bestätigte **Gesamtergebnisse** werden niemals stillschweigend verändert.
- **Schlüpfriger Geist (Slippery Mind), Schurke Klassenstufe 15:** Der Übungsbonus wird bei Rettungswürfen auf Weisheit und Charisma automatisch berücksichtigt, wenn er nicht bereits aus einer anderen Quelle hinzugefügt wird. Gilt auch bei Mehrklassencharakteren ab Schurken-*Klassenstufe* 15.

## Anwendung

Die passiven Fertigkeitsregeln werden in der vorbereiteten Kampagne Rabenwacht (Wahrnehmung, Heimlichkeit, Arkane Kunde usw.) und bei bestätigten Wahrnehmungsproben im allgemeinen Erzähl- und Ermittlungsablauf berücksichtigt. Offene W20-Proben speichern den rechnerischen Bonus und einen eventuellen Schurken-Mindestwurf in der Kampagne. Das Laden validiert die Zustände gegen den tatsächlich gespeicherten Charakter.

Ein Beispiel: Ein Schurke der Stufe 7 mit Wahrnehmungsübung und WE 12 würfelt eine natürliche **1**. Bei einem Übungsbonus +3 beträgt die unmodifizierte Summe 5. Verlässliches Talent behandelt die natürliche 1 als 10 und wertet die Probe stattdessen mit **14**. In der Ereignishistorie bleiben sowohl der echte Naturwurf 1 als auch die 14 nachvollziehbar.

## Grenzen

Automatisch unterstützt sind **bestätigte Fertigkeitsproben**. Es gibt noch kein frei kombinierbares Fertigkeits-/Werkzeug- und Expertise-System für sämtliche denkbaren Handlungen: Tool-Checks, frei gesprochene situative Vorteile und andere Klassenmerkmale müssen weiterhin explizit geregelt werden. Alleskönner wird daher nicht als pauschaler Bonus auf jeden beliebigen Attributswurf behandelt.

Bereits bestehende Spielstände ohne das neue `minimumNatural`-Feld sind weiter lesbar. Laufende ältere Würfelanforderungen bleiben bei der zum Zeitpunkt des Speicherns bestätigten Wertung; neue Anfragen benutzen den verbesserten Regelkern.

## Tests und Code

- `app/lib/domain/skill_check_passives.dart`: reine 2024-Fertigkeitsregeln
- `app/lib/domain/character_rule_engine.dart`: Klassen- und Attributsbonus
- `app/lib/domain/game_engine.dart`: natürliche und effektive Würfelwerte
- `app/lib/domain/models.dart`: Validierung und Kompatibilität offener Proben
- `app/test/skill_check_passives_test.dart`: Stufenschwellen, Mehrklassen, kein Bonus-Stapeln, Runen-/Wahrnehmungsproben, Persistenz und Eingabeschutz

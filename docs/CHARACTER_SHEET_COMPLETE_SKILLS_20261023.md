# Charakterbogen – alle 18 SRD-Fertigkeiten (23.10.2026)

## Ausgangslage
Ausgangscommit: `3ad3d63164dba139d90d2d3a605ea103bcd72e6d`.
Das nach PR #123 fest verankerte Referenzdesign zeigt in der
Fertigkeitenkarte sechs hervorgehobene Beispiele. Bisher listete jedoch
**auch „Alle anzeigen“ nur diese sechs** plus ungeprüfte andere gespeicherte
Fertigkeiten auf. Dadurch fehlten zwölf reguläre Fertigkeiten im Detaildialog.

Zudem verwendete die ältere Designvorlage „Medizin“, der mit dem aktuellen
SRD-Klassenkatalog abgestimmte und bei der Charaktererstellung bestätigte
Name ist jedoch „Heilkunde“. Eine reine Ersetzung der Bezeichnung würde
historisch gespeicherte Charaktere fälschlich als ungeübt anzeigen.

## Implementiert
- Ein lesender Standardkatalog `srdSkillAbilities` ordnet den 18 Namen aus
  `srd_character_classes.dart` die normalen fünf zugehörigen Attribute
  zu. Das sind **Standardzuordnungen**; situative Abweichungen durch
  explizite Spielleiterentscheidung bleiben möglich.
- Die Grafik selbst behält sechs kompakte Einträge, der Detaildialog
  „Alle anzeigen“ zeigt alle **18** SRD-Fertigkeiten und deren aktuell
  berechnete Boni über `CharacterRuleEngine.abilityCheck`.
- Die bestehende Anzeigenbezeichnung „Medizin“ und der kanonische
  Speicherschlüssel „Heilkunde“ werden ohne Änderung des Spielstands
  für den *gleichen* Skill aufgelöst. Der Regelengine wird der tatsächlich
  gespeicherte Fertigkeitsname übergeben, damit Barden-/Schurken- und
  Erschöpfungsregeln unverändert angewendet werden.
- Andere nicht im SRD-Katalog definierte historische Fertigkeiten
  bleiben sichtbar, aber erhalten ausdrücklich **keine erfundene
  automatische Berechnung**.
- Unbekannte Attributwerte erscheinen als „–“, nicht als 0.
- Die einmalige Pergamenttafel mit sechs Attributen, gespeicherte
  Porträts, Zauber, Zustände, Ausrüstung, Rettungswürfe und die
  feststehende W20-Schnellaktionsleiste bleiben unverändert.

## Testmatrix
`app/test/fantasy_complete_srd_skills_test.dart` prüft
Katalogvollständigkeit und -reihenfolge, 18 Detailzeilen und
Regelengine-Boni, Kanonisch-/Altnamenprofil, Legacy- und unbekannte
Attribute, keinen falschen Bonus, unverändertes Charakter-JSON
sowie den Schutz gegen eine zweite Attributtafel.

Zusätzlich vollständige vorhandene Regel-, Charakterbogen-, UI- und
Android-CI ausführen. Ein erfolgreiches Dateischreiben oder ein
grüner PR ohne die vollständigen Tests ist kein Buildnachweis.

## Nachweise, Rechte und Grenzen
Quelle: Wizards of the Coast LLC, *System Reference Document v5.2.1*,
„Playing the Game“ / „Skills“ (CC BY 4.0),
https://www.dndbeyond.com/srd .
Die App verwendet die bereits in diesem Repository vorhandenen
deutschen Bezeichnungen und den autoritativen Klassenkatalog.

Status nach CI:
- **Implementiert:** Anzeigekatalog, Regel-/Altnamenauflösung, Tests im Branch.
- **Getestet:** nur bei grünen, commitgenauen GitHub Checks.
- **Nicht getestet:** Echtes Android-Gerät / visuelle Pixelabnahme.
- **Noch nicht implementiert:** interaktive Rollenauswahl oder automatische
  Abweichungen von den normalen Fertigkeitsattributen; diese benötigen
  explizite Regelführung.

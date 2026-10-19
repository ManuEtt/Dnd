# Würfelraunen 0.8.9 – regelbasierter Stufenaufstieg (SRD 5.2.1)

## Was vollständig im Aufstiegsablauf berücksichtigt wird

- **Gesamtstufe 1–20** für alle zwölf Grundklassen des SRD, jeweils genau eine Stufe pro bestätigtem Aufstieg.
- **Kumulative Erfahrungspunkte** mit SRD-Schwellen oder bewusst ausgewählter Meilenstein-Regel. Beim Aufstieg werden XP nicht verbraucht.
- **Übungsbonus nach Gesamtstufe**, Klassenstufen getrennt pro Klasse.
- **Trefferpunkte**: bestätigte Konstitution, fester Zuwachs des jeweiligen Trefferwürfels ab Klassenstufe 2 und rückwirkende HP-Anpassung bei Änderung des Konstitutionsmodifikators.
- **Talentauswahl / Attributsverbesserung** (+2 oder +1/+1, bis Attribut 20) auf den passenden Klassenstufen; andere Talente bleiben als ausdrücklich offene Auswahl erfasst.
- **Haupt- und Zweitklasse** mit ihren eigenen Klassenstufen, ihren eigenen auf Stufe 3 gewählten SRD-Unterklassen und nur den dafür freigeschalteten Merkmalen.
- **Zusätzliche Klasse wählen:** Attributsvoraussetzungen beider Klassen, zusätzliche Fertigkeitswahl soweit anwendbar, keine unerlaubte Startausrüstung/Startrettungswürfe, standardmäßige XP-Prüfung; Meilensteine müssen im Dialog ausdrücklich angewählt werden.
- **Charakterbogen, Fortschrittsanzeige, Speicherung und Export** verwenden den bestätigten Stand; alte JSON-Spielstände ohne `secondarySubclass` laden unverändert.
- **Sicherheitsregeln** gegen Stufe 21, doppelte Unterklasse, veraltete Aufstiegsvorschläge und fehlende bestätigte TP/Attribute.

## Was nicht als fertig simulierte 5e-Klassenmechanik ausgegeben wird

Ein Klassenmerkmal in der SRD-Tabelle ist **nicht automatisch eine vollständig implementierte Wirkung**. Bereits vorhandene Engine-Systeme berechnen die tatsächlich unterstützten Aktionen (z. B. zusätzliche Angriffe und verschiedene Klassenressourcen). Die anderen Merkmale bleiben im Charakterbogen mit Kennzeichnung `Regelprüfung erforderlich`, ihre nicht gewählten Unterklassen/Talente als explizite offene Entscheidungen. Das betrifft insbesondere nicht implementierte Talente und deren Sonderwirkungen, zusätzliche Zauberauswahl und komplexe Unterklassenmerkmale. Keine automatischen oder fiktiven Zauber- und Talentboni.

Die App erlaubt bewusst auch manuell bestätigte Charakterbögen; deshalb ersetzt die XP-Prüfung im Aufstiegsassistenten kein vollständiges Rollen- und Rechtemodell gegen nachträgliche manuelle Änderungen.

## Bedienung

1. Aktiven Charakter öffnen und im Editor **Bestehende Klasse nach SRD steigern** wählen.
2. Haupt- oder Zweitklasse auswählen und **Erfahrung** (Standard) oder ausdrücklich **Meilenstein** bestimmen.
3. Falls fällig, SRD-Unterklasse und Attributsverbesserung wählen. Die Vorschau zeigt Trefferpunkte und neu freigeschaltete Tabellenmerkmale.
4. Aufstieg bestätigen, danach **Charakter speichern**. Die App aktualisiert gespeicherte Kampagnen über das vorhandene Controller-/Repository-System.
5. Zum **erstmaligen Hinzufügen einer zweiten Klasse** den separaten Zweitklassen-Assistenten verwenden. Bereits existierende Zweitklassen werden im normalen Klassenaufstieg fortgeführt.

## Prüfungen

`app/test/full_level_up_progression_test.dart` umfasst die Klassenspanne 1–20, beide Unterklassen, die XP-/Meilenstein-Prüfung, den Ausschluss nicht verfügbarer Klassenmerkmale, alte Spielstände und ungültige Aufstiegsvorschläge. Zusätzlich bleiben die bisherigen Klassen-, Kampf-, Mehrklassen-, XP- und UI-Tests erforderlich.

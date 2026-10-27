# Chat A – Waldläufer Roving (SRD 5.2.1), 27.10.2026

**Repository:** `ManuEtt/Dnd` · **Ausgangsbasis:** `main@4bd97b4d72fc747228df9bea46b61c3d4c82c382` · **Entwicklungsbranch:** `feat/chat-a/ranger-roving-20261027`.

## Quelle / Scope

- Offizielles **SRD 5.2.1**, Wizards of the Coast LLC, **CC BY 4.0**, *Ranger – Level 6: Roving*, https://www.dndbeyond.com/srd.
- Anforderung `CLASS-WALDL-UFER-6-BASE-ROVING-0`.
- Die Laufgeschwindigkeit steigt um 10 Fuß (im Projektmodell 3 m), solange keine schwere Rüstung getragen wird. Der Waldläufer erhält außerdem Kletter- und Schwimmgeschwindigkeit entsprechend seiner aktuell wirksamen Geschwindigkeit.

## IMPLEMENTIERT

- `app/lib/domain/character_rule_engine.dart`: Rückgriff nur auf tatsächlich bestätigte Waldläufer-**Klassenstufe 6** (auch als Zweitklasse), nicht Gesamtstufe 6; 3 m Bonus in der allgemeinen berechneten Geschwindigkeit, ohne den gespeicherten Grundwert zu überschreiben. Beim Rüstungswechsel oder Rest/Statusneuberechnung folgt die Anzeige dem aktuellen Zustand.
- Nur bestätigte SRD-Katalogeinträge entscheiden, ob eine ausgerüstete Rüstung schwer ist; eine unbekannte ausgerüstete Rüstung schaltet den Bonus **nicht** frei.
- Die abgeleiteten, read-only `rovingClimbSpeedMeters` und `rovingSwimSpeedMeters` liefern die effektive Geschwindigkeit einschließlich Erschöpfung, Bewegungsverbot und schweren Rüstungs-/Stärke-Abzügen. Schwere Rüstung blockiert nur den 3-m-Bonus, **nicht** die Zuteilung dieser beiden Geschwindigkeitsarten.
- `app/lib/ui/fantasy_character_sheet.dart` zeigt Kletter-/Schwimmgeschwindigkeit unter Verteidigung bei bestätigter Ranger-Klassenstufe >= 6 an.
- `app/lib/domain/srd_class_feature_catalog.dart` stuft Roving weiterhin ausdrücklich nur als **partial** ein. Kein neues SQLite-Schema, kein neuer Eventtyp, keine unbestätigte automatische Geländeaktion, keine Änderung der gespeicherten Bewegung.

## TESTS IMPLEMENTIERT (Ausführung nur durch nachfolgende CI belegt)

- `app/test/ranger_roving_rules_test.dart`: Stufengrenzen, Primär- und Zweitklasse, andere Klassen, bestätigte schwere/mittlere Rüstung und Schild, unbekannte Rüstung, barbarisches Fast Movement, Erschöpfung, Halbmeterschritte, Bewegungsverbot, fehlende Basisgeschwindigkeit und JSON-Kompatibilität.
- `app/test/ranger_roving_sheet_test.dart`: Anzeigen auf dem Charakterbogen vor/nach Stufe 6 und mit schwerer Rüstung.

## GETESTET / NICHT GETESTET / BLOCKIERT

- Die **neu hinzugefügten Tests** sind bis zur erfolgreich abgeschlossenen GitHub-CI auf dem finalen PR-Head **nicht bestanden gemeldet**. Im Connector-Sitzungskontext sind kein lokales Dart-/Flutter- und Android-SDK vorhanden; deshalb weder lokale Analyse noch APK, Emulator, TalkBack oder echter Gerätetest behauptet.
- CI-Fehler werden vor Merge über einen separaten Commit korrigiert. Draft-PR, keine fremden Branches verändern.

## NOCH NICHT IMPLEMENTIERT

- Eine konkrete Kletter-/Schwimm-`RuleCommand` mit Terrain-/Wasserbedingungen, korrekter Bewegungsausgabe, bestätigter Spielerentscheidung und persistiertem Ereignis; derzeit nur Geschwindigkeit und Bewegungsvorrat berechnet und angezeigt. Gelände- und Umgebungsangaben dürfen **nicht** aus KI-Erzählungen als bestätigte Regelfakten interpretiert werden.
- Die übrigen SRD-Klassenmerkmale werden nicht als automatisch wirksam ausgegeben.

## Nächster Entwicklungsschritt

Terrain-/Bewegungsaktion mit autorisierter Geländeangabe und sauberer Kostenberechnung; anschließend nachweislich atomare Speicherung, Tests bei langen Strecken, Geländewechsel, Klassenverlust und Neustart. Danach das nächste begrenzte SRD-Klassenmerkmal.

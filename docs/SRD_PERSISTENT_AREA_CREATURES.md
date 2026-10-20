# SRD 5.2.1 – Persistente Zusatzkreaturen für Flächenzauber

**Version 0.8.26+76 (Entwicklungsinkrement).** Regelquelle: [D&D SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0. Begrenzt auf ausdrücklich bestätigte Ziel-/Trefferpunktinformationen.

## Ergebnis

Der persistente Kampagnenzustand `Campaign.trackedAreaCreatures` enthält bis zu 19 zusätzliche Kreaturen mit **stabiler ID, Name, aktuellen und maximalen TP**. Zusammen mit dem bisherigen Hauptgegner können somit höchstens 20 Ziele mit `AcidSplashRules` in einem Wurfvorgang abgerechnet werden. Der Wert 20 ist eine technische Schutzgrenze, keine SRD-Flächenbegrenzung.

Die Kreaturen werden im bestehenden **schemaVersion 1** unter dem **optionalen** JSON-Feld `trackedAreaCreatures` gespeichert. Alte Kampagnen ohne das Feld bleiben unverändert importierbar. Neue Versionen validieren vor Annahme eindeutige IDs, Obergrenzen, Wertebereiche, Kollisionen mit Hauptgegner/Held und unzulässige Veränderungen. `Campaign.copyWith` bewahrt die vollständige Liste. Auch nach dem Ende der Hauptbegegnung bleiben Zusatz-TP in der Kampagne erhalten.

Die Engine bietet `trackAreaCreature` zur bewusst bestätigten HP-Erfassung sowie `castAcidSplash` mit `additionalTargets`. **Vor jeglichem Würfelwurf** wird überprüft, dass jedes Zusatz-Ziel schon gespeichert ist und dessen ID, Name, HP und maximale HP exakt dem aktuellen Speicherstand entsprechen. Nur explizit bestätigte Kreaturen der 5-Fuß-Kugel sind zulässig. Es gibt *einen Schadenswurf* für alle Ziele mit fehlgeschlagenem eigenem GES-Rettungswurf; Hauptgegner-HP, zusätzliche Ziel-HP, Magieaktion und Journal werden **zusammen über den vorhandenen revisionsgeschützten Controller-Commit** abgelegt.

In der Oberfläche erscheint **„Kreatur-TP erfassen“** als manuelle Eingabe und die Säurespritzer-Zielauswahl listet bereits gespeicherte lebende Zusatzkreaturen. Jedes ausgewählte Ziel verlangt seinen **eigenen** bestätigten GES-Rettungswurfbonus, Deckungsgrad, Richtung zum Kugelursprung, Wirkpfad/Abwehr und Vorteil/Nachteil. Der Nutzer muss alle Betroffenen einschließlich Verbündeter bestätigen. Die bisherigen Einzelziel-Flows bleiben erhalten.

## Bewusste Regel- und Architekturgrenzen

**Dies ist noch kein vollwertiger Mehrgegnerkampf.** Zusatzkreaturen sind zunächst HP-geführte **Flächenziele**, nicht selbständige Akteure. Sie besitzen noch **keine Initiative, Angriffe, Aktionsökonomie, Positionen, Rettungswurfprofile, automatischen Resistenzmerkmale oder Loot**. Das bestehende `Encounter` steuert ausschließlich den ursprünglichen Hauptgegner. Ein besiegter Hauptgegner kann den Kampf weiterhin beenden; zusätzliche HP-Einträge bleiben dann ausdrücklich im Kampagnenzustand erhalten und stellen noch keine vollständige Gegner-Siegbedingung dar. Ein späteres echtes Mehrgegner-Encounter benötigt deshalb eigene Turn-Slots, HP je Akteur und korrekte Abschlussbedingungen.

Unbestätigte Kartenpositionen/Deckung und Monsterfähigkeiten werden **nicht** vom Erzähler als Regel-Fakten übernommen. Die 2024er *Acid Splash*-Fläche betrifft auch Verbündete im 5-Fuß-Radius; der neue Dialog fordert ausdrücklich deren Einbeziehung. Nicht einzeln erfasste Kreaturen machen die Bestätigung unzulässig.

## Abnahme

```bash
python3 -m unittest discover -s scripts/tests -v
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/area_creature_persistence_test.dart
flutter test test/area_creature_dialog_test.dart
flutter test
flutter build apk --debug
```

Ältere Spielstände / neue HP-Einträge / Duplikat- und Wertevalidierung / unveränderliche Kopien / alle Zielwürfe / ein gemeinsamer Schaden / serialisierter Checkpoint / unbestätigte Ziele sowie Widget-Eingaben werden gesondert getestet. Android-Geräteabnahme bleibt offen.

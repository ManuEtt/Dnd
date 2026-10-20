# SRD 5.2.1 – Säurespritzer (Acid Splash) und Mehrziel-Regelkern

Quelle: [amtliches D&D SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0, *Spells / Acid Splash*. Es gelten die **2024-Regeln**, nicht die 2014er Variante mit ein oder zwei benachbarten Zielen.

## Fertig in diesem Inkrement

- **Evocation-ZT, Magier/Zauberer, Aktion, V/S, 60 Fuß**: Punkt innerhalb der Reichweite erzeugt eine **Kugel mit 5 Fuß Radius**. Jede ausdrücklich innerhalb der Kugel bestätigte Kreatur führt **ihren eigenen Geschicklichkeitsrettungswurf** gegen den Zauber-SG aus.
- `AcidSplashRules.cast` nimmt eine Liste eindeutig identifizierter, bestätigter Kreaturen-Snapshots mit individuellen HP, maxHP, GES-Save-Bonus, Deckung relativ zum Ursprungsort und Rettungswurf-Vorteilen an. Vor dem Würfeln müssen alle Einträge, Anzahl und Bedingungen validiert sein; Dubletten und unbekannte Defensivwerte werden abgelehnt.
- Bei mindestens einem misslungenen Save: **ein einziger gemeinsam geltender Schadenswurf** für die ganze gleichzeitige Wirkung (1W6 Stufe 1–4, 2W6 Stufe 5–10, 3W6 Stufe 11–16, 4W6 Stufe 17–20). Erfolgreiche Saves: **0 Schaden**. Für jede Kreatur wird der neue HP-Wert separat berechnet, ohne ursprüngliche Eingaben zu ändern. Bei ausschließlich erfolgreichen Saves wird **kein** Schadenswürfel geworfen.
- Deckung: Der Rettungswurfbonus durch halbe/3⁄4 Deckung wird nur bei ausdrücklich bestätigtem Ursprungsort **auf der Gegenseite** angewendet. Die 2024er **Heilige Flamme** ist davon ausdrücklich verschieden. Bei unbekannter vollständiger Deckung ist die Auflösung sicherheitshalber gesperrt.
- Unterstützt wird die reine Domänenauswertung für **bis zu 20 bestätigte Ziele pro Ausführung** (technische Schutzgrenze, **keine** SRD-5-Fuß-Flächenbegrenzung). Ein künstlicher Maximalwert wird nicht als Spielregel dargestellt.
- `GameEngine.castAcidSplash`, `GameController.castAcidSplash` und der neue Bestätigungsdialog bieten eine durchgehende **Einzelgegner-Integration**. Das Event `spell.acidSplash` protokolliert Ziel-ID, individuellen Save, gemeinsamen Schadenswurf, HP, Zauber-SG und bestätigten Ursprung; keine Zauberplätze, nur die Magieaktion.

## Noch nicht abgeschlossen (Matrixstatus partial)

**Der bestehende Encounter speichert genau einen aktiven Gegner.** Darum akzeptiert die in die Kampagne integrierte Aktion aktuell **nur** eine ausdrücklich bestätigte Kugel mit dem einen aktiven Gegner als einziger Kreatur. Wenn weitere Gegner, Helden oder NSCs im 5-Fuß-Radius betroffen sind, verweigert sie den Vorgang vor dem ersten Wurf. Andernfalls würden deren HP-Änderungen im Kampagnen-Spielstand nicht dauerhaft abgelegt. Der mehrzielige Domänenkern ist getestet, **aber noch nicht an ein persistentes Mehrgegner-Kampfsystem angebunden**.

Fehlende nächste Arbeit: Encounter-Migration zu stabilen Kreatur-IDs und mehreren HP-Konten, bestätigte geometrische Kugel-/Deckungsreichweite, gemeinsame Würfel-Ergebnisse samt Zustandsrollback aller Teilnehmer, Initiative/Aktionen und Monster-Abwehrfähigkeiten pro Kreatur. Die Einziel-Kampfintegration kann dann durch echtes `result.targets`-Mapping ersetzt werden.

Vollständiger offizieller SRD-Quellenabgleich aller Zauber bleibt offen, ebenso Tests auf einem realen Android-Gerät.

## Abnahme

```bash
python3 -m unittest discover -s scripts/tests -v
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/acid_splash_rules_test.dart
flutter test test/acid_splash_dialog_test.dart
flutter test
flutter build apk --debug
```

CI für Backend, Flutter und kleine Alpha-APKs muss erfolgreich sein, bevor diese Version nach `main` gemergt wird.

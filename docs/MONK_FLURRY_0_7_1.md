# Würfelraunen 0.7.1+41 – Mönch: Schlaghagel (SRD 5.2.1)

**Regelquelle:** D&D SRD 5.2.1, Monk's Focus (Stufe 2) und Heightened Focus (Stufe 10); Creative Commons Attribution 4.0. Offizielle Grundregeln: https://www.dndbeyond.com/sources/dnd/br-2024/character-classes

## Neu / tatsächlich automatisiert

- `MonkFlurryRules.use` führt **2 eigene unbewaffnete Angriffswürfe ab Mönchsstufe 2** aus; ab **Mönchsstufe 10 sind es 3 Angriffe**. Erfordert 1 noch verfügbaren Fokuspunkt und eine unverbrauchte Bonusaktion.
- Jeder Angriff wird individuell mit W20, Übungsbonus, einem bestätigten Attributswert, Erschöpfungs- und vorhandenen pauschalen Zustandsnachteilen ausgewertet. Der Kampfkunst-Schadenswürfel richtet sich nach der **Mönch-Klassenstufe** (nicht Gesamtstufe). Bei kritischem Treffer werden **nur die Schadenswürfel**, nicht der Attributsmodifikator, verdoppelt.
- Die Spieleraktion `Schlaghagel` beziehungsweise `Flurry of Blows` ist auch **vor der regulären Angriffsaktion** möglich. Nach einer regulären Angriffsaktion wird der Gegnerzug für einen Mönch mit noch verfügbarer Schlaghagel-Option zurückgehalten; `Zug beenden` bleibt jederzeit möglich.
- Einzelwürfe und Schadenswerte werden als nachvollziehbares Ereignis `class.flurryOfBlows` im Kampagnenjournal protokolliert. Fokuspunktverbrauch und gegnerische Trefferpunkte sind über das bestehende JSON-Schema 1 rückwärtskompatibel gespeichert; ein zusätzliches Schemafeld wird nicht benötigt.
- Der bestehende Spielerzug, die Sieg-/Questauflösung und der Gegnerzug werden bei Schlägen mit bestätigtem Ergebnis fortgesetzt. Treffer gegen bereits besiegte Gegner entfallen.
- Neue UI-Schaltfläche bei Mönchen mit noch verfügbarem Fokus und freier Bonusaktion; automatische Deaktivierung nach Verwendung.

## Bekannte Grenzen / bewusst keine Regelwerte erfunden

- Für die automatische Schadensberechnung werden **keine Rüstung und kein Schild** vorausgesetzt; ein gerüsteter Mönch benötigt noch separate Regeln für gewöhnliche unbewaffnete Angriffe. Grapple/Shove-Varianten der Unarmed Strike werden nicht ausgeführt.
- Kontextabhängige Modifikatoren (Deckung, konkrete Zielzustände, Positions- oder Ally-Vorteile) werden nicht aus Erzähltext erschlossen. Die automatische Wahl zwischen bestätigter Stärke und Geschicklichkeit bevorzugt den höheren Wert; in der UI fehlt noch die ausdrückliche Attributwahl.
- Keine allgemeinen Gelegenheitsangriffe oder Karten-/Positionssimulation. Weitere komplexe Monk-Level-10-Effekte werden separat entwickelt.
- Im vereinfachten Solo-Kampf erfolgen die Schlaghagel-Würfe **automatisch**; die normale Angriffsaktion kann weiterhin manuelle W20-Anfragen auslösen. Manuelle Eingabe der einzelnen Schlaghagel-W20 steht noch aus.

## Teststatus und Ausgangsbasis

- Basis: GitHub `ManuEtt/Dnd` Commit `47b549125d95973b2d9e066e9a2401488ef322d2` (0.7.0+40).
- Neues Testmodul `app/test/monk_flurry_rules_test.dart`: Schadens- und Angriffsgrenzen, Fokus, Stufe 10, Mehrklassen, Krits, Zustandssperren, Zugabschluss, JSON-Roundtrip.
- Weitere CI-Korrekturen: Charakterbogen-Test erwartet `6 m` statt `6.0 m`, und `Ich weiche aus` blockiert nun eine zweite volle Aktion bei noch laufender Mehrfachangriffsaktion.
- Die lokale strukturelle Prüfung und Python-Projekttests sind unabhängig von der Flutter-Analyse. Solange keine neuen GitHub-CI-Ergebnisse vorliegen, sind die hinzugefügten Dart-Tests/Flutter-Analyse/Android-APK **nicht als bestanden zu betrachten**.

## Lokaler Import und Build

1. ZIP in ein leeres Verzeichnis entpacken, GitHub-Repository **nicht verschachteln**.
2. `python3 scripts/verify_project.py .` und `python3 -m unittest discover -s scripts/tests` ausführen.
3. Im Unterordner `app`: `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` und `flutter build apk --debug`.
4. Änderungen erst nach erfolgreichem Build oder mit klarem Teststatus in den gewählten Repository-Branch übernehmen.

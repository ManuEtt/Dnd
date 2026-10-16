# Würfelraunen 0.6.7+37 – Kämpferressourcen (SRD 5.2.1)

**Basis:** GitHub `ManuEtt/Dnd`, `main`-Commit `de88027f842a9dca80dd58ffccedb5a961551338` (0.6.6+36).
**Quellen:** [SRD 5.2.1](https://www.dndbeyond.com/srd), Klassenkapitel *Fighter*, *Second Wind* und *Action Surge*. Siehe auch <https://5e24srd.com/classes/fighter.html>. Lizenz: CC BY 4.0.

## Implementiert

- Neue deterministische `ClassFeatureResources`-Domäne für Kämpfer-Klassenstufen, einschließlich einer Kämpfer-Zweitklasse.
- **Second Wind/Zweite Luft:** Ab Kämpferstufe 1 als ausdrückliche Bonusaktion mit 1W10 + **Kämpfer-Klassenstufe**. Nutzungen: 2 ab Stufe 1, 3 ab Stufe 4, 4 ab Stufe 10; maximaler TP-Wert bleibt eingehalten. Eine zweite Bonusaktion in derselben Kampfrunde wird abgewiesen.
- **Action Surge/Aktionsschub:** Ab Kämpferstufe 2 eine Nutzung, ab 17 zwei Nutzungen pro Rast, aber höchstens einmal pro Zug. Im aktuellen Einzelgegner-Kampf reserviert die explizite Aktion (`Action Surge` oder `Aktionsschub`) eine **zusätzliche Angriffsaktion**; diese wird *nach* den einzelnen Attacken der gewöhnlichen Angriffsaktion eröffnet und löst keinen vorzeitigen Gegnerzug aus. Die vorhandene Extra-Attack-Anzahl wird auch für die zweite Angriffsaktion angewandt.
- **Rasten:** Kurze Rast regeneriert genau **eine verbrauchte Second-Wind-Nutzung** und alle verbrauchten Action-Surge-Nutzungen; lange Rast regeneriert alle. Das funktioniert auch bei vollen TP ohne Trefferwürfelverbrauch. Sonstige Rast- und Paktmagie-Regeln bleiben erhalten.
- **Persistenz:** `spentSecondWind`, `spentActionSurge` auf `HeroCharacter`; `surgeReserved` und `surgeUsedThisTurn` im `Encounter`. SchemaVersion 1 bleibt unverändert; alte Speicherstände ohne die Felder sind lesbar. Manipulierte oder zu hohe Klassenressourcen werden beim Import abgewiesen.
- **UI:** Anzeige der verbleibenden Second-Wind-/Action-Surge-Nutzungen im Charakterbogen.
- **CI-Korrektur:** Der freistehende Dokumentationskommentar vor `damage_rules.dart` wurde in einen normalen Kommentar geändert, um `dangling_library_doc_comments` aus dem am 16.10.2026 beobachteten Flutter-Analysefehler zu entfernen.

## Bewusste Grenzen

- Der vereinfachte Kampf unterstützt bei Action Surge vorerst nur **eine weitere Angriffsaktion** (keine weiteren nichtmagischen Aktionsarten). Nach dem Ende der ersten Angriffsaktion wartet die Engine sonst direkt auf den Gegnerzug; darum **Action Surge spätestens während dieser Angriffsaktion aktivieren**.
- Das vollständige Regelwerk erlaubt andere nichtmagische Aktionen mit Action Surge, die aktuelle vereinfachte Kampf-Engine noch nicht. Magic ist nach SRD ausdrücklich ausgeschlossen.
- **Tactical Mind, Tactical Shift** und weitere Kämpfermerkmale sind noch nicht als Regelskripte umgesetzt.
- Barbarians Rage/Kampfrausch, Mönch-Fokus, Schurken-Hinterhältiger Angriff und Unterklassenressourcen sind Folgearbeiten, keine behaupteten Implementierungen.
- Rasten werden vom Spieler explizit ausgelöst; eine echte Spielweltzeit- und Unterbrechungsprüfung existiert noch nicht. Keine automatische KI-Bestätigung mechanischer Regeln.

## Tests & Abnahme

Neue Dart-Tests: `class_feature_resources_test.dart`, `class_feature_combat_test.dart`; sie decken Klassenstufen, Mehrklassen, doppelte Aktivierung, Ressourcenverbrauch, Rast und das Speichern/Importieren einer reservierten Zusatzaktion ab.

Die vorhandenen Python-Projektprüfungen sind getrennt von der Flutter-/Dart-Codeprüfung. Zur Freigabe auf dem CI-Runner:

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Ohne erfolgreichen Flutter-Testlauf und Android-Build **keine installierbare APK als getestet freigeben**.

# SRD 5.2.1 – Konzentrationsverlust durch mehrere Schadensquellen

**Stand:** 30.10.2026 · **Quelle:** Wizards of the Coast LLC, [SRD 5.2.1](https://www.dndbeyond.com/srd), *Rules Glossary / Concentration* (CC BY 4.0). Wichtig: SRD 5.2.1 **begrenzt den Konzentrations-SG auf 30**. Ältere 5.1-Beschreibungen ohne diese Grenze sind für dieses Projekt nicht maßgeblich.

## Regelentscheidung

Das neue eigenständige Domain-Modul `app/lib/domain/srd_concentration_damage_rules.dart` erhält einen ausdrücklich bestätigten **Charakterzustand nach dem Schaden** und eine nichtleere Liste separat identifizierter, bestätigter Schadensquellen. Für jede davon gilt ein separater Konstitutionsrettungswurf:

`SG = min(30, max(10, Schaden / 2 (abgerundet)))`

So entspricht ein Schaden von 21 einem SG von 10, 39 einem SG von 19 und ab 60 einem SG von 30. Natürliche W20-Ergebnisse 1 und 20 verursachen bei **gewöhnlichen Rettungswürfen** keinen pauschalen automatischen Erfolg/Misserfolg: Der bestätigte W20-Wert plus vollständigem, ausdrücklich bestätigtem Rettungswurfmodifikator wird mit dem SG verglichen.

Die reine Funktion `SrdConcentrationDamageRules.resolve` verarbeitet verschiedene Quellen einzeln in vorgegebener Reihenfolge. Bei der ersten misslungenen Rettung wird auf dem **neuen** `HeroCharacter` die Konzentration beendet. Bei Bewusstlosigkeit, Handlungsunfähigkeit, Lähmung, Betäubung, Versteinerung, 0 TP oder Tod endet die Konzentration ohne Wurf. Die übrigen TP, Zustände, Ressourcen und die ursprüngliche unveränderte Figur bleiben bestehen.

## Vertrauens- und Integrationsgrenzen

- Schäden und Zustände müssen bereits durch eine geprüfte Regelentscheidung am übergebenen Snapshot vorliegen. Das Modul **verursacht keinen Schaden** und zieht ihn nicht von TP ab.
- Schadensmenge, eindeutige Quellen-ID, der bereits unter Berücksichtigung von Vorteil/Nachteil ermittelte natürliche W20 und der vollständige Konstitutionsrettungswurfmodifikator (einschließlich Übung, Erschöpfung und situativer Effekte) sind **explizit bestätigte Eingaben**. Das Modul behauptet weder deren Herkunft noch deren automatische Ableitung.
- Die gesamte Liste wird vor einer Zustandsentscheidung validiert; unbekannte, doppelte, unbestätigte, unsichtbar manipulierte oder fehlerhafte Werte dürfen nicht über vorherige Fehlwürfe kaschiert werden.
- Es gibt **keine direkte Integration** in `game_engine.dart`, `game_controller.dart`, SQLite oder die Konzentrationsereignisse. Das zurückgegebene neue Snapshot muss später mit einem validierten Ereignis und erwarteter Revision atomar persistiert werden. Es wird kein Wurf generiert, keine reale Uhr vorangetrieben und kein bestehender Kampfeffekt automatisch beendet.
- Kein Savegame-/JSON-/SQLite-Schema, keine Versionsnummer, kein UI-/Story-/Backend-Code geändert. Vorhandene Kampagnen bleiben lesbar. Die gesamte Konzentrationsautomatik ist **nicht fertig**.

## Deterministische Tests

`app/test/srd_concentration_damage_rules_test.dart` prüft SG-Grenzen einschließlich der **30-Obergrenze**, Rundung, exakten Erfolg, natürliche 1/20 ohne automatische Folgen, getrennte Quellen, Abbruch nach erster fehlgeschlagener Rettung, unbestätigte spätere Quellen, unzulässige IDs und W20-/Modifikatorwerte, Ausfall durch Zustände ohne Wurf, Snapshot-Pflicht, unveränderte Eingaben und JSON-Roundtrip.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_concentration_damage_rules_test.dart
flutter test
flutter build apk --debug
```

Anforderungsstatus: **partial** – isolierter Regelbaustein, keine durchgängige Kampf-/Controller-Integration. Vollständige CI-Abnahme muss auf dem finalen GitHub-Commit nachgewiesen werden; Android-Geräteabnahme separat.

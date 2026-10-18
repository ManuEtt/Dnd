# 0.8.1+51 – Arescan als persönliche Importkampagne, nicht als Bestandteil der App

## Änderung
- Die Startseite bietet **keinen Arescan-Spielstand** und keine fest hinterlegte Arescan-Kampagne mehr an.
- `GameController.createArescan`, `GameEngine.createArescan` und Arescan-spezifisches `_arescan`-Scripting wurden aus dem Produktivcode entfernt.
- Die historische JSON-Datei befindet sich nur noch als **Kompatibilitätstest-Fixure** unter `app/test/fixtures/arescan_legacy.json`; sie wird nicht als Asset der installierten App ausgeliefert.
- Regelengine trennt Demo (`origin=demo`) von **allen anderen lokalen/importierten Kampagnen**. Importierte Geschichten bekommen **keine** Mooswacht-/Demo-Gegenstände oder Quests und bei nicht belegbaren Kampfaktionen keine erfundenen Gegnerwerte.
- Die Option zum manuellen JSON-Import sowie die normalen persistenten Charakter- und Kampagnenlisten bleiben erhalten.
- Persönlich gespeicherte Kampagnen werden **nicht automatisch gelöscht**. Bei einer bestehenden Installation muss ein Nutzer seine eigene Arescan-Kampagne bei Bedarf manuell in „Deine Kampagnen“ löschen. Vorher ggf. exportieren.

## Kompatibilität
Alte Save-JSON-Daten einschließlich unbestätigter Merkmale, Ereignisse und der `facts.origin=arescan`-Angabe lassen sich weiterhin laden; diese Angabe ist nur historische Nutzerdaten und kein produktspezifischer Ablauf mehr. Nicht automatisch rekonstruierte Quests oder magische Gegenstände.

## Prüfhinweis
Die Kompatibilitätstests verwenden nur die Test-Fixture. Nach dem Import eine reguläre Kampagne (kein fest eingebauter Charakter). Flutter-Dart-Tests/Android-Build in einem SDK-bereiten Umfeld ausführen.

# SRD 5.2.1 – Manuelle Mehrgegner-Zugfolge (0.8.28+78)

**Regelquelle:** D&D SRD 5.2.1, Kapitel „Combat / Initiative“, unter CC BY 4.0.

## Implementiert

Nach vollständiger Bestätigung der Initiative von Held, Hauptgegner und den lebenden zusätzlichen HP-Kreaturen erzeugt `SrdInitiativeRosterRules.createManualQueue` eine absteigende, **eindeutig bestätigte** Reihenfolge. Bei Würfelgleichstand darf nur **innerhalb dieses Gleichstands** umsortiert werden. Die ausgewählte Reihenfolge muss ausdrücklich bestätigt werden. Fehlende oder doppelt eingetragene Akteure, falsche Reihenfolge und fehlende Gesamtinitiative werden vor der Speicherung abgelehnt.

Der neue optionale JSON-Kampagnenwert `manualTurnQueue` enthält die Kampf-ID, Akteur-IDs in Reihenfolge, die aktuelle Position und die manuell gezählte Runde. Er passt in das vorhandene **schemaVersion 1**, ohne bisherige Spielstände zu verändern. `GameEngine.establishManualTurnQueue` und `advanceManualTurnQueue` schreiben die Änderungen revisionsgeschützt über den bestehenden Controller und erzeugen zwei nachvollziehbare Journal-Ereignisse. Beim manuellen Fortsetzen werden besiegte zusätzliche Kreaturen übersprungen und ein Umlauf erhöht die manuelle Rundenzahl.

Die eigene Schnellaktion **„Manuelle Zugfolge“** zeigt den aktiven Marker, ermöglicht über Hoch-/Runter-Pfeile das Umsortieren gleicher Initiativen und das explizite Bestätigen und manuelle Weiterschalten. Nach neu erfassten Kreaturen oder geänderten Initiativwerten wird die bisherige Liste ungültig. Neue Gegnerkämpfe oder der Sieg über den Hauptgegner löschen sie, statt veraltete Akteure weiterzuverwenden.

## Absichtliche Trennung von der alten Kampfengine

**Diese Zugfolge ist ein persistentes Planungs- und Notizsystem, noch keine autonome Mehrgegner-Kampfsteuerung.** Sie setzt weder `Encounter.activeParticipant` noch `Encounter.round`, würfelt niemals Angriffe, verbraucht keine Ressourcen und autorisiert keine Spieler- oder Monsteraktionen. Die separate manuelle Runde ist **nicht** identisch mit der weiterhin autonom laufenden Hauptgegner-Runde; die UI weist ausdrücklich darauf hin. Das Umschalten dient dem sicheren Vorbereiten einer später integrierten kanonischen Turn-Engine.

**Weiterhin offen:** Per-Gegner-Aktion, Angriff, Angriffszahl, Rettungswürfe, Reaktionen, Konzentrations- und Zustandsablauf, Initiative identischer Monstergruppen, Tiebreaking zwischen verschiedenen Zuständigkeiten, geteilte Haupt-/Nebenaktionen, richtige Mehrgegner-Kampfende- und Beutebedingungen, echte Positions-/Deckungsregeln sowie Gerätetest.

Die Anforderung `RULE-COMBAT-INITIATIVE` bleibt deshalb **partial**, nicht „vollständig“.

## Build-Gates

```bash
python3 -m unittest discover -s scripts/tests -v
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Merge erst nach grünem GitHub-Actions-Workflow inklusive Alpha-APKs, Quellcode-ZIP und Prüfsummen.

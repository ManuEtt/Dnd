# Roadmap

## P0 – Erster prüfbarer Build

1. GitHub-Schreibrechte für den verwendeten Connector korrigieren bzw. Dateien manuell committen.
2. `flutter create` und Flutter-Analyse auf tatsächlicher SDK-Umgebung ausführen; alle Compiler-/Plugin-Fehler beheben.
3. Android-CI mindestens einmal erfolgreich laufen lassen und Artefakt herunterladen.
4. Reale Android-Tests: SQLite-Neustart, Mikrofonberechtigung, deutsche Spracheingabe und TTS.

## P1 – Spielbare Solo-Alpha

1. Vollständige SRD-5.2.1-Charakteroptionen und Charaktervalidierung.
2. Regelengine für Skills, Proficiencies, Attacken, Initiativen, AC, Trefferpunkte, Status und Tod.
3. Persistentes, regelgeprüftes Kampfzustandsmodell und Kampfoberfläche.
4. Export/Import von Charakteren und Kampagnen und Schema-Migrationstests.
5. Kompletter Turn-/Würfel-/Kampf-Integrationstest und Crash-Recovery.
6. Eingebauter Bestätigungsdialog für regeltechnische Aktionen aus dem Spielleitertext.

## P2 – Online-KI und Audio

1. Backend-Authentifizierung, Rate Limits, Kostenkontrolle und Tool-Validierung.
2. OpenAI-Textprovider hinter austauschbarer Schnittstelle.
3. Sichere, kurzlebige WebRTC-Realtime-Sitzungen; Fallback-Transkription/TTS.
4. Deutsche Satzlänge und Audio-Unterbrechungen geräteseitig testen.

## P3 – Gedächtnis und Multiplayer

1. Langzeitfakten, NPCs, Quests, Inventar, Zusammenfassungen und kontextselektive Retrieval-Logik.
2. Vollständige Zustandsrekonstruktion aus Ereignissen und Versionsmigration.
3. PostgreSQL, serverseitige Zugriffsprüfung und Synchronisierung.
4. Push-to-Talk mit manueller Sprecherzuordnung für gemeinsame Kampagnen.

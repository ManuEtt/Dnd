# Arbeitsanweisungen für kommende Entwicklungssitzungen

## Einstieg

1. Arbeitsverzeichnis, Git-Status, Branches, Remotes und vorhandene Commits prüfen.
2. Diese Datei sowie `DEVELOPMENT_STATUS.md`, `ROADMAP.md`, `ARCHITECTURE.md` und `TESTING.md` lesen.
3. Vorhandene Änderungen anderer Beteiligter erhalten. Das ZIP ist ein eigenständiger Entwicklungsstand, kein geprüfter Merge mit einer älteren Repositoryversion.
4. Werkzeuge mit `flutter --version`, `dart --version`, `java -version` und `node --version` prüfen.
5. Den nächsten offenen, überprüfbaren Schritt aus der Roadmap bearbeiten. Keine fertigen Funktionen unnötig neu schreiben.

Das vorgesehene Hauptrepository ist `ManuEtt/Dnd`, SSH `git@github.com:ManuEtt/Dnd.git`. Kein alternatives Hauptrepository anlegen. Kein Force-Push und keine fremden Dateien ohne Prüfung überschreiben. Geheimnisse niemals anfordern oder im Chat, in Logs, Quellcode oder Commits ausgeben.

## Architektur und Regeln

- Flutter in `app/`, Fastify/TypeScript in `backend/`; UI, Domänenregeln und Datenzugriff getrennt halten.
- Der Spielleiter liefert Erzählung und validierte Vorschläge. Zustandsänderungen erfolgen ausschließlich durch die autorisierte Geschäfts- beziehungsweise Regelengine.
- Natürliche Würfelergebnisse getrennt von Gesamtwerten halten; Boni niemals zweimal anwenden.
- Kontrollierbare Zufallsquellen für Regeln verwenden. Tests benötigen keine kostenpflichtige KI.
- Historische Arescan-Werte 19 und 14 erhalten, aber nicht als neue bestätigte Regelberechnungen behandeln. Keine fehlenden Attribute erfinden; insbesondere den alten ungeprüften Modifikator +7 nicht übernehmen.
- Nur rechtmäßig verwendbare SRD-5.2.1-Inhalte und eigene Texte einsetzen. Neue Regelumsetzungen mit Quelle und Test versehen. `THIRD_PARTY_NOTICES.md` erhalten.
- Als Demo ausgewiesene Werte sind ausdrücklich festgelegte Demo-Daten; sie dürfen nicht stillschweigend den historischen Arescan-Bogen ersetzen.

## Speicher- und Sicherheitsvorgaben

- SQLite-Schema und Importformat versionieren. Schemaänderungen brauchen Migrationen und Wiederherstellungstests.
- Snapshot und dazugehöriges Ereignis in derselben Transaktion speichern.
- Doppelte Ereignis-IDs dürfen keine zweite Zustandsänderung erzeugen.
- Ungültige Importe ohne Teiländerungen ablehnen. Den letzten bestätigten Zustand nach Neustart erhalten.
- Dauerhafte Anbieter-Schlüssel ausschließlich serverseitig speichern; `.env` und Benutzerexporte nicht committen.
- Authentifizierung, Rollenprüfung, Eingabevalidierung und Nutzungsgrenzen nicht durch Clientdaten umgehen lassen.
- Audio nicht dauerhaft speichern. Geräteabhängige Spracherkennung nicht als garantiert offline bezeichnen.
- Die vorhandene Solo-Architektur nicht als fertigen öffentlichen Mehrspielerdienst darstellen.

## Befehle

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

```bash
cd backend
npm ci
npm run typecheck
npm run build
npm test
```

Unter Linux benötigen SQLite-Tests `libsqlite3-dev`; der CI-Workflow installiert das Paket.

Flutter 3.35.7, Dart 3.9.2, Java 17 und Node.js 22.14.0 bilden die CI-Grundlage. Lockdateien mit Änderungen an Abhängigkeiten gemeinsam prüfen. App-Tests sollen insbesondere Regeln, Speichertransaktionen, Export/Import und relevante UI-Abläufe abdecken. Backend-Tests dürfen Fastify-Injection und Anbieter-Mocks verwenden. Erfolgreiche Tests nur mit tatsächlich beobachtetem Ergebnis dokumentieren.

## Abschluss eines Inkrements

Relevante Analyse, Tests und Build ausführen, Fehler beheben und `DEVELOPMENT_STATUS.md`, `CHANGELOG.md` sowie nötige technische Dokumentation aktualisieren. Klar zwischen **IMPLEMENTIERT**, **GETESTET**, **NICHT GETESTET**, **BLOCKIERT** und **NOCH NICHT IMPLEMENTIERT** unterscheiden. Build, Emulator und reales Gerät getrennt aufführen. Bei fehlendem Zugriff eine konkrete Übergabe erstellen und unabhängig mögliche Arbeiten fortführen. Geprüfte Änderungen mit aussagekräftiger Nachricht auf einem Entwicklungsbranch committen; nur bei vorhandener Berechtigung pushen.

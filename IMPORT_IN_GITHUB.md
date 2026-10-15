# GitHub-Import – Aetheria 0.3.8+14

Ausgangsbasis: `ManuEtt/Dnd` `main` Commit `323f16236fd8b44d78e117a466a1bb919182f0a4` (0.3.7+13).

1. ZIP entpacken. `app/`, `backend/`, `scripts/`, `docs/`, `.github/` und die Wurzeldateien sind der Inhalt des Repository-Hauptordners; keinen äußeren ZIP-Ordner mit hochladen.
2. In GitHub nach Möglichkeit einen neuen Branch direkt vom genannten Basis-Commit erstellen. Die geänderten Dateien hochladen/ersetzen, aber neuere fremde Änderungen vorher abgleichen.
3. **Actions** durchlaufen lassen. Zuerst Python/Backend/Flutter Analyse und Tests; nur bei Erfolg eine APK oder einen Merge als erfolgreich betrachten.
4. Unter **Optionen** einen Backend-Server verbinden. Für autonome kreative Geschichten benötigt der Server `AI_PROVIDER=openai`, `ALLOW_PAID_AI=true`, `OPENAI_API_KEY`, `OPENAI_MODEL` und einen HTTPS-Zugriff. Nie einen OpenAI-Key in die App oder ein GitHub-Commit eintragen.
5. Auf Android „KI-Kampagne erstellen“, mehrere freie Entscheidungen und den Tagebucheintrag prüfen. Testmodus (`AI_PROVIDER=mock`) liefert absichtlich nur ein statisches Beispiel.

**Wichtig:** KI-Ausfälle führen zu lokalen Antworten. Eine neue KI-Kampagne kann bei einem Verbindungsfehler nicht erstellt werden. Vollständige Android- und Flutter-Prüfungen sind in der Erstellungssitzung nicht möglich. Bisheriger `main` wurde nicht verändert. Geheimnisse der KI-Geschichte sind im vollständigen exportierten JSON vorhanden; Sicherungen vertraulich behandeln.

## 0.3.8+14 – neue Annahmetests

- Nach dem Import unter **Actions** bestätigen, dass `npm run typecheck`, `npm test`, `flutter analyze`, `flutter test` und der Android-Build **alle grün** sind. Der Vorgängerstand scheiterte an Fastify-Typen; der Patch ist enthalten, aber hier noch nicht durch die echte Fastify-Installation verifiziert.
- Für den Mock-Test unter Optionen ein korrekt konfiguriertes Backend verbinden, eine KI-Kampagne mit vollständigem Heldenbogen starten, `Ich suche eine Begegnung` eingeben, das Angebot annehmen und einen bestätigten Gegnerkampf spielen. Ein Sieg muss den Queststatus und die nichtmagische Beute ändern.
- Alternativ `Ich untersuche die Spuren` für einen W20-Wahrnehmungswurf gegen SG10.
- **Die bisherigen Dateien nicht einzeln löschen.** Die vollständige ZIP wie den Inhalt des Repository-Wurzelordners integrieren, neue Dateien mit hochladen; insbesondere `app/lib/domain/adventure_catalog.dart` und `docs/AI_ADVENTURES.md`. Bei neueren Commits Änderungen abgleichen.
- Die ZIP enthält Quellcode, Tests und Konfiguration, **keine bereits kompilierte APK**. Der eigentliche Backend-Dienst und dessen geheimen Schlüssel müssen unabhängig vom GitHub-Upload betrieben werden.

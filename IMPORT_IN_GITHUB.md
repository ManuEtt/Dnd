# GitHub-Import – Aetheria 0.3.7+13

Ausgangsbasis: `ManuEtt/Dnd` `main` Commit `ea486481d28856228abf65dd209857028b3b3c45` (0.3.6+12).

1. ZIP entpacken. `app/`, `backend/`, `scripts/`, `docs/`, `.github/` und die Wurzeldateien sind der Inhalt des Repository-Hauptordners; keinen äußeren ZIP-Ordner mit hochladen.
2. In GitHub nach Möglichkeit einen neuen Branch direkt vom genannten Basis-Commit erstellen. Die geänderten Dateien hochladen/ersetzen, aber neuere fremde Änderungen vorher abgleichen.
3. **Actions** durchlaufen lassen. Zuerst Python/Backend/Flutter Analyse und Tests; nur bei Erfolg eine APK oder einen Merge als erfolgreich betrachten.
4. Unter **Optionen** einen Backend-Server verbinden. Für autonome kreative Geschichten benötigt der Server `AI_PROVIDER=openai`, `ALLOW_PAID_AI=true`, `OPENAI_API_KEY`, `OPENAI_MODEL` und einen HTTPS-Zugriff. Nie einen OpenAI-Key in die App oder ein GitHub-Commit eintragen.
5. Auf Android „KI-Kampagne erstellen“, mehrere freie Entscheidungen und den Tagebucheintrag prüfen. Testmodus (`AI_PROVIDER=mock`) liefert absichtlich nur ein statisches Beispiel.

**Wichtig:** KI-Ausfälle führen zu lokalen Antworten. Eine neue KI-Kampagne kann bei einem Verbindungsfehler nicht erstellt werden. Vollständige Android- und Flutter-Prüfungen sind in der Erstellungssitzung nicht möglich. Bisheriger `main` wurde nicht verändert. Geheimnisse der KI-Geschichte sind im vollständigen exportierten JSON vorhanden; Sicherungen vertraulich behandeln.

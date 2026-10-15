# Umbenennung in Würfelraunen

Die öffentliche App heißt **Würfelraunen – Der lebendige Spielleiter** (ab Version 0.5.2+22).

Eine gezielte Websuche nach der Wortschöpfung „Würfelraunen“ und der Schreibweise „Wuerfelraunen“ hat keine offensichtliche gleichnamige Spiele-App ergeben. **Das ist keine verbindliche Marken- oder App-Store-Freigabe**. Vor Veröffentlichung DPMAregister, EUIPO/TMview, Google Play, App Store sowie ähnliche Schreibweisen und Domainnamen prüfen.

## Rückwärtskompatibilität

- Android `applicationId`, Kotlin-Package und Android-MethodChannel `de.aetheria.lebendiger_spielleiter` bleiben stabil, damit Updates, Backups und gespeicherte SQLite-Kampagnen weiterhin funktionieren.
- Die historischen Weltnamen, Fixture-IDs und zuvor gespeicherte Story-Titel mit „Aetheria“ werden nicht überschrieben. Die Weltenbezeichnung eines Abenteuers ist nicht automatisch der Produktname.
- `app/pubspec.yaml`-Paketname bleibt ebenfalls bestehen; eine technische Umbenennung ist eine separate Migration mit potenziellen Risiken.
- Frühere Logodesigns dürfen nicht mehr „Aetheria“ als Produkttitel zeigen. Die bestehenden eingebauten WebP-Motive sind Landschaften und Inventarsymbole ohne eingebettetes Produktlogo.

# Fantasy-Charakter- und Inventardialoge – Zyklus 3

Die Bestätigungsdialoge für **SRD-Inventarattribute**, **Start-Trefferpunkte** und **manuelle Inventargegenstände** verwenden jetzt dieselben zustandsabhängigen Fantasy-Schaltflächen wie die Kampf- und Würfeloberfläche.

- Sekundäraktionen „Abbrechen“: Eisenmaterial, ohne Seiteneffekte.
- Bestätigungen: Gold/Holzmaterial mit den bekannten Hover-, Pressed- und Disabled-Zuständen.
- Die `ValueKey('character-enrich-confirm')`-Kennzeichnung bleibt für vorhandene Widget- und Integrationstests erhalten.
- Unveränderte Funktionen: explizite Benutzerbestätigung vor der Übernahme, Formularvalidierung, Inventargegenstands-IDs, SRD-Start-TP-Berechnung und Fehlermeldungen.
- Keine Änderungen an SQLite, Domänenmodellen oder D&D-Regelengine.

Die GitHub-Actions-CI ist die verbindliche Prüfung für Dart-Format, Flutter-Analyse, alle Tests und Android-Build.
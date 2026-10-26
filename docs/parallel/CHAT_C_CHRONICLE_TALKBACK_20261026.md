# Chat C – getrennt vorlesbare Kampfchronik (26.10.2026)

## Ziel
Bei Android-TalkBack werden die bestätigten Einträge der Kampf- und Würfelchronik als eigenständige Ereignisse vorgelesen. Einzelne Einträge werden nicht mit dem nächsten zusammengezogen. Die bestehende visuelle Chronik und die Reihenfolge „neueste zuerst“ bleiben unverändert.

## Akzeptanzkriterien
1. Für zwei aufeinanderfolgende bestätigte Ereignisse gibt es getrennte Semantik-Einheiten mit Datum, Titel und ausschließlich ausdrücklich erlaubten Ereignisdetails.
2. Bei 320 und 360 dp mit 200 % Systemschrift sind Ereignisse einschließlich Wurf-, Treffer-, Schaden- und Heilungswerten lesbar, ohne Flutter-Layoutausnahme.
3. Technische `stateAfter`-Snapshots und private Felder tauchen weder sichtbar noch in den Screenreader-Labels auf.
4. Kein Eingriff in SRD-Regeln, Würfelauflösung, KI, Kampagnenfortschritt, SQLite/JSON, Android-Version oder andere Chats.

## Umsetzung
- `app/lib/ui/fantasy_combat_chronicle.dart`: `Semantics(container: true)` um jeden zusammengefassten, explizit erlaubten Ereignistext; unverändert `ExcludeSemantics` für die dekorative Innenstruktur.
- `app/test/fantasy_combat_chronicle_test.dart`: Regression für zwei 200%-Breiten, je ein getrenntes Angriff-/Heilungslabel, Sortierung und Ausschluss des privaten Checkpoints.
- GitHub-CI auf dem zugehörigen PR-HEAD ausführen. Echte Android-Geräte-/TalkBack-Abnahme bleibt separat offen.

## Zustand
Implementiert und versioniert; endgültige vollständige CI vor Integration ausdrücklich erforderlich.

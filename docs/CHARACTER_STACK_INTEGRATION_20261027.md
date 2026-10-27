# Charaktererstellung – verlustarme gemeinsame Integration (27.10.2026)

## Fixierte Quellen
- Main `4bd97b4d72fc747228df9bea46b61c3d4c82c382`
- Vier Stacked-PRs: [#264](https://github.com/ManuEtt/Dnd/pull/264) → [#272](https://github.com/ManuEtt/Dnd/pull/272) → [#273](https://github.com/ManuEtt/Dnd/pull/273) → [#275](https://github.com/ManuEtt/Dnd/pull/275)
- Gemeinsamer Stack-HEAD `ae148053feca82f5db1741b37536385f4d7d41c5`
- Merge-Base `08bcd4dda585224c2ca8671786adecaf263d736c`

Die **22 Fach-/Abdeckungsdateien** aus dem gemeinsamen Stack werden mit ihrem unveränderten Git-Blob auf die Main-Tree-Basis aufgetragen (davon zwei rein dokumentarische Konfliktpfade ausgenommen). Für README und `docs/CODEX_CHECKPOINT.md` wurde der neuere Main-Text beibehalten und nur ein Integrationseintrag vorne ergänzt. Die `docs/CHARACTER_CREATION_COMPLETE.md` wurde zusätzlich mit einer aktuellen Begründung vor historische Einzelpaketnotizen ergänzt. Dieses Vorgehen wahrt die Main-eigenen NPC-/Story-/Release-Änderungen und vermeidet unkontrollierte Übernahmen aus alten Kopien.

Die Integrationshistorie bewahrt beide Eltern (Main sowie exakten Stack-HEAD). Keine Änderung an `app/pubspec.yaml`, `schemaVersion`, SQLite oder Kampagnen-JSON. Die Funktionalität ist für SRD 5.2.1 **nur teilweise vollständig**. Magic-Initiate-Zauber, Talentwirkungen, alle Spezies- und Klassenmerkmale und Echtgerätetests bleiben offen.

## Prüfungen
- Einzelprüfung der Quellversion [#275 / Run 40456350744](https://github.com/ManuEtt/Dnd/actions/runs/40456350744): erfolgreich, einschließlich Android-Alpha-Release.
- **Gemeinsame Integrations-CI:** vor Abschluss des aktuellen Integrations-PRs auf dessen endgültigem Commit überprüfen; Status nicht aus dem Quellstand übernehmen.
- **Main-CI:** nach regulärem Merge neu ausführen und prüfen.
- **Branchbereinigung:** nur nach dokumentiertem Ancestry-/SHA-Abgleich; in diesem Paket werden keine alten Branches gelöscht.

## Fachliche Grenzen
Keine KI-erfundenen Attributwerte oder Ausrüstung; neue Boni nur nach expliziter Bestätigung. Neue Startwerte und gewählte Hintergrundausrüstung einmalig, mit optionalem Herkunftsnachweis. Alte JSONs bleiben lesbar. Die neue Heiliges-Symbol-Auswahl verleiht keine automatische Spellcasting-Befugnis.

Quellregel: [SRD 5.2.1, CC BY 4.0](https://www.dndbeyond.com/srd).

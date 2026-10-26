# CHAT A – Klassenbezogene SRD-Zauberwerte (25.10.2026)

- **Basis-Main:** `97a06118f17d71cc77be2cb15a2fc9a53db20ee0`.
- **Branch:** `feat/chat-a/spell-class-stats-20261025`.
- **Vorheriger offener Chat-A-PR:** [#180](https://github.com/ManuEtt/Dnd/pull/180) (Zauberdauer); dieser Branch berührt **keine** seiner geänderten Dateien.
- **Dieser Pull Request:** wird bei Erstellung in der PR-Beschreibung dokumentiert.
- **Module:** `app/lib/domain/srd_spell_saving_throw_rules.dart`, `app/test/srd_class_spell_stats_test.dart`.
- **Weitere Dateien:** `docs/SRD_SPELL_CLASS_STATS_20261025.md`, eigener Checkpoint, README und `docs/CODEX_CHECKPOINT.md`, optional Anforderungsregister. Gemeinsame Dokumentationsänderungen vor Integration mit Chat D konsolidieren.

## IMPLEMENTIERT

Rein lesender SRD-Klassenabgleich für acht Zauberklassen mit sicherer Auflösung von Klassenattribut, Übungsbonus, Zauberangriffsbonus und Zauber-Rettungswurf-SG, einschließlich unterschiedlichen Werten für einen Mehrklassencharakter. Alte API bleibt kompatibel.

## GETESTET

Die acht Testgruppen sind geschrieben. Ein erfolgreicher Test- oder CI-Lauf wird hier erst dokumentiert, sobald der finale Commit nachgewiesen ist.

## NICHT GETESTET / BLOCKIERT

Lokal fehlen Flutter-/Dart-/Android-SDKs. Reale Android-Geräteabnahme und produktive Signierung bleiben offen.

## NOCH NICHT IMPLEMENTIERT

Generische Zauberangriffsausführung, Prüfung individueller Zauber-/Subclassberechtigungen, Effekte, Reaktions-/Krit-Regeln im vollständigen Kampfverlauf; keine Fertigmeldung für ganze SRD-Kapitel.

## NÄCHSTER SCHRITT

Nach erfolgreicher CI eine einzige tatsächliche Zauberangriffs-Aktion mit bestätigtem Ziel, Würfelergebnis, separater Klassenfähigkeit, sicherem Slot-/Aktionsverbrauch und Neustart-/Idempotenztests an die bestehende Regelschicht anbinden, nur wenn keine konkurrierenden PRs die zugehörigen Controller-/State-Dateien bearbeiten.

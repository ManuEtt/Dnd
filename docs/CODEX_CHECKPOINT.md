# CODEX-CHECKPOINT – Klassenprüfung für Heilige Flamme

Stand **2026-10-26T05:08:37+00:00**. Version **0.8.41+91**, SQLite **2**, Kampagnen-JSON **1**.

## Git und Quellen

- Basis-Main `575a885bd34ecae2bd173dc183abf88a367a69af`, Arbeitskopie `/workspace/Dnd-sacred-flame-20261026`, Branch `fix/sacred-flame-caster-validation-20261026`. Main in diesem Paket nicht verändert.
- [PR #184](https://github.com/ManuEtt/Dnd/pull/184), Source-Head `0a7f3dc75161cf6936163b85c04dc9a78bfb12c1`, normal integriert; originale Source-CI #40220880850 erfolgreich. Dieser Einzelbeleg ersetzt nicht die neue gemeinsame Abnahme.
- Letzte vor dem Paket vollständig beobachtete Main-CI [#40233719625](https://github.com/ManuEtt/Dnd/actions/runs/40233719625) auf `5f9a01dd73f68ad4f9e226f859a8ca87803b8337` erfolgreich. Spätere Main-Integrationen #194/#195 separat vom alten Beleg unterscheiden.
- Aktueller Integrationscommit vor Fachänderung `ac51d6b`; Fach-/UI-/Regressionen noch im Arbeitsstand. README-/Checkpoint-/Changelog-/Statusfassungen von Main und PR #184 archiviert; manifeste SHA256 unter `docs/history/sacred_flame_before_20261026/`.

## IMPLEMENTIERT

Heilige Flamme verwendet den klassenbezogenen Rechner im echten Domain-/GameEngine-/Controllerpfad. Alias-Doppelklassen, unbekannte Partner und ungültige Klassenstufen werden vor RNG abgelehnt. Bestehende ausdrückliche SG-Bestätigung bleibt Voraussetzung; kein erfundenes Zustimmungstrue. Gültige Kleriker-Zweitklasse nutzt WIS und Gesamtstufen-Übung. UI zeigt diese Werte erst nach Bestätigung und sperrt ungültige Profile; Titel/Inhalt scrollen gemeinsam bei kleiner Android-Fläche.

Keine globale Klassen-/Importmigration: historische Profile und gespeicherte Ereignisse bleiben lesbar. Event, Snapshot und Revision weiterhin durch vorhandene SQLite-Transaktion; keine neuen Netzwerk-/KI-Aufrufe.

## GETESTET

20 Domain-, vier reale SQLite-/Controller- und sieben Widgettests erfolgreich. Sieben neue Domain-Gegenfälle zuerst rot gegen alten Code, nach Korrektur grün. Reale importierte Alias-/Unknown-Profile bleiben lesbar, erzeugen aber keine Würfel, Aktion, HP- oder Journaländerung. Gültiger Wizard5/Cleric1 mit INT20/WIS12 nutzt SG12, 2W8 Schaden und unveränderten Ressourcenumfang. Neustart/Rekonstruktion, Stale Revision, Wiederholung und echter SQLite-Eventfehler mit vollständigem Rollback geprüft. UI bei 360dp, 1,8×Schrift und Tastatur geprüft. Importgrenzen/Projektstruktur erfolgreich.

## NICHT GETESTET

Komplette neue Suite, neue Android-Builds und finale PR-CI noch ausstehend. Echtes Android-Gerät, reales historisches Geräte-Upgrade, TalkBack und produktive Signierung bleiben offen. SRD insgesamt nicht fertig.

## BLOCKIERT

Kein echtes Gerät/Produktivschlüssel. Flutter3.35.7/Dart3.9.2, Java17, Node22.14 und Android-SDK lokal vorhanden; keine fehlende Toolchain als Begründung übernehmen.

## NOCH NICHT IMPLEMENTIERT / GENAU EIN NÄCHSTER SCHRITT

Nach Abnahme: Feuerpfeil mit ausdrücklicher Bestätigung unbekannter Zauberangriffsmodifikatoren an Klassenwerte-Rechner anschließen; vorhandene Klassenwahl und Erschöpfung erhalten. Vor Bestätigung keine RNG-/Ressourcen-/HP-/Aktionsänderung. Details im README. Keine neue Klassenwahl oder bereits vorhandene reine Module duplizieren.

## Sicherung und Fortsetzung

Vollprojekt-ZIP/Patch/Manifest/SHA nach diesem Update unter `/workspace/artifacts/0.8.41+91/`. Patchbasis `575a885bd34ecae2bd173dc183abf88a367a69af`. Vor Abschluss tatsächliche Gesamttests, Buildquelle, Commit/PR und CI eintragen. Logs unter `/workspace/validation/20261026-sacred-*`. Frühere uncommittete Checkpoints und historische Worktrees nicht entfernen. Zuerst Main und aktive PRs neu prüfen; mehrere Chats entwickeln parallel. Keine automatische Fortsetzung außerhalb aktiver Sitzung.

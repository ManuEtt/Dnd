# Charaktereditor: veraltete Bearbeitungen ablehnen (28.10.2026)

## Problem
Vorher übergab der Charaktereditor nur den nachträglich bearbeiteten
`HeroCharacter`. Wenn ein anderer Spielzug, ein zweiter SQLite-Zugriff
oder ein zweites Editorfenster während der Eingabe neuere Daten bestätigte,
konnte die spätere Bestätigung mit alten Eingabewerten erfolgen. Besonders
`saveStandaloneHero` verwendete für reine Archivfiguren das überschreibende
`saveCharacter` ohne Vergleich mit dem ursprünglich geladenen Stand.

## Änderungen
- **Kampagneneditor:** die UI merkt sich beim Öffnen Kampagnen-ID und
  Revision. `GameController.saveHero` prüft beide gegen den laufenden und
  den tatsächlich gespeicherten Stand. Der bereits vorhandene transaktionale
  `saveCampaign(expectedRevision: ...)` schützt das Zeitfenster danach.
- **Charakterarchiv:** die UI übergibt die beim Öffnen erhaltene ursprüngliche
  `HeroCharacter`-Version. Neue `AtomicCharacterSnapshotStore`-Schnittstelle
  vergleicht in einer SQLite-Transaktion das tatsächliche kanonische
  JSON-Snapshot oder bei Neuanlage den freien Primärschlüssel. Bei
  Abweichung wird *nichts* überschrieben.
- **Gemeinsame Heldenkennung:** wenn der Archivcharakter zu der aktiven
  Kampagne gehört, bleibt der persistente Schreibweg über die Regelengine
  und die Kampagnenrevision erhalten. Ein Kampagnenwechsel während der
  Bearbeitung wird abgelehnt.
- Benutzer erhalten eine deutsche Meldung über den Versionskonflikt.
- Vorhandene Imports, Legacy-Testimplementierungen und alte Charakterdaten
  bleiben unverändert; SQLite-Schema Version 2, Charakter-JSON unverändert.
  Alt-Aufrufer ohne Editorkontext nutzen die alte API bewusst weiter.

## Belege und Grenzen
- `app/test/character_editor_stale_save_test.dart`: echte SQLite-Datei
  mit zwei gleichzeitigen Datenbankzugängen, abweichende Kampagnenrevision,
  falsche Kampagnen-ID, alte Archivfassung, Neuanlage mit bereits belegter ID,
  gelöschter Charakter und akzeptierter frischer Revisionsbasis/Neustart.
- **CI-Status:** neue Tests geschrieben; erfolgreiche vollständige CI auf dem
  finalen Commit separat nachweisen. Kein Geräte- oder TalkBack-Test.
- Keine vollständige Entwurfstransaktion: bereits beim Editoröffnen
  gespeicherte Charaktere bleiben weiterhin von anderen Regeln editierbar;
  bei Versionskonflikt muss der Benutzer den Editor neu öffnen. Ein
  Konflikt-Merge wird nicht automatisch durchgeführt.
- Vollständige SRD-5.2.1-Charaktererstellung (Spezies, Pflichtentscheidungen
  aller Klassen, Talente, Zauber, Inventar) bleibt unabhängig offen.
- PR #319 führt bereits Klassenbestätigungen und sichere erneute Starterpakete
  ein. Dieses Paket implementiert sie ausdrücklich nicht erneut.

## Nächster konkreter Schritt
PR #319, #324 und dieses Paket auf aktuellem `main` gemeinsam
konfliktgeprüft integrieren. Anschließend persistente, bei Abbruch
nicht bestätigte Entwürfe mit eigenen Versionen und vollständiger
Erstellungs-Audit-Autorität einführen.

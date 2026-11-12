# Branchmigration vom 12.11.2026

## Auftrag und gesicherter Umfang

Alle 87 beim Start erfassten Branches (main und 86 Nebenbranches) wurden lokal
mit ihrer vollständigen Quellhistorie vereinigt. Der maschinenlesbare Nachweis
steht in `MIGRATION_20261112.json`. Die Veröffentlichung verwendet den aktuellen
Main-Commit als ersten Elterncommit und die erfassten Quellheads als zusätzliche
Eltern; dadurch bleibt jeder Originalcommit erreichbar. Kein Force-Push.

## Konfliktentscheidungen

- Dokumentationsnachträge additiv erhalten; der vorhandene README-Inhalt bleibt
  unverändert als Präfix erhalten. Historische Testmeldungen sind keine aktuelle Abnahme.
- NPC-Kontext und Stufenaufstieg: finale Format-/Profilkorrekturen übernommen.
- Akt VII: explizite Angebotsentscheidungen und beide bestätigten Varianten der
  Namensverwahrung kombiniert. Fragen und beiläufige Erwähnungen bleiben gesperrt.
- Heilzauber: finale KeyedSubtree-Implementierung mit stabilen Formular-Keys
  erhalten; zusätzliche Live-Wechsel-Regressionen aus älteren Varianten behalten.
- Rabenwacht: korrigierte Besuchereintrag-Erwartung erhalten. Eine Untersuchung
  der Kapelle darf die Handlung fortsetzen, aber keine Rückreise zur Mühle auslösen.
- Importgrenzen: vorhandene frühe Prüfung verlinkter Quellwurzeln erhalten;
  ergänzenden Regressionstest auf den tatsächlich einen Fehler abgestimmt.

## Tatsächlich ausgeführte lokale Prüfungen

- Projektstruktur, Modulgrenzen und SRD-Register: bestanden.
- Python: 426 Tests bestanden.
- Backend: Typecheck und Build bestanden; 79 Tests über `node --import tsx --test
  test/*.test.ts` bestanden. Der npm-Testlauncher konnte im Sandbox-Dateisystem
  seinen IPC-Socket nicht anlegen; derselbe Testsatz wurde direkt ausgeführt.
- Dart 3.9.2: 732 Dateien formatiert, zwei Testdateien korrigiert. Fehlende
  Paketauflösung für die Lint-Konfiguration ist kein Flutter-Analyse-Erfolg.
- Flutter-/Android-Gesamtabnahme: auf dem kombinierten GitHub-Stand noch offen.
  Lokale Flutter-Einrichtung durch Sicherheitsprüfung wegen Metadatenzugriff gestoppt.

## Issue und Bereinigung

Beim Start existiert kein offenes Issue. Die früheren Migrations-Issues #425
und #333 sind bereits geschlossen und werden nicht erneut als erledigt verbucht.
Quell-PRs und Branches bleiben bis zur erfolgreichen kombinierten Abnahme erhalten.
Danach nur unveränderte, vollständig integrierte Heads archivieren und löschen;
zwischenzeitlich hinzugekommene Arbeit separat prüfen. Keine Spielstandmigration.

## Actions-Konsolidierung

Der vollständige Android-Workflow übernimmt unverändert alle Format-, Analyse-, Backend-, Flutter-, Protokoll-, nativen Android- und APK-Prüfungen. Die redundanten Mönch-/Eldritch-Spezialworkflows und der einmalige Format-Reparaturworkflow sind entfernt; keine Fachtests entfernt. Der zentrale Workflow bleibt manuell startbar. Der sichere Branch-Cleanup prüft offene PRs, Branchschutz und SHA unmittelbar vor der Löschung erneut. Zwei zusätzliche ausführbare Regressionen testen echte Workflow-Logik gegen simulierte GitHub-Antworten. Jetzt 428 Python-Tests bestanden. Historische Actions-Protokolle wurden nicht gelöscht.

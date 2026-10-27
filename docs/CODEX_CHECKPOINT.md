# Charakter-Audit – Checkpoint 2026-10-27T19:37:07.117509+00:00

Würfelraunen **0.8.44+94**, SQLite **2**, Kampagnen-/Helden-JSON **1** unverändert.
Branch `feat/character-creation-audit-evidence-20261027`, Worktree
`/workspace/Dnd-character-audit-20261027`, Basis-Main `8239f5e71ec6b229a2a0883500adaf431bb70087`.
Kopf mit `git rev-parse HEAD` bzw. Artefaktmanifest bestimmen. PR wird nach
früher Sicherung erstellt; PR #297 / f1d2785 bleibt separat offen.

## IMPLEMENTIERT

Nachweisbasierter lesender Audit mit sieben Zuständen. Keine Bestätigung aus
bloßen Spezies-/Klassenmerkmalnamen, beliebigen Gegenständen oder 0 Gold.
Vorhandene StartingAbilityOrigin/SrdBackgroundPackageChoice werden verwendet,
Widersprüche auf Stufe 1 erkannt, historische spätere Werte nicht rückwirkend
verändert. Doppelübungen einschließlich Medizin-/Heilkunde-Alias werden erkannt;
Mehrklassenaufteilung/Unbekannte Partner geprüft. Auch bekannte Klassenbezeichnungen und Editor-Vorauswahlen werden ohne
Entscheidungsnachweis nicht als bestätigt ausgegeben.

Editor prüft aktuelle ungespeicherte Werte; strenge Zahlenprüfung und 10,5-m-
Restdezimeter erhalten. Deutscher Dialog mit sieben Zustandsbeschreibungen,
Screenreader-Semantik, erreichbarem Schließen. Keine neue Auditdaten-Persistenz,
keine Schemaänderung, keine autoritativen Regel-/Story-Aktionen.

## GETESTET

24 gezielte Tests erfolgreich: zwölf Domainfälle (mit allen zwölf Klassen),
neun Widgetfälle (320/360 dp, 200 % Schrift, Tastatur, Semantik, Entwurfsfehler,
Bestätigung und Hausregel), drei SQLite-Integrationstests. Audit ändert weder
sechs DB-Tabellen noch Events/Revisionen/Archiv/Outbox/Controllerbenachrichtigungen.
SQLite-Neustart, Rekonstruktion, Helden-/Kampagnenimport und Export erhalten
Teilentscheidungen und historische Werte. Vollständige Flutter-Analyse ohne Befund.
Logs `/workspace/validation/20261027-audit-targeted.log` und `20261027-audit-analyze.log`.

Letzte tatsächlich erfolgreiche Main-Android-CI
https://github.com/ManuEtt/Dnd/actions/runs/40531665011 auf `8239f5e71ec6b229a2a0883500adaf431bb70087`.
Vorheriges eigenes Paket PR #297 erfolgreich in #40503354461; kein Nachweis
dieser neuen Auditänderung. Offene PR-Dateien beim Einstieg geprüft; keine andere
laufende Charakter-Audit-Implementation gefunden.

## NICHT GETESTET

Neue vollständige scripts/check.sh-Suite, Android-Debug/native Tests,
ARM64-Alpha und finale neue PR-CI beim frühen Checkpoint noch offen. Echter
Android-/TalkBack-Test, installiertes Datenupgrade und produktive Signatur offen.

## BLOCKIERT / bekannte Fehler

Kein echtes Gerät/Produktivschlüssel. Lokale Toolchain vorhanden, keine SDK-Ausrede.
Unabhängiger Main-Bereinigungsworkflow #40533669855 rot: Annotation
`Unhandled error: HttpError: Not Found`; Main-App-CI grün. Wartungs-PR #301 und
andere Story-/Tooling-PRs sind separat; dieser Charakter-Branch löscht keine
fremden Branches und verändert den Bereinigungsworkflow nicht.
Keine aktuelle Kontingentmenge erfunden; vor Limits zuerst Quellcheckpoint sichern.

## NOCH NICHT IMPLEMENTIERT

Vollständiger Assistent und persistenter Entwurf; Quellenmetadaten sämtlicher
Klassenstartwahlen; sämtliche Speziesvarianten/-merkmale; vollständige Talente,
Magic Initiate und Zauber-/Fokuswahl. Der Audit bleibt Teilprüfung ohne
Gesamt-SRD-Erfolgsflag. Eine bekannte Klassenbezeichnung oder Editor-Vorauswahl belegt keine
ausdrückliche Klassenentscheidung. Ein Hintergrundpaket belegt kein Klassenpaket.

## Sicherung und genau nächster Schritt

Projekt-ZIP, binärer Patch, Dateimanifest und Prüfsummen unter `/workspace/artifacts/character-audit-20261027T193707Z`.
Originale Main-Dokumente unter `docs/history/character_audit_20261027T193707Z` mit SHA256 erhalten.
Früher ZIP-/Patch-Checkpoint vor Gesamtprüfung; dann exakte PR-CI/Artefakte
prüfen und Ergebnis nachtragen. Vollprojekt umfasst generierte Grafiken,
keine APKs, SDKs, privaten Spielstände oder Schlüssel.

Nach Abnahme: **erste Klassenstartentscheidung quellengetrennt versionieren**.
DoD: ausdrückliche Klassen-/Fertigkeits-/Ausrüstungswahl im vorhandenen Dialog
als geprüfte Entscheidung speichern; Hausregel-/Legacy-Daten nicht erfinden;
Klasse/Attribut-/Paketänderungen widerspruchsfrei behandeln; Audit liest echte
Quelle; SQLite-Neustart, JSON, Abbruch und Stale-Revision testen. Vorher
aktuelles Main und PR #297 erneut prüfen. Keine automatische Weiterarbeit
außerhalb einer aktiven Sitzung. Prüfungen: `bash scripts/check.sh`, zusätzlich
`flutter build apk --debug` und `:app:testDebugUnitTest` gemäß Workflow.

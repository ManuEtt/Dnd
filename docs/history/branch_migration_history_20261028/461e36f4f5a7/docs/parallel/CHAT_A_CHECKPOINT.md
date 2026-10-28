## 27.10.2026 – Chat A: Gestapelter Weitsprung-Kampfübergang – [PR #285](https://github.com/ManuEtt/Dnd/pull/285), CI-Auswertung offen

- **Basis/Koordination:** [PR #284](https://github.com/ManuEtt/Dnd/pull/284), HEAD `4e15ba643a22b94e9ec3ba7da72e8330a0b0e56c`, stammt aus `main` `e7736bfc99427bfa6a1d0fd3ff887252c75c9413`. Neuer Branch `feat/chat-a/long-jump-encounter-plan-20261027` **mit PR-Zielbranch #284**, nicht ungeprüftem `main`.
- **IMPLEMENTIERT:** `SrdLongJumpEncounterRules.prepare` und `SrdLongJumpEncounterPlan` projizieren eine bestätigte Sprungbewegung aus unveränderter `Campaign` / `Encounter`, prüfen aktive Runde, IDs, Revision, offene Würfe, Zustand, bezahlten Anlauf, D20-Würfe und exakte Dezimeter; bei bestätigtem misslungenem SG-10-Akrobatikwurf wird `liegend` nur im Kandidaten ergänzt. 15-cm-Reste bleiben ausdrücklich blockiert, nicht stillschweigend gerundet. Neue negative/positive Flutter-Domain-Tests. Keine gleichzeitige Änderung an #280-Engine/Controller-Dateien.
- **GETESTET:** Canonical-Dartformatierung der beiden neuen Dateien mit [GitHub Actions #40475431987](https://github.com/ManuEtt/Dnd/actions/runs/40475431987) festgestellt und auf dem Branch korrigiert; temporären Diagnose-Workflow wieder gelöscht. Offizieller SRD-Regeltext, Quellcode/PRs geprüft; Basis-PR #284 besitzt vollständig erfolgreiche [CI #40472176859](https://github.com/ManuEtt/Dnd/actions/runs/40472176859), aber dieser Lauf betrifft nicht den neuen Branch.
- **NICHT GETESTET:** Finaler neuer Branch-Format-/Flutter-/Android-Gesamtlauf und echtes Android-Gerät. Lokales Dart-SDK fehlt.
- **BLOCKIERT:** Engere Engine-/SQLite-Integration wartet auf koordinierte Geländebewegungs-PRs #280/#278/#276 und Revisions-/Ereignisschutz.
- **NOCH NICHT IMPLEMENTIERT:** Kein `GameUpdate`, keine SQLite-Transaktion, keine Idempotenzkennung oder UI-Auswahl. Projizierter Zustand ist **keine** dauerhaft gespeicherte Aktion, keine Freigabe für Spielstände.
- **Unverändert:** SQLite 2, JSON 1, App 0.8.42+92; keine Schemaänderung, keine globale SRD-Abdeckungsbehauptung.
- **Weitere Details:** `docs/parallel/CHAT_A_LONG_JUMP_COMBAT_PLAN_20261027.md`.
- **Genau ein nächster Schritt:** nach grüner CI und Integration von #284 und abgestimmtem #280-Rechtsstand koordinierter einmaliger GameEngine-/GameController-/Repository-Commit mit Ereignis-, Rollback- und Neustarttests.

---

# Chat A – SRD-Weitsprungprüfung (27.10.2026)

- Ausgangs-`main`: `e7736bfc99427bfa6a1d0fd3ff887252c75c9413`.
- Branch: `feat/chat-a/long-jump-preflight-20261027`; Pull Request: [#284](https://github.com/ManuEtt/Dnd/pull/284), Basis `e7736bfc99427bfa6a1d0fd3ff887252c75c9413`. Die kanonische Dartformatierung wurde mit der temporären Diagnose [40471878051](https://github.com/ManuEtt/Dnd/actions/runs/40471878051) ermittelt, im Code korrigiert und die temporäre Workflowdatei auf `75fb868b5fdeaac14b1bffc6bcbe2109048aea54` wieder entfernt. Gesamte CI auf finalem Commit separat abwarten.
- IMPLEMENTIERT: `SrdLongJumpRules`, sofort bestätigter Anlauf ab 10 Fuß, exakt halbierter Standweitsprung, Zentimeter-Bewegungsbudget, getrennte Akrobatik-Landung und optionale Athletik-Hindernisprobe; sichere Behandlung ausstehender Ergebnisse. Keine automatische Aktion oder Mutation.
- GEÄNDERTE DATEIEN: `app/lib/domain/srd_long_jump_rules.dart`, `app/test/srd_long_jump_rules_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_A_CHECKPOINT.md` und `docs/parallel/CHAT_A_LONG_JUMP_20261027.md`.
- GETESTET: offizielles SRD 5.2.1 (Druckseiten 184–185), Quellcode, offene PR-Dateipfade und vorherige Hochsprung-CI [40469553724](https://github.com/ManuEtt/Dnd/actions/runs/40469553724) **auf anderem Commit** geprüft.
- NICHT GETESTET: neue Weitsprung-Tests lokal und gesamter Android-/CI-Build; finalen GitHub-Lauf gesondert auswerten. Frühere nicht finale Branch-Läufe scheiterten bereits am Dart-Format-Gate; nun wurde die echte Dart-Formatterausgabe übernommen. Kein grüner Gesamtbuild vorweggenommen.
- BLOCKIERT: kein lokales Dart-/Flutter-SDK. GitHub-CI zur tatsächlichen Regelabnahme verwenden.
- NOCH NICHT IMPLEMENTIERT: Weitsprung/Prone/Bewegung als transaktionale Kampfaktion, revisionsgebundene Ereignisse, Geräteabnahme.
- MIGRATION: keine; SQLite 2, JSON 1, App-Version 0.8.42+92 unverändert. Keine zentralen Regel-/Story-Verträge geändert.
- NÄCHSTER SCHRITT: nach grüner CI genau ein koordiniertes, sicheres Weitsprung-Ausführungspaket mit Wiedereintritt/Idempotenz/Neustart-Tests.
- Detailprotokoll: [CHAT_A_LONG_JUMP_20261027](CHAT_A_LONG_JUMP_20261027.md).

---

# Chat A – Checkpoint (26.10.2026): Eldritch-Blast-Klassenprüfung

- Ausgangs-Main: `42d14ad36cc947691f7e5a1e8647a43f5421b86e`; Branch: `fix/chat-a/eldritch-primary-class-validation-20261026`.
- IMPLEMENTIERT: `SrdEldritchBlastRules.resolve` weist unbekannte Hauptklassen vor RNG zurück, auch mit gültiger Warlock-Zweitklasse. Deterministischer Negativ-/Positivtest ergänzt.
- GETESTET: erfolgreiche vorherige Main-CI #40329543284/#40329543416; neue Branch-CI noch nicht ausgewertet.
- NICHT GETESTET: Branch-Flutter/Dart/Android, realer Gerätetest, historisches Geräte-Upgrade.
- BLOCKIERT: kein lokales Dart/Flutter-SDK. GitHub Actions übernimmt die ausführbare Abnahme.
- NOCH NICHT IMPLEMENTIERT: vollständiges SRD, weitere Mechanik; `SPELL-ENTRY-ELDRITCH-BLAST` bleibt partial.
- Kompatibilität: SQLite2, JSON1, keine Migration oder Eingriffe anderer Chats.
- Detailbericht: [Eldritch-Primärklassen-Prüfung](CHAT_A_ELDRITCH_PRIMARY_VALIDATION_20261026.md).
- Nächster Schritt: klassenrichtige Zauber-SG-Berechnung für Säurespritzer prüfen.

---

# Chat A – Regelwerk: Feuerpfeil-Klassenvalidierung

Stand: 2026-10-26 09:15 Europe/Berlin. Dies ist ein gesonderter Arbeitsstand von Chat A, kein Merge nach main.

## Ausgangslage / Git
- Ausgangs-main: `20098805d8c70cbd361a13862379894c47ef4eb6`.
- Eigener Branch: `feat/chat-a/fire-bolt-confirmed-modifiers-20261026`.
- Erstes Implementierungscommit: `992f5d537f158f0d1883fbd7210bf874205357cf`.
- Pull Request: [#221](https://github.com/ManuEtt/Dnd/pull/221) (Entwurf, kein Merge).
- PR #175: bereits geschlossen/gemerged; offene fremde PRs bei Ausgangsanalyse #216, #218, #219 ohne Überschneidung der geänderten Laufzeit-/Testdateien. Dokumentationsüberschneidung mit #216/#218 beim Integrationsreview durch Chat D konsolidieren.

## IMPLEMENTIERT (noch nicht vollständig CI-abgenommen)
- `FireBoltRules.cast` nutzt den bestehenden, klassenbezogenen `SrdSpellSavingThrowRules.statsForClass`, nicht mehr eine unvalidierte zweite Attribut-/Übungsrechnung.
- Feuerpfeil verlangt ausdrücklich die zunächst abgewählte Bestätigung, dass keine unmodellierten Gegenstände oder Merkmale den Zauberangriffsbonus verändern. Durchgängiger Transport: Dialog → App → Controller → GameEngine → Domain; Ablehnung vor Würfelwurf oder Spielstandänderung.
- Basisangriffsvorschau erst nach der Bestätigung; Eigenschaft/Klasse und Gesamtstufen-Übungsbonus bleiben erkennbar. Erschöpfung wird im Würfelbonus genau einmal angewendet.
- SRD-5.2.1-Provenienz: *Spellcasting* (Spell Attack Modifier), *Multiclassing* (Proficiency Bonus) und *Attack Rolls*; Wizards of the Coast LLC, CC BY 4.0. `THIRD_PARTY_NOTICES.md` unverändert. Requirement bleibt `partial`.

## Geänderte Dateien
- `app/lib/domain/fire_bolt_rules.dart`
- `app/lib/domain/game_engine.dart` (eng begrenzte Feuerpfeil-Schnittstelle)
- `app/lib/services/game_controller.dart` (eng begrenzte Weiterleitung)
- `app/lib/ui/fire_bolt_dialog.dart`
- `app/lib/ui/app.dart` (eng begrenzte Weiterleitung)
- `app/test/fire_bolt_rules_test.dart`
- `app/test/fire_bolt_dialog_test.dart`
- `docs/FIRE_BOLT_CLASS_VALIDATION_20261026.md`, `README.md`, `docs/CODEX_CHECKPOINT.md`, diese Datei.

## GETESTET / CI
- Erstes Android-CI auf `992f5d5`, [Run #40289603452](https://github.com/ManuEtt/Dnd/actions/runs/40289603452): **fehlgeschlagen** bei `dart format --output=none --set-exit-if-changed lib test` (genau zwei Testdateien), spätere Gates **nicht ausgeführt**. Formatierungsbehebung anschließend eingecheckt.
- Erster separater Chat-A-Regression-Workflow [#40289603227](https://github.com/ManuEtt/Dnd/actions/runs/40289603227): `completed/success`; ersetzt keine vollständige Android-CI.
- **Vollständige Android-CI [#40290687523](https://github.com/ManuEtt/Dnd/actions/runs/40290687523) auf geprüftem Code-/Test-HEAD `588b746e60fa27d9f4c40064a70c13aa9f125dd0`: completed/success.** 1.706 Flutter-Tests, 141 Python- und 57 Backend-Tests; 389 Dartdateien ohne Formatänderung, Flutter-Analyse ohne Befund, Backend-Typecheck/Build und Android-Debug/native/3 Alpha-ABI-Builds erfolgreich. Ein weiterer paralleler CI-Lauf ist keine Voraussetzung für diese nachgewiesene Einzelabnahme.
- GitHub-Artefakte nachgewiesen: [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40290687523/artifacts/12635429229), [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40290687523/artifacts/12635723341), [Alpha-/Buildartefakt](https://github.com/ManuEtt/Dnd/actions/runs/40290687523/artifacts/12635748319), [Quell-Checkpoint](https://github.com/ManuEtt/Dnd/actions/runs/40290687523/artifacts/12635414535). Artefaktarchive nicht mit lokal gerätegetesteten APKs gleichsetzen.
- Endgültiger Laufzeit-/Testquellcommit: `588b746e60fa27d9f4c40064a70c13aa9f125dd0`. Ein nachgelagerter reiner Dokumentationscommit enthält keine Änderung an `app/`, `backend/` oder `scripts/`.

## NICHT GETESTET
Lokale Flutter-/Dart-/APK-Befehle mangels installiertem SDK nicht ausführbar; stattdessen vollständige GitHub-CI auf Code-HEAD `588b746e60fa27d9f4c40064a70c13aa9f125dd0` erfolgreich. Reales Android-Gerät, TalkBack, historisches Geräte-Upgrade und Produktionssignierung fehlen. CI-APKs wurden gebaut und als GitHub-Artefakte bereitgestellt, aber nicht auf einem Gerät installiert.

## BLOCKIERT
Lokale Ausführung von `flutter test`, `flutter analyze` und `flutter build apk --debug` mangels Flutter-SDK. GitHub Actions hat die vollständige Integrationsprüfung bestanden. Keine unabhängigen Remote-Branches verändert oder gelöscht; README und zentraler Checkpoint sind bei parallelen PRs beim Integrationsreview zu konsolidieren.

## Speicher / Kompatibilität
Keine Migration, kein Schema-/JSON-Update (SQLite 2, Kampagnen-JSON 1). Historische Profile bleiben lesbar; ungültige Werte werden ausschließlich bei neuen Aktionen zurückgewiesen. Keine KI- oder Storyzustandsänderung.

## NOCH NICHT IMPLEMENTIERT
Zusätzliche bestätigte magische Angriffsmodifikatoren als echte modellierte Werte; vollständige Feuerpfeil-Objekt-/Umgebungswirkung; vollständige SRD-Inventur. Diese Prüfung beansprucht keine vollständige Regelabdeckung.

## NÄCHSTER SCHRITT
Nach erfolgreichem Review dieses Pakets: **Feuerpfeil-Ziel- und Gegenstandsregeln unabhängig prüfen**. Akzeptanz: brennbare unbeaufsichtigte Objekte nur mit explizit bestätigtem Objekttyp und Reichweite; keine Änderung eines unbestätigten Objekts, kein RNG vor Validierung; deterministische positive/negative Tests sowie Alt-JSON- und Ablehnungsinvarianz.

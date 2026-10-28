# Chat A – Würfel-Zauberbereich: validierter Ursprung (28.10.2026)

- **Ausgangs-main:** `ab8bef62039a2c4df04ee0cbecf0baebfefc8d78` (unverändert bei Vor-PR-Prüfung).
- **Arbeitsbranch:** `feat/chat-a/cube-spell-origin-20261028`; **PR:** wird nach Dokumentationscommit erstellt (Link im PR/Checkpoint-Nachtrag).
- **Anforderung:** `RULE-SPELLS-SPELL-AREAS-OF-EFFECT` bleibt `partial`. SRD 5.2.1, *Rules Glossary / Cube*, und *Spells / Thunderwave*, S. 169; Wizards of the Coast LLC, CC BY 4.0, https://www.dndbeyond.com/srd.
- **Ausgangsproblem:** `SrdCubeAreaRules.preview` nahm ein beliebiges Rasterfeld als Ursprung an, ohne den vom Zauberkatalog beschriebenen Wirker-Ursprung, die Reichweite oder die Kartenblocker durch das vorhandene Spell-Target-Preflight zu validieren. Andere Bereichsformen besitzen einen solchen Einstieg.
- **IMPLEMENTIERT:** `SrdCubeAreaRules.previewConfirmedSpell` prüft zuerst die separat bestätigte Würfelform und anschließend `SrdSpellGridTargetRules.validateOrigin`. Erst dann erfolgt die unveränderte, rein lesende 2D-Kandidatenberechnung. Keine Zauberwirkung, kein Wurf, keine Slotbuchung und keine KI-Interpretation.
- **Dateien:** `app/lib/domain/srd_cube_area_rules.dart`, `app/test/srd_cube_area_rules_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, dieser Checkpoint.
- **Akzeptanzkriterien:** Gültiger Self-Ursprung für Thunderwave erzeugt die bestätigte 15-Fuß-Würfel-Kandidatenfläche; unbestätigte Form/Ausrichtung, ungültige Größe, entfernter Self-Ursprung, unsichere/vollständig blockierte oder außerhalb der Karte liegende Felder werden vor der Vorschau abgelehnt; Kandidatenliste unveränderbar.
- **Tests hinzugefügt:** positive und negative Flutter-Domänentests in `srd_cube_area_rules_test.dart`. **GETESTET:** tatsächliche GitHub-Dateiversionen und PR-Dateipfade geprüft; noch kein bestandener neuer Dart-/Flutter-/CI-Test auf dem Branch dokumentierbar.
- **NICHT GETESTET:** `dart format`, `flutter analyze`, `flutter test`, Android-Build, Gerätetest sowie Python-/Backend-Gesamtsuite auf diesem neuen Branch; lokale Flutter-/Dart-SDKs fehlen. GitHub Actions nach PR-Erstellung prüfen.
- **BLOCKIERT:** lokale ausführbare Flutter-Prüfung mangels SDK; formale Freigabe erst bei grünen GitHub-Gates.
- **Kompatibilität:** keine Änderung an bestehendem `preview`, SQLite, JSON, Spielständen, Ereignissen, Ressourcen oder Storyschnittstellen. Keine Migration. Kein Konflikt mit offenem PR #353 (dessen geänderte Dateien liegen außerhalb dieses Regelpakets; zentrale Registerdatei bewusst unverändert).
- **NOCH NICHT IMPLEMENTIERT:** automatische 3D-Wirkfläche, tatsächliche Zielerfassung, Konstitutionsrettung, Donner-Schaden/Schub von Thunderwave oder andere vollständige Zauberwirkungen.
- **NÄCHSTER SCHRITT:** unabhängige, regelgeprüfte Würfel-Footprint-Richtungswahl statt nur positiver Rasterachsen; Akzeptanz: alle vier bestätigten horizontalen Quadranten ohne erfundene 3D-Treffer, deterministische Rand-/Blocker-Regressionen.

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

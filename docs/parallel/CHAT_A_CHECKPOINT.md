# Chat A – Kurzrast-Ressourcen vor Trefferwürfeln prüfen

Stand30.10.2026 UTC, Basis-Main `55fe44475a113943c6310ec16a8ffb481185f4e9`.
Branch `feat/chat-a/short-rest-resource-preflight-20261030`,
Quellcode-/Testcommit `19fe5e16394fae096c082a86e7aa8886461fc883`. [PR #428](https://github.com/ManuEtt/Dnd/pull/428) ·
[aktuelle CI-Ergebnisse](https://github.com/ManuEtt/Dnd/pull/428/checks). Kein Main-Merge behauptet; Chat D konsolidiert.
Appbasis **0.8.48+98**, SQLite **3**, äußeres JSON **1**, keine Migration.

## Ausgangsproblem / Akzeptanz

Ein Kämpfer2 mit SecondWind3, ActionSurge2 oder unverdienter Rage1 scheiterte
bisher erst **nach einem** Heilungswurf. Paktverbrauch1 ohne Hexenmeister wurde
sogar akzeptiert: HP3→6, Pakt1→0, ein Würfel. Die Ressourcengrenzen müssen vor
RNG/Heilung/Regeneration gelten; ein Erholungsreset darf einen ungültigen
Ausgangswert nicht verdecken. Gültige Erholung darf nicht doppelt erfolgen.

## IMPLEMENTIERT

`RestRules.shortRest` prüft direkt nach der vorhandenen Rastzulässigkeit:
`ClassFeatureResources.validate`, `ClassResourceRules.validate` und
`SpellcastingRules.availablePactSlots` auf dem **Originalhelden**, bevor ein
Trefferwürfel geworfen wird. Bestehende Regenerationskette und optionale
Zauberkraftregeneration bleiben unverändert. Keine GameEngine-, Modell-,
Controller-, Persistenz- oder UI-Datei verändert; deutsche Fehlermeldungen
nutzen den vorhandenen Fehlerkanal. Historische gültige Spielstände bleiben
unverändert lesbar, keine ungefragte Reparatur oder Neuberechnung.

Akzeptanzfälle: negative/überhöhte/unverdiente Zähler abweisen, ursprüngliche HP,
HD und Ressourcen bewahren, kein Würfel bei ungültigem Pool; gültige Mönch-,
Kämpfer-, Pakt- und weitere Klassenregeneration genau einmal; Abbruch/Import,
Retry, stale Revision, SQLite-Neustart und atomarer Rollback absichern.

## GETESTET

**65** gezielte Domain-/Bestandsfälle bestanden, darunter **33 neue** Unitfälle:
negative/überhöhte/unverdiente Zähler, 1/2HD, Klassen-/Alias-/Mehrklassenfälle,
unveränderte Eingabe, genau einmalige Regeneration und explizites Sorcerous-Restoration-Opt-in.
**Sieben neue** Flow-/SQLitefälle bestanden: echte Engine-/Controllerablehnung
vor RNG, unveränderte sechs Tabellen bei ungültigen Daten, gültige Erholung,
Request-ID-Replay vor/nach Neustart, stale Zweitcontroller, JSON-Export/Import,
Eventprovenienz und später SQLite-Fehler. Bei letzterem sind zwei gültige Würfe
bereits erfolgt; die Datenbank rollt zurück, Zufallszahlen werden nicht als
rückrollbar behauptet. Kein Test deaktiviert.

Ein erster Flow-Testlauf hatte fünf erfolgreiche Fälle und zwei neue
Fixturefehler (Roh-JSON-Exportvertrag, Wizard/Magier-Slotannahme). Fixtures auf
bestehende Verträge korrigiert; danach sieben grüne Fälle, unveränderte rohe
Tabellenvergleiche. Ursprünglicher Fehllog bleibt im externen Prüfnachweis erhalten.

Vollsuite, Analyse, Debug/native und aktuelle GitHub-CI werden separat anhand
[des aktuellen PR-Kopfs](https://github.com/ManuEtt/Dnd/pull/428/checks) und des vollständigen Testberichts im PR
geführt. Frühere Basis-CI oder PR416 gelten nicht als Abnahme dieses neuen Pakets.
Alle tatsächlich abgeschlossenen Läufe/Artefakte werden dort mit Commit/ID belegt.

## NICHT GETESTET / BLOCKIERT / NOCH NICHT IMPLEMENTIERT

Echtes Android-Gerät/TalkBack, installiertes Altversionsupgrade und produktive
Signierung bleiben offen. Kein Code-/GitHub-Zugriffsblocker. Dieser Fix gilt
**nur für kurze Rast mit Trefferwürfelverbrauch**. Engine-Sonderpfade ohne HD,
lange Rast, allgemeine Rastdauer/Unterbrechungen, freie Null-HD-Auswahl und
normale Zauberplatzvalidierung bleiben getrennt. Keine vollständige Rast- oder
SRD-Automatik behauptet. Requirement `RULE-SPELLS-PACT-MAGIC` bleibt **partial**.

## Quellen / Koordination

Amtliches [SRD5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
CC BY4.0, gedruckte S.187 Short Rest, S.48 Second Wind/Action Surge,
S.71 Pact Magic. Lizenzhinweise unverändert. Vor der Implementierung alle
**32** damaligen offenen PR-Dateilisten geprüft: keine Überschneidung von
`rest_rules.dart` und neuen Tests. Gemeinsame README-/Checkpoint-Ergänzungen
bleiben im eigenen Branch; Chat D konsolidiert sie bei Integration.

Voriger eigener [PR416](https://github.com/ManuEtt/Dnd/pull/416), Kopf870d4e98,
ist offen und mit [CI41074122650](https://github.com/ManuEtt/Dnd/actions/runs/41074122650)
geprüft. Sein GameEngine-Anteil wird hier nicht parallel verändert. Er ist
nicht auf Main übernommen; erfolgreiche Einzeltests ersetzen keine Kombination.
Historische ältere SDK-/SQLite2-/Integrationskandidaten-Aussagen darunter sind
Momentaufnahmen, kein aktueller Blocker.

## Sicherung / Wiederaufnahme

ZIP, Binärpatch, Manifest und Git-Bundle außerhalb des Projekts unter
`/workspace/artifacts/chat-a-short-rest-preflight-20261030/`, Frühstand `frueh/`,
Endstand `abschluss/`, tatsächliche Logs `pruefnachweise/`; Importanleitung
`ARTEFAKTE_UND_IMPORT.md`. Patchbasis ausdrücklich Main55fe4447; keine privaten
Spielstände/Schlüssel aufnehmen. Bestehende Arbeitsstände nicht mit ZIP überschreiben.
Vor neuen Änderungen Main/PRs/CI und Masterprompt erneut prüfen.

**Genau nächster Schritt:** bestätigte SRD-Klassenaliase bei normalen
Zauberplätzen kanonisieren. Reproduzierte separate Lücke:
`MulticlassRules.combinedSpellcasterLevel` vergleicht rohe Namen; Wizard erhält
keine Slots, Magier schon. Akzeptanz: gleiche Slotzahlen für alle erlaubten
Caster-Aliase und Mehrklassen, Pact Magic getrennt, unbekannte Klassen nicht
erraten, bisherige JSONs unverändert und Domain-/Persistenz-/CI-Nachweis.
Nicht im Rastpaket verändert; vor Umsetzung Überschneidungen erneut prüfen.
Keine automatische Entwicklung nach Sitzungsende.

---

## Historischer Verlauf (damaliger Schreibstand)

# Chat A – Checkpoint (26.10.2026): Eldritch-Blast-Klassenprüfung

## Integrationskandidat 29.10.2026 – Chat A

Zusammengeführte Fachpakete: [#357](https://github.com/ManuEtt/Dnd/pull/357), [#361](https://github.com/ManuEtt/Dnd/pull/361), [#366](https://github.com/ManuEtt/Dnd/pull/366), [#367](https://github.com/ManuEtt/Dnd/pull/367), [#372](https://github.com/ManuEtt/Dnd/pull/372), [#375](https://github.com/ManuEtt/Dnd/pull/375), [#385](https://github.com/ManuEtt/Dnd/pull/385). Die ursprünglichen Branch-HEADs, PR-Beschreibungen, Tests, bekannte Grenzen und Statusmeldungen sind im [Integrationsjournal](INTEGRATION_20261029.md) mit Git-Historie dokumentiert. **Dieser Stand ist weder auf main integriert noch gemeinsam CI-abgenommen; Drafts sind nicht freigegeben.** Bisherige Checkpoint-Einträge bleiben erhalten.


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

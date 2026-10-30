# Chat A – Todesrettung: bestätigte Klassen vor Regelwirkung

Stand 30.10.2026 UTC, Basis-Main `55fe44475a113943c6310ec16a8ffb481185f4e9`,
Arbeitsbranch `feat/chat-a/death-save-class-validation-20261030`.
Laufzeit-/Testcommit `ee1e5a19e03b5db60fad838d0da36d1f360b84bc`. Dieses Paket ist ein eigener PR-Arbeitsstand;
Integration und Dokumentationskonsolidierung obliegen Chat D.
Appbasis `0.8.48+98`, SQLite **3**, äußeres JSON **1**, keine Migration oder
Versionsänderung. Der frühere Mönch-Abschluss ist bereits auf Main integriert;
ältere Aussagen „kein lokales SDK“, „SQLite2“ und „Integrationskandidat nicht main“
weiter unten sind historische Schreibstände.

## Ausgangsproblem und Akzeptanz

`Unbestätigt 6 / Mönch 14` und `Mönch 14 / Unbestätigt 6` erhielten mit natürlicher
4 unzulässig +6, einen Erfolg und Zugriff auf den Fokus-Wiederholungswurf. Die
bisherige Klassenprüfung bestätigte nur die numerische Verteilung. Unbekannte
Kämpferkombinationen konnten entsprechend Unbeugsamkeit freigeben.

- Hauptklasse und tatsächlich gewählte Zweitklasse müssen aus dem bestehenden
  SRD-Klassenresolver bestätigt sein; kanonische Aliase bleiben erlaubt.
- Unbekannte Klassen ergeben vor Bonus, neuer Todesrettung oder Ressourcenwahl
  eine verständliche FormatException; bestehende Stufen-/Doppelklassenprüfungen bleiben.
- Auch eine unversionierte historische offene Todesprobe wird **vor** einem
  zufälligen, natürlichen oder nur als Gesamtergebnis übergebenen neuen Wurf geprüft.
- Historische Profile, rohe Spielstände und unversionierte Proben bleiben lesbar,
  ohne stillschweigende Klassenergänzung oder Neuinterpretation ihrer Geschichte.
- Ablehnung erzeugt keinen Wurf, Ressourcenverbrauch, Event, Revisionswechsel oder
  SQLite-Teilstand. Gültige Klassen behalten Übung, Klassenstufe und gewählte Wiederholung.

## IMPLEMENTIERT

`DeathSavingThrowRules._validateClassLevels` prüft zusätzlich die beiden
Klassenidentitäten. `GameEngine.resolveRoll` ruft für Todesproben die bestehende
lesende Klassenprüfung vor `dice.check` auf, auch für alte Regelversion0. Neue
versionierte PendingRoll-/PendingDeathSave-Importe werden über ihre vorhandene
Revalidierung abgewiesen. Kein Modell-, Controller-, Repository- oder UI-Umbau;
die deutsche Fehlermeldung läuft durch den vorhandenen Fehlerkanal.

Gemeinsame `game_engine.dart`: genau fünf Zeilen Vorprüfung in einem koordinierten
Integrationsanteil dieses Pakets. Vor der Änderung wurden alle **27** zu diesem
Zeitpunkt offenen PRs samt Dateipfaden geprüft: kein anderer PR bearbeitete die
beiden Laufzeitdateien oder neuen Tests. PR175 ist bereits geschlossen/gemergt.
#387/#400/#405/#408 bleiben eigenständige fremde Zauberpakete; keine Übernahme,
kein Schließen/Mergen/Löschen ihrer Branches. README-/Checkpoint-Ergänzungen werden
nur im eigenen Branch geführt, bisherige Einträge bleiben erhalten.

## GETESTET

- **84** gezielte Domain-/bestehende Ablauf-/UI-Fälle bestanden, darunter **45**
  neue Klassenprüfungsfälle: alle zwölf Einzelklassen, elf Mönch-Mehrklassenfälle,
  Aliase, unbekannte/verschleierte Namen, Doppelklasse, unverändertes Hero-JSON.
- **Neun** neue Integrations-/SQLite-Fälle bestanden: vier ungültige Kombinationen,
  manipulierter versionierter Wurf/Entscheidung, alte offene Probe, gültige Mönch-
  und Kämpfer-Mehrklassenfälle, Neustart, Retry/stale Revision. Bei Ablehnung
  bleiben alle sechs rohen SQLite-Tabellen exakt unverändert und RNG unberührt.
- Die bestehenden Todesrettungs-Widgettests bei 320/360 dp bleiben grün.
- Der erste neue Flow-Testlauf hatte sieben Fixturefehler (Listeninitialisierung
  und JSON-Schlüsselreihenfolge), zwei Fälle bestanden. Fixtures korrigiert;
  rohe Datenbankvergleiche erhalten, anschließende neun Fälle grün. Kein Test deaktiviert.

Vollständige lokale Prüfkette `bash scripts/check.sh` auf dem eingefrorenen
Quellcode bestanden: **2.504 Flutter-, 221 Python-, 72 Backend-Tests**,
537 Dart-Dateien unverändert formatiert, Analyzer ohne Befund, Backend-Typprüfung,
Build und Protokollsmoke erfolgreich. Der lokale **ARM64-Debug-Build und zwölf native App-Tests** sind ebenfalls
erfolgreich; APK-ABI, Version98 und v2-Testsignatur geprüft. Der normale Debug-
Build und drei optimierte ABIs werden durch die GitHub-CI getrennt geprüft.
[PR #416](https://github.com/ManuEtt/Dnd/pull/416) · [maßgebliche CI-Ergebnisse des aktuellen Kopfs](https://github.com/ManuEtt/Dnd/pull/416/checks).
Die lokalen Ergebnisse sind kein Ersatz für diesen aktuellen CI-Nachweis;
Status, tatsächliche Lauf-IDs und Artefakte werden im PR geführt.
Frühere Main-CI40922492508 ist Basisnachweis, keine Abnahme des neuen Pakets.

## NICHT GETESTET / BLOCKIERT / NOCH NICHT IMPLEMENTIERT

Echtes Android-Gerät/TalkBack, installiertes Altversionsupgrade und produktive
Signierung fehlen. Kein Regel-/GitHub-Zugriffsblocker. Vollständiges SRD sowie alle
externen Rettungswurfmodifikatoren bleiben offen. Unbekannte manuelle Klassen
werden weiterhin gespeichert, erteilen aber keine bestätigte neue SRD-Todesrettung.
`RULE-CORE-RULES-DEATH-SAVING-THROWS` bleibt **partial**; keine Gesamtvollständigkeit.

## Regelquelle

Amtliches [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf),
CC BY 4.0, gedruckte S.17–18 (Death Saving Throws), **48** (Fighter9/Indomitable),
**52** (Monk14/Disciplined Survivor). Level-/Übungsboni nur aus bestätigter eigener
Klasse; keine Klasse aus KI-Text erfinden. Lizenzhinweise unverändert.

## Dateien / Wiederaufnahme

Laufzeit: `app/lib/domain/death_saving_throw_rules.dart`,
`app/lib/domain/game_engine.dart`. Neue Tests:
`app/test/death_save_class_validation_test.dart` und
`app/test/death_save_class_validation_flow_test.dart`. SRD-Register um Beleg
ergänzt, keine neue Anforderungszählung. Fachnachweis und Tests vor Änderungen lesen.
Vor Integration Main/PRs/CI erneut prüfen; Kombination anderer PRs separat abnehmen.

Genau nächster unabhängiger Schritt: **Kurze Rast ohne Trefferwürfelverbrauch**
prüfen und umsetzen. Amtliches SRD: Würfelverbrauch ist optional. Akzeptanz:
Ressourcen-/Paktregeneration auch bei leerem HD-Pool, keine Heilungs-/Würfelannahme,
explizite Bestätigung, kein RNG bei null Würfeln, Alt-JSON/SQLite/Retry und deutsche
Ablaufanzeige. Zuerst offene PRs und gemeinsame Engine-/Resultverträge abstimmen.
Keine automatische Arbeit nach Sitzungsende.

---

## Historische Einträge (jeweiliger damaliger Stand)

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

## GitHub und Sicherungen

Eigener [PR #416](https://github.com/ManuEtt/Dnd/pull/416); [aktuelle Checks](https://github.com/ManuEtt/Dnd/pull/416/checks).
Source-Commit `ee1e5a19e03b5db60fad838d0da36d1f360b84bc`; abschließende
Dokumentationscommits ändern die Laufzeit-/Testdateien nicht. CI-Läufe auf
überholten Köpfen gelten nicht als Freigabe. Chat D übernimmt die Integration;
keine fremden Branches werden geschlossen oder gelöscht.

Vollprojekt-ZIP und binärfähiger Patch außerhalb des Projekts unter
`/workspace/artifacts/chat-a-death-save-class-validation-20261030/`; Frühstand
`frueh/`, Endstand `abschluss/`, tatsächliche Prüfnachweise `pruefnachweise/`.
Patchbasis ausdrücklich Main `55fe44475a113943c6310ec16a8ffb481185f4e9`.
Nicht auf bereits integriertem Main erneut anwenden. Download- und Importdetails
im zugehörigen PR und lokalen `ARTEFAKTE_UND_IMPORT.md`; keine privaten Spielstände
oder Schlüssel in die Quellpakete aufnehmen.

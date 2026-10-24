## Aktiver Integrationsabschluss – 24.10.2026

Während der abschließenden CI wurde PR #145 nach main1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd übernommen. Dokumentationskonflikte werden unter Erhalt beider Historien aufgelöst; XP-Code und beide Tests unverändert integriert. Keine neue Regelphase begonnen. Die bisher unten belegte grüne CI40057898163 auf bfc991f prüft den Vorintegrationsstand. Die neue Kombination muss erneut vollständig geprüft und als eigenes ZIP/Patch gesichert werden. APKs des alten Standes bleiben erhalten und gelten nicht automatisch für diesen neuen Source-Stand.

Nächste notwendige Aktion: Integration committen, Format/Analyse/Flutter/Backend/Python und Android aus neuem Quell-ZIP abnehmen, PR147 aktualisieren. Alte geprüfte Artefakte liegen unverändert in /workspace/artifacts, vollständige ZIPs+Patches vorhanden. Neue Binaries unter /workspace/artifacts/0.8.37+87_main_1c2ee erzeugen; keine alten Dateien überschreiben.

---

# CODEX-CHECKPOINT – Würfelraunen

Stand **2026-10-24T03:20:14+00:00**, aktive Sitzung. Vollständige vorige Übergabe: [Historie](history/main_0.8.36_20261023/CODEX_CHECKPOINT.md). Vor Wiederaufnahme tatsächliches main, PRs und CI erneut abfragen.

## Git und Produkt

- Basis-main: `5958579e5321338bb7b4e46abb859fd3bfd1515f` (PR143 integriert).
- Arbeitsbranch: `feature/sneak-attack-ally-integration-20261023`.
- Formatnormalisierung: `309b07e`; funktionaler Code: `0a56aba7057dc12d80750759443f6d70ed510dc1`.
- Version: **0.8.37+87**, Android-Alpha. Auf GitHub gesichert; [PR147](https://github.com/ManuEtt/Dnd/pull/147) offen und konfliktfrei gegen Basis5958579. Veröffentlichter Dokumentationsstand vor Abschluss:182f44bee57a0b7531396fd2893cd7f077256179.
- Offener Fremd-PR bei Bestandsaufnahme: [144 / Sending](https://github.com/ManuEtt/Dnd/pull/144), nicht dupliziert.
- Vollständige Code-CI: [40056875863](https://github.com/ManuEtt/Dnd/actions/runs/40056875863), **completed/success** auf PR-HEAD `182f44bee57a0b7531396fd2893cd7f077256179`; geprüfter Merge-Teststand `de67cd3d0899c8aec351e3fcc77905179450080f`. Alle Projekt-/Backend-/Flutter-/Android-/Alpha-/Artefaktschritte erfolgreich. Der nachfolgende reine Dokumentationscommit enthält denselben ausführbaren Code. Aktuellen PR-HEAD und neueste Checks bei Wiederaufnahme erneut lesen.
- Letzter vollständig erfolgreicher Basisworkflow: [40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485), geprüftes SHA5958579. Kein Nachweis für neuen Code.

## IMPLEMENTIERT

Hinterhältiger Angriff mit manuell bestätigtem Verbündeten für einen offenen Hauptwaffenangriff. Beide Fakten (5Fuß zum Ziel, nicht Incapacitated) werden separat erfasst und an Kampagne/Ziel/Wurf gebunden. Vorbereitung würfelt nicht und verbraucht keine Ressourcen; erst der gültige Treffer erzeugt Zusatzwürfel und Nutzung. Entfernen, Krit, Miss und neue Probe sind angebunden. Keine aus KI-Text erfundenen Werte. Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt partial.

Import und Ausführung prüfen dieselbe Bindung, eigene Zugberechtigung, Finesse/Fernkampf und Nutzung. Gespeicherter Angriffsbonus kommt aus RulesEngine einschließlich Bogenschießen. Story darf pendingRoll nicht verändern. SQLite 2 und Kampagnen-JSON 1 bleiben erhalten; optionales PendingRoll.sneakAttackAlly hat nestedVersion1, Alt-JSON bleibt gültig.

Dateien: neue Domain `app/lib/domain/sneak_attack_ally_rules.dart`, Models, GameEngine, Controller, rules_api, Abenteuer-UI, neuer Dialog und zwei neue Testdateien; App-Version, CI-Formatgate, Requirement-Register und Statusdokumentation. Backend, Outbox und Berechtigungen unverändert.

## GETESTET

- Normalisierte Basis: scripts/check.sh vollständig erfolgreich; **1.431 Flutter-Tests**, **100 Python-Tests**, Backend-Typecheck/Build/**31 Tests**, Analyse und Formatierung.
- Android: Debug-APK erfolgreich aus dem geprüften ZIP gebaut; CRC, aapt-Metadaten/minSdk24/targetSdk36/Build 87, drei ABIs und apksigner-Signatur erfolgreich. **12 native JUnit-Tests** ohne Fehler, Gradle BUILD SUCCESSFUL. 461 Dateien zwischen ZIP, Buildkopie und Arbeitsstand per SHA256 identisch.
- ARM64-Alpha: 19.728.422 Bytes, Build 87 ohne ABI-Offset, CRC/Metadaten/Signatur erfolgreich.
- Neuer Code gezielt: **11 Domain-/SQLite-Tests** und **6 Widgettests** erfolgreich. Abgedeckt: vor Zufall validieren, Treffer/Miss/Krit, 1x-pro-Zug, Datenmanipulation, verbrauchte/fremde Ziele, Storygrenze, Neustart, Export/Import, Rekonstruktion, stale Dialog, verspäteter Eventfehler/Rollback, Abbruch, Eingabeentwurf, 360dp/Schrift1,8/Tastatur260dp.
- Neuer vollständiger Lauf erfolgreich: **1.448 Flutter-Tests**, Format 344-Dateien/Analyse ohne Befunde, Backend 31 und Python 100 erfolgreich.
- Prüfprotokolle: `/workspace/validation/20261023-sneak-full-check.log`, `20261023-sneak-domain.log`, `20261023-sneak-ally-ui-final.log`.

## NICHT GETESTET

Reales Gerät und sicherer App-Updatepfad nicht getestet. Die dokumentierte Code-CI ist vollständig grün; nachfolgende Dokumentationsstände sind getrennt zu identifizieren. Keine fremde grüne CI als neue Freigabe ausgeben.

## BLOCKIERT

Kein erreichbares Android-Realgerät und keine produktive Release-Signierung. Flutter3.35.7/Dart3.9.2, Node22.14, Java17 und Android-SDK sind lokal verfügbar; fehlende SDKs aus älteren Übergaben gelten hier nicht.

## NOCH NICHT IMPLEMENTIERT

Allgemeine Verbündeten-/Positionsverwaltung, bestätigter Nebenhandkontext und allgemeine Gelegenheitsangriffe; vollständiges SRD. Keine globale Abdeckungsquote (1.419 Prüfaufträge, neun Inventurlücken). Frühere Item-Arbeit separat in `/workspace/Dnd-current` und `/workspace/artifacts` gesichert; sie basiert auf b965efc und muss vor Übernahme mit neuerem main abgeglichen werden. Dort letzter Gesamtversuch: zwei überholte Python-Quellstring-Vertragstests fehlgeschlagen; kein neuer Android-Build behauptet.

## Noch laufender Abschluss / Artefakte

Gesamtlauf, Debug-APK und native Tests erfolgreich. Lokale Prüfungen und vollständige GitHub-Code-CI erfolgreich. Branch/PR147 sind erstellt. Abschließender Dokumentationsnachtrag, aktualisiertes Quell-ZIP/Patch und tatsächliche finale PR-Checks sind getrennt vom bereits geprüften Code zu sichern. Main nicht ungeprüft verändern. ZIP/Patch entstehen mit scripts/create_checkpoint.py gegen Basis5958579. Tatsächlich geprüftes Build-Quell-ZIP: `/workspace/artifacts/Wuerfelraunen_0.8.37+87_20261023T194739479771Z_sneak-attack-vor-android_Vollprojekt.zip`, SHA256 `3df17f778c328594ec093b3c9aebdceccd62d7f41ae00a7edb5a991f658fc832` (617 Dateien). Finales ZIP wird mit aktueller Dokumentation erneuert; Hash steht separat in SHA256SUMS.txt.

ARM64-Alpha: `/workspace/artifacts/Wuerfelraunen_0.8.37+87_arm64-v8a_Alpha.apk`, SHA256 `7347f06e25ce2fcf02f06c6d25ceef6f41c114dd3bc916dbf4118c5ed89d7f03`, Metadaten `Wuerfelraunen_0.8.37+87_ARM64_Alpha_Pruefung.json`. Releaseoptimierung mit derselben lokalen Debug-Testsignatur, keine Gerätefreigabe.

Debug-APK: `/workspace/artifacts/Wuerfelraunen_0.8.37+87_Debug.apk`, 144077056 Bytes, SHA256 `3d3ac043c4f9cbc2342fda8524cd6a0bccbdb0cc0e35eba3fc2ab8f642307fb7`. Metadaten: `Wuerfelraunen_0.8.37+87_APK_Pruefung.json`; Gesamtprotokoll: `Wuerfelraunen_0.8.37+87_Pruefergebnisse.json`. Workspace-Dateien sind keine behaupteten externen Uploads. Beobachtete GitHub-Artefakte aus grünem Lauf40056875863 (nicht abgelaufen):

- [Quell-ZIP](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546510086), GitHub-Archiv-Digest `eea30931ca5b8197a73fb6b57e039e74bf2914f3cf538f4b887bde18ccab499c`.
- [Drei Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546286030), GitHub-Archiv-Digest `32b497ac50103416f8a115bad20ac1bb5616ee84bc152481e87e9b31b3983d69`.
- [Versioniertes Alpha-Release-Paket](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546311528).
- [PR-Gesamtpatch](https://github.com/ManuEtt/Dnd/pull/147.diff); lokale versionierte ZIP/Patch/SHA256-Paare in /workspace/artifacts.

GitHub-Artefakte haben begrenzte Aufbewahrung und eigene Build-/Signaturherkunft. Ihre Digests gehören zum GitHub-Archiv, nicht zu den separat lokal gebauten Dateien. Import: [ARTIFACT_IMPORT_20261024.md](ARTIFACT_IMPORT_20261024.md).

## Genau ein nächster fachlicher Schritt

**Nebenhand-Sneak-Attack am tatsächlich angreifenden Inventargegenstand prüfen und bestätigen.** Akzeptanz: Finesse/Fernkampf der wirklichen Waffe, einmal pro Zug, fehlende Fakten ablehnen, separate Haupt-/Nebenhand, Krit und Miss, JSON/SQLite-Neustart, alte Hauptwaffenprobe unverändert. Gelegenheitsangriffe bleiben eigener Scope.

Prüfung: `bash scripts/check.sh`; `python3 scripts/check_domain_boundaries.py`; `python3 scripts/srd_coverage.py --json`; `cd app && flutter build apk --debug`; `cd android && bash ./gradlew :app:testDebugUnitTest --no-daemon`. SDK-/SQLite-Pfade dieser Umgebung: `/workspace/validation/TOOLCHAIN.md`.

Keine automatische Wiederaufnahme außerhalb einer tatsächlich laufenden Sitzung.


## Übernommener Status aus Main145 (historisch)

## Zyklus 2026-10-23 (Europe/Berlin) – Widersprüchliche XP-Belohnungs-ID ablehnen (PR-/CI-Prüfung)

- **LIVE-BASIS:** `main` `5958579e5321338bb7b4e46abb859fd3bfd1515f`, GitHub Actions [#40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485) **completed / success** ausschließlich auf diesem Main-SHA. Bei Beginn war [PR #144](https://github.com/ManuEtt/Dnd/pull/144) zum Zauber `Sending` offen; dessen [CI #40012034969](https://github.com/ManuEtt/Dnd/actions/runs/40012034969) erfolgreich für einen **anderen** Code-HEAD. Arbeitsbranch `fix/xp-reward-id-conflict-20261023`, Ausgangsversion `0.8.36+86`; kein paralleler Versionssprung wegen offenem PR #144.
- **IMPLEMENTIERT:** `ExperienceProgression.grant` bestätigt eine wiederholte ID nur noch bei **exakt gleichem** bereits gespeicherten XP-Betrag; abweichende oder unlesbare Bestandswerte führen zu `FormatException` ohne Zustandsänderung. Bekannte identische Bestätigungen bleiben idempotent. **Kein geänderter SRD-Mechanismus:** Es handelt sich um Konsistenzprüfung der lokalen Belohnungsbelege.
- **TESTS GESCHRIEBEN:** `app/test/experience_progression_test.dart` – bestätigte Duplikate nach JSON-Roundtrip, ID-Kollision mit abweichendem Betrag und manipulierter Legacy-Beleg ohne Veränderung von Held/XP/Fakten. Die lokale Ausführungsumgebung hat **kein Dart-/Flutter-SDK**; Tests werden erst nach tatsächlichem erfolgreichem CI-Lauf als bestanden bezeichnet.
- **KOMPATIBILITÄT:** SQLite-Schema 2 und Kampagnen-JSON `schemaVersion=1` unverändert, kein KI-Provider, keine Migration. Widersprüchliche Altdaten werden nicht automatisch überschrieben.
- **GETESTET:** Main-CI #40012217485 nur als Vorher-Baseline. **NICHT GETESTET:** Neue Branch-CI und Android-Gerät bis eindeutige Ergebnisse vorliegen. **BLOCKIERT:** Lokale Flutter-/Android-/Geräteprüfungen mangels SDK/Gerät. **NOCH NICHT IMPLEMENTIERT:** Vollständige SRD-5.2.1-Regelabdeckung sowie Validierung externer Erzählungs-/Belohnungsquellen.
- **NÄCHSTER KONKRETER SCHRITT:** Den PR-Workflow auf dem **finalen** Branch-SHA auswerten und Fehler beheben; anschließend separat eine bestätigte, revidierbare XP-Belohnungsaktion von GameEngine/GameController bis SQLite-Journal auf Doppel-IDs und Neustart prüfen. Keine automatische Integration in `main` ohne PR-Abnahme.

---

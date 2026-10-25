# CODEX-CHECKPOINT – Würfelraunen

Stand **2026-10-24T12:08:54+00:00**. Abgeschlossenes Paket: Hinterhältiger Angriff mit bestätigtem Verbündeten, einschließlich Integration des Main-XP-Fixes aus PR #145. Vor einer neuen Sitzung tatsächliche Branches, PRs und CI erneut prüfen.

## Git, Produkt und Nachweise

- Version **0.8.37+87**; Branch `feature/sneak-attack-ally-integration-20261023`.
- Aktuelle integrierte Main-Basis: `1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd`. Ursprüngliche Basis 5958579; reine Formatnormalisierung309b07e; Funktionscommit0a56aba; integrierter und vollständig geprüfter Code **`a6a949cbc00d3b6abd6a6281cbc4d1ed8a8d6244`**.
- [PR #147](https://github.com/ManuEtt/Dnd/pull/147) ist offen und nach der Main-Integration konfliktfrei. Main wurde von dieser Sitzung nicht direkt verändert. Zuletzt beobachtete andere offene PRs: #144 Sending und #149 Rabenwacht/XP; nicht übernommen oder dupliziert.
- Vollständige [GitHub-CI #40059091439](https://github.com/ManuEtt/Dnd/actions/runs/40059091439): **completed / success** auf PR-HEAD `a6a949cbc00d3b6abd6a6281cbc4d1ed8a8d6244`, Merge-Teststand `30fb8f22ab4777e762df9cada9fcb4c09993a33a`. Projekt-, Python-, Backend-, Flutter-, native Android-, Debug-/Alpha-Build- und Artefaktschritte erfolgreich.
- Nachfolgende Abschlussänderungen betreffen ausschließlich Dokumentation. Deren HEAD mit `git rev-parse HEAD` ermitteln und die neuesten PR-Checks separat prüfen; die obige Freigabe bezeichnet ausdrücklich den ausführbaren Code, keine künftig ungeprüfte Änderung.

## IMPLEMENTIERT

Für eine offene Hauptwaffenprobe kann ein Schurke einen Verbündeten benennen und zwei Fakten getrennt bestätigen: höchstens 5 Fuß vom Ziel entfernt und nicht `Incapacitated`. Der typisierte Kontext ist an Kampagne, Ziel und Wurf gebunden und vor dem Würfeln entfernbar. Vorbereitung verbraucht weder Zufall noch Ressourcen. Ein zulässiger Treffer löst Zusatzschaden aus, Krit verdoppelt die Würfel; die vorhandene Begrenzung pro eigenem Zug bleibt erhalten.

Import und Ausführung prüfen Waffenart, Zug, Ziel, Nutzung und Kontext. Gespeicherte Angriffsboni verwenden dieselbe Berechnung wie die Auflösung, einschließlich Mehrklassen-Bogenschießen. Der deutsche Dialog erhält freie Eingabeentwürfe; Controller und SQLite sichern Revision, Snapshot und Event atomar. Story/KI dürfen den Kontext nicht bestätigen. SQLite 2 und Kampagnen-JSON 1 bleiben kompatibel; das neue optionale PendingRoll-Feld besitzt nestedVersion 1.

Main-PR 145 ist erhalten: Wiederholung einer XP-Beleg-ID quittiert nur exakt denselben Betrag. Widersprüchliche oder beschädigte Belege werden ohne Teiländerung abgewiesen. Beide Regressionstests wurden gemeinsam ausgeführt.

Betroffene Dateien: neue Domain `sneak_attack_ally_rules.dart`, Models/GameEngine/Controller/rules_api, Abenteuer-UI und neuer Dialog, zwei neue Testdateien, CI-Formatgate, Version und Anforderungs-/Statusdokumentation. Backend und Berechtigungen funktional unverändert. Regelquelle: SRD 5.2.1 Rogue/Sneak Attack S. 61–62, CC BY 4.0; Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt **partial**.

## GETESTET

- Vollständiges `scripts/check.sh` auf integriertem Code: **1.450 Flutter-, 100 Python-, 31 Backend-Tests**, Backend-Typecheck/Build, 344 Dart-Dateien ohne Formatänderung, Flutter-Analyse ohne Befund; Backend-Protokolltest eingeschlossen.
- Neue Funktionsfälle separat: 11 Domain-/SQLite-Tests und 6 Widgettests. Treffer/Miss/Krit, einmalige Nutzung, Validierung vor Zufall, fehlende/manipulierte Fakten, alte JSONs, Storygrenze, Export/Import, Neustart, Rekonstruktion, stale Dialog, verspäteter Eventfehler/Rollback, Abbruch und freie Eingaben; 360dp, Schrift1,8 und Tastatur260dp.
- Story-/Rules-Importprüfung erfolgreich. Coverage: 1.419 Prüfaufträge, 9 Inventurlücken; keine globale Fertigstellungsquote.
- Neue Debug-APK und ARM64-Alpha aus dem integrierten vollständigen ZIP gebaut; **12 native JUnit-Tests**, 0 Fehler. ZIP-CRC, Metadaten, ABI und apksigner erfolgreich. 461 ausführungsrelevante Quelldateien zwischen ZIP, Buildkopie und Branch per SHA256 identisch.
- Android: Version 0.8.37/Build 87, minSdk24/targetSdk36. Debug enthält ARM64/ARMv7/x64; Alpha nur ARM64, Build 87 ohne ABI-Offset. Beide tragen dieselbe lokale Debug-Testsignatur.
- Protokolle: `/workspace/validation/20261024-sneak-integrated-check.log`, `20261024-integrated-native-tests.log`, `20261024-integrated-android-build.log`, `20261024-integrated-alpha-build.log` und zugehörige JSON-Metadaten.

## NICHT GETESTET

Reales Android-Gerät, Installation/Update über einen älteren persönlichen Spielstand und produktive Release-Signierung. Lokale und GitHub-APKs sind getrennte Builds mit eigener Herkunft; deren Digests nicht vertauschen. Spätere Dokumentations-HEADs haben eigene PR-Checks.

## BLOCKIERT

Kein erreichbares Android-Realgerät und kein produktiver Signaturschlüssel. Lokale Flutter-/Dart-/Node-/Java-/Android-Werkzeuge stehen zur Verfügung; keine aktuelle SDK-Blockade. Keine bekannten Fehler in den ausgeführten Prüfungen.

## NOCH NICHT IMPLEMENTIERT

Allgemeine Verbündeten-/Positionsverwaltung, der bestätigte Nebenhandkontext, allgemeine Gelegenheitsangriffe und das vollständige SRD. Alte Item-Arbeit unter `/workspace/Dnd-current` und in separaten ZIPs erhalten; sie basiert auf b965efc und darf aktuelle Modelle nicht ersetzen. Dort historische zwei Python-Vertragsfehler nicht als heutige Fehler des integrierten Branches ausgeben.

## Artefakte und Wiederherstellung

Neue lokale Binaries unter `/workspace/artifacts/0.8.37+87_main_1c2ee/`; alte Vorintegrations-Binaries unverändert erhalten.

- Debug: `719107eeb2e1af3fc3717a35c6b41ec6a884f260226aa7981a20c538e02fce05`, 144077680 Bytes.
- ARM64-Alpha: `e317f5316ba72871fcfce45dd4c7c03eaac5169ab27d87a40f5d499b53104dc3`, 19728422 Bytes.
- Tatsächliches Build-Quell-ZIP: `Wuerfelraunen_0.8.37+87_20261024T033835608042Z_integration-main1c2ee-vor-abnahme_Vollprojekt.zip`; SHA256 **`82fafc82c9b16ed8dcd101fd5fe1fd366f8971573183aa7c500024187c3be973`**,619 Dateien, Code a6a949c.
- Abschließendes Vollprojekt-ZIP/Patch mit aktueller Dokumentation: `scripts/create_checkpoint.py --output-dir /workspace/artifacts --base 1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd --label sneak-main-integriert-abschluss`. Echte Namen/Hashes stehen im externen Dateimanifest, SHA256SUMS und Artefaktindex. Codegleichheit zum Build-ZIP vor Abschluss prüfen.
- Beobachtete GitHub-Downloads aus dem grünen integrierten Lauf: [Quell-ZIP](https://github.com/ManuEtt/Dnd/actions/runs/40059091439/artifacts/12547141868), [drei Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40059091439/artifacts/12546708433), [PR-Gesamtpatch](https://github.com/ManuEtt/Dnd/pull/147.diff). Actions-Aufbewahrung zeitlich begrenzt. Quellartefakt-Digest `sha256:bf5ae943719576548692eae9aafebebb7ce15c26635e110debeb92768ad0b647`; er bezeichnet das GitHub-Archiv, nicht das lokale ZIP.
- Importanleitung: [ARTIFACT_IMPORT_20261024.md](ARTIFACT_IMPORT_20261024.md). Patchbasis ist jetzt **1c2eeab**, nicht die frühere Basis 5958579.

## Genau ein nächster fachlicher Schritt

**Nebenhand-Sneak-Attack anhand der tatsächlich angreifenden Waffe prüfen und bestätigen.** Definition of Done: Finesse/Fernkampf der wirklichen Waffe, keine unbestätigten Fakten, gemeinsame einmalige Nutzung pro Zug, getrennte Haupt-/Nebenhand, Krit/Miss, JSON/SQLite-Neustart und unveränderter Alt-Hauptwaffenpfad. Allgemeine Gelegenheitsangriffe separat lassen.

Prüfen mit `bash scripts/check.sh`, `python3 scripts/check_domain_boundaries.py`, `python3 scripts/srd_coverage.py --json`, `cd app && flutter build apk --debug`, danach `cd android && bash ./gradlew :app:testDebugUnitTest --no-daemon`. Umgebungsdetails: `/workspace/validation/TOOLCHAIN.md`.

Historie: [vorheriger Main-Checkpoint](history/main_0.8.36_20261023/CODEX_CHECKPOINT.md), [Stand vor Integrationsabschluss](history/sneak_before_main_20261024/CODEX_CHECKPOINT.md). Keine automatische Wiederaufnahme außerhalb einer aktiven Sitzung.

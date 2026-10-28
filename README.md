# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Fantasy-Rollenspiel-App für Android: lokale Soloabenteuer,
Charakter- und Kampagnenverwaltung, ausgewählte Regeln des **D&D SRD 5.2.1** und
ein optionaler KI-Erzähler. **Alpha 0.8.46+96**; lokales Spielen benötigt keinen
Account oder KI-Server. Die vollständige Charaktererstellung und Regelengine
sind weiter in Entwicklung.

## Aktueller Stand und autonome Fortsetzung

Produktstand: Main `6576d2fc742f000bacdd1c105282bc9e3282ae7e` aus
[Integrations-PR #351](https://github.com/ManuEtt/Dnd/pull/351), 28.10.2026.
SQLite-Schema **3**, Kampagnen-/Charakter-JSON **1**, keine neue Datenmigration.

**Main-CI bestanden:** [Lauf 40708407065](https://github.com/ManuEtt/Dnd/actions/runs/40708407065) auf `6576d2fc742f000bacdd1c105282bc9e3282ae7e`.

**28 alte Quell-/Integrationsbranches archiviert und entfernt.** Alle Köpfe sind Vorfahren des geprüften Main; die exakten Archivtags stehen im Inventar. `feat/srd-warlock-magical-cunning-20261028` (Beobachtung `2026-10-28T14:59:26.197499+00:00`: `47cb207e99eeba0af3308de2b88c19f8357b0808`, PR #352) entstand danach und bleibt als aktive, separat zu prüfende Entwicklung erhalten.

**IMPLEMENTIERT:** Gemeinsame Integration der vorhandenen Charakter-, Klassen-,
Story-, Ausrüstungs-/Sprung- und Tooling-Pakete. Behoben sind der reproduzierte
Altarchiv-CAS-Fehler, der Barden-Dialogüberlauf und Integrationskonflikte zwischen
Barden- und Mönchsinitiative. Bestätigte Attribut-, Klassen-, Hintergrund- und Talentbelege
bleiben getrennt; Audit und Kataloge erteilen keine erfundenen Vorteile.

**GETESTET:** 2.185 Flutter-, 195 Python- und 72 Backend-Tests in der finalen
PR-CI; zusätzlich 20 gezielte UI-Prüfungen. Lokale Vollsuite, Formatierung von
500 Dart-Dateien, Analyzer, Backend-Build, Android-Debug-Build und zwölf native
Android-Tests bestanden. Genaue Commits und Main-Abnahme siehe Nachweistabelle.

**NICHT GETESTET:** Echtes Android-Gerät, TalkBack auf Gerät, Upgrade einer alten
installierten APK mit vorhandener Datenbank und produktive Signierung.

**BLOCKIERT:** Kein angeschlossenes Android-Testgerät. Die aktive parallele
Hexenmeister-Arbeit benötigt eine eigene fachliche und CI-Abnahme.

**NOCH NICHT IMPLEMENTIERT:** Vollständiger Charakter-Wizard mit allen Pflichtwahlen
und sämtliche SRD-Wirkungen. Magieinitiierter bestätigt bisher Zauberwahl und
Zauberattribut, nicht das vollständige Wirken. Wilder Angreifer besitzt dauerhafte
Würfelbelege und eine Entscheidungsvorprüfung, noch keinen durchgängigen
Angriffs-/Schadensabschluss. Entrinnen-Vorprüfung ist keine TP-Buchung.

## Funktionen und Grenzen

| Bereich | Im integrierten Stand vorhanden | Weiter offen |
| --- | --- | --- |
| Charaktere | Attributmethoden und Herkunft, vier Hintergrundpakete, explizite Klassenbelege, Start-TP und Paketwahl für zwölf Klassen, Magieinitiierter-Zauberwahl, sicherer Editor | Vollständiger Wizard, Spezies-/Talent-/Zauberpflichtwahlen, sämtliche Klassenmerkmale |
| Regeln | Bestätigte Einzelmechaniken für Kampf, Ressourcen, Zustände, Zauber, Klassenaufstieg und ausgewählte Klassenaktionen | Nicht alle SRD-Wirkungen, Monster, Ziele und Ausnahmen |
| Kampagne | Rabenwacht, freie Soloabenteuer, Journal, Quests, bestätigtes NPC-Gedächtnis, sitzungsgebundener Replay und dauerhafte Sendeaufträge | Keine universell autonome oder öffentliche Mehrspielerspielleitung |
| Speicherung | SQLite, atomare Ereignisse/Revisionen, Archiv-Schreibschutz, JSON-Import/-Export, Altspielstand-Kompatibilität | Keine Cloud-Synchronisierung oder lokale Datenbankverschlüsselung |
| Android | Fantasy-UI, anpassbare Schrift, Datei-Backup, geräteabhängige Sprachein-/ausgabe | Echte Geräte-/TalkBack-Abnahme, produktive Signatur und Store-Release |

Die maschinenlesbare SRD-Matrix führt **1.419 Prüfaufträge und neun offene
Inventurlücken**. Das ist kein vollständiger SRD-Nenner und kein
Fertigstellungsprozentsatz. [Abdeckungsnachweis](docs/SRD_5_2_1_COVERAGE_AUDIT.md) ·
[Charaktererstellung](docs/CHARACTER_CREATION_COMPLETE.md).

## Prüfungen und Downloads

| Nachweis | Tatsächlicher Stand |
| --- | --- |
| Finale PR-CI | [40706203860](https://github.com/ManuEtt/Dnd/actions/runs/40706203860), Kopf `c06b549`, Checkout `9cf5ead`; erfolgreich mit 2.185 Flutter / 195 Python / 72 Backend und 20 gezielten UI-Prüfungen |
| Main-CI | [40708407065](https://github.com/ManuEtt/Dnd/actions/runs/40708407065) auf `6576d2f`: erfolgreich |
| Lokal | `4f03b788`: vollständige Suite, Debug-APK, zwölf native Tests; Format und Analyse erfolgreich |
| Produkt-/CI-Baum | Main `6576d2f`, PR-Kopf `c06b549` und PR-Checkout `9cf5ead` besitzen denselben Git-Baum `ec6bd620` |

- [Main-Quellcheckpoint: Vollprojekt-ZIP, Binärpatch, Manifest und History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40708407065/artifacts/12826680612)
- [Main-Android-ARM64-Alpha (Debug-Testsignatur)](https://github.com/ManuEtt/Dnd/actions/runs/40708407065/artifacts/12826535931)

Vollprojekt-ZIP, tatsächlich anwendbarer Binärpatch, Dateimanifest, SHA256 und
wiederherstellbares Git-Bundle gehören zum Quell-Checkpoint. APKs tragen die
Debug-Testsignatur; ein erfolgreicher Build belegt keinen Gerätetest.
Migrationsnachweise: [Bericht](docs/BRANCH_MIGRATION_20261028.md) ·
[Branch-/Archivinventar](docs/BRANCH_MIGRATION_20261028_INVENTORY.json).

## Nächster konkreter Entwicklungsschritt

Die drei vorhandenen SRD-Katalogvarianten des Heiligen Symbols im bestehenden
Klassenassistenten für **Kleriker und Paladin** ausdrücklich auswählen lassen.
Auswahl in UI, typisiertem Inventar und Klassenbeleg speichern und über
SQLite-Neustart sowie JSON-Export/-Import nachweisen. Bestehende
`startingClassChoice`-Datensätze der Version 1 ohne diese Auswahl müssen lesbar
bleiben und historisch ungeklärt ausgewiesen werden; neue Pflichtwahlen dürfen
nicht nachträglich denselben Importvertrag verschärfen. Keine automatische
Ergänzung historischer Ausrüstung und keine erneute Gold- oder Paketvergabe.
Abbruch, Wiederholung, manipulierte Katalog-ID, alte Belege und 320/360 dp bei
200 % Schrift testen. Vor Beginn Main und offene PRs prüfen; den aktiven
Hexenmeister-Branch weder überschreiben noch löschen.

## Lokal starten und prüfen

Vorgesehene Toolchain: Flutter **3.35.7**, Dart **3.9.2**, Java **17**, Node.js **22.14.0**.

```bash
python3 scripts/generate_fantasy_buttons.py
cd app
flutter pub get
flutter run
```

Für die vorhandene gemeinsame Prüfkette sowie Android:

```bash
bash scripts/check.sh
(cd app && flutter build apk --debug)
(cd app/android && bash gradlew testDebugUnitTest)
```

`scripts/check.sh` führt Projekt-/Importgrenzen-/SRD- und Pythonprüfungen,
Backend-Typprüfung/Tests/Build, Dart-Formatierung, Analyse und Fluttertests mit
lokalem Backend-Protokolltest aus. SQLite-Tests benötigen die native SQLite-Bibliothek.
Ein optionaler eigener HTTPS-Erzähler wird in [BACKEND_CONNECTION.md](docs/BACKEND_CONNECTION.md)
beschrieben; externe KI-Nutzung erfordert eine ausdrückliche Sitzungseinrichtung.

## Architektur, Regeln und Historie

`app/lib/domain/` enthält Regeln und Modelle, `story/` Kampagnen und Gedächtnis,
`data/` SQLite, `services/` die bestätigende Steuerung und `ui/` Flutter.
`backend/` ist der optionale Fastify-/TypeScript-Erzähler. Die lokale Regelengine
bestätigt mechanische Änderungen; KI-Texte dürfen keine Charakterwerte,
Würfelergebnisse oder Gegenstände erfinden und übernehmen.

Quelle: [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0;
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) erhält die Namensnennung.
Nur lizenzierte Inhalte und eigene Texte verwenden.

[Operativer Checkpoint](docs/CODEX_CHECKPOINT.md) · [Entwicklungsstatus](DEVELOPMENT_STATUS.md) ·
[Architektur](ARCHITECTURE.md) · [Tests](TESTING.md) · [Änderungen](CHANGELOG.md).
Ältere widersprüchliche Momentaufnahmen sind bytegenau unter
[docs/history/migration_abschluss_20261028/](docs/history/migration_abschluss_20261028/MANIFEST.json)
mit SHA256- und Git-Blob-Nachweisen archiviert.

## Verifizierte Main-Artefakte und Bereinigung

Der tatsächlich heruntergeladene Main-Quellcheckpoint enthält **1.228 Dateien**;
alle SHA256-Werte und Dateimodi stimmen mit dem Manifest und dem Alpha-Quellpaket
überein. Der Binärpatch wurde tatsächlich gegen
`f9d68a97f35799e50881e9c6992efaed807e6301` angewendet und das Ergebnis vollständig verglichen.
Das History-Bundle wurde isoliert wiederhergestellt; `git fsck --full --strict`
und die Ancestry-Prüfung von **30 Ursprungs-/Integrations-/Main-Köpfen** sind erfolgreich.

| Datei | SHA256 |
| --- | --- |
| Main-Vollprojekt-ZIP | `912ca182f3bb24d77e599881288ca79ad5130bbe20682baa7b175a29f5b13196` |
| Main-Binärpatch | `5b83bb0d8f20d443bba56ae496f7530d966a80431b78d3a9bf46a95b37ca9099` |
| ARM64-Alpha-APK | `3f77e31663a154df9b5ff6e0549b7f4b050316101d44e93654c17457637c7c44` |

Die APK enthält ausschließlich `arm64-v8a`; die v2-Signatur mit Debug-Testschlüssel
ist geprüft. Dies ist keine produktive Signierung und kein realer Gerätetest.
[Cleanup-Lauf 40710914533](https://github.com/ManuEtt/Dnd/actions/runs/40710914533)
ist erfolgreich. Der Abschlussbeleg von `2026-10-28T14:59:26.197499+00:00` bestätigt
alle 28 alten Branches: Remote-Ref fehlt, Archivtag zeigt exakt auf den ursprünglichen
Kopf, Kopf ist Vorfahr des geprüften Main. Main und der neue aktive Hexenmeister-Branch
blieben erhalten. Dessen separat beobachteter Kopf ist `47cb207e99eeba0af3308de2b88c19f8357b0808`
([PR #352](https://github.com/ManuEtt/Dnd/pull/352)); vor weiterer Arbeit erneut live prüfen.

Dieser anschließende Dokumentationsabschluss hat die Projekt-/Importgrenzenprüfung,
195 Python-Tests und die unveränderte 1.419-/9-SRD-Inventur bestanden. Alle getrackten
Dateien unter `app/`, `backend/`, `scripts/` und `.github/` sind bytegleich mit
`6576d2fc742f000bacdd1c105282bc9e3282ae7e`. Es wurde keine neue APK für den Dokumentations-Commit erzeugt und keine
zusätzliche Produkt-CI daraus behauptet.

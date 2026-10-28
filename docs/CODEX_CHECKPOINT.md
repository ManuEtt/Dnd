# Codex-Checkpoint – Branch-Migration und Abnahme

Stand: 2026-10-28T15:01:43.081541+00:00 (UTC).
Würfelraunen **0.8.46+96**, SQLite **3**, JSON **1**.
Produkt-Main `6576d2fc742f000bacdd1c105282bc9e3282ae7e`; Dokumentationsbranch
`docs/migration-abnahme-20261028` auf diesem Main. Dieser Abschluss verändert
keine App-, Backend-, Skript- oder Workflowdateien und erhöht keine Version.

**Main-CI bestanden:** [Lauf 40708407065](https://github.com/ManuEtt/Dnd/actions/runs/40708407065) auf `6576d2fc742f000bacdd1c105282bc9e3282ae7e`.

**28 alte Quell-/Integrationsbranches archiviert und entfernt.** Alle Köpfe sind Vorfahren des geprüften Main; die exakten Archivtags stehen im Inventar. `feat/srd-warlock-magical-cunning-20261028` (Beobachtung `2026-10-28T14:59:26.197499+00:00`: `47cb207e99eeba0af3308de2b88c19f8357b0808`, PR #352) entstand danach und bleibt als aktive, separat zu prüfende Entwicklung erhalten.

## Tatsächlicher Entwicklungsstand

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

## Exakte Abnahme und Herkunft

- [PR #351](https://github.com/ManuEtt/Dnd/pull/351) integriert die alten
  Entwicklungspakete regulär. PR-Kopf `c06b5495b18260b170732e985e7786f0d4afebf0`;
  tatsächlich geprüfter PR-Checkout `9cf5eadf708b3198295ebddd6d62cd4b8747fdce`.
- [Finale PR-CI 40706203860](https://github.com/ManuEtt/Dnd/actions/runs/40706203860) vollständig erfolgreich:
  2.185 Flutter / 195 Python / 72 Backend, zusätzlich 20 gezielte UI-Prüfungen;
  Android-Debug/native-/ABI-/Alpha-/Quellcheckpoint-Schritte bestanden.
- Main `6576d2fc742f000bacdd1c105282bc9e3282ae7e` besitzt denselben vollständigen Git-Baum
  `ec6bd6207681a59b55599a3f2ef8f7ae51487af4`. [Main-CI 40708407065](https://github.com/ManuEtt/Dnd/actions/runs/40708407065):
  vollständig erfolgreich.
- Lokaler fester Quellstand `4f03b7880c36ca225325c87ec9f2c56e0a93dccd`:
  2.185 Flutter / 195 Python / 72 Backend, zwölf native Tests, 500 Dart-Dateien
  unverändert formatiert, Analyzer/Backend-/Android-Debug-Build erfolgreich.
- Der frühe Vollversuch `300f7be` wurde mit 143 bewusst abgebrochen, um den
  reproduzierten Legacy-CAS-Defekt zu beheben. Er ist kein vollständiger Erfolg.
  Doppelte Push-/Archivläufe wurden bewusst beendet; die genannten erfolgreichen
  PR-/Main-Abnahmen sind die maßgeblichen Belege.
- Abschlussdokumentation benötigt Pythonprüfungen und einen Vergleich der
  unveränderten Produktpfade gegen Main. Sie erzeugt keine neue APK und wird
  nicht durch einen älteren Quellstand als separat gebaut ausgegeben.

## Sichere Migration und Daten

26 ursprüngliche Nebenbranches plus der parallele Import-/Button-Integrationsbranch
und der Gesamtintegrationsbranch bilden die 28 alten Quell-/Integrationsbranches.
Main wird nie gelöscht. Vollständige Historie und Originaldokumente bleiben erhalten;
Archivtags und exakte Köpfe stehen im [Inventar](BRANCH_MIGRATION_20261028_INVENTORY.json).
Das Ausgangs-Bundle wurde unabhängig in ein leeres Bare-Repository importiert:
27/27 Ursprungsrefs stimmen, 15.861 Objekte, `git fsck --full --strict` erfolgreich.
Neue, weitergeschriebene, aktive, geschützte oder nicht integrierte Branches bleiben
von der Bereinigung ausgeschlossen. Die aktive Hexenmeister-Arbeit ist kein
geprüfter Bestandteil dieses Produktstands.

Altspielstände werden beim Lesen nicht geschrieben oder neu berechnet. Der
Archiv-CAS-Vergleich normalisiert beide Seiten innerhalb derselben Transaktion,
damit alte Kataloggegenstände ohne `stats` bearbeitbar bleiben; echte konkurrierende
Änderungen werden weiterhin abgewiesen. Keine neue Migration. KI-/Story-Grenzen,
Revisionen, Ereignisse und bestätigte Herkunftsbelege bleiben erhalten.

Die SRD-Register zählen weiterhin 1.419 Prüfaufträge / neun Inventurlücken. Keine
neue globale Vollständigkeitsquote. Ausschließlich SRD 5.2.1 / CC BY 4.0 und eigene
Inhalte; keine externen KI-Kosten oder Geheimnisse in diesem Durchlauf.

## Artefakte und Wiederherstellung

- [Main-Quellcheckpoint: Vollprojekt-ZIP, Binärpatch, Manifest und History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40708407065/artifacts/12826680612)
- [Main-Android-ARM64-Alpha (Debug-Testsignatur)](https://github.com/ManuEtt/Dnd/actions/runs/40708407065/artifacts/12826535931)

Lokale geprüfte Nachweise liegen unter
`/workspace/artifacts/branch-migration-20261028/`; der Artefaktindex
`ARTEFAKTE_0.8.46+96.md` nennt ZIP-/Patch-/APK-/Bundle-Hashes und Herkunft.
Für Wiederherstellung zuerst die SHA256 prüfen. Eine vollständige ZIP in einen
leeren Ordner entpacken; den Binärpatch auf dessen ausdrücklich genannte Basis
anwenden, nie blind auf einen abweichenden Main. Git-Bundle in ein separates
Repository importieren und den dokumentierten Commit auschecken. Vor einem neuen
GitHub-PR App-/Projektprüfungen ausführen. Benutzer-Spielstände sind nicht Teil der
öffentlichen Quellarchive.

## Genau nächster Implementierungsschritt

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

Vor Änderungen `AGENTS.md`, diesen Checkpoint, Main, offene PRs und letzte CI lesen.
Eigener Branch; Regelquelle SRD 5.2.1 prüfen. Vorhandene
`StartingEquipmentImport`, `StartingClassChoice` und Klassenassistenten erweitern,
keine parallele Ausrüstungsengine. Minimale Abnahme: Domain-, Widget- und
SQLite-/JSON-Regressionen plus `bash scripts/check.sh`, Android-Debug/native und
finale PR-CI. Kein automatisches Weiterarbeiten nach Ende der aktiven Sitzung.

## Historie

Dieser kompakte Checkpoint ersetzt alte widersprüchliche Live-Angaben. Seine
vollständige Vorgängerfassung und die sechs weiteren konsolidierten Dokumente
liegen bytegenau in
[history/migration_abschluss_20261028/MANIFEST.json](history/migration_abschluss_20261028/MANIFEST.json),
mit Quellcommit, SHA256 und Git-Blob-ID pro Datei. Fachberichte und SRD-Register
bleiben unverändert maßgeblich.

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

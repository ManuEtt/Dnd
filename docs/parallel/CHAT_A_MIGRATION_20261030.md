# Chat A – verlustfreie Branchintegration am 30.10.2026

Ausgangs-Main: `6465a4b2fc8d42ae7aab596ac26e85d61d2b8f49`.
Integrationsbranch: `integrate/rules-all-20261030` (lokales Teilpaket der
koordinierten Gesamtmigration zu Issue #425).

## Übernommene Historien

Alle 13 zu Sitzungsbeginn vorhandenen `feat/chat-a/*`- und `fix/chat-a/*`-Heads
sind mit regulären Merge-Commits erreichbar; keine ursprüngliche Historie wurde
umgeschrieben. Der ältere `fix/.../spell-material-id-integrity`-Head war bereits
Vorfahr seines `feat/...`-Nachfolgers. Beide Casting-Time-Branches sind enthalten.
Ihr einziger fachdateiseitiger Add/Add-Konflikt unterscheidet sich um eine
Kommentarzeile; die neuere, kommentierte Datei wurde übernommen.

README, zentraler Checkpoint und Chat-A-Checkpoint wurden bei Konflikten mit
beiden Ergänzungen vereinigt. Die ursprünglichen sechs geteilten
Dokumentationsdateien von Main bleiben vollständig als Zeilenfolge erhalten.
Die zwei unterschiedlichen Änderungen im SRD-Requirementsregister wurden
automatisch zusammengeführt; keine Requirement-ID, Statusbedeutung oder
Inventurlücke wurde entfernt. Alle weiteren Fach-/Testdateien waren konfliktfrei.

## Behobene Kombinationsfehler

Die Konzentrationsvorbereitung erlaubte einen vollständigen bestätigten
Modifikator bis ±60, die separate Schadensauflösung akzeptierte aber nur ±30.
Belegte Gesamtsummen +36 und −38 scheiterten deshalb beim Übergang. Die
Schadensauflösung verwendet jetzt dieselbe technische Gesamtgrenze ±60.
Dies ist **keine SRD-Bonusvergabe oder offizielle Regelobergrenze**: Jeder
Zusatzmodifikator muss weiterhin unabhängig bestätigt sein. Die Negativtests
prüfen die neue Grenze mit ±61; die neuen Übergangstests prüfen beide gültigen
Vorzeichen einschließlich unverändertem Quellcharakter und JSON-Rundlauf.

Außerdem lehnte die Konzentrationsvorbereitung eine namentlich vorhandene,
zulässige Zweitklasse mit Stufe 0 nicht ab. Der Guard verlangt jetzt mindestens
Stufe 1 für eine ausgewählte Zweitklasse. Eine eigene Regression belegt den
Fehler und den unveränderten Charakter bei Ablehnung.

## Tatsächliche Prüfungen

- Vor Integrationskorrektur: 168 gezielte Tests in allen 14 übernommenen neuen
  Fach-/Flow-Testdateien bestanden; `flutter analyze` ohne Befund.
- Neue drei Kombinationsregressionen zunächst **alle fehlgeschlagen**, danach
  zusammen mit beiden vorhandenen Konzentrationstestdateien **19 bestanden**.
- `scripts/check_domain_boundaries.py` erfolgreich; SRD-Coverage-Auswertung
  erfolgreich, Inventur weiterhin unvollständig.
- Finaler Teilstand: **171 gezielte Tests** in allen 15 betroffenen neuen
  Testdateien bestanden, Formatprüfung **559 Dateien unverändert**,
  `flutter analyze` ohne Befund.
- Vollständige App-/Backend-/Android-Abnahme und neue GitHub-CI gehören zum
  nachfolgenden kombinierten Gesamtstand, nicht zu diesem lokalen Teilbericht.

## Ausdrückliche Grenzen

Neue Konzentrations-, Aktionsökonomie-, Materialwert- und Mehrziel-Magisches-
Geschoss-Module bleiben, soweit in ihren Fachdateien beschrieben, eigenständige
Regelhelfer beziehungsweise Opt-in-Übergänge. Ihre Übernahme macht daraus keine
fertigen GameEngine-/UI-/SQLite-Befehle. Konzentrationswurf nach Schaden,
Zauberaktionsbindung und vollständige Mehrziel-Spielabläufe benötigen weiterhin
eine gesonderte atomare Integration mit Bestätigung, Wiederholungsschutz und
Persistenztests. Die übernommenen bereits angebundenen Todesrettungs- und
Kurzrast-Prüfungen behalten ihre bestehenden Grenzen. Keine Schema-, Versions-
oder Spielstandmigration in diesem Teilpaket.

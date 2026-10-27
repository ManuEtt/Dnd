# Chat A – Sanfter Fall im Abenteuer (SRD 5.2.1)

Stand: 27.10.2026; Basis: `main` bei `2d82dbd4cf920dc2f255a85f3856c9155808f33e`.
Voraussetzungen: #289 (Vorprüfung), #291 (GameEngine/GameController + SQLite-Transaktion), beide in `main`.

## Umfang

- **Sichtbarkeit:** Beim aktiven Kampf erhält eine Figur mit mindestens **vier bestätigten Mönch-Klassenstufen** (auch zweite Klasse) die neue Aktion **Sanfter Fall**. Verbunden mit freier Reaktion, lebendigem/handlungsfähigem Helden, keinen offenen Würfen/Reaktionen und keiner ungelösten Story-Outbox.
- **Dialog:** Keine automatische Freischaltung durch KI-Fließtext. Erfordert manuelle Eingabe von bestätigtem Sturzschaden **nach allen anderen Schadensanpassungen** (0–100.000), explizite Bestätigung des tatsächlichen Sturzes und der abgeschlossenen Schadensauflösung. Zeigt die Mönch-Klassenstufe, verhinderte und verbleibende Schadenshöhe; **Reaktion einsetzen** ist bis dahin deaktiviert.
- **Ausführung:** `GameController.applyConfirmedSlowFall` bekommt ursprüngliche **Kampagne, Revision, Encounter-ID** aus dem Zustand *vor* Öffnen des Dialogs. Der Controller/SQLite committen TP, temporäre TP, Reaktion, Audit-Ereignis und Revision gemeinsam. Bestätigung aus einem inzwischen veralteten Dialog wird nicht übernommen.
- **Abbruch:** verändert keinen Spielstand. Keine Behauptung, dass ein Sturz ohne manuell bestätigte Ursache stattgefunden hat.

## Dateien

- `app/lib/ui/monk_slow_fall_dialog.dart` – Eingabe/Bestätigung/Vorschau
- `app/lib/ui/app.dart` – Abenteuer-Aktionsknopf und revisionstreuer Controller-Aufruf
- `app/test/monk_slow_fall_dialog_test.dart` – Schadensgrenzen, zwei Checkboxen, verbrauchte Reaktion und Klassenstufe
- `app/test/monk_slow_fall_adventure_ui_test.dart` – 360px Abenteuer, Abbrechen ohne Mutation, expliziter Commit und bereits verbrauchte Reaktion
- `docs/srd_5_2_1_requirements.json` – Requirement `CLASS-M-NCH-4-BASE-SLOW-FALL-1` mit aktuellen Testbelegen

## Nicht behauptet

- Kein automatisch erkannter Sturz, keine automatische Generierung/Validierung eines Sturzschadenswurfs, kein Echtzeit-Trigger nach einer unbelegten Erzählung. Darum im Requirement-Register weiterhin **partial**.
- Noch kein signiertes Store-Release oder bestätigter Test auf einem echten Android-Gerät.
- Erst die auf finalem PR-Head abgeschlossene grüne Flutter-/Backend-/Android-CI darf als Endabnahme angegeben werden.

Quelle: Wizards of the Coast, [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0, Monk, Slow Fall.

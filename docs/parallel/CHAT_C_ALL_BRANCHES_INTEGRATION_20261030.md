# UI-Teilintegration aller Altbranches – 30.10.2026 (UTC)

Dieses Teilpaket gehört zum ausdrücklich beauftragten Gesamtmigrationslauf und
Issue #425. Es ist ein lokaler Integrationskandidat, kein eigenständiger
Main-/APK-/Gerätenachweis.

- Basis: `6465a4b2fc8d42ae7aab596ac26e85d61d2b8f49`.
- Lokaler Branch: `integrate/ui-all-20261030`.
- Geprüfter Code-/Testkopf: `12dc079c` (vollständiger SHA im Git-Verlauf).
- Alle zehn unten genannten ursprünglichen Heads sind mittels regulärer
  Merge-Commits nachweislich Vorfahren dieses Teilpakets.

**IMPLEMENTIERT:** Die neun Chat-C-Pakete für Header, Referenzzeilen,
Abenteuerstatus, gesperrte Angriffs-Semantik, Heldenaktionen, ausstehende
Handlungen, NPC-Auswahl, EP- und Ausrüstungsdialog sind kombiniert. Die
NPC-Reparatur aus #436 bleibt enthalten: genau eine Dialog-Scrollfläche und
eine normale `Column` statt verschachteltem `ListView(shrinkWrap: true)`.
Keine fachliche UI-Änderung musste bei der Teilintegration verworfen werden.

17 von 18 unterschiedlichen UI-/Testdateien sind auf Git-Blob-Ebene exakt
identisch zu ihrem ursprünglichen Feature-Head. Die einzige kombinierte Datei
`fantasy_character_sheet.dart` enthält zusätzlich aus Main den Import und die
Einbindung von `ToolProficiencyPanel`; die Headerkorrektur bleibt vollständig.
Markdown-Konflikte wurden als additive Vereinigung beider Seiten gelöst.
Sämtliche vorherigen Main-Zeilen von README, zentralem und Chat-C-Checkpoint
sind anschließend als geordnete Subsequenz geprüft erhalten.

**GETESTET:** `flutter pub get`, `flutter analyze` ohne Befund,
`dart format --output=none --set-exit-if-changed lib test` (544 Dateien,
null Änderungen), `verify_project.py`, `check_domain_boundaries.py` und
**55 Widgettests in elf Dateien erfolgreich**. Die elf Testdateien umfassen
alle neun neuen bzw. erweiterten UI-Pakete sowie bestehende fixierte
Schnellaktions- und Todesrettungs-Regressionen. Geprüft sind insbesondere
320/360 dp, 200 % Schrift, simulierte IME, Touch-Erreichbarkeit,
Tab/Enter-Reihenfolge, deaktivierte Aktionen und unveränderte Charakterdaten.

**NICHT GETESTET:** finale A/B/C/D-Gesamtkombination, vollständige
Backend-/Flutter-/Android-CI, APK-Build und reales Android/TalkBack-Gerät in
diesem Teilpaket. Diese Prüfungen erfolgen separat am Gesamtintegrations-HEAD.
**BLOCKIERT:** kein UI-Codeblocker; Remote-Merge und sichere Branchbereinigung
bleiben beim leitenden Integrationslauf. **NOCH NICHT IMPLEMENTIERT:** keine
zusätzlichen Produktfunktionen außerhalb dieser übernommenen Pakete.

Keine Versionserhöhung, Schema-/JSON-/SQLite-/Inventar- oder Regeländerung.
Kein Push in fremde Branches, keine Remote-Löschung und kein Main-Commit.
Die älteren darunterstehenden Vorabberichte behalten ihren historischen Stand.

## Ursprüngliche Branchheads

| Branch | Gesicherter Ursprungs-HEAD |
| --- | --- |
| `feat/chat-c/adventure-status-details-large-text-20261029` | `fdc393ff035ccc038e0cad70be1ad4fd084c7488` |
| `feat/chat-c/equipment-loadout-large-text-ime-20261030` | `c8bc256bd7a6e16d463a89df6dc02433c86b41a8` |
| `feat/chat-c/hero-actions-large-text-ime-20261030` | `d4945144509f78b8598b7c1385e80ae3cb34cd67` |
| `feat/chat-c/npc-picker-large-text-20261030` | `da25b5b873b54d580e538480b97d710d05c83476` |
| `feat/chat-c/pending-action-controls-large-text-20261030` | `ad3a30cf6954638c3aa6100eb9ef6ceff6750d66` |
| `feat/chat-c/reference-rows-large-text-20261029` | `3e64a76981d81bb5ae52cbc46eec7c0a133414e8` |
| `feat/chat-c/sheet-header-large-text-20261029` | `97262ab3900f21f5951afd45bd35da197c3b57ae` |
| `feat/chat-c/shortcut-disabled-hints-20261030` | `3a8d7531de9f088ac2c1c51598f9b093cf7dd2de` |
| `feat/chat-c/xp-reward-dialog-ime-scroll-20261030` | `5788de891ae2025e8610e5d7af597f8bc0a0dfaa` |
| `fix/chat-d/npc-picker-scroll-layout-20261030` | `da2745ebba1c7c81c19aca63ee7ebf3a94c826a2` |

## Nächster Schritt

Das Teilpaket regulär mit den übrigen A/B/D-Paketen kombinieren, gemeinsame
Dokumentation konsolidieren und auf dem finalen Stand `scripts/check.sh`,
Android-Debug-/native Tests und die komplette GitHub-CI bestehen lassen.
Erst danach ursprüngliche unveränderte Branchheads archivieren und löschen.

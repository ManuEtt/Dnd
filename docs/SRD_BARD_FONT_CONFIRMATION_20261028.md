# SRD 5.2.1: Barde – Quelle der Inspiration (bestätigte Regelaktion)

Stand: 28.10.2026. Grundlage: [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0.

## Implementierte Ausführung

- Der vorliegende Stapel baut ausdrücklich auf PR #323 auf; er wird nicht mit dem unabhängigen Hauptbranch verwechselt.
- Ab **Barden-Klassenstufe 5** zeigt der Charakterbogen einer **aktiven Kampagne** eine bestätigbare Umwandlung an, wenn mindestens eine Bardische Inspiration verbraucht wurde.
- Ein Spieler wählt einen *verfügbaren* regulären Zauberplatz (bei Mehrklassencharakteren optional einen passenden Paktplatz). Vor jeder Zustandsänderung wird eine zweite ausdrückliche Bestätigung verlangt.
- `SrdBardFontProposal.applyTo` prüft denselben unveränderten Charakter-Snapshot; `GameEngine.confirmBardFontOfInspiration` schreibt gleichzeitig den Platzverbrauch und eine zurückgewonnene Nutzung in **einer** Kampagnenrevision samt `class.bardFontOfInspiration`-Ereignis.
- `GameController.confirmBardFontOfInspiration` vergleicht die persistierte Kampagnenrevision und speichert über bestehendes CAS. Bei zwischenzeitlicher Änderung, offenen Würfelproben oder fehlender Berechtigung wird *nichts* gespeichert.
- Keine Aktion und keine Bonusaktion werden verbraucht. Der Charakterbogen wird nach erfolgreicher Änderung geschlossen, damit beim erneuten Öffnen der bestätigte Stand sichtbar ist.
- Die isolierte Heldenarchivansicht bleibt absichtlich ohne die Aktion, weil der aktuelle `CampaignRepository.saveCharacter`-Vertrag dort keine eigenständige Versionsprüfung/Atomizität für konkurrierende Archiv-Updates anbietet.
- `Font of Inspiration` wird für diese genau belegte Regelausführung als `Bestätigte Regelaktion` klassifiziert; der gesamte Bardenmechanismus einschließlich Ziel-Inspiration und Würfelanwendung ist damit **nicht** automatisch komplett implementiert.

## Tests und nicht beanspruchte Fertigstellung

- Vorhandenen Import-Test aus PR #323 korrigiert: Sparse-JSON von alten Figuren wird beim Import normalisiert, Ressourcen werden separat verglichen, und erst die wiederholte kanonische Serialisierung ist idempotent.
- Tests in `app/test/srd_bard_font_confirmed_action_test.dart`: Kampagnenrevision, genau ein Audit-Ereignis, beide Ressourcen in einem Commit, stale-Snapshot, explizite Ablehnung, Dialog-Abbruch und bestätigte Auswahl.
- Klassenmatrix testet nun den tatsächlichen Ausführungsstatus des neuen Merkmals.

Die vollständige Mechanik der übrigen Klassenmerkmale, Unterklassen, Wahl-/Zielentscheidungen und aller Zaubereffekte ist weiterhin offen; hier wird keine Vollautomatik behauptet. Flutter-Format, Analyse, Tests und APK sind erst mit einem **grünen GitHub-Actions-Lauf auf dem neuen HEAD** abgenommen. Ein Realgerätetest ist nicht erfolgt.

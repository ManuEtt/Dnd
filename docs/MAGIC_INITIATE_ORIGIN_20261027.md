# SRD 5.2.1 – Magieinitiierter: bestätigte Auswahl

Stand: 27.10.2026. Entwicklungszweig:
`feat/character-magic-initiate-choices-20261027`.

**Quelle:** [Wizards of the Coast SRD 5.2.1](https://www.dndbeyond.com/srd),
*Feats – Magic Initiate* (CC BY 4.0), *Character Backgrounds*.

## Umgesetzt

Der bestehende Hintergrundassistent kann für einen nachweislich bestätigten
Akolythen (Kleriker-Liste) oder Weisen (Magier-Liste) eine
`SrdMagicInitiateChoice` verlangen:

- **Zwei unterschiedliche Zaubertricks** aus der jeweiligen Liste.
- **Ein Zauber des ersten Grades** aus derselben Liste.
- **Zauberattribut** Intelligenz, Weisheit oder Charisma.
- Explizite deutsche Dialogbestätigung; Abbrechen verändert keine Daten.
- Identitätsgebundene, versionsgeprüfte JSON-Felder im `HeroCharacter`.
  Ein importierter Nachweis ohne passendes bestätigtes Hintergrundpaket
  oder mit erfundenen Zaubern wird abgewiesen.
- Der bestehende Audit zeigt die fehlende Zauberwahl getrennt an.
- Ältere Charaktere ohne diesen Nachweis bleiben unverändert lesbar.

Die beiden Schreiblisten sind eine geprüfte Momentaufnahme des
versionierten Assets `app/assets/srd_5_2_1_spells.json` (Kleriker
7 Zaubertricks / 15 Zauber Grad 1; Magier 15 / 30). Ein Test vergleicht
jede angebotene Auswahl gegen die dortigen spell-`classes`/`level`
Metadaten. Der Herkunftsnachweis ist unveränderlich.

**Sicherheitsgrenze:** Die drei bestätigten Zauber werden bewusst
**nicht** automatisch der allgemeinen `hero.spells`-Liste zugewiesen.
Der vorhandene Zauberwirkungs-/Ressourcenmechanismus kann die
Talent-Nutzung noch nicht nachweisbar von Klassen-Zauberslots trennen.

## Nicht implementiert

- Einmaliges Wirken des Grad-1-Zaubers ohne Platz pro langer Rast,
  bestandsfähiger Verbrauch und Wiederaufladung im SQLite-Replay.
- Zusätzliches Wirken mit tatsächlich verfügbaren Zauberplätzen.
- Zugehörige Zauberwirkungsattribut-Berechnung und freie Zaubertricks.
- Stufenaufstiegsgebundener Austausch genau eines Zaubers derselben
  Klassenliste/des gleichen Grades.
- Wiederholter Erwerb des Talents über andere Quellen/Klassen.
- Vollständig mechanische Herkunftstalente aller vier Hintergründe.
- Physischer Android-Gerätetest, TalkBack und Upgrade alter APKs.

## Tests und Abnahme

`app/test/srd_magic_initiate_choice_test.dart` prüft den vollständigen
Abgleich der offiziellen Klassenlisten mit dem Asset, JSON,
Manipulation, Legacy, Attributauswahl und Audit.

`app/test/srd_magic_initiate_dialog_test.dart` prüft vollständige
Auswahl, doppelte Zaubertricks, Abbrechen und eine 320-dp-Oberfläche
mit 200 % Textskalierung.

`app/test/srd_magic_initiate_storage_test.dart` prüft den tatsächlichen
SQLite-Neustart und Hero-Export/-Import. Vor Abschluss der GitHub-CI
sind die Tests nicht als bestanden zu behaupten.

Der neue PR baut direkt auf aktuellem `main` auf; er überschreibt
weder den offenen Charakterbogen-PR #297 noch parallele KI-/Kampf-PRs.

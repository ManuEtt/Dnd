# Charaktererstellung – zusammengeführte Entwicklungsbranches (28.10.2026)

Dieser Teilstand gehört zur übergreifenden Branch-Migration. Ausgangs-Main ist
`dd0c2e94ccf0995c6070010b6af1df315205b36a`; Arbeitsbranch
`integration/migration-character-20261028`. Die folgenden Quellköpfe wurden durch
reguläre Merge-Commits erhalten, nicht durch unprüfbares Kopieren ersetzt:

| PR | Teilumfang | Quellkopf |
| --- | --- | --- |
| #297 | Sichere Attributwürfe und historische Startwerte im Charakterbogen | `f1d2785c0d7ec3fa84b291a4bb541911ab9b44d4` |
| #319 | Typisierte historische Klassen-, Fertigkeits- und Paketwahl | `b4db131e490801efbe95cfdcf7bf6bb938c3d3e8` |
| #324 | Start-TP-/Ausrüstungseingangsprüfung aller zwölf Klassen | `0ca0f91d0ae4a74299ad1f23fed445fc1ef42bf4` |
| #317 | Bestätigte Magieinitiierter-Zauberwahl für Akolyth/Weiser | `35d6403c1d03aff603be31fb1e85e0c03d416f52` |
| #330 | Veraltete Charaktereditoren vor atomarem Speichern abweisen | `1280db9155b0d8cf38f227440856c76e8e78eda6` |

## Integrationsentscheidungen

- Der siebenstufige, nachweisbasierte `SrdCharacterCreationAudit` bleibt erhalten.
  Die alte Auditfassung aus #317 ersetzt ihn nicht. Ausschließlich die eng
  begrenzte Magieinitiierter-Wahlprüfung kommt hinzu; ein falscher Hintergrund
  ergibt `invalid`, ein fehlender Nachweis `missing`. Bestätigte Zauberwahl
  bestätigt keine kostenlose Anwendung, Zauberplätze oder vollständige Talentwirkung.
- `HeroCharacter` erhält beide optionalen Nachweise `startingClassChoice` und
  `startingMagicInitiate` zusätzlich zum vorhandenen `startingAbilityOrigin`.
  Lesen erteilt keine Boni, Gegenstände oder Zauber. Die Magic-Initiate-Version
  muss tatsächlich eine ganze Zahl sein; `1.0` wird wie bei den anderen
  neuen Herkunftsnachweisen abgewiesen.
- Neue erste Klassenwahlen benötigen jetzt für alle zwölf Klassen bestätigte
  Konstitution und eine verfügbare Klassenpaket-/Goldwahl. Die alten #319-
  Widgetabläufe ohne KO bzw. ohne Paket entsprechen dem neuen Vertrag nicht mehr.
  Sie wurden an die echte Bedienung angepasst: KO ausdrücklich angegeben,
  manuelle Testwerte ausdrücklich als Hausregel markiert, Startgold oder
  Ausrüstung gewählt. Fehlendes Paket sperrt die Bestätigung weiterhin.
- Klassenwechsel im noch unbestätigten Dialog überträgt keine alten Übungen.
  Bereits vergebene Pakete dürfen nach wie vor keiner anderen Klasse
  zugeordnet werden; Wiederbestätigung vergibt weder Gold noch Ausrüstung doppelt.
- Die vorhandene CAS-Implementierung aus #330 ist wiederverwendet. Kein zweiter
  Speicherweg, keine Datenbankschema- oder JSON-Hauptversionsänderung.
- Ursprüngliche kollidierende Dokumentfassungen liegen unter
  `docs/history/branch_migration_character_20261028/`; das dortige Manifest
  enthält ihre SHA-256-Werte. Die Anforderungsmatrix enthält die vereinigten IDs,
  ohne vollständige Klassen-/Talent-/Charakterabdeckung zu behaupten.

## Gemeinsamer Speichernachweis

`character_start_class_storage_test.dart` verbindet Klassenpaket A eines Barbaren,
den vollständig bestätigten Standardsatz mit Weiser-Erhöhungen, das separate
Weiser-Goldpaket und die typisierte Magieinitiierter-Zauberwahl. Nach SQLite-
Neustart ist der gesamte Charakter identisch. Ein zweiter SQLite-Schreiber
verbraucht Gold und entfernt eine Waffe. Der veraltete Editor darf diesen
Stand nicht überschreiben: alle sechs Speichertabellen bleiben unverändert.
Neustart und ein frischer, gültiger Editor-Speichervorgang bewahren anschließend
alle Herkunftsnachweise, die Attribute und das tatsächlich verbliebene Inventar.
Die Talentzauber werden dabei nicht in die wirkbare Zauberliste aufgenommen.

## Abnahmegrenzen

Lokal auf diesem Charakter-Integrationsstand bestanden: **96 gezielte Tests**
über 13 Attribut-/Klassen-/Talent-/UI-/SQLite-/CAS-Dateien und weitere **24
Audit-/Hintergrundtests** über drei Dateien; insgesamt 120 unterschiedliche Tests.
`dart format --output=none --set-exit-if-changed lib test` prüfte 483 Dart-Dateien
ohne Änderung. `flutter analyze` aus `app/` meldete keine Probleme.
Logs: `/workspace/validation/20261028-migration-character-targeted-final.log`,
`20261028-migration-character-audit-final.log`,
`20261028-migration-character-format.log` und
`20261028-migration-character-analyze-final.log`.
Die frühere Testausführung enthielt einen inzwischen behobenen falschen
Widget-Testtyp; der abschließende 96-Test-Lauf ist vollständig erfolgreich.
Die früheren grünen Einzel-PR-CIs ersetzen keine vollständige kombinierte Prüfung. Android-Realgerät, TalkBack am Gerät, produktive Signierung
und vollständige SRD-Charaktererstellung bleiben offen. Ein vollständiger Wizard,
sämtliche Speziespflichtwahlen, zusätzliche Klassen-/Zauberentscheidungen und die
restliche Herkunftstalentmechanik sind durch dieses Zusammenführen nicht fertig.

Branchlöschungen und Remote-Änderungen führt ausschließlich der übergreifende
Migrationsschritt nach Sicherung, Ancestry-Prüfung und erfolgreicher gemeinsamer
Abnahme aus. Dieser Teilbranch hat keine Remote-Branches gelöscht.

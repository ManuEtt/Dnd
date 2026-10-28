# Chat A: Sanfter Fall – veraltete Dialogbestätigung (27.10.2026)

## Kontext

- Repository-Basis: `main` bei `f9b2f72a4bf8e4216bf8baac60c7f92c4a8a997f`.
- [PR #294](https://github.com/ManuEtt/Dnd/pull/294) hat den manuellen Dialog für Monk 4 Slow Fall bereits integriert.
- Das Regelkommando im `GameController` kontrolliert schon `campaignId`, `expectedRevision` und `encounterId`. Die UI gab bei inzwischen geänderter Revision bislang jedoch keine spezifische Rückmeldung, sondern ließ den alten Dialog an den Controller senden.

## Verbesserung

- Beim Bestätigen des Dialogs vergleicht die Abenteueroberfläche den aktuell geladenen Kampagnen-, Revisions- und Encounter-Stand sowie das Reaktionsbudget mit dem Snapshot von vor Öffnung des Dialogs.
- Bei Abweichung: **keine Aktion an den Controller**; stattdessen sichtbare, verständliche SnackBar mit Aufforderung zum erneuten Öffnen.
- Die **autorisierende Prüfung im Controller/Repository bleibt unverändert** und deckt auch Veränderungen nach diesem UI-Vergleich ab. Kein Race wird allein durch den UI-Check als sicher ausgegeben.
- Test `app/test/monk_slow_fall_stale_dialog_ui_test.dart` auf 360 px mit SQLite: Dialog vollständig ausgefüllt offen halten, von außen eine echte Reaktion in derselben Begegnung speichern, dann den veralteten Dialog bestätigen. Erwartung: Hinweis sichtbar, **kein zweiter Commit**, nur **ein** Slow-Fall-Event, kein TP-/Revisionsverlust.

## Abgrenzung

- Keine neue SRD-Regel, keine Änderung an Klassenstufen oder Schadenswürfen.
- Kein DB-Schemawechsel und keine Änderungen an anderen Chat-Branches.
- Test, Flutter-Analyse und Android-Build erst nach grüner CI auf endgültigem PR-Head als bestanden kennzeichnen.

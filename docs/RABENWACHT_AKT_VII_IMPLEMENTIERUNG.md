# Rabenwacht – Akt VII: Das Haus ohne Türen

**Stand:** 21.10.2026 – Implementierung auf dem Entwicklungsbranch
`feature/rabenwacht-voice-act7-20261021` (aufbauend auf dem offenen Akt-VI-PR #77).
**Qualitätsstatus:** Quellcode und Regressionstests geschrieben; Dart/Flutter/Android-CI
und realer Gerätetest noch **nicht nachgewiesen**. Kein Releaseversprechen.

## Anschluss ohne Retcon

Die vorhandene Fortsetzung `rabenwacht-voice-v1` beginnt ausschließlich auf
ausdrückliche Spieleraktion nach einem abgeschlossenen ursprünglichen Finale.
Akt VII schließt an `voice-gallery` aus Akt VI an. Die dortige Mindestbedingung
von **zwei tatsächlich erworbenen unabhängigen Hinweisen** bleibt bestehen.
Das Story-Modul wird aus der bestehenden Rabenwacht-Fassade angesprochen.
Weder Quests des ersten Abenteuers noch Held, Inventar, Trefferpunkte, EP,
Kampfzustand, Würfel oder Zauberressourcen werden in Akt VII verändert.

## Szenen und Zustandsübergänge

| Szene | Spielbare Handlung | Persistierter Beleg |
| --- | --- | --- |
| `voice-gallery` | Dreizehn Porträts vergleichen; vierzehntes Bild ist mögliche Zukunft; Bibliothek betreten oder zum Haus zurückkehren | `voice:portraitCompared` |
| `voice-library` | Chronist kennenlernen; Angebot ablehnen, Bedingungen erfragen, Zustimmung vortäuschen oder Preis anzeigen; Blatt suchen | `voice:chronistMet`, `voice:termsQuestioned`, `voice:chronistChoice` |
| `voice-price` | Den Preis ausdrücklich bestätigen oder ohne Folgen abbrechen | `voice:priceExplained`, bei exakter Bestätigung `voice:chronistChoice=accepted`, `voice:chronistDebt=pending` |
| `voice-ledger` | Das beschädigte vierzehnte Blatt finden; Abschrift Liora anvertrauen oder selbst verwahren; zur Bibliothek zurückkehren | `voice:oathPageFound`, `voice:nameCustody` |
| `voice-threshold` | Akt-VII-Zwischenziel; Rat der Zeugen bleibt für Akt VIII offen | `voice:act7Reached` |

Der Chronist ist eine **Figur der Originalgeschichte**, kein neues Monster
mit unbestätigtem D&D-Statblock. Sein Angebot wird nicht durch frei erfundene
Zauberwirkungen, unbemerkten EP-Verbrauch oder das Löschen einer Figur
ausgeführt. Auch bei ausdrücklicher Bestätigung ist der Preis zunächst eine
**offene erzählerische Schuld**; ein tatsächliches Opfer benötigt einen eigenen,
regel- und narrativ geprüften Folgeentscheid in Akt VIII.

## Entscheidungsregeln

- Ablehnen und vorgetäuschte Zustimmung sind voneinander getrennte,
  gespeicherte Ausgänge. Ein bereits festgelegter Ausgang kann nicht durch
  ein zweites Kommando ersetzt werden.
- Verhandeln protokolliert nur nachgefragte Bedingungen. Es ist **keine**
  Annahme und noch kein endgültiger Ausgang.
- Die Preisbestätigung akzeptiert nur den konkreten Satz
  `Ich bestätige den Preis: Eine andere Person wird vergessen.`.
  Unvollständige, mehrdeutige oder negierte Eingaben ändern keine Entscheidung.
- Der Name wird nicht als objektiv lesbar erfunden. Vor dem tatsächlichen
  Untersuchen des Blatts kann er niemandem anvertraut werden.
- Lioras frühere Beziehung aus Akt VI beeinflusst ihre Reaktion. Auch nach
  einer Anschuldigung bleibt eine freiwillige Übergabe möglich.
- Die Zwischenstation markiert **nicht** `voice-main` oder alle offenen
  Nebenquests als erledigt. Kein erneuter Final-Meilenstein und keine neuen EP.
- Das spoilerfreie Hinweisprotokoll zeigt den Chronisten, seinen Handel und
  die Beweiskette erst nach den entsprechenden Spielszenen.

## Geplante technische Abnahme

Neue Regressionstests:
`app/test/rabenwacht_fourteenth_voice_act7_test.dart`.

Sie prüfen den Weg aus Akt VI zur Galerie und Bibliothek, die nicht sichtbaren
Spoiler vor Erstkontakt, das irreversible Nein, Verhandlung ohne automatische
Annahme, Täuschung und Verdacht, den Preis mit ausdrücklicher Einwilligung,
Abbruch ohne Opfer, Fundvoraussetzung für das Eidblatt, zwei Arten der
Aufbewahrung, fehlende automatische Beendigung des Hauptauftrags sowie
JSON-Roundtrips für die neuen Fakten.

Vor einer Integration nach `main` müssen mindestens
`python3 scripts/check_domain_boundaries.py`,
`dart format --output=none --set-exit-if-changed lib test`,
`flutter analyze`, `flutter test` und `flutter build apk --debug` auf
einem geeigneten Checkout laufen; dazu später ein Android-Gerätetest.
Ein erfolgreich angelegter PR allein ist **kein** Testnachweis.

## Weiterentwicklung Akt VIII

1. Rat der Zeugen mit alter Eidauslegung, drei voneinander unabhängigen
   Aussagen und sichtbar unterschiedlichen Folgen der vier ursprünglichen Enden.
2. Gesicherte versus öffentlich vorgetragene Ersatzzeugnisse als risikoreiche
   Alternative; kein automatisch aus Erzähltext abgeleiteter Erfolg.
3. Drei Schlusswege: Eid erneuern, Chronistenarchiv nach Beweissicherung
   zerstören oder neuen gemeinsamen Eid verhandeln.
4. Preis-/Täuschungsfolgen aus Akt VII auswerten; keine erzwungene
   Opferwahl und keine freie Eingabe, die echte Regel- oder Ressourcenänderungen
   ohne bestätigte Aktion auslöst.
5. Deterministische End-to-End-Tests über Save/Load, alte Finalstände,
   negierte Kommandos, einmalige Meilensteine und unbesuchte Nebenquests.

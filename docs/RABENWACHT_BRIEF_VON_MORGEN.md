# Rabenwacht – Der Brief von Morgen

**Entwicklungsstand:** 21.10.2026, separater Folgebranch
`feature/rabenwacht-brief-von-morgen-20261021`, aufgebaut auf dem
Epilog-PR #86 und damit indirekt auf Akt-VIII-PR #84.

## Erzählabsicht

Drei Wochen nach dem abgeschlossenen Epilog taucht ein Brief mit zwei
widersprüchlichen Fassungen desselben Morgens auf. Eine Seite behauptet,
der Brunnen sei leer gewesen; die andere bezeugt dort drei Menschen.
Ein Datum auf Papier ist **kein Beweis einer Prophezeiung**. Statt
eines Retcons untersucht der Spieler, wie Texte, Erzählungen und
dokumentierte Herkunft die Wahrheit einer Gemeinschaft beeinflussen.

Die drei bereits entschiedenen Abschlüsse des Rates, alle vier alten
Rabenwacht-Enden und das spätere Dorfvermächtnis bleiben vollständig
bestehen. Die Nachgeschichte ist optional und nicht der Beginn einer
neuen Pflichtkampagne.

## Zugang

- Ausschließlich im bestehenden Fortsetzungsmodus
  `rabenwacht-voice-v1`, aus dem tatsächlich abgeschlossenen
  `voice-epilogue-complete`.
- Benötigt bestätigtes `voice:ending`,
  `voice:witnessChain=true`, eines der drei gespeicherten
  `voice:legacy` und abgeschlossenen Auftrag `voice-epilogue`.
- Expliziter Start **„Brief von Morgen beginnen“**. Negierte
  Formulierungen starten nichts; bloßes Lesen von Hinweisen ebenfalls
  nicht.
- Kein Charakterneustart, keine Änderung von TP, EP, Inventar,
  Monsterwerten oder Zaubern.

## Ermittlungen und Sperren

| Szene | Handlung | Daten |
| --- | --- | --- |
| `voice-morrow-square` | Umschlag öffnen; drei mögliche Spuren frei wählen | `voice:morrow:letterRead` |
| `voice-morrow-elda` | Register nach Original-/Abschriftstatus prüfen | `voice:morrow:elda` |
| `voice-morrow-tarek` | Tinte und Papier auf die gemeinsame Herkunft prüfen | `voice:morrow:tarek` |
| `voice-morrow-well` | Wachs und Spuren am Brunnen dokumentieren | `voice:morrow:well` |
| `voice-morrow-council` | Erst mit geöffnetem Brief und **mindestens zwei voneinander unabhängigen** geprüften Ortsbelegen | Freie Bewertung des Schriftstücks |
| `voice-morrow-end-sealed` | Brief versiegelt verwahren, öffentlich nur Existenz und Ungewissheit bezeugen | `voice:morrow:outcome=sealed` |
| `voice-morrow-end-published` | Beide Versionen mit getrennt genannten Quellen veröffentlichen | `voice:morrow:outcome=published` |
| `voice-morrow-end-liora` | Liora die eigene Entscheidung über ihre Beteiligung lassen | `voice:morrow:outcome=liora` |

Ein erneuter Besuch derselben Spur erzeugt **keinen zweiten
unabhängigen Beleg**. Zu früh einberufener Rat verrät keine
untersuchten Ergebnisse. Keine Aussage beschuldigt automatisch
Liora oder einen anderen NPC. Auch nach dem Rat dürfen weitere
Belege gesammelt werden.

## Integration und Regression

Dateien:
- `app/lib/story/fourteenth_voice_morrow.dart`
- `app/test/rabenwacht_fourteenth_voice_morrow_test.dart`
- Router und spoilerbedingte Hinweise:
  `app/lib/story/fourteenth_voice_campaign.dart`.

Persistenz: vorhandene `Campaign.facts`, `storyBible.stage`,
`Quest` und `StoryThread`; **keine Migration**. Die optional
hinzugefügte Quest `voice-morrow` wird einmalig angelegt
und nur bei bewusst gewähltem Ausgang abgeschlossen.

Automatisierte Tests prüfen echten Einstieg über die alte Kampagne,
Akt VI–VIII, Epilog, Startverbot und Negation, alle drei Spurwege,
Doppelbesuche, Ratsschwelle, drei Abschlüsse, Spoilergrenzen,
Idempotenz, unveränderte Haupt- und Epilogquests, ursprüngliches
Ende, JSON-Roundtrip und unberührte Helden-EP.

**Vor Freigabe:** Offizielle Dart-Formatierung, `flutter analyze`,
alle Flutter-Tests, Android-Debug-APK, native Tests, vollständige
GitHub-Actions-Pipeline. Der reale Android-Gerätetest steht getrennt
aus. Die PRs #84 und #86 müssen vor diesem Folgeinkrement
sicher gegen den dann aktuellen Hauptbranch integriert werden.

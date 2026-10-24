# Kampagnen-Spannung: Schutz vor wörtlicher Plot-Geheimnisoffenlegung

Stand: 24.10.2026. Implementiert in [PR #163](https://github.com/ManuEtt/Dnd/pull/163).

## Abgegrenzte Lücke

Beim Kampagnenstart erhält der generative Spielleiter sein internes \`secret\` gemeinsam mit öffentlich sichtbaren Feldern wie \`opening\`, NPC-/Ortsbeschreibungen und Questfäden. Bei der Fortschreibung liefert die App das zuvor gespeicherte \`secret\` als Erzählkontext mit. Der bestehende Server validierte bislang Struktur und Länge, nicht jedoch ein direktes wörtliches Abschreiben des gesamten Geheimnisses in öffentlich sichtbare Felder. Ein Versehen könnte die Handlung vorzeitig verraten.

## Umsetzung

- \`backend/src/story_secret_guard.ts\` enthält unabhängige, reine TypeScript-Prüfungen für \`StoryPlan\` und \`StoryTurn\`. Der komplette geheime Text wird nach Unicode-NFKC, einfacher Whitespace-Normalisierung und deutscher Groß-/Kleinschreibung mit sichtbaren Textfeldern verglichen. Wortgrenzen vermeiden zufällige Treffer innerhalb größerer Wörter.
- \`backend/src/app.ts\` wendet diese Prüfung **nach** den bestehenden \`parseStoryPlan\`- und \`parseStoryTurn\`-Validierungen an. Start: sichtbarer Titel, Welt, Auftakt, Rahmenhandlung/Ziel, Thread-, NPC- und Ortsfelder. Fortsetzung: Erzähltext, Thread-/NPC-Updates und optionales Abenteuerangebot.
- Das eigene interne \`secret\`-Feld der Planantwort wird nicht gegen sich selbst geprüft: Die App benötigt es unverändert für die lokale Kampagnenbibel. Die API hat weiterhin keine Schreibrechte an Trefferpunkten, Würfeln, Questbelohnungen oder Inventar.
- Eine unzulässige Anbieterantwort wird mit dem bereits vorhandenen generischen HTTP-502-\`provider_unavailable\` zurückgewiesen, ohne den beanstandeten Geheimtext zurückzusenden. Es gibt keine kostenpflichtigen Testaufrufe.
- Das Verhalten gilt unabhängig vom verwendeten \`Narrator\`-Provider, weil die Sicherheitsprüfung am API-Ausgang erfolgt. Der kostenlose Mock besteht die regulären gültigen Pfade.

## Prüfungen

\`backend/test/story_secret_guard.test.ts\` deckt Startfelder, Story-Fortsetzung, NPC-Notizen, Abenteuerangebote, Groß-/Kleinschreibung, Unicode/Leerzeichen, Wortgrenzen, positive gültige Antworten und beide authentifizierten Fastify-Routen einschließlich generischem 502 ab.

Die **vollständige neue** GitHub-CI ist über [PR #163 / Checks](https://github.com/ManuEtt/Dnd/pull/163/checks) zu prüfen. Ältere erfolgreiche CI von PR #159–#162 belegt die Änderung nicht. Lokaler vollständiger Flutter-/Android-Test ist in dieser Entwicklungsumgebung nicht möglich.

## Grenzen

Dies ist **kein semantischer Spoilerfilter**: Abkürzungen, Paraphrasen, Synonyme und Teilenthüllungen des Geheimnisses werden nicht verlässlich erkannt. Die Serverprüfung kann keine legitime Offenlegungsentscheidung anhand des Spielerfortschritts treffen; dafür braucht es später eine explizite, lokal bestätigte Reveal-Funktion in der Story-/Kampagnenarchitektur. Der Zeitpunkt einer echten Offenlegung wird daher weder automatisiert noch behauptet. Der interne Plot bleibt im Backend-Request als Kontext enthalten und ist weiterhin keine autoritative Regelentscheidung.

Keine Änderung an Android-App 0.8.38+88, SQLite 2, Export-JSON 1, Migrationen oder SRD-5.2.1-Regelabdeckung. Kein direkter main-Push, kein Force-Push und kein Eingriff in parallele PRs #159–#162.

**Ein nächster Entwicklungsschritt:** Finale CI von PR #163 einschließlich Python, Backend, Flutter und Android prüfen, Fehler beheben und erst nach grünem Status für menschliche Review freigeben.

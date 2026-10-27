# Chat A – Bestätigte Kletter- und Schwimmbewegung, 27.10.2026

**Stacked PR-Basis:** `feat/chat-a/ranger-roving-20261027` (PR #276). Neue Funktion baut auf der dort implementierten, read-only `CharacterRuleEngine.rovingClimbSpeedMeters`/`rovingSwimSpeedMeters` auf; sie darf nicht unabhängig gegen einen älteren `main`-Stand gemergt werden.

## SRD-5.2.1-Quelle und Mechanik

[SRD 5.2.1 CC BY 4.0](https://www.dndbeyond.com/srd), *Rules Glossary – Climbing, Swimming, Difficult Terrain*: je Fuß Klettern/Schwimmen werden ohne passende besondere Geschwindigkeit zwei Fuß Bewegung verbraucht, in schwierigem Gelände drei. Mit einer passenden Kletter-/Schwimmgeschwindigkeit fällt der zusätzliche Spezialbewegungsaufwand weg; schwieriges Gelände kostet weiterhin doppelt. Ein Fuß = drei Dezimeter im bestehenden Bewegungsmodell.

## IMPLEMENTIERT

- `srd_terrain_movement_rules.dart`: reine deterministische Kostenberechnung, Gelände-/Distanzbestätigung, Zusatzproben-Guard, Null-/0-Tempo, kampfunfähige/liegende Figuren, gültige Bewegungsbudgets, keine Rundung von 0,5-m-Resten; sonst keinerlei Spielstandsänderung.
- `GameEngine.moveOnConfirmedTerrain`: aktive Heldenrunde ohne offenen Würfelwurf/Todesrettung/Gelegenheitsreaktion; genau eine bestätigte Strecke per `combat.climbed` oder `combat.swam`, Ereignis enthält Modus, 3-dm-Fuß-Strecke, Kosten, Gelände, besondere Geschwindigkeit und Budget-Rest. Bestätigte frühere Deckung wird ungültig, nicht kommentarlos behalten.
- `GameController.moveOnConfirmedTerrain`: revisionsgeschützte, atomare Persistenz und Fehlerweitergabe. Keine neuen Tabellen/JSON-/Event-Schemaversionen; bestehende Event-Journal-Metadaten bleiben verwendbar.
- `app/lib/ui/app.dart`: getrennte explizit gewählte Menüs für Klettern und Schwimmen während des eigenen laufenden Kampfs, mit 5/10 Fuß, normalem/schwierigem Gelände und vorab berechneten Kosten; `terrainConfirmed` stammt nur aus dieser bestätigenden Nutzerinteraktion, nicht aus freier Erzählung. Extremgelände mit zwingend offenem Athletikwurf muss über bestätigten Prüfpfad aufgelöst werden und wird durch die UI **nicht** als automatisch bewältigt ausgegeben.

## TESTS

- `app/test/srd_terrain_movement_rules_test.dart`: ohne und mit Roving, Klettern/Schwimmen, schwieriges Gelände, 1,4-m-Rest, Revisions-/Eventwerte, fehlendes Terrain, ausstehende Zusatzprobe, unzulässige Strecke und eigener Zug.
- `app/test/srd_terrain_movement_storage_test.dart`: SQLite/Controller mit Neustart, Stale-Revision, Rollback bei abgebrochenem `combat.swam`-Journal und abgelehntem Geländekontext.

## AUSSCHLÜSSE UND STATUS

- Vollständiges Kartenpositionsmodell, Wasserhindernisse, verbrauchte Luft, Durchlässigkeit von Wänden, gegnerische Gelegenheitsangriffe beim Klettern/Schwimmen und eigenständige Athletik-Würfelanfragen werden nicht eingeführt; Beschreibungen dürfen niemals diese Daten fingieren.
- **Vollständige lokale Flutter-/Android-/Realgeräte-Tests:** ohne SDK nicht möglich. CI erst nach Prüfung des finalen PR-Heads als erfolgreich bezeichnen; solange **partial**.
- Open PR #276 und #266 bleiben unverändert und stehen weiter unter Integration-/CI-Prüfung. Keine fremden Branches gelöscht.

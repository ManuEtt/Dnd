# Chat A: Mönch Slow Fall – revisionssichere Kampfbuchung (27.10.2026)

## Ausgangspunkt

- Voraussetzung: [PR #289](https://github.com/ManuEtt/Dnd/pull/289) über `main` als Commit `574fb05b6482c6f63a26cce74e7e243f64bc0b72`.
- Quelle: Wizards of the Coast, [SRD 5.2.1](https://www.dndbeyond.com/srd) (CC BY 4.0), Monk 4, Slow Fall.
- Requirement `CLASS-M-NCH-4-BASE-SLOW-FALL-1`. **Weiterhin nur partial**, weil noch keine durch bestätigte Spieldaten eröffnete UI-Fallentscheidung implementiert ist.

## In diesem PR hinzugefügt

- `GameEngine.applyConfirmedSlowFall(...)`: Sturz, Kampf-/Encounter-ID, freie Reaktion, ausdrückliche Zustimmung und bestätigter Schaden *nach anderen Schadensanpassungen* sind zwingend. Das Gelände bzw. Sturzgeschehen darf nicht aus einer KI-Erzählung entnommen werden.
- Reaktionsbuchung und Anwendung des bereits bestätigten Sturzschadens sind **ein GameUpdate** mit einer neuen Revision und dem Event `combat.slowFallResolved`.
- Für verbleibenden Schaden wird die vorhandene `CharacterEffectRules.untypedDamage` benutzt: temporäre Trefferpunkte, 0-TP-Regeln, Konzentrationswurf, automatische Folgen für Kampfstatus. Kein doppelter Widerstandsabzug; der Auftrag verlangt zuvor separat bestätigten Schaden nach übrigen Anpassungen.
- `GameController.applyConfirmedSlowFall(...)`: Kampagnen- und Revisionstest über `_effectCampaign`; SQLite speichert Hero/Encounter/Event nur in der vorhandenen atomaren Transaktion `saveCampaign`.
- **Sicherheit:** Verweigerung bei unbestätigtem Sturz, falscher Kampf-ID, verbrauchter Reaktion, fehlenden Schadenszahlen, laufendem gegnerischen Schildangebot oder offenen Würfen, Handlungsunfähigkeit oder alten Revisionen. Kein heimlicher Wurf aus Storytext.
- Neue Tests in `srd_monk_slow_fall_commit_rules_test.dart` und `srd_monk_slow_fall_commit_storage_test.dart`, einschließlich Off-Turn-Reaktion, Mehrklasse, temporären TP, 0 TP, doppelte Nutzung, Neustart, Stale Revision und erzwungenem SQLite-Rollback.

## Noch offen

- Keine automatische Erkennung von Sturzstrecken oder Würfen aus der Erzählung; kein UI-Dialog für das ausdrückliche Reaktionsangebot. Eine spätere, getrennte UI-Aufgabe kann nur einen bestätigten Fall an den Controller weitergeben.
- Kein nachträglicher Effekt für bereits abgespeicherte Fallereignisse.
- Keine Datenbankmigration oder Versionsänderung. Alte JSONs bleiben kompatibel.
- Positive GitHub-CI auf **finalem PR-Head** ist Voraussetzung für Freigabe und Merge; reale Geräteabnahme und produktive Signierung bleiben getrennt.

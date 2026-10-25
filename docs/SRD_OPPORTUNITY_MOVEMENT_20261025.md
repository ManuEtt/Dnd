# Gelegenheitsreaktion: gespeicherte Bewegungsunterbrechung

Anforderung **RULE-COMBAT-OPPORTUNITY-ATTACKS**, weiterhin **partial**. SRD 5.2.1, *Playing the Game → Combat → Melee Attacks → Opportunity Attacks*, gedruckte Seite 15. [Amtliche PDF](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), Wizards of the Coast LLC, CC BY 4.0; [Namensnennung](../THIRD_PARTY_NOTICES.md). PDF am 25.10.2026 geprüft, SHA256 `8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87`.

Die Quelle erlaubt genau einen Nahkampfangriff mit Waffe oder Unarmed Strike als Reaktion unmittelbar vor dem Verlassen sichtbarer Reichweite. Disengage, Teleportation und Bewegung ohne eigene Bewegung/Aktion/Bonusaktion/Reaktion lösen ihn nicht aus. Dieses Paket speichert ausschließlich den davor nötigen bestätigten Unterbrechungspunkt; keine Ausweitung der zulässigen Auslöser aus PR #174.

## Akzeptanz

- Bestätigte vorherige/nachfolgende Entfernung und Reichweite, Sicht, Bewegungstyp, eindeutige tatsächlich angelegte SRD-Nahkampfwaffe oder Unarmed sowie ausdrückliche Spielerfreigabe. Keine Werte aus KI-Prosa. Nur aktiver, lebender Gegner im tatsächlich offenen Gegnersegment.
- Eindeutiges Angebot mit Ursprungsrevision und Runde. Keine Würfel, HP-, Ressourcen-, Aktionsbudget- oder Rundenänderung. Alte Spielstände ohne optionales Feld bleiben lesbar; manipulierte oder konkurrierende Pending-Zustände ablehnen.
- Snapshot, Ereignis und Revision in bestehender SQLite-Transaktion. Controller zeigt Änderungen erst nach Commit. Neustart, Export und Replay erhalten das Angebot. Doppelte oder veraltete Bestätigung überschreibt nichts.
- Abenteuerdialog beginnt ohne Fakten/Zustimmung. Abbrechen verändert nichts. Persistentes Panel zeigt Zustand und fehlende Angriffsausführung offen; ausdrücklicher Verzicht löscht ausschließlich das Angebot. Gegnerangriffe erst auf neue Eingabe fortsetzen. Alte Verzicht-Callbacks können kein neueres Angebot entscheiden.
- Offenes Angebot sperrt andere Controller-Mutationen vor Würfeln/Providerzugriff; Kampagnenwechsel, Export und bewusste Löschfunktionen bleiben verfügbar. Keine Freigabe für Story-Manipulation des Pending.

## Code und Tests

`models.dart`: optionales `PendingOpportunityAttack` und strikter Cross-Field-Import. `srd_opportunity_attack_rules.dart`: vorhandene reine Vorprüfung inklusive Ausschluss eines zweiten Angebots. `game_engine.dart`: Angebot/Verzicht, gemeinsame Commit-Sperre. `game_controller.dart`: Revision und zentrale Pending-Sperre. Abenteuer und `opportunity_movement_dialog.dart`: Benutzerentscheidung.

Regressionen: `opportunity_movement_test.dart`, `opportunity_movement_dialog_test.dart`, `opportunity_movement_ui_test.dart` plus vorhandene `srd_opportunity_attack_rules_test.dart`. Reale temporäre SQLite-Dateien für Neustart/Replay, zweite Schreiber und absichtlich scheiternde Event-Inserts; deterministische Zufallsquelle verbietet jede unerlaubte Würfelziehung. Kleine Displays, große Schrift, Tastatur, Dialogabbruch und überholte UI-Callbacks.

## Grenze und nächstes Paket

Keine automatische Positionsverfolgung oder ausgeführte Bewegung, keine Würfel-/Schadensauflösung, kein Reaktionsverbrauch, keine Unterbrechung des ersten bereits automatisch abgewickelten Gegnerangriffs. Angebot nur in tatsächlich offenen Gegnersegmenten, insbesondere zwischen bestätigten Mehrfachangriffen. Der normale Angriffsaktionspfad darf wegen Extra Attack/Light/Surge/automatischem Gegnerzug nicht unverändert für Reaktionen verwendet werden. Ein eigener Reaction-Pfad mit tatsächlicher Zugbindung für Sneak Attack ist das nächste Paket.

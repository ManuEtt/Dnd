# Chat A – Mehrfachmaterial und Inventarbindung (27.10.2026)

## Git und Koordination

- Basis: **offener** Chat-A-PR [#271](https://github.com/ManuEtt/Dnd/pull/271), HEAD `779137bbfeaf86242bd246918c53bdc757febd9f`; dieser neue Branch baut absichtlich auf dessen bereits geprüften Materialrezepten auf.
- Branch: `feat/chat-a/audited-material-inventory-20261027`.
- PR-Ziel: zunächst **PR-271-Branch**, nicht `main`. Die Reihenfolge der Integration muss erhalten bleiben. Nach Zusammenführung von #271 kann dieser Branch konfliktarm auf main umgestellt werden, jedoch nur mit erneuter CI.
- Keine Dateien von Chat B, C oder Charaktererstellung werden geändert.

## SRD-Provenienz und Anforderung

Wizards of the Coast LLC, **SRD 5.2.1**: *Spells / Components*, Beschreibungen *Astral Projection*, *Clone*, *Legend Lore* und *Secret Chest*. Lizenz CC BY 4.0; `THIRD_PARTY_NOTICES.md` unverändert.

- `RULE-SPELLS-MATERIAL-COMPONENTS`: weiterhin **partial**, keine vollständige SRD-Abdeckung.
- `RULE-SPELLS-SPELL-COMPONENTS`: weiterhin **partial**.

## IMPLEMENTIERT

- Reines Domain-Modul `srd_spell_audited_inventory_rules.dart`: stabile Rezeptpositions-ID zu bestehender, eindeutiger Inventar-Stapel-ID. Identität/Preis und benötigte Stückzahl müssen jeweils ausdrücklich bestätigt sein; keine Erkennung aus Namen, Beschreibungen oder KI-Erzählung.
- Alle benötigten Positionen müssen vorhanden und eindeutig zugeordnet sein. Ein Stapel darf nicht mehrfach verschiedenen Positionen zugewiesen werden. Fehlende oder doppelte Inventar-IDs, nicht vorhandene Stapel oder ungenügende Menge werden abgewiesen.
- Aus dem geprüften Rezept abgeleitete **exakte Stückzahlen**: Legend Lore benötigt vier Elfenbeinstreifen; Astral Projection benötigt jede seiner zwei Materialarten **pro bestätigtem Ziel**. Clone und Secret Chest benötigen jeweils ein Stück jeder Materialposition. Die Zielanzahl und Zielberechtigung müssen unabhängig bestätigt werden.
- Verbrauchbare Positionen (z. B. Clone-Diamant) werden als explizite ID/Menge zurückgegeben, nicht verbrauchbare Positionen (z. B. Clone-Gefäß und Secret-Chest-Truhen) bleiben bestehen. Ausgerüstete, verbrauchbare Stapel sind gesperrt.
- `SrdSpellInventoryRules.commitConfirmedCast` bindet für auditierte Zauber die Inventarprüfung verpflichtend ein; alte freie Verbrauchslisten und Sammelflags ohne gültige Bindungen reichen nicht. Für nicht auditierte Zauber bleibt die bisherige API kompatibel.
- Die bestehende immutable Slot-/Inventartransaktion und Snapshot-Stale-Prüfung bleiben der einzige Mechanismus für die tatsächliche Rückgabe geänderter Spielfiguren. Keine Teilmutationen bei Ablehnung.

## GETESTET

Neu: `app/test/srd_spell_audited_inventory_rules_test.dart`. Positiv/negativ für alle vier Rezepte: Mehrziel-Stückzahlen, vier Elfenbeinstreifen, fehlende/unbekannte/doppelte Zuordnungen, Inventarmengen, ausgerüstete Objekte, read-only Resolver und Slot-/JSON-/Replay-Invarianz am in einem Zug vorbereitbaren Secret Chest. Der tatsächliche CI-Status muss anhand des neuen PR-HEAD und der GitHub Actions nachgetragen werden.

## NICHT GETESTET / GRENZEN / BLOCKIERT

- Clone, Legend Lore und Astral Projection sind **mehrzügige Zauber** und werden im derzeitigen Standard-`SrdSpellPreflightRules` noch nicht als vollständiger Cast freigegeben; für sie ist die **reine** Inventarauflösung implementiert, keine End-to-End-Ausführung. Secret Chest kann als bestehender Single-Turn-Preflight-Probezauber den Ressourcencommit prüfen.
- Die Preis-/Identitäts-Bestätigungen sind fachlich manuelle Beweiseingaben; das bisherige InventoryItem-Modell hat keinen allgemein verifizierten Wert und keinen Beleg zu jeder Materialposition. Selbstbezeichnende Namen oder KI-Text genügen nicht.
- Keine UI-/Controller-Änderung, keine automatische Zielauswahl, keine neuen Speicherfelder, keine neue Journal-Schnittstelle, keine Migration (SQLite 2/JSON 1 unverändert).
- Ein GitHub-CI-Android-Build ist kein realer Gerätetest. Manuelle Android-Eingabe und historische Upgrades bleiben offen.

## NOCH NICHT IMPLEMENTIERT / nächster Schritt

Gesonderte Freigabe der langen Zauberzeiten, belegte Wert-/Identitätsprüfung pro Inventarposten, UI-Eingabe und Controller-/Repository-Grenzprüfung der auditieren Bindungen. Nach freigegebenem PR #271 und diesem Folgepaket die atomare Bestätigung der Materialpreise und des endgültigen Zaubereffekts ohne Doppelverbrauch integrieren.

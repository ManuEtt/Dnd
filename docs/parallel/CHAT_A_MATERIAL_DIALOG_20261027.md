# Chat A – Material-Inventardialog (27.10.2026)

## Status, Herkunft und Abhängigkeiten

- Projekt: Würfelraunen – Der lebendige Spielleiter
- Baseline: offener [PR #274](https://github.com/ManuEtt/Dnd/pull/274), HEAD `4d7b8c0107022d531d0c5950c09dcaff9b60e6cd`.
- #274 basiert auf dem ebenfalls offenen [PR #271](https://github.com/ManuEtt/Dnd/pull/271). Die Integrationsreihenfolge lautet: **#271 → #274 → Dialog-PR**, jeweils mit erneut geprüfter Main-Basis.
- Arbeitsbranch: `feat/chat-a/material-inventory-dialog-20261027`.
- Quelle: SRD 5.2.1, *Spells / Components* und Beschreibungen *Astral Projection*, *Clone*, *Legend Lore*, *Secret Chest*, Wizards of the Coast LLC, CC BY 4.0.

## IMPLEMENTIERT

- Neuer eigenständig verwendbarer, deutschsprachiger `SrdMaterialInventoryDialog` in `app/lib/ui/srd_material_inventory_dialog.dart`.
- Der Dialog liest vier auditierte Materialrezepte und bietet je Position einen Inventarstapel zur Auswahl. Er fordert je Materialposition die ausdrückliche Bestätigung von **Identität/Wert**, **vollständiger benötigter Menge** und bei Verbrauch **Reservierung des Verbrauchs**.
- Bei *Astral Projection* kann die Anzahl der bereits unabhängig bestätigten Ziele eingegeben werden. Zielberechtigung, Zustimmung und Maximalzahl sind **nicht** aus der Eingabe abgeleitet; sie müssen gesondert regelgeprüft werden.
- Beim Bestätigen wird der bisherige, reine Domain-Validator aufgerufen. Fehlende/doppelte Stapel, unzureichende Mengen und unbestätigte Angaben blockieren den Abschluss. Unbekannte Materialrezepte sind gesperrt.
- Bei erfolgreicher Prüfung gibt der Dialog ein unveränderliches `SrdMaterialInventoryChoice` mit `bindings`, `confirmations` und ggf. `confirmedTargetCount` zurück. Diese Angaben können künftig an SRD-Preflight und Inventar-Commit weitergeleitet werden.
- **Keine** unmittelbare Änderung von Inventar, Zauberplätzen, Konzentration, Effekten oder gespeichertem Kampagnenzustand.

## GETESTET / Abnahme

Neue Widget-Tests in `app/test/srd_material_inventory_dialog_test.dart` überprüfen ungeprüfte Positionen, Auswahl beider Truhen, doppelte Stapelauswahl, Clone-Verbrauchsbestätigung, unbekannte Rezeptdaten und keine Slot-/Inventaränderung bei Abbruch. CI-Status der endgültigen PR-SHA vor dem Merge auf GitHub verifizieren.

## NICHT GETESTET und Grenzen

- Bei Erstfassung des Checkpoints keine vollständige CI für diesen Dialog-Branch behauptet; Flutter-Analyse, Widget-Tests, Android-Debug und Alpha-APKs sind separat abzunehmen.
- Kein realer Android-Gerätetest, TalkBack-Geräteabnahme oder Test historischer Geräte-Upgrades.
- Der Dialog ist bewusst **noch nicht** im Haupt-Zauberablauf verdrahtet; eine autorisierte Regel-/Controller-Integration mit unveränderter Ereignis- und Speichertransaktion muss separat erfolgen. Es wird kein unbelegter Zauber ausgelöst.
- Keine verlässlichen Inventarwerte im aktuellen Modell; die Wahrheitsprüfung von Kosten und Gegenstandsidentität bleibt eine manuelle Bestätigung. Der Name eines Stapels gilt nicht als Nachweis.
- Die drei mehrzügigen Zauber *Astral Projection*, *Clone*, *Legend Lore* werden nicht dadurch als vollständiger Cast unterstützt; dieser Dialog prüft lediglich Materialien.

## BLOCKIERT / NOCH NICHT IMPLEMENTIERT / nächster Schritt

Die Controller-/SQLite-/UI-Orchestrierung berührt geteilte Integrationsgrenzen anderer Entwicklungs-Chats. Vor solchen Arbeiten die tatsächlichen Dateipfade und offenen PRs neu überprüfen und Chat-D-Integration koordinieren. `RULE-SPELLS-MATERIAL-COMPONENTS` bleibt `partial`; keine Gesamt-SRD-Abdeckung behaupten.

Als nächstes die Auswahl `SrdMaterialInventoryChoice` an genau einen autorisierten Single-Turn-Preflight-/Cast-Pfad anbinden (zuerst *Secret Chest*), mit Stale-Revision-, Wiederholungs-, Abbruch-, Ablehnungs- und JSON-/SQLite-Persistenztests; andere Zaubereffekte niemals aus UI-Eingaben oder Narration ableiten.

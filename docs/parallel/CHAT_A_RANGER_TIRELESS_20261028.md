# Chat A – SRD 5.2.1 Waldläufer: Unermüdlich (Tireless)

28.10.2026 · Branch: feat/srd-ranger-tireless-short-rest-20261028

## Quelle

SRD 5.2.1, Ranger Level 10: Tireless, CC BY 4.0.
https://www.dndbeyond.com/srd

## Umfang

- Nur **Decrease Exhaustion**: Bei Abschluss einer regelgerecht bestätigten Short Rest eine Erschöpfungsstufe weniger, falls vorhanden. Die Zahl der Stufen wird bei einer Rest-Aktion höchstens um eins reduziert.
- Eigenständige Regel SrdRangerTirelessRules (Klassenstufe statt Gesamtstufe; kein unbestätigter Mehrklassenbonus; totes Ziel ausgeschlossen).
- ClassResourceRules.afterShortRest verbindet die Regel mit der bestehenden generischen Ressourcenregeneration.
- GameEngine erlaubt ausdrücklich bestätigte kurze Rast **ohne Trefferwürfelverbrauch**, wenn nur dieser Ranger-Effekt ansteht, auch bei vollständigen HP und ohne übrige Trefferwürfel. Dokumentation im Ereignis (exhaustionBefore/After).
- RestRules.shortRest (mit tatsächlichem Hit-Dice-Verbrauch) verwendet bereits ClassResourceRules.afterShortRest und erhält den Effekt ohne zusätzliche Doppelbuchung.
- Exportierter Regelbaustein, Runtime-Teilstatus und Testpaket mit 21 Tests.

## Grenzen

- Die **Temporary Hit Points** Magic Action ist inzwischen als expliziter Spielbefehl mit 1W8 + Weisheitsmodifikator, Klassenstufe 10, Nutzungszähler, Ausdauergrenze und Kampfrunden-Aktionsverbrauch implementiert. **Nicht vollständig simuliert** sind Mehrakteur-Kampfrunden, Weltzeit und Unterbrechungen; der Auditstatus bleibt bis zur vollständigen Nachweisführung **partial**.
- Rest-Interruption, Weltzeit und tatsächliche Rastdauer werden nicht durch diese Änderung als vollständig simuliert behauptet.
- Neue Klasse-/Kampf-Branches (PR #336 und #339) verändern teilweise ebenfalls game_engine.dart. Konflikte vor Merge einzeln prüfen.
- Der PR bleibt Entwurf, bis CI-Formatierung, statische Analyse, Flutter-Test, Android-Build und Geräteabnahme bewertet sind.

## Tests

app/test/srd_ranger_tireless_rules_test.dart:
Stufe 9/10, Mehrklasse, HP/Temp-HP/Unveränderlichkeit, Tod, kein doppelt angewendeter Effekt, Wundheilung und Trefferwürfel, volle HP ohne Verbrauch, erschöpfter Würfelpool, andere Klasse und Long Rest.

Keine Schema-Migration und kein Eintrag aus einer freien KI-Erzählung erzeugt diese mechanische Wirkung.

## Fortsetzung: Tireless Temporary Hit Points

- Ausdrücklich unterstützter Spielbefehl: `Unermüdlich: temporäre Trefferpunkte` (wahlweise `... ersetzen`, wenn der Spieler bewusst einen bestehenden höheren Pool überschreiben möchte).
- Neue Regelgrenze: `SrdRangerTirelessRules.useTemporaryHitPoints`, `resourceKey=tirelessTemporaryHitPoints` in `ClassResourceRules`. Der bereits vorhandene Klassenressourcen-Speicher serialisiert Nutzungen in `spentClassResources`, Long Rest setzt sie zurück, Short Rest belässt sie. Alte Speicherstände bleiben kompatibel.
- Die eigentliche Magieaktion benötigt bestätigtes Wisdom, verfügbare Nutzung und regelkonformen Zustand. Im vorhandenen Einzelgegner-Kampf nur im eigenen Zug mit freier Action, nicht mit Bonusaktion oder bereits reserviertem Action Surge.
- Rohwürfel, Modifikator, tatsächlicher und vorheriger temporärer TP-Pool und verbleibende Nutzungen werden als `class.tirelessTemporaryHitPoints` dokumentiert. Zwei temporäre TP-Pools stapeln sich nicht.
- Zusätzliche zehn deterministische Tests für Ressource, Level, Mehrklasse, ungültiges Wisdom, Save-Roundtrip, Rast-Regeneration, Minimum, HP-Pool und Kampf-Aktionsökonomie. Neue Tests sind zum Commitzeitpunkt **noch nicht nachweislich grün**, Status nicht als `tested` deklarieren.

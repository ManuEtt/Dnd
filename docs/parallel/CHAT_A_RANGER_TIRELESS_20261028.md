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
- Exportierter Regelbaustein, Runtime-Teilstatus und Testpaket mit zehn Tests.

## Grenzen

- Die separate **Temporary Hit Points** Magic Action (1d8 + WIS, nutzungsbegrenzt) wurde bewusst nicht implementiert; Status **partial**, niemals 'computed' oder 'tested'.
- Rest-Interruption, Weltzeit und tatsächliche Rastdauer werden nicht durch diese Änderung als vollständig simuliert behauptet.
- Neue Klasse-/Kampf-Branches (PR #336 und #339) verändern teilweise ebenfalls game_engine.dart. Konflikte vor Merge einzeln prüfen.
- Der PR bleibt Entwurf, bis CI-Formatierung, statische Analyse, Flutter-Test, Android-Build und Geräteabnahme bewertet sind.

## Tests

app/test/srd_ranger_tireless_rules_test.dart:
Stufe 9/10, Mehrklasse, HP/Temp-HP/Unveränderlichkeit, Tod, kein doppelt angewendeter Effekt, Wundheilung und Trefferwürfel, volle HP ohne Verbrauch, erschöpfter Würfelpool, andere Klasse und Long Rest.

Keine Schema-Migration und kein Eintrag aus einer freien KI-Erzählung erzeugt diese mechanische Wirkung.

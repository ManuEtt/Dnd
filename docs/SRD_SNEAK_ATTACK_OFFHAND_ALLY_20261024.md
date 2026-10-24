# SRD 5.2.1: bestätigter Verbündeter beim Nebenhandangriff

Stand: 24.10.2026. Arbeitspaket [PR #160](https://github.com/ManuEtt/Dnd/pull/160).

**Stabile Anforderung:** `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1`, weiterhin `partial`.
**Quelle:** Wizards of the Coast, SRD 5.2.1, *Rogue / Sneak Attack*, S. 61–62, unter CC BY 4.0. Lizenz/Provenienz siehe `THIRD_PARTY_NOTICES.md`.

## Fehler und Ziel

Die bestehende Kampflogik erlaubt einen separat bestätigten Nebenhandangriff mit einer leichten zweiten Nahkampfwaffe. Sie bewertet bereits die tatsächliche `pendingRoll.weaponId` auf Finesse/Fernkampf, statt die Hauptwaffe zu verwenden. Allerdings konnten bisher sowohl `PendingRoll.fromJson` als auch `SneakAttackAllyRules.eligible` nur für `type='attack'` eine **manuell bestätigte Verbündetenquelle** aufnehmen. Dadurch blieb die regelkonforme alternative Quelle für zulässige Nebenhandwürfe ohne Vorteil unzugänglich.

## Implementierung

- `SneakAttackAllyRules.eligible` erlaubt zusätzlich `offhandAttack`, nur wenn die bestehende Angriffs-/Bonusaktion bereits korrekt vorbereitet ist: gleiche Kampagne, passender Ziel-/Wurfkontext, aktiver Held, kein verbrauchter Sneak Attack, vorgeprüfte leichte echte Nebenhandwaffe, `actionUsed`, `bonusActionUsed`, `lightAttackAvailable`, `attacksRemaining == 0`.
- Die Regel prüft ausdrücklich **die angreifende Nebenhandwaffe** über deren Inventar-ID. Ein Dolch in der Hauptwaffe macht eine Nebenhandaxt nicht finesse-fähig. Uneindeutige/fehlende oder entfernte Waffen erlauben keine Verbündetenfreigabe.
- Weiterhin beide ausdrücklich bestätigten Beobachtungen: Verbündeter innerhalb von 5 Fuß **des Ziels** und nicht `Incapacitated`; kein verbleibender Nachteil auf dem Wurf. Die Beobachtungen werden nicht aus Erzählung oder KI generiert.
- `PendingRoll.fromJson` akzeptiert dieselbe bestehende versionierte Bestätigung (Schema 1) jetzt für beide Waffenangriffstypen. Ein unbekannter Probetyp, unbestätigter Fakt, falsches Ziel/eine fremde Kampagne oder eine veraltete Probe wird weiterhin abgelehnt. Keine neue Migration und kein neues Eventformat.
- `GameEngine.confirmSneakAttackAlly`, `GameController`, UI-Dialog und Bestätigungs-/Entfernungsaktionen bleiben derselbe Pfad. Der gespeicherte Beleg wird in der Abenteueransicht auch bei `offhandAttack` angezeigt und kann vor dem Würfeln entfernt werden.
- Erst ein **bestätigter Treffer** löst zusätzlichen Schadenswurf aus; kritische Treffer verdoppeln die Schadenswürfel, ein Fehlschlag nicht. Haupt- und Nebenhand teilen die bereits vorhandene einmalige Nutzung des Sneak Attack pro Zug.
- `StoryRuleBoundary`, KI-Grenzen, SQLite 2, Kampagnen-JSON 1 und die App-Version 0.8.38+88 bleiben unverändert. Keine allgemeine Gelegenheitsangriff-/Positions- oder freie Bonusaktionsmechanik.

## Relevante Regressionen

- `app/test/sneak_attack_offhand_ally_test.dart`: Dolch ohne Vorteil mit bestätigtem Verbündeten, Nicht-Finesse-Gegenbeispiel, Nachteil, verbrauchter Zug, geänderte/ungültige Roll-/Ziel-/Kampagnenbindung, Entfernen, Miss, Krit, JSON-Import, Export, SQLite-Neustart und Stale-Revision.
- `app/test/sneak_attack_ally_ui_test.dart`: gleicher Bestätigungs-/Entfernungsdialog für tatsächlichen Nebenhandangriff, keine Freigabe für Nebenhandaxt und unveränderte Hauptwaffen-Widgets.
- `app/test/sneak_attack_ally_integration_test.dart` und `app/test/sneak_attack_weapon_context_test.dart`: bestehende Hauptwaffen- und Nebenhandregressionen bleiben Bestandteil des Gesamtchecks.

## Abnahme / Grenzen

GitHub-PR-Checks sind maßgeblich: [PR #160](https://github.com/ManuEtt/Dnd/pull/160/checks). Vorläuferläufe scheiterten zunächst an Dart-Formatierung und an **einer zu breiten Assertion für Alt-JSON-Inventarstats**; der zweite Fehler wurde auf einen überprüfbaren Vergleich der offenen Probe eingegrenzt. Der reguläre vollständige CI-Lauf auf dem danach korrigierten Code muss separat erfolgreich durchlaufen; alte grüne PR-#159-Nachweise belegen diesen Code nicht.

Für lokale Prüfung, falls Flutter/Dart vorhanden:

```bash
python3 scripts/verify_project.py
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py --json
python3 -m unittest discover -s scripts/tests -v
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/sneak_attack_offhand_ally_test.dart test/sneak_attack_ally_ui_test.dart test/sneak_attack_ally_integration_test.dart test/sneak_attack_weapon_context_test.dart
flutter test
flutter build apk --debug
cd android
bash ./gradlew :app:testDebugUnitTest --no-daemon
```

Echter Android-Gerätetest einschließlich Upgrade eines persönlichen Altspielstands, produktive Release-Signierung und vollständige SRD-Abdeckung stehen weiterhin aus. Offizielle amtliche Spielleitungs- und Positionsdaten dürfen nicht aus freien KI-Texten als bestätigt übernommen werden.

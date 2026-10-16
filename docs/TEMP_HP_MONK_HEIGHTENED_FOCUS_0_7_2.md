# Würfelraunen 0.7.2+42 – Temporäre TP und verstärkte Geduldige Verteidigung

**Regelquelle:** D&D SRD 5.2.1 (CC BY 4.0), Abschnitte "Temporary Hit Points" und "Monk / Heightened Focus". Siehe https://www.dndbeyond.com/srd und https://www.dndbeyond.com/sources/dnd/br-2024/playing-the-game.

## Ab dieser Version ausgeführt

- Mönche mit **mindestens zehn Mönch-Klassenstufen** erhalten durch die **mit einem Fokuspunkt verstärkte Geduldige Verteidigung** temporäre TP in Höhe **zweier Kampfkunstwürfel**. Der Würfeltyp richtet sich nach der Mönch-Klassenstufe. Auf Stufe 10 ist dies **2W8**, ab 11 **2W10**, ab 17 **2W12**.
- Würfe entstehen ausschließlich über `DiceEngine`, nicht über KI-Erzählungen. Ohne Würfeldienst oder verfügbaren Fokus wird die Aktion ohne Zustandsänderung abgewiesen. Die bereits vorhandene Bonusaktion für Rückzug/Ausweichen bleibt erhalten.
- `HeroCharacter.temporaryHitPoints` ist ein eigenes, optional gespeichertes Feld. Alte Schema-1-Spielstände laden mit 0. Es wird niemals auf die maximalen oder aktuellen Trefferpunkte addiert.
- Bereits vorhandene temporäre Trefferpunkte werden standardmäßig behalten, wenn sie höher sind; die reine `RulesEngine.grantTemporaryHitPoints` erlaubt ein bewusstes Ersetzen durch einen niedrigeren Vorrat. Die Kampf-UI bietet diese Wahl noch nicht ausdrücklich an.
- Schaden wird zuerst von temporären TP abgezogen. Nur der Rest erreicht normale Trefferpunkte und kann 0 TP, Todesrettungen oder massiven Schaden auslösen. Heilung erhöht temporäre TP nicht. Nach einer langen Rast verfallen diese Punkte, nach einer kurzen Rast nicht.
- Im Kampf werden gewürfelte temporäre TP, absorbierter Schaden, wirklicher TP-Verlust und verbleibende temporäre TP im Ereignisjournal protokolliert. Charakterbogen und Kampfanzeige zeigen den separaten Wert.
- Weiterhin **nicht** automatisiert: das Befördern eines verbündeten Wesens mit Schritt des Windes (Stufe 10), Selbstwiederherstellung, alle lageabhängigen Reaktionen und Kartenpositionen.

## Regression und CI

- `app/test/temporary_hit_points_test.dart`: Vorwärts-/Rückwärtskompatibilität, Überschreiben und Nichtstapeln, vollständige und partielle Schadensaufnahme, massive Schäden, Heilung und Rast, Mehrklassen-Mönch, Würfeln, Ressourcenverbrauch, Eventjournal und Widget.
- Bekannte Lint-Warnung in `app/lib/domain/monk_flurry_rules.dart` korrigiert (`unnecessary_non_null_assertion` im Commit `73c5bfe5`).
- `app/pubspec.yaml` auf `0.7.2+42` gesetzt, bestehendes Schema bleibt Version 1.

Vor Veröffentlichung weiterhin `flutter analyze`, `flutter test` und `flutter build apk --debug` in der CI ausführen. Die lokal ausgeführten Python-Projekttests sind kein Ersatz für die Flutter-Tests.

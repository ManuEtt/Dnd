# SRD 5.2.1 – Zauberdauer-Metadaten (Chat A)

**Quelle:** Wizards of the Coast, *System Reference Document 5.2.1*, Abschnitt *Spells / Duration*, gedruckte Seite 106; CC BY 4.0, https://www.dndbeyond.com/srd. Lizenzhinweis: `THIRD_PARTY_NOTICES.md`.

**Baseline:** `main` bei Beginn `5c1499a9342449050bb946542659b221ac2653da`; offener PR #176 betrifft Gelegenheitsangriffe und gemeinsam genutzte Zustandsdateien.

## Problem

`app/assets/srd_5_2_1_spells.json` enthält unterschiedliche Dauerformen. Bisher fehlte eine eigenständige, reine Regelkomponente, die diese Metadaten konservativ voneinander trennt. Ein einfacher Zeitpunkt darf nicht für spezielle, konzentrationsgebundene oder auslöserabhängige Wirkungen erfunden werden.

## Umsetzung und Akzeptanz

- `app/lib/domain/srd_spell_duration_rules.dart` und Export in `app/lib/rules/rules_api.dart`.
- Einordnung in augenblicklich, feste Zeitdauer, begrenzte Dauer, Konzentration, bis zur Bannung oder bis Bannung/Auslösung.
- Numerische Einheiten verbleiben unverändert als Runde/Minute/Stunde/Tag; keine automatische Umrechnung in Spielzugabläufe.
- Fehlende, unerwartete oder widersprüchliche Dauerangaben scheitern geschlossen; `Special` bleibt explizit ohne automatische Dauerbewertung.
- Keine Zustandsänderung, keine Speicher-/JSON-Migration, keine KI-Abhängigkeit.
- `app/test/srd_spell_duration_rules_test.dart`: gültige und ungültige Beispiele, Konzentrationskonflikte, lange/kurze Zeitspannen, katalogweite Klassifikation.

## Prüfung und Grenzen

Das tatsächliche Zauber-Katalog-JSON enthält 339 Einträge. Ein unabhängiger Metadatencheck in der aktiven Sitzung klassifizierte 338 Angaben und ließ genau `Creation: Special` offen; keine Inkonsistenzen in den Katalog-Zeichenketten festgestellt. **Diese Prüfung ist kein Dart- oder Flutter-Test.** Flutter-Analyse, Dart-Formatierung, vollständige Tests, Android-Build und echte Geräteprüfung benötigen gesonderte Nachweise auf dem finalen PR-Commit.

Die `docs/srd_5_2_1_requirements.json`- und `docs/srd_5_2_1_entities.json`-Register bleiben unverändert: ein Klassifikator ist keine verifizierte komplette Zauberwirkung, und die amtliche Spell-Descriptions-Inventur bleibt offen. Keine zusätzlichen `tested`-Einträge oder globale Fertigstellungsprozente.

**Nächster unabhängiger Schritt:** einen explizit bestätigten Spielzeit-/Rundenzähler über einen separaten Integrationsvertrag für eine ausgewählte zeitbegrenzte Zauberwirkung anbinden, inklusive Neustart- und Grenzzeit-Tests. Vorher keine automatische Ablaufbuchung aus Metadaten zulassen.

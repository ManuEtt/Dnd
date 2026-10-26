# Chat A – Ritualzauber-SRD-Preflight, 25.10.2026

- **Baseline:** Main `af70a48c84d83c133ced4200be04ca81a91abf1b` beim Branch-Anlegen.
- **Branch:** `feat/chat-a/ritual-casting-preflight-20261025`.
- **Eigene Dateien:** `app/lib/domain/srd_ritual_casting_rules.dart`, `app/test/srd_ritual_casting_rules_test.dart`, `docs/SRD_RITUAL_CASTING_PREFLIGHT_20261025.md`, dieser Checkpoint. Register-Eintrag `RULE-SPELLS-RITUAL-CASTING` nur `partial`.
- **Vorherige offene Chat-A-PRs:** #180 (Zauberdauern), #184 (Klassen-Zauberwerte), #188 (Zauberangriff). Alle drei bei letzter Liveprüfung auf ihren Heads GitHub-Actions-grün; nicht in diesem Branch integriert.

## IMPLEMENTIERT

Konservative, zustandsfreie Ritual-Vorprüfung: Ritual-Tag, 29 Katalogrituale, Klassen-/Vorbereitungsnachweis, 10 Minuten Extra-Zeit, Zeit- und Konzentrationsbestätigung, Ziel/V-S-M, Rüstung/Aktionsfähigkeit, Snapshot gegen veraltete Charaktere; ohne Zauberplatzkosten.

## GETESTET

Testfälle geschrieben. Die tatsächlichen GitHub-Actions-Ergebnisse werden erst nach vollständig ausgeführter CI auf dem letzten PR-HEAD bestätigt.

## NICHT GETESTET

Android-Gerät/Upgrade, wirkliche Zeitverfolgung, Start/Unterbrechung/Ende eines Rituals, Materialabbuchung und tatsächliche Wirkung.

## BLOCKIERT

Keine SDKs im aktuellen lokalen Runtime; GitHub-CI übernimmt Flutter-/APK-Prüfung. Gemeinsame README/CODEX_CHECKPOINT-Zeilen mit parallelen Chats vor Integration konfliktfrei abgleichen.

## NOCH NICHT IMPLEMENTIERT / NÄCHSTER SCHRITT

Eigene ritualisierte Controller-Aktion mit autoritativem Zeitfortschritt, Unterbrechung, Material-/Konzentrationsprüfung, sauberem Abbruch und idempotenter Journal-/Persistenztransaktion; erst nach grüner PR-CI und Koordination von Main/anderen Chat-A-PRs. Keine global vollständige SRD-Implementierung behaupten.

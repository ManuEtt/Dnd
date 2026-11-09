# Integration: zwei vollständig geprüfte Qualitätskorrekturen (08.11.2026)

## Quelle und Belege

- Integrationsbasis `main`: `404e9a5fc9b7d1c231b7bdd52c61319d4eb57752`. Android-Main-CI [#42518852945](https://github.com/ManuEtt/Dnd/actions/runs/42518852945): `completed/success`.
- Ursprüngliche Main-Basis beider Fachbranches: `8bfaa22cded60e7731f5a3dc95684949bad49276`.
- [PR #649](https://github.com/ManuEtt/Dnd/pull/649): `fix/chat-d/raw-dart-uri-boundary-20261108`, Quell-HEAD `5c8b670ef2f8af881b8a257895a943089af9af49`. [Vollständige Quell-CI](https://github.com/ManuEtt/Dnd/actions/runs/42516773832) `completed/success`: sechs Jobs.
- [PR #650](https://github.com/ManuEtt/Dnd/pull/650): `fix/chat-d/source-zip-safe-modes-20261108`, Quell-HEAD `e729ff0f570ca1a438a59bbb8ef0742e4aba5f63`. [Vollständige Quell-CI](https://github.com/ManuEtt/Dnd/actions/runs/42518519859) `completed/success`: sechs Jobs.
- Integrationsbranch `fix/chat-d/integrate-reviewed-quality-20261108`, eigener Integrations-PR gegen `main`; beide Quell-Heads bleiben als zusätzliche Commit-Eltern erhalten. Keine Rewrites oder unkontrollierte Branchlöschung.

## Integrierte Fachänderungen und Tests

1. `scripts/check_domain_boundaries.py` und `scripts/tests/test_domain_boundaries.py`: Raw-Dart-URI-Präfixe und bedingte Imports/Exports/Parts gegen verbotene Modulabhängigkeiten absichern, inklusive positiver und negativer Tests; Code und Tests aus PR #649 unverändert.
2. `scripts/package_project.py` und `scripts/tests/test_package_project.py`: ZIP-Metadaten übernehmen nur normale Unix-rwx-Bits, nicht Setuid/Setgid/Sticky; Testfall für 4755/2750/1755, gewöhnliche Ausführbarkeit und identischen Dateiinhalt; Code und Tests aus PR #650 unverändert.

Die vier Python-Fachdateien waren zwischen gemeinsamer ursprünglicher Basis und aktuellem `main` blobidentisch. Das vermeidet die Übernahme konkurrierender Fachänderungen. Die beiden separat vollständig grünen CIs sind **kein Ersatz für eine kombinierte CI**.

## Dokumentationskonflikte verlustfrei aufgelöst

- Die vollständige neuere README von `main` mit sämtlichen Nachträgen aus dem integrierten UI-Paket #648 bleibt unverändert als Bytepräfix erhalten.
- Die vorhandenen neutralen README-Fachnachträge aus #649 und #650 sind ausschließlich *am absoluten Dateiende* und in ihrer ursprünglichen Reihenfolge angefügt. Kein Chat-Label in README-Überschriften oder redaktionellen Texten.
- `docs/CODEX_CHECKPOINT.md` und `docs/parallel/CHAT_D_CHECKPOINT.md` übernehmen jeweils sämtliche Main-Inhalte und fügen danach die beiden vollständigen Fachnachträge an. Keine früheren Fortschritte sind entfernt.

## Sicherheit, Migration und Freigabekriterien

- Keine Änderung an Flutter-/Backend-Produktcode, D&D-Regeln, Story, UI, App-/Build-Version, SQLite-/JSON-Schemas, Spielständen oder Nutzerbackups. Keine Migration.
- **GETESTET:** Beide Quell-CIs einschließlich Python, Backend, Dart/Flutter, Android-Debug und drei ABI-APKs sowie Release-Zusammenstellung; erfolgreiche aktuelle Main-CI; Quellen-/Dokumentationsvergleich und Fachdatei-SHA-Prüfung.
- **NICHT GETESTET:** Gemeinsame Integration auf dem endgültigen Integrationscommit, weitere Änderungen parallel zu diesem HEAD, echtes Android-Gerät oder Upgrade-Installation.
- **BLOCKIERT:** Bis die gemeinsame Integrations-CI erfolgreich ist, bleibt der PR im Draft. Vor jedem Merge Main-HEAD, Quell-Heads, andere offene PRs und alle sechs CI-Jobs erneut prüfen.
- **NÄCHSTER SCHRITT:** Auf finalem Integrations-HEAD alle CI-Jobs erfolgreich abnehmen, dann konfliktfrei regulär nach `main` übernehmen und die neue Main-CI kontrollieren.

## Review- und PR-Nachtrag

Der konfliktfreie, historienerhaltende Integrationsbranch ist unter [PR #652](https://github.com/ManuEtt/Dnd/pull/652) gegen `main` zur Prüfung veröffentlicht. Der Fach-Integrationscommit `c9cda978ea5cc5dc3d6526d436b909769dc593f1` besitzt die Main-Basis und beide originalen Quell-Heads als drei Eltern. PR bleibt als Draft geöffnet, bis **der abschließende dokumentierte Integrations-HEAD** vollständig sechsfach grüne GitHub-CI nachweist. Alte PRs und Branches werden nicht eigenmächtig geschlossen oder gelöscht.

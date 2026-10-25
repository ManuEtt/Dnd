# CHAT A – REGELWERK-CHECKPOINT

- Datum: 25.10.2026
- Ausgangs-`main`: `5c1499a9342449050bb946542659b221ac2653da`
- Arbeitsbranch: `feat/chat-a/spell-duration-classification-20261025`
- Letzter reiner Code-/Test-/API-Commit vor Dokumentation: `00bec4b970058bacc8837d9f3e7333ae8f36e605`
- PR: bei Anlage des Checkpoints noch zu erstellen; verbindlicher PR-HEAD steht anschließend im Pull Request.
- Überschneidungen: PR #176 berührt Kampf, Modelle, Controller und außerdem README/CODEX_CHECKPOINT. Keine Änderungen von Chat A an Kampf-/Speichermodellen; Chat D konsolidiert gemeinsame Dokumentation beim Merge.

## IMPLEMENTIERT

Reine SRD-5.2.1-Dauerklassifikation und fünf Dart-Testgruppen, exportiert über `app/lib/rules/rules_api.dart`. Geänderte Quell- und Testdateien:

- `app/lib/domain/srd_spell_duration_rules.dart` (neu)
- `app/test/srd_spell_duration_rules_test.dart` (neu)
- `app/lib/rules/rules_api.dart` (Export)
- `docs/SRD_SPELL_DURATION_CLASSIFICATION_20261025.md` (fachliche Beschreibung)
- `docs/parallel/CHAT_A_CHECKPOINT.md`, `docs/CODEX_CHECKPOINT.md`, `README.md` (Dokumentation)

## GETESTET

Vorprüfung des tatsächlichen JSON-Zauberkatalogs durch gesonderte Metadaten-Auswertung: 338 von 339 Dauerangaben klassifizierbar; `Creation: Special` bewusst nicht klassifiziert, 0 widersprüchliche Katalogangaben. Kein ausführbarer Dart-Test in dieser Umgebung.

## NICHT GETESTET / BLOCKIERT

Flutter/Dart-SDK und Android-SDK lokal nicht vorhanden. Dart-Formatierung, Flutter-Analyse, Flutter-Tests, APK, vollständige Python-/Backend-/CI-Kette und Geräteprüfung nur nach explizitem erfolgreichem Actions-Nachweis als bestanden bezeichnen. Keine persistenten Daten und keine Migration geändert.

## NOCH NICHT IMPLEMENTIERT

Automatischer Zeitfortschritt, Zauber-Endereignisse, Konditionen aus Einzelzauberbeschreibungen, Speicherung von Dauer-/Ablaufereignissen und offizielle Vollverifikation der 339 Zauberspezifikationen. SRD-Inventurlücke bleibt bestehen.

## NÄCHSTER SCHRITT

Zeitablauf einer einzigen ausdrücklich bestätigten, festen Zauberwirkung an autorisierten Zustand anbinden, mit Grenzwert-, Doppelereignis-, Revisions-, Neustart- und SQLite-Tests; nicht beginnen, solange das Integrationsmodul in einem fremden PR belegt ist.

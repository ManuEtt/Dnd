# CHAT C – HUD-Barrierefreiheit

**Datum:** 25.10.2026 (Europe/Berlin)  
**Ausgangs-main:** `97a06118f17d71cc77be2cb15a2fc9a53db20ee0`  
**Neuester Main-Abgleich:** `af70a48c84d83c133ced4200be04ca81a91abf1b` (Chat-D-PR #186; ohne Überschreiben anderer Module)  
**Letzter nachgezogener main:** `713b8cc2831f9d8039ef4e6ebf37c10682aec675` (enthält Chat D PR #183 mit APK-ZIP-Validierung)  
**Vorheriger Main-Abgleich:** `45bea9c2a897275583bdbe32ed50afde5d0a76b0`  
**Branch:** `feat/chat-c/accessible-status-hud-20261025`  
**PR:** [#185](https://github.com/ManuEtt/Dnd/pull/185) (offen).  
**Code-/Testcommit:** `ada88fa8c11f6c79df13a1872a52755f7a7f90ce` (vor dem Dokumentationsmerge)

## Problem

`FantasyAdventureStatusHud` erzwingt bei schmalen Fenstern auch bei 200 % Systemschrift zwei Statusspalten. Werte werden in `FittedBox` geschrumpft und semantisch nur als TP/RK/Tempo/EP benannt. Fortschrittsbalken tragen teils unvollständige Screenreader-Labels.

## Akzeptanzkriterien

- Bei 320/360 dp und 200 % Systemschrift stehen die vier Karten untereinander, jede enthält den unverfälschten Wert; keine RenderFlex-Overflows.
- Bekannte Trefferpunkte, RK, Tempo und Erfahrung werden mit vollem deutschen Statusnamen gelesen.
- Unbekannte Werte bleiben unbekannt, auch in der Semantik; keine erfundenen XP-Prozente.
- Prozentanzeigen enthalten nur aus bereits bestätigtem Zustand berechnete Werte.
- Keine neuen Aktionen, keine Änderungen an Kampagne, Regelengine, Speicherformat oder Nutzerdaten.
- Positiver und negativer Widgettest sind vorhanden; Format, Analyse und Tests auf dem finalen Commit prüfen.

## IMPLEMENTIERT

- `app/lib/ui/fantasy_adventure_hud.dart`: Layoutsteuerung über Textskalierung und Breite; kein `FittedBox` für Statuszahlen; sprechende Semantik je Metrik/Prozentbalken.
- `app/test/fantasy_adventure_hud_test.dart`: positive 320-/360-dp-Tests bei 200 % inklusive Kartenanordnung, vollständigen Semantik-Labels und fehlender visueller Textverkleinerung; negativer Test für unbestätigte Werte.
- Keine Änderungen von Dateien aus offenen Code-PRs #178–#184; die globalen README-/Checkpoint-Sektionen müssen bei ihrer späteren Integration behutsam zusammengeführt werden.

## GETESTET

Die erste Actions-CI brach beim Dart-Formatcheck in der neuen Widgettestdatei ab; vorherige Python-, Backend- und Architekturprüfungen waren erfolgreich. Die kanonische Dart-3.9-Formatierung wurde durch einen temporären GitHub-Workflow ermittelt und unverändert übernommen. Der Diagnose-Workflow wurde wieder entfernt. Auf dem formatierten Commit der aktuelle [Workflow #40221062928](https://github.com/ManuEtt/Dnd/actions/runs/40221062928): Python-/Backend-, Architektur-/SRD-, Format- und Analyse-Schritte nachweislich erfolgreich. Der vollständige Abschluss ist getrennt zu prüfen.

## Nachgewiesene Regression und Korrektur

[CI #40221062928](https://github.com/ManuEtt/Dnd/actions/runs/40221062928): 1.585 Flutter-Tests bestanden, drei neue Tests zunächst wegen nicht rechtzeitig geschlossener Semantik-Handles fehlgeschlagen. Codeänderung nicht erforderlich. Im folgenden Lauf #40221632170 bestanden die beiden positiven HUD-Tests; ein negativer Test war wegen doppelter Semantik-Handle-Freigabe noch rot. Diese doppelte Freigabe ist im Commit `410e994a42562071f706785a71b47299a6268e25` beseitigt. Die vollständige CI des nachgezogenen Main-/Dokumentationsstands steht noch aus. Keine falsche Erfolgsbehauptung.

## NICHT GETESTET

Finale Testsuite und Android-APKs für den endgültigen Dokumentations-/Main-Merge-Commit; echte Android-Installation, TalkBack-Geräteabnahme, Produktionssignatur.

## BLOCKIERT

Kein lokales Flutter-/Dart-SDK. Prüfnachweis über GitHub Actions. Parallel gepflegte README-/Checkpoint-Abschnitte sind nicht automatisch konfliktfrei mergebar.

## NOCH NICHT IMPLEMENTIERT

Keine Datenmigration, keine SRD-Änderung, keine Persistenzänderung. `0.8.40+90`, SQLite 2 und JSON 1 bleiben bestehen.

## NÄCHSTER SCHRITT

Eigenständige Questboard-Barrierefreiheitsprüfung für 320 dp/200 %: Labels sollen ohne Abschneiden lesbar und für Screenreader vollständig sein, positiver und negativer Widgettest, keine Quest-/Speichermutation.

## Erfolgreiche Abnahme und erneute Integration

- **Geprüfter HUD-/Main-Abgleich:** `91d007120e3a1a7b4beea9e91a7e8cffb2d831d8` – [GitHub Actions #40222374831](https://github.com/ManuEtt/Dnd/actions/runs/40222374831) `completed/success`, einschließlich aller drei HUD-Regressionstests, Flutter-Gesamtsuite, Python-/Backend-Prüfungen, nativer Android-Tests, Debug-APK, kleiner Alpha-APKs und Quell-Checkpoint.
- **Neue Main-Integration:** Chat-D-PR #186 bis `af70a48c84d83c133ced4200be04ca81a91abf1b` übernommen; nur README/Checkpoint dokumentationsseitig kombiniert. CI auf dem dadurch neu entstandenen Merge-Commit getrennt kontrollieren.
- **Nicht getestet:** reales Smartphone mit TalkBack, reguläre Play-Store-Signierung/Veröffentlichung.

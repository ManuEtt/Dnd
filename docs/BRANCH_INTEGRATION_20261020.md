# Historische Branches – Integrationsabgleich vom 20.10.2026

**Referenz:** `main` bei Beginn des Abgleichs: `4369cf15371aace5f74c5c1a6e43c1809781a78a`.

## Sicher integriert

- `feature/xp-level-progression-20261019` (`a4a4bec1a449259b1edc78536ca006ef3a6ec8dd`): über [PR #35](https://github.com/ManuEtt/Dnd/pull/35) als eigener Domain-Baustein gemergt. Die integrierte Version schützt unbekannte historische XP; neue Regressionstests prüfen SRD-Schwellen und einmalige Vergabe.
- Die getypte Ausrüstung aus `fix/equipment-import-attributes-20261019` wurde schon vor diesem Abgleich durch [PR #13](https://github.com/ManuEtt/Dnd/pull/13) funktional übernommen. Die alten Dateien dürfen **nicht** über die neueren Main-Implementierungen kopiert werden.

## Weitere neun historische Entwicklungsbranches

| Branch (Stand beim Abgleich) | Sachstand | Weiteres Vorgehen |
|---|---|---|
| `docs/merged-character-branches-20261019` (`f7023926b122a0286b4f02c8829875b50b6ca527`) | Alte Integrationsnotizen; Main-Dokumentation inzwischen fortgeschrieben | Nicht überschreiben; als Historie behalten |
| `feat/complete-graphics-ui-20261019` (`a94a3a61749917f312044d9109df225aa79948cd`) | Alte Bild-UI, eigener Importer und Widgettests; aktuelle Main-Implementierung verwendet andere APIs | Alte Tests nur nach Portierung übernehmen |
| `feature/complete-fantasy-artwork-ui-20261019` (`7baea4f91c03d8fbaa1f08c87ae4c359fb1d77a8`) | Asset-Importer und Porträt-Picker teilweise bytegleich mit Main; weitere Dateiänderungen wurden weiterentwickelt | Kein Rückmerge veralteter UI-/Workflow-Dateien |
| `feature/fantasy-portraits-and-ui-20261019` (`3f4c45838c7460352ed57def9d89235de8c51aa8`) | Früherer Grafik-PR #14 gemergt; danach abweichende Navigation und Versionsangaben | Nachfolgende Änderungen vor Archivierung prüfen |
| `feature/fantasy-rune-main-navigation-20261019` (`a1aaf75818dffd09579dd648f4a3f1fba81714bb`) | Neuere Runennavigation aus PR #31 in Main | Visuellen Regressionstest vor Schließen alter Branch-Arbeit |
| `feature/moonlit-scenery-20261019` (`66d530a3c75564e6465973bdf65209f4afe364c2`) | Nachfolger PR #32 gemergt, ältere Shaderänderungen weichen ab | Visuellen Vergleich sicherstellen |
| `feature/primary-class-level-up-20261019` (`8ee18d04a5ba7ab820eaca72529295a8e81c6586`) | PR #10 durch konsolidierten SRD-Aufstieg/PR #11/#13/#19 ersetzt; alter Dialog nicht mehr aktiv | Fehlende Testfälle gezielt auf neue `SrdClassLevelUpRules` übertragen |
| `fix/equipment-import-attributes-20261019` (`ff764e193c98c73547fe8ad5ce9fafe46772ac9b`) | Hauptfunktion und mehrere Tests in Main über #13 | Kein direkter Rückmerge, vollständigen Regressionstest durchführen |
| `fix/fantasy-ui-responsive-20261019` (`22de1096d57ba9cb5f530b652d783ae3b41bd4f6`) | PR #30 nicht direkt gemergt; Main hat neuere Mobile-UI über #29 und #31 | Test bei 320/360/400 dp durchführen |

**Wichtig:** Eine Funktion auf Main ist nicht dasselbe wie die originale Git-Historie eines Branches im Main-Verlauf. Die oben als ersetzt gekennzeichneten Branches bleiben daher bestehen, bis der Abgleich abgeschlossen, ihre einzigartigen Tests übernommen und die jeweiligen HEADs gesichert sind.

## Validierung vor weiteren Merges

1. `flutter analyze`, `flutter test` und APK-Build gegen den aktuellen Main-/Integrationsstand ausführen.
2. Bei Grafik-Branches Original-WebP-Dateien und Fallback-Widgets getrennt prüfen. Der Importer allein beweist nicht, dass die binären Dateien tatsächlich vorhanden sind.
3. Klassenaufstieg, Zweitklasse und unbekannte XP mit echten gespeicherten Charakteren abgleichen.
4. Erst danach etwaige alte Branches mit unveränderlichem SHA archivieren; keine Force-Pushes und keine automatischen Löschungen.

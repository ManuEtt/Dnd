# Chat A – SRD-5.2.1-Klassenmerkmale: automatische Stufe-20-Effekte

**Stand:** 26.10.2026. Basis `main` `67f146e690306b13d490bd8e7fd5636bb187c77e`.
**Scope:** ausschließlich zwei deterministische, auswahlfreie Klassenstufe-20-Effekte; **keine Behauptung einer vollständigen 282-Merkmale-Automatik**.

## Quelle und Anforderungen

Amtliche Quelle: [System Reference Document 5.2.1](https://www.dndbeyond.com/srd), Wizards of the Coast LLC, **CC BY 4.0**.
Im englischen PDF: Barbarian, *Level 20: Primal Champion*, Druckseite 30 (PDF-Seite 30); Monk, *Level 20: Body and Mind*, Druckseite 52 (PDF-Seite 52).

- `CLASS-BARBAR-20-BASE-PRIMAL-CHAMPION-0`: Stärke und Konstitution jeweils +4 bis maximal 25.
- `CLASS-M-NCH-20-BASE-BODY-AND-MIND-0`: Geschicklichkeit und Weisheit jeweils +4 bis maximal 25.

## IMPLEMENTIERT

- `app/lib/domain/srd_class_level_up.dart`: Im bestätigten Stufenaufstieg wird ausschließlich bei **Klassenstufe** 20 die automatische Attributsänderung berechnet; kein Auslösen bei bloßer **Gesamtstufe** 20 durch Multiclassing.
- Obergrenze 25; Attribute mit bereits höherem bestätigten Wert werden nicht herabgesetzt. Unbestätigte für das Merkmal nötige Attribute werden abgelehnt, statt geraten.
- Barbarischer Konstitutionsmodifikator wird für alle 20 Stufen auf maximale und aktuelle Trefferpunkte angerechnet (zusätzlich zu dem normalen Stufentrefferpunktgewinn); derselbe bereits bestätigte Spielstand kann einen Vorschlag nicht doppelt einspielen.
- Freigeschaltete Merkmale bleiben im Klassenkatalog; keine Mutation des Feldes `HeroCharacter.features` als Ersatz für die Regelwirkung.
- `app/lib/ui/srd_class_level_up_dialog.dart` weist die unvermeidlichen automatischen Attribute ausdrücklich **vor** dem Speichern in der Stufenvorschau aus.
- `app/lib/domain/srd_class_feature_catalog.dart` kennzeichnet nur diese zwei neu tatsächlich mechanisierten Level-20-Einträge zusätzlich als `automatic`.

## TESTS HINZUGEFÜGT (CI erst auf finalem Commit bewerten)

- `app/test/srd_class_level_up_test.dart`: Basisschritte für Barbar/Mönch, Konstitutions-TP, Serialisierungs-Roundtrip, unveränderter manueller Merkmalstext, Maximalwert 25, bereits höhere Attribute, Zweitklasse und fremde Klassen, fehlende Attributbestätigung, Replay-Sperre.
- `app/test/ui_srd_class_level_up_test.dart`: Vorschau vor Save und Übernahme in Charakterbogen.

## NICHT GETESTET / BLOCKIERT

Flutter/Dart/Android-SDK stehen in dieser direkten Connector-Umgebung nicht lokal zur Verfügung; daher **kein lokaler Dart-Format-, Flutter-Analyse-, Widget-, Android-Build- oder Gerätetest**. Für endgültige CI-Freigabe auf GitHub Actions den letzten Branch-/PR-Head und Build-Artefakte prüfen.

## NOCH NICHT IMPLEMENTIERT

Die anderen **280** katalogisierten Klassenfreischaltungen sind durch dieses Paket nicht neu vollständig automatisiert. Ihre bereits vorhandenen Einzelregeln bleiben erhalten; ungetestete Klassenentscheidungen, Ressourcen, Situationsbedingungen, Bonusaktionen, Unterklassen, Zauber, Ruhe-/Wiederaufladung und persistente Trigger sind einzeln gegen SRD und Tests abzugleichen. Kein Feat, Unterklasseneffekt und keine KI-Antwort wird aus bloßem Katalogeintrag automatisch als ausgeführte Regel gewertet.

**Nächster Arbeitsschritt:** für jede der verbleibenden Anforderungen ein konkretes, testbares Trigger-/Effect-/Choice-/Persistence-Mapping anlegen und einen repräsentativen vertikalen Funktionspfad bis UI + bestätigtem Spielstand implementieren. Nicht automatisch mergen oder fremde Branches löschen.

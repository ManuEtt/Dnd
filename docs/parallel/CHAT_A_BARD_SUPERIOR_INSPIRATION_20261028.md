# Chat A – SRD 5.2.1: Barde 18 / Überlegene Inspiration

Datum: 28.10.2026. Arbeitsbranch: feat/srd-bard-superior-inspiration-20261028.

## Quelle und Anforderung

Offizielles SRD 5.2.1, Klassen / Barde / Superior Inspiration, veröffentlicht unter CC BY 4.0: https://www.dndbeyond.com/srd. Anforderungs-ID: CLASS-BARDE-18-BASE-SUPERIOR-INSPIRATION-0.

## Mechanische Umsetzung

- Bei einem bestätigten Initiativewurf regeneriert Barde ab Klassenstufe 18 zuvor verbrauchte Barden-Inspiration, bis mindestens zwei nutzbare Einsätze vorhanden sind. Kein Überschreiten des bestätigten Ressourcenmaximums. Unbestätigtes Charisma, Manipulation an Nutzungszählern oder unreine Erzählungsdaten lösen keine Gutschrift aus.
- Deterministische, read-only Eingabe plus unveränderliche Kopie des Helden in app/lib/domain/srd_bard_superior_inspiration_rules.dart.
- Verknüpft mit allen drei bereits existierenden Kampfstart-Pfaden in app/lib/domain/game_engine.dart: angenommenes KI-Kampfangebot, Rabenwacht-Skelettwächter, Waldschrein-Dornenwächter. Keine Ausführung je Folgerunde.
- Ereignisse kennzeichnen die Anzahl unter bardicInspirationRecoveredAtInitiative. Bestehende Mönch-Perfekter-Fokus-Funktion bleibt erhalten; keine Migrations-/JSON-Schemaänderung.
- app/test/srd_bard_superior_inspiration_rules_test.dart umfasst 10 Testfälle für Level 17/18, Mehrklasse, 0/1/2 verfügbare Nutzungen, niedrige bestätigte maximale Ressource, fehlende/manipulierte Eingaben, drei Kampfstarts und Save-Roundtrip.
- app/lib/domain/srd_class_automation.dart, app/lib/domain/srd_class_feature_catalog.dart, app/lib/rules/rules_api.dart und docs/srd_5_2_1_requirements.json für das eindeutige Merkmal aktualisiert.

## Status und Grenzen

IMPLEMENTIERT: Produktionscode und Tests im Branch.

NICHT GETESTET: lokale Dart-/Flutter-Testläufe (SDK hier nicht installiert), vollständige finale CI, Android-Build und reale Geräteabnahme. Bis Nachweis bleibt das Merkmal in der Matrix bewusst partial.

OFFEN: Freischaltung der gesamten SRD-Klassenmechanik (282 katalogisierte Unlocks sind kein Nachweis getesteter Regelmechanismen), neue Initiativpfade außerhalb der drei bestehenden Einzelgegner-Kampfstarts und parallele Integration anderer Klassen-PRs (z. B. Mönch-Uncanny-Metabolism). Änderungen an gemeinsam genutztem game_engine.dart dürfen nur konfliktgeprüft zusammengeführt werden.

Nächster Schritt: PR-CI auswerten, Formatter-/Analyse-/Testfehler beheben und erst danach als getestet dokumentieren.

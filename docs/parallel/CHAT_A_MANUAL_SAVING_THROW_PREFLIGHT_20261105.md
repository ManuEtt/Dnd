# Initiale manuelle Rettungswürfe – Chat A

## 05.11.2026 – Chat A: erste manuelle Rettungswürfe vor Klassenbonus prüfen

**Implementiert auf Codecommit `6d6207f12ae3769475e28cd4751731cb555232df`**, Basis-Main
`74548d3d5243485c05fa7cb26bf1cea945e6ce9b`, Branch `fix/chat-a/manual-save-class-preflight-20261105`,
App **0.8.52+102**. Der neue schreibfreie Vorbereitungshelfer nutzt den vorhandenen
reinen Klassen-/Übungsvalidator; keine doppelte Regelberechnung oder erfundenen
Konzentrationsbestätigungen. GameEngine ruft ihn vor dem ersten manuellen W20 auf
und protokolliert ungültige, lesbare Altprofile als deutsche rules.blocked-Ablehnung.
Automatische STR/DEX-Fehlschläge bleiben ohne W20/Bonus; fehlende Attribute bleiben
Fehler. Lesende Charakterbogenberechnungen und gespeicherte Profile unverändert.

**Getestet:**52 neue Domain-/Enginefälle,8 SQLite-/Controller-Flows und2 tatsächliche
App-UI-Flows bestanden. Zusammen mit31 alten Regressionen93 gezielte Fälle. Unter
den UI-Nachweisen: Altprofil ablehnen, explizite Klassenkorrektur speichern, neue
Rettung mit einmaligem Bonus würfeln, Neustart; gültige englische Klassenaliase.
**Noch offen:** vollständiges scripts/check.sh, Android-Build/native Tests und
finale GitHub-CI dieses Branches. Keine erfolgreiche neue APK/CI behauptet.
SQLite3/JSON1 ohne Migration. Core-Requirement RULE-CORE-RULES-SAVING-THROWS partial;
weitere Rettungswurfquellen und vollständiger Charakterassistent/SRD bleiben offen.

**Live-Hinweis:** Main ist nach der letzten lokalen Abnahme erneut fortgeschritten;
vor finaler Abnahme Main und neue PR-Dateilisten prüfen, Änderungen koordinieren
und den kombinierten Stand erneut testen. Vorige Kontingentunterbrechungen haben
den Scope nicht ersetzt. Dieser überprüfte Teilstand wird zuerst remote/als ZIP
gesichert. Nächster Schritt: finale Integration und komplette Prüfkette.

---

## Mechanik und Kompatibilität

`SrdManualSavingThrowRules.prepare` gibt für automatische Fehlschläge null zurück;
damit wird kein erfundener Modifier als bestätigter Charakterwert ausgegeben.
Für tatsächliche Würfe werden vor der vorhandenen Berechnung in
CharacterRuleEngine Klassen/Stufen/Übungen geprüft. Der vorhandene reine Guard
SrdConcentrationSaveModifierRules.validateClassAndProficiencies benötigt keine
Konzentration und keine Spielerbestätigungsflags. Sein prepare-Aufruf wird nicht
mit fingierten Parametern verwendet. Rule-Fassade exportiert die Vorbereitung.

Ablehnungen sind Journalereignisse mit Revision; der Hero und Ressourcen bleiben
unverändert, RNG0. Nicht importierbare gefälschte Stufenprofile werden getrennt
an der Domain-Grenze geprüft, statt durch JSON-Normalisierung als alte Spielstände
ausgegeben. Ein später SQL-Fehler rollt den Speicherzustand zurück, keinen
zuvor legitimen W20. Quellen/Story/KI bestimmen keine bestätigten mechanischen Werte.

## Quelle und Tests

Amtliches SRD5.2.1, CC BY4.0, https://www.dndbeyond.com/srd . Frisch bestätigte
PDF-SHA8974902d109d6e63672d7c490bde9ccf052410503d9cfa768237154fbc5e3d87.
Saving Throws S7, Proficiency S8, Monk14 S52, Rogue15 S63; automatische Zustände
S186/189/191. Lizenzhinweise unverändert in THIRD_PARTY_NOTICES.md.

Tests: srd_manual_saving_throw_preflight_test.dart (52),
srd_manual_saving_throw_preflight_flow_test.dart (8),
srd_manual_saving_throw_preflight_ui_test.dart (2). Die früheren zehn
Fixturefehler betrafen nicht importierbare Stufen, zusätzlich wurde einmal ein
nicht vorhandener Testdateiname gestartet. Fixtures fachlich getrennt; kein
Test deaktiviert. Vorhandene Rettungswurf-/Zustands-/Indomitable-Might-Regressionen
bestanden. Aktuelle Logs liegen unter /workspace/validation/20261105-manual-save-*.

Reales Gerät, TalkBack, Upgrade und produktive Signierung bleiben offen.
Der branchbezogene finale CI- und Artefaktnachweis folgt nach den noch offenen
Prüfungen; frühere CI-Ergebnisse sind kein Testnachweis dieses neuen Heads.

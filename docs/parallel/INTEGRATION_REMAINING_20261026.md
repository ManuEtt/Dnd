# Integrationspaket – verbleibende Funktionen 2026-10-26

Ausgangspunkt: `f1f3e997bc8650a757d34234eff49d870dcf9369`. Die originalen Kopf-Commits der Fachbranches werden als Git-Eltern erhalten:
- #202 (Eldritch-Blast): `31136c840ebc82f84923fa799065151cf1a118a6`
- #199 (Kampf-Zugfolge): `399625c92ced66529ce058cc47c53f7fc167c962`
- #198 (NPC-Identitätskontext): `070d871f31e3e413a30941cd249ac0b69ce4097e`
- #200 (portable ZIP-Dateinamen): `1ceccc839a702630d0c953fd07fc9033a5e66594`
- #189 (Gradle-Parameterprüfung): `284558948eb751f9ce84ed74d3557cc68dfe0015`

Die gemeinsamen veralteten README-/CODEX_CHECKPOINT-Varianten werden nicht überschrieben. Die Eldritch-Blast-Einträge sind nur mit Status `partial` und konkreten Code-/Testnachweisen nachgeführt. Die Original-PRs #189 und #200 waren noch als Draft markiert; statt diese direkt zu mergen werden ihre Änderungen hier neu getestet.

**Fehlerkorrektur:** In der CI von #198 (z. B. 40274598321) schlug `backend/test/backend.test.ts` fehl, weil die erweiterte Sitzungsschnittstelle nun auch `capabilities: ['npc-identity-v1']` zurückgibt. Die Test-Erwartung für den bestätigten neuen Response-Vertrag ist aktualisiert; Provider-Anrufe, Zugangsdaten und Session-Schutz dürfen weiterhin nicht im Response auftauchen.

**Status:** Der neue Gesamtstand ist erst nach eigener grüner CI auf genau diesem Commit freigegeben. Eine reale Android-Geräteabnahme wurde nicht durchgeführt.

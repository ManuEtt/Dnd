# Koordinierte Integration der fünf offenen A–D-PRs (04.11.2026)

Ausgangs-main: `c8f25132a82bcf55368a79100e0c2ea5595140b6`; übernommen werden die ursprünglichen Head-Commits der PRs #535, #536, #537, #538 und #539 als unveränderte Commit-Eltern dieses Integrationsstands, damit sämtliche Historien erhalten bleiben. Die fachlichen Git-Blobs aller fünf PRs wurden unverändert übernommen. README, zentraler Checkpoint und CHAT_A_CHECKPOINT.md wurden unter vollständiger Beibehaltung aller originalen Zeilen und sämtlicher PR-Ergänzungen additiv vereinigt.

| PR | Head | Inhalt | letzte PR-CI |
|---|---|---|---|
| #535 | `b7115900499fe44276bac218dc0f748b2d6da102` | TalkBack/Xp | failure – Alpha-APK/Quellcheckpoint, Kernprüfungen bestanden |
| #536 | `87b15f353de50e42e5ca930d1524b5cd570fda5e` | Story-IDs | success |
| #537 | `5db7bbdb666d27e750a3b709bbf46d049cc12b55` | Gradle-Properties | success |
| #538 | `5804de7bd094d86ff931179f1e2a3e7c400bf32d` | Ranger Tireless | success |
| #539 | `6eb3155e1c23853b16aa6f8109768b320425ed52` | Warlock Magical Cunning | failure – Alpha-APK/Quellcheckpoint, Kernprüfungen bestanden |

**Noch ausstehend:** kombinierte CI, Main-Merge, erfolgreiche neue Main-CI und SHA-verifizierte Archivbereinigung. Bis dahin sind sämtliche fünf Originalbranches geschützt. Der bestehende Workflow `.github/workflows/cleanup-merged-safe-20261027.yml` archiviert und löscht nur nach grünem Main-Workflow vollständig integrierte, unveränderte und nicht mehr von offenen PRs geschützte Branches. Issues #333 und #425 wurden bereits vorher erledigt und sind geschlossen.

Es wurden weder SQLite/JSON-Schemas noch App-Version, Spielstände oder andere Branch-Refs geändert. Eine echte Android-Geräteabnahme ist nicht belegt.

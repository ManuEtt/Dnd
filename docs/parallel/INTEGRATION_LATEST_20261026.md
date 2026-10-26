# Integrationspaket: Eldritch Blast, NPC-Transport und Release-Sicherheit

Basis: `76ab5ae404144d4bb6f8de0b0cc429e009d03edd`. Ursprüngliche Branch-HEADs:
- PR #206: `6db42ab13f90d9f5202eaf2d2f7a31a0b6cd82a8`
- PR #208: `9840ed64ac7c55d536ac708f0894fcd697fcc610`
- PR #207 (Draft): `5c45af1bd12ec1f6ae9946d43166b40da975269a`

Änderungen: Single-Foe-Eldritch-Blast-Encounter mit Revisionsbindung, serverseitig verhandeltem NPC-Identitätskontext und Release-Prüfung verwaister Symlinks. Die sich überschneidenden Änderungen in `app/lib/services/game_controller.dart` wurden an beiden voneinander getrennten Methoden-/Aufrufstellen kombiniert. Der SRD-Eintrag `SPELL-ENTRY-ELDRITCH-BLAST` bleibt bewusst nur `partial`, einschließlich Quell- und Testverweisen.

Originalhistorien bleiben als weitere Git-Elterncommits erhalten. Gemeinsame README und CODEX_CHECKPOINT werden nicht durch parallele historische Versionen überschrieben. PR #207 bleibt für sich ein Draft; seine Korrektur wird hier mit eigenen Tests verifiziert, statt ungeprüft direkt gemergt.

**Freigabestatus:** Dieser kombinierte Commit ist bis zu eigener vollständiger CI nicht freigegeben. Kein Anspruch auf echte Android-Geräteabnahme oder Vollständigkeit des SRD-Regelwerks.

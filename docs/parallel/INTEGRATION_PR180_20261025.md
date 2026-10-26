# Integration PR #180 – klassifizierte Zauberdauer

Ausgangsbasis: main `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`.
Ursprünglicher PR-Kopf: `154bdcd538e155c196d0fd8611e6ef62bbd220fc` als zweiter Elterncommit erhalten.

Fachcode und Test `srd_spell_duration_rules.dart` und `srd_spell_duration_rules_test.dart` aus ursprünglichem PR #180 übernommen. Export in der aktuellen `rules_api.dart` ergänzt. Historische README- und Checkpoint-Änderungen bleiben über den zweiten Git-Elterncommit nachvollziehbar und ersetzen nicht die aktuellen Hauptbranch-Dokumente.

Der ursprüngliche Commit war durch vollständige Android-Alpha-CI erfolgreich abgenommen. Der neue Integrationsstand ist bis zu einer separaten CI **NICHT GETESTET**. SRD-Regelstatus und restliche fehlende Zaubereffekte werden nicht als vollständig implementiert ausgewiesen.

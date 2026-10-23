# Würfelraunen – Wiederaufnahme ausstehender Spielerhandlungen

Stand: 23.10.2026. Produktanforderung WR-INT-REQUEST-002, keine SRD-5.2.1-Spielregel.

## Ausgangslage
- Baseline main: 1d13b1aeef7cefe6ddf62b6f0ff63b227963c0a7.
- Die Schnellaktionen (PR #128) und die idempotente sendAction-Kennung (PR #129) wurden bereits in main integriert.
- Der Controller erkennt bestätigte Handlungen anhand ihrer Request-ID im persistierten Ereignisprotokoll wieder. Die UI nutzte diese Kennung bisher nicht.

## IMPLEMENTIERT
- PlayerActionOutbox unter app/lib/services/player_action_outbox.dart hält einen lokalen Sendeauftrag pro Kampagne in den vorhandenen SQLite-Einstellungen, Schlüssel pendingPlayerActionsV1. Der Auftrag wird vor dem Aufruf der Regeln oder des Erzählers gespeichert.
- Zufällige Kennungen werden mit Random.secure() aus 18 Bytes erzeugt. Ein Wiederholungsversuch übernimmt Kennung und Text unverändert.
- Die Abenteueransicht stellt einen offenen Auftrag nach Kampagnenwechsel/Neustart wieder her, sperrt bis zur Entscheidung weitere neue Eingaben und bietet Erneut bestätigen und Verwerfen an.
- Texteingaben, bestätigter erkannter Sprachtext, Kampfschnellaktionen, Erkundung und Rückblick nutzen den gemeinsamen GameController.sendAction-Pfad samt Kennung.
- Es erfolgt kein automatischer Versand nach Neustart. Wird eine bereits bestätigte Handlung wiederholt, erkennt der Controller deren Kennung vor Regeln/Würfeln/Backend und die Outbox wird entfernt.
- Verwerfen muss bestätigt werden und entfernt nur den offenen Auftrag, niemals ein gespeichertes Spielereignis.
- Kein neues SQLite-Schema, keine Migration, keine geheimen KI-Zugangsdaten in der Outbox.

## TESTS
- app/test/player_action_outbox_test.dart: SQLite-Neustart, alte Einstellungen, ID-Kollision, getrennte Kampagnen, korrupte Daten, sichere Entfernung.
- app/test/ui_app_test.dart: offene Handlung wird ohne automatischen Versand gezeigt; manuelles Replay; verlorene Bestätigung nach erfolgtem Commit.
- Bestehende Controller-SQLite- und Erzähler-Idempotenztests bleiben erhalten.
- Die finale CI muss Dart-Formatierung, Flutter-Codeanalyse und Flutter-Tests, Python/Backend sowie Android-Build vollständig durchlaufen.

## NOCH OFFEN / RISIKEN
- Externe KI-Anfragen vor erstem lokalen Commit können bei manuell erneutem Versuch wiederholt werden und Kosten verursachen. Der Benutzer muss selbst entscheiden; es wird keine vollständige Exactly-once-Garantie über Drittanbieter behauptet.
- Das existierende App-Settings-Dokument wird durch read-modify-write aktualisiert. Gleichzeitige Schreiber auf diese Einstellungen sind noch nicht transaktional koordiniert. Eine eigene SQLite-Outbox-Tabelle mit getesteter Migration wäre die robuste nächste Stufe.
- Andere Befehle wie freie Würfe, explizite Würfelbestätigungen und Effekte verwenden noch nicht überall Request-IDs.
- Keine echte Android-Geräteabnahme; Widgettests ersetzen weder Barrierefreiheit noch alle kleinen Bildschirm-/Tastaturzustände.

IMPLEMENTIERT ist nicht gleich GETESTET: Nur die CI des finalen PR-HEAD ist belastbare Build-/Test-Evidenz.
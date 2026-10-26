# Chat B – ausgehandelter NPC-ID-Transport für Flutter (26.10.2026)

## Abhängigkeiten und unabhängiger Branch
- GitHub: `ManuEtt/Dnd`.
- Branch: `feat/chat-b/negotiated-npc-transport-20261026`, ab `main` `f1f3e997bc8650a757d34234eff49d870dcf9369` (Integration Chat B aus PR #204 bereits enthalten).
- Voraussetzung für die neue Übertragung: Backend-Vertrag `npcContexts`/`campaignRevision` und authentifizierte Fähigkeitsmeldung `npc-identity-v1`. **Durch den zwischenzeitlichen Integrations-Merge #205 sind beide inzwischen auf `main` enthalten**. Die historischen Einzel-PRs #193/#198 sind für die Nachvollziehbarkeit verlinkt; ein installierter Backend-Server muss diese Version tatsächlich ausführen.
- Basiscode aus PR #196 (lokale NPC-ID- und Revisionschronik) wurde durch Integrations-PR #204 in `main` übernommen; deshalb keine Änderung an offenen Integrationsbranches notwendig.

## Implementiert
1. `app/lib/services/backend_narrator.dart`: Nur nach erfolgreichem GET `/v1/session` mit unverändertem Provider-/Scope-/Ablaufprüfprozess wird das Array `capabilities` auf den exakten Marker `npc-identity-v1` geprüft. Bei `disconnect`/Sitzungslöschung wird die Freigabe zurückgesetzt.
2. `BackendNarrator.advanceStory`: Zwei zusammen optionale Parameter `campaignRevision` und `npcContexts`. Beide werden bei neuer Freigabe gesendet, teilweise gesetzte/überhöhte Parameter werden vor Netzwerk-/Provideraufruf abgelehnt; ältere Server erhalten unverändert den Legacy-Request.
3. `app/lib/story/npc_identity_story_payload.dart`: read-only Auswahl passender, durch den Spielertext *eindeutig* benannter NPCs, streng nach ID und lokaler Kampagnenrevision. Max. 3 Figuren und je 3 (höchstens 5) bestätigte Notizen. Bei Namensdoppelung – auch Groß-/Kleinschreibung – keine willkürliche Zuordnung; unbekannte/nicht relevante, nicht validierbare oder umbrochene Texte werden ausgelassen. `NpcIdentityMemory.requireCurrent` wird vor dem Weiterreichen aufgerufen.
4. `app/lib/services/game_controller.dart`: Der optionale Kontext wird nur im bereits bestehenden KI-Kampagnenpfad bei ausgehandelter Fähigkeit aufgebaut und mit der Story-API gesendet. Normale Demo, Regeln, SQLite, Kampf und NPC-Beziehungsbestätigung bleiben unverändert.
5. `app/test/npc_identity_transport_integration_test.dart`: SQLite/GameController/BackendTransport-Integration für fähigkeitsfähigen Server und Legacy-Server, keine HP-/Persistenzänderung.
6. `app/test/npc_identity_story_payload_test.dart`: mehrdeutige Namensgleichheit, gestützte IDs, fehlende Relevanz, Kapazitätsgrenzen, Revisionsschutz und Kontrollzeichen.

## Sicherheitsabgrenzung
- Name allein darf niemals zwischen zwei gleichnamigen NPCs wählen. Eine spätere explizite NPC-ID-Auswahl per Oberfläche wäre ein separates Arbeitspaket.
- Die Backend-Fähigkeit kommt nur aus der authentifizierten Sitzungsantwort der vom Spieler eingestellten HTTPS-Adresse; keine Heuristik nach Backendversion und keine wiederholten Probe-Anfragen.
- Bei nicht unterstützendem Backend wird kein zusätzlicher Kontext übertragen. Keine geheime Schlüsselverwaltung, keine zusätzlichen Providerkosten durch automatische Replays.
- `campaignRevision` ist die lokale geplante neue Revision vor atomarer Spielstandübernahme. Diese liegt noch nicht als remote autoritativer Wert vor. SQLite-OCC lehnt parallele Änderungen nach dem optionalen Erzählen weiterhin ab.
- Das Backend ist zustandslos und kann die vom Client behauptete Revision nur auf innere Konsistenz prüfen, nicht an einer Serverkopie des Spielstands authentifizieren.
- Keine neuen Fähigkeiten zum Ändern von TP, RK, EP, XP, Inventar oder Quests. Antwortautorität unverändert.
- Keine API-Migration für alte Server, keine SQLite-/JSON-Migration, keine neue App-Version.

## Akzeptanz und Abnahme
- Mit exakt `npc-identity-v1` im GET /v1/session erreicht der relevante NPC-Kontext den simulierten `/v1/story/advance`-Endpoint.
- Ohne Fähigkeit und nach Disconnect keine zusätzlichen Felder oder bleibende Freigabe.
- Bei identischen sichtbaren Namen niemals raten; alle unbestätigten oder unpassenden Daten weglassen.
- Vollständige GitHub-Workflowprüfung erforderlich: Format, Analyse, Flutter-Testgesamtmenge, Backend-Pipeline, Android-Debug/Alpha und Quelle-ZIP. Reale Geräteinstallation sowie kostenpflichtige KI-Betreiber **nicht geprüft**.
- Frühere Zwischencommits zeigten Dart-Format-, Syntax- und Analysefehler; nach deren Korrektur bestanden bei CI #40276027697 Backendtests, Format, Analyse, 1.661 Fluttertests einschließlich beider neuen SQLite-Integrationstests. Ein einzelner fehlerhafter Testaufruf (Exception vor Expect) wurde im Folgecommit korrigiert. Vollständiger Test-/APK-Erfolg erst durch final grüne CI.

## Folgeschritt
Nach Integration dieses Client-PRs gemeinsamer Mock-End-to-End-Test gegen denselben vollständigen Branch sowie reale Android-/TTS-Tests. Nutzeroberfläche für explizite Auswahl gleichnamiger NPCs separat.

# Zusammenführung der Story-Sicherheitsprüfung in Android und Backend

Stand 25.10.2026 · Gemeinsamer Integrations-[PR #169](https://github.com/ManuEtt/Dnd/pull/169).

## Ursprung / reiner Integrationsumfang

Der Integrationsbranch `integration/story-safety-pr165-167-168-20261025` basiert auf **dem exakt geprüften HEAD von [#168](https://github.com/ManuEtt/Dnd/pull/168): `e157801b929f27a6244e087baa0d8f9fd0ad69d2`**. #168 enthält die vollständige #165-Story-Korrektur, die wiederum vom geprüften Integrations-PR #164 abstammt. Hier werden zusätzlich drei ausführbare Backend-Quell-/Testdateien aus dem separat grün geprüften [#167](https://github.com/ManuEtt/Dnd/pull/167) als **identische Git-BLOB-Objekte** übernommen, **ohne** neue Eigenimplementierung oder Überschreiben der Android-Änderungen.

| Bereich | Quelle | Übernommene Funktion |
| --- | --- | --- |
| Gemeinsam geprüfter Start | [#164](https://github.com/ManuEtt/Dnd/pull/164), CI [#40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457) | Sending, Schurke, Story-Terminalstatus im Backend, Quoten, wörtlicher Plot-Spoilerschutz |
| Android-Story-Endstatus | [#165](https://github.com/ManuEtt/Dnd/pull/165), CI [#40170005782](https://github.com/ManuEtt/Dnd/actions/runs/40170005782) | Geschlossene/aufgegebene Stränge nur nach explizitem manuellen Wiederöffnen; KI-Stale-Replay blockieren |
| Android-Identitäten | [#168](https://github.com/ManuEtt/Dnd/pull/168), CI [#40182898798](https://github.com/ManuEtt/Dnd/actions/runs/40182898798) | Doppelte lokale NPC-/Thread-IDs vor generativen Zuordnungen und beim Commit zurückweisen |
| Backend-Kontext | [#167](https://github.com/ManuEtt/Dnd/pull/167), CI [#40180964702](https://github.com/ManuEtt/Dnd/actions/runs/40180964702) | Doppelte Thread-/NPC-IDs vor Erzähleraufruf ⇒ HTTP 400 und 0 Anbieteraufrufe |

**Exakte übernommene Backend-Git-Blobs:** `backend/src/story.ts` → `ffa52d731d8d0216d5a68b591bd81883fcdc9afc`; `backend/src/app.ts` → `3b6ad03365517a63bdd0a1dc95540cc368cd3280`; `backend/test/story.test.ts` → `a526bb1f8f594023771f146caefa551e5b00d754`. Diese 3 Code-/Testdateien bleiben byteidentisch zu #167. Die vorhandenen Android-Dateien und ihre Tests bleiben byteidentisch zu #168. Die ursprünglichen fachlichen Belege beider PRs sind im kombinierten Baum.

## Abnahme und Sicherheitsgrenzen

Die zuvor grüne CI der Einzel-PRs ist **nicht** gleichbedeutend mit der erforderlichen gemeinsamen Abnahme. Auf **genau dem finalen HEAD von PR #169** müssen Python-/SRD-/Import-Boundarychecks, Backend-Typecheck/Build/Tests, Dart-Format/Analyse/Flutter-Komplettsuite, Android-Debug-/native Tests sowie ARM64/ARMv7/x64-Alpha-Pakete erfolgreich sein. Solange der abschließende GitHub-Actions-Lauf nicht `completed/success` meldet, bleibt PR #169 Entwurf. Keine neuen Secrets oder KI-Kosten erforderlich.

**Unverändert:** App-Version `0.8.38+88`, SQLite `2`, Kampagnen-Export-JSON `1`, bestätigte lokale Regelautorität, `stateChanges: []`, teilweise SRD-5.2.1-Abdeckung. Die lokalen Guards prüfen nur den generativen Story-Übernahmepfad; `Campaign.fromJson` wird hier **nicht** als globaler ID-Sanierer verändert. Der Backend-Guard prüft nur die gegebenen bestätigten Kontext-IDs, nicht komplexe semantische Handlungswahrheit. Wortgleiche Plot-Geheimnisse werden gesperrt, sinngemäße Paraphrasen nicht vollständig erkannt. Kein produktiver Multi-Instanz-Limiter behauptet.

## Vermeidung von Doppel-Merges

Das ist ein auf [#164](https://github.com/ManuEtt/Dnd/pull/164) **gestapelter** Integrations-PR, nicht bereits in `main` enthalten. Nach expliziter Projektfreigabe zunächst #164 reviewen und mergen, dann den gemeinsamen #169 gegen aktuelles `main` neu basieren/erneut CI prüfen und **nur #169** mergen. Die durch ihn ersetzten, aber bewusst unangetasteten Folge-PRs #165/#167/#168 können anschließend dokumentiert geschlossen werden. Alternativ dürfen die drei PRs einzeln geprüft und integriert werden, dann #169 schließen. Nicht beide Wege ohne Abgleich anwenden.

[PR #166](https://github.com/ManuEtt/Dnd/pull/166) (SRD Light-/Kampfregeln) bleibt wegen Änderungen an denselben Modell-/Regel-/UI-Dateien bewusst **außerhalb dieses Story-Integrationspakets** und benötigt einen eigenen Konfliktabgleich. Kein fremder Branch wurde gelöscht oder verändert.

**Ein nächster Schritt:** Neue vollständig grüne kombinierte GitHub Actions CI dokumentieren, PR #169 reviewbereit machen; kein automatischer Merge nach main oder Versprechen eines Echtgerätetests.

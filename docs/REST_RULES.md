# Rasten und Trefferwürfel – SRD 5.2.1 (App 0.5.8+28)

**Regelquelle:** [SRD 5.2.1 (Wizards of the Coast / CC BY 4.0)](https://www.dndbeyond.com/srd), „Rules Glossary“: **Short Rest**, **Long Rest**, und „Classes“: **Hit Points and Hit Dice**. Die erforderliche Namensnennung befindet sich in `THIRD_PARTY_NOTICES.md`.

## Implementiert

- Eine **kurze Rast** ist eine explizit vom Spieler bestätigte Handlung, die mindestens 1 Stunde Spielzeit beansprucht. Ein Charakter mit mindestens 1 TP kann einen oder mehrere verfügbare Trefferwürfel ausgeben. Pro Würfel wird dessen Wurf + bestätigter Konstitutionsmodifikator berechnet (mindestens 1 TP pro Würfel); die Trefferpunkte steigen nicht über ihr Maximum.
- Trefferwürfel kommen aus den bestätigten Klassenstufen, bei Mehrklassen aus jedem beteiligten Würfeltyp. Beispiel: Kämpfer 2 / Magier 1 besitzt 2W10 und 1W6. Bereits ausgegebene Würfel sind in `spentHitDice` gespeichert und werden von den verfügbaren abgezogen. Eine kurze Rast darf nicht mehr ausgeben, als vorhanden ist.
- **Lange Rast** (mindestens 8 Stunden) stellt verlorene Trefferpunkte und alle verbrauchten Trefferwürfel wieder her. Bereits tote oder bewusstlose Charaktere dürfen weder eine kurze noch lange Rast ausführen.
- Rasten im aktiven Kampf oder bei noch offener Probe werden blockiert. Nicht spezifizierte `Ich raste`-Kommandos verändern keine Spielwerte, sondern fordern die Wahl kurz/lang an.
- Die lokale Regelengine ändert und persistiert Werte; das KI-Backend besitzt hierfür keine Schreibberechtigung. Journalereignisse `character.shortRest` und `character.longRest` enthalten Bestätigungs- und Wurfdaten.
- Im Charakterbogen → **Verteidigung** werden verfügbare Trefferwürfel und der Gesamtpool je Würfeltyp angezeigt, z. B. `D10: 1/2 · D6: 1/1`.

## Benutzung im Abenteuer

- `Ich mache eine kurze Rast.` – ein verfügbarer Trefferwürfel des zuerst verfügbaren Würfeltyps.
- `Ich mache eine kurze Rast 2W10.` – zwei passende Trefferwürfel ausgeben, sofern verfügbar.
- `Ich mache eine lange Rast.` – TP und Würfelvorrat wiederherstellen.

Eine kurze Rast gibt keine Trefferwürfel zurück. Sie werden durch eine lange Rast wiederhergestellt.

## Datenkompatibilität

Das JSON-Schema bleibt `schemaVersion: 1`. `spentHitDice` ist optional; fehlende Einträge alter Spielstände entsprechen einem **noch vollständigen Trefferwürfelvorrat**. Die Anwendung validiert Schlüssel (`d6`, `d8`, `d10`, `d12`), Datentypen, negative/überhöhte Werte und verhindert Ressourcenüberschreitungen. SQLite speichert das JSON in den vorhandenen Transaktionen, inklusive Import/Export. Die technische Android-Paket-ID bleibt unverändert.

## Bewusst noch offen

- Rastunterbrechungen und die tatsächliche In-Game-Zeitmessung (einschließlich 16 Stunden Wartezeit vor der nächsten langen Rast) sind noch nicht automatisiert; der Spieler bestätigt die verstrichene Zeit in der Erzählung.
- Die Wiederherstellung von Klassenfähigkeiten, Zauberplätzen, Attributsminderungen und Erschöpfung benötigt getrennte Datenmodelle und weitere Regeln. Dieses Teilpaket darf nicht als vollständige Implementierung aller Rastregeln bezeichnet werden.
- Gerätetest und voller Flutter-/Android-CI-Build für 0.5.8+28 stehen bis zur Übernahme ins Repository aus. Neue Dart-Unit-, Integrations- und Widgettests liegen vor und sind **noch nicht mit Flutter ausgeführt**.

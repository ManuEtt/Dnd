# Hinterhältiger Angriff: bestätigter Verbündeter im Spielablauf

Version 0.8.37+87; Basis main 5958579; funktionaler Code 0a56aba7057dc12d80750759443f6d70ed510dc1.

Quelle: offizielles [SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), Rogue / Sneak Attack, gedruckte S.61–62, CC BY 4.0. Attribution: THIRD_PARTY_NOTICES.md. Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt `partial`.

## Fachlicher Umfang und Akzeptanz

1. Nur ein offener zulässiger Hauptwaffenangriff im eigenen aktiven Kampfzug kann die Bestätigung erhalten. Schurkenstufe, Finesse/Fernkampf, Vorteil/Nachteil und nicht verbrauchte Nutzung bleiben erforderlich.
2. Verbündeter wird ausdrücklich benannt; Nähe innerhalb von 5 Fuß **zum Ziel** und fehlende Handlungsunfähigkeit werden getrennt bestätigt. Initial ist nichts ausgewählt. Abbruch mutiert nichts.
3. `SneakAttackAllyConfirmation` bindet Kampagne, Wurf und Ziel; unbekannte/fehlende Fakten, fremde Zuordnung und ungültige Importe werden verworfen. Bei der Ausführung wird vor jedem Würfelwurf erneut validiert.
4. Bestätigung würfelt nicht, verursacht keinen Schaden und verbraucht keine Aktion. Erst der bestätigte Treffer würfelt den SRD-Zusatzschaden; Krit verdoppelt nur Würfel. Nach Fehlschlag bleibt die Fähigkeit verfügbar, aber die nächste Probe braucht eine neue Bestätigung.
5. Nur der tatsächlich angewendete Zusatzschaden setzt die bestehende Nutzungsmarkierung. Bereits verbrauchte Nutzung, fremder Zug, Handlungsunfähigkeit oder ungeeignete Waffe werden abgewiesen.
6. Entfernen vor der Auflösung erhält dieselbe offene Probe. Controller prüft erfasste Kampagnenrevision und Wurf-ID; SQLite speichert Zustand/Ereignis gemeinsam oder rollt beides zurück.
7. Backup/Import, Neustart und Journal-Rekonstruktion erhalten den offenen Kontext. Alte JSONs ohne Feld bleiben unverändert gültig. Keine DB-Migration: SQLite2, JSON1; neues optionales `PendingRoll.sneakAttackAlly` mit eigener Version1.
8. Story-/KI-Text bleibt ohne Befugnis zur Bestätigung. Kein NPC, Monsterwert oder Verbündetenstand wird aus einer Beschreibung erfunden. Eingabeentwürfe bleiben erhalten; Dialog bei 360dp, Schrift1,8 und Tastatur geprüft.

## Integration

- `sneak_attack_ally_rules.dart`: getypte Beobachtungen, Bindung und zentrale Zulässigkeitsprüfung.
- `models.dart`: optionales PendingRoll-Feld und Importprüfung; Angriffsbonus über RulesEngine wie bei der Ausführung.
- `game_engine.dart`: explizite Bestätigung/Entfernung, Validierung vor Zufall, vorhandene Schadens-/Krit-/Zuglogik.
- `game_controller.dart`: Revisionsschutz und vorhandener atomarer Commit.
- `sneak_attack_ally_dialog.dart` und Abenteuer-PendingPanel: Auswahl, Anzeige und Entfernen.
- Ereignisse `combat.sneakAttackAllyConfirmed` / `combat.sneakAttackAllyCleared`; aufgelöster Wurf protokolliert Anfrage, Zusatzwürfel und bestätigte Quelle.

## Nachweise und Grenzen

11 neue Domain-/SQLite-Tests und 6 Widgettests erfolgreich. Vollständige Prüfkette erfolgreich: 1.448 Flutter-Tests, 100 Python-Tests, 31 Backend-Tests, Format und Analyse. Debug-APK, ARM64-Alpha und12 native Tests erfolgreich. Vollständige GitHub-Code-CI40056875863 auf182f44b grün; Details und finale Dokumentationsstände im operativen Checkpoint. Die vorhandene Rule-/Story-Grenze bleibt aktiv.

Der Verbündete ist eine manuell bestätigte Beobachtung, kein neues automatisch verwaltetes Kampfobjekt. Nebenhand, Gelegenheitsangriffe, vollständiger Positionskampf und vollständige SRD-Abdeckung sind offen. Die bereits vorhandene automatische Auslösung über echten Angriffsvorteil bleibt erhalten. Keine Änderung an Backend, Anbieterfreigaben, Outbox oder Geräteberechtigungen.

Die Formatkorrektur liegt separat in 309b07e; der Workflow prüft jetzt alle lib/- und test/-Dateien wie scripts/check.sh. Dieser Qualitätsfehler wird nicht durch Einschränken des lokalen Gates umgangen.

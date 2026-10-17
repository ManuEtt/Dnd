# Gemeinsame Charaktereffekte und ausführbare Heilzauber

Version 0.7.7+47. Grundlage: offizielles SRD 5.2.1 unter CC BY 4.0, https://www.dndbeyond.com/srd, geprüfter englischer PDF-Text. Eigene deutsche UI-Texte; Attribution bleibt in THIRD_PARTY_NOTICES.md erhalten. Lokale Anforderungs-IDs und Nachweise: RULE_COVERAGE.md.

## Externe bestätigte Effekte

„Effekt bestätigen“ im Abenteuerheader ist für Schaden, Heilung und temporäre TP erreichbar. Quelle und Betrag werden ausdrücklich bestätigt. Bei Schaden gilt die bestätigte Art und gegebenenfalls Abwehr nur für dieses Paket. Kritische Würfel müssen bereits im Betrag enthalten sein; sie werden nicht erneut verdoppelt. Mehrfachresistenzen stapeln nicht. Versteinert gewährt allgemeine Resistenz, ein bestätigter aktiver Kampfrausch physische Resistenz ohne schwere Rüstung. Unbekannte Demo-Schadensarten bleiben unbekannt; keine KI-Narration kann einen Effekt auslösen.

CharacterEffectRules wird auch von Gegnerangriffen verwendet: Abwehr, temporäre TP, echte TP/Todesrettungsfolgen und Konzentration in dieser Reihenfolge. Konzentrations-SG verwendet den angewendeten Schaden vor Absorption durch temporäre TP. Immunität/0 Schaden erzeugt keinen Wurf. KO/Tod/Handlungsunfähigkeit beendet Konzentration. Ein Paket hat einen Konzentrationswurf; getrennte Quellen werden getrennt bestätigt. Quelle, Ziel, Komponenten, Abwehr, TP-Folgen und Würfel werden im Ereignisjournal mit dem Snapshot transaktional gespeichert. Heilung über das Maximum und Stapeln temporärer TP sind ausgeschlossen. Diese Eingabe verwaltet externe Beträge; sie ersetzt nicht die Ressourcen-/Quellmechanik fremder Fähigkeiten.

Quellen: SRD S.17–18 (Schaden, Heilung, 0 TP, temporäre TP), S.187 (Konzentration). Automatische ST-/GE-Fehlschläge: gelähmt/versteinert/betäubt/bewusstlos, Glossar S.186/188/190. Keine Würfel oder Wiederholungsressourcen bei automatischem Fehlschlag. Betäubt hat nach 2024 keine allgemeine Bewegungsrate-0-Regel.

## Ausführbare Selbstheilzauber

„Heilzauber wirken“ erscheint für bestätigte unterstützte Zauber im Charakterbogen. Der Dialog wählt Zauberklasse, tatsächlich freien normalen/Paktplatz und mögliche Komponenten. Wunden heilen nutzt pro tatsächlichem Platzgrad 2W8, Heilendes Wort 2W4, jeweils plus eigenes Zauberattribut genau einmal. Englische/deutsche Namen sind kompatibel. Der bestätigte eigene Zaubereintrag gilt in diesem begrenzten Modell als vorbereitet; die Funktion gewährt keine neuen Zauber, Talente oder erweiterten Klassenlisten. Mehrklassenplätze erlauben Hochstufung, ersetzen aber nicht die eigene Klassen-/Vorbereitungsberechtigung. Aktuelle Ziele sind ausschließlich der eigene Charakter. Eine bewusstlose Figur kann sich nicht selbst zaubernd heilen; externe bestätigte Heilung bleibt möglich.

Wunden heilen benötigt verbal/gestisch, Heilendes Wort verbal und Sicht auf das eigene Ziel. Nicht repräsentierte freie Hand/Sprachmöglichkeit werden ausdrücklich bestätigt; ungeübte Rüstung/Schild, handlungsunfähige/tote Figuren und nicht bestätigte Zauberattribute werden abgewiesen. Ohne Sonder-Sinnesmodell ist Heilendes Wort bei blind/unsichtbar konservativ gesperrt. Lebensdomäne ab Kleriker 3 gewährt 2+Platzgrad, ab 17 maximale Heilwürfel statt RNG. Blessed Healer gilt bei Selbstheilung nicht zusätzlich. Die vorhandene einzelne Unterklasse wird nur ihrer primären Klasse zugeordnet; keine Zweit-Unterklasse aus Freitext erraten.

Quellen: SRD S.25–26 (Mehrklassen), S.40 (Life Domain), S.105–106 (Komponenten/Ziele), S.121 (Cure Wounds), S.139 (Healing Word).

Im Kampf bucht GameEngine die Magieaktion oder Bonusaktion und `spellSlotExpendedThisTurn`. Der Flag gilt für normale und Paktplätze gemeinsam und bleibt nach Speichern/Neustart erhalten; der nächste eigene Zug setzt ihn zurück. Ein Heilzauber beendet den eigenen Zug nicht automatisch. „Zug beenden“ löst den bestehenden Gegnerzug aus. Rage sperrt Zauber; die begrenzte vorhandene Action-Surge-Aktion erlaubt keine Magieaktion. Bei reserviertem Action Surge ist eine Magieaktion konservativ gesperrt; die allgemeinere freie Reihenfolge der ursprünglichen und zusätzlichen Aktion ist noch offen. Außerhalb aktiver Kämpfe fehlt weiterhin eine bestätigte Spielzeit-/Zugachse. Manuelle Ressourcenverwaltung im Charaktereditor ist weiterhin ausdrücklich eine Charakterkorrektur ohne ausführbare Zauberwirkung.

## Speicherung und Grenzen

SQLite und Importformat bleiben Schema 1: das neue optionale boolesche Encounter-Feld fehlt in alten Daten und wird dann false. Fremde Typen werden abgewiesen. UI-Dialoge binden Bestätigungen an Kampagnen-ID und Revision. Reale SQLite-Tests prüfen Neustart und einen Abbruch nach begonnener Snapshotänderung: TP, Platz, Zugflag und Ereignis werden gemeinsam zurückgerollt.

Offen bleiben insbesondere Fremdziele/Gruppenmitglieder, allgemeine Zaubervorbereitung, zusätzliche Herkunft aus Talenten/Unterklassen, Zustandsquellen und Dauern, optionale Konzentrationswiederholungen, Reaktionszauber, vollständige Monstermechaniken sowie das übrige SRD. Die globale Formatbereinigung ist eine semantisch neutrale Codepflege; CI prüft Formatierung vor Analyse/Tests.

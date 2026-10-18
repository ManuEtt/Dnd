# Kampf mit zwei Waffen – Regelengine 0.8.5+55

Regelgrundlage: D&D SRD 5.2.1 (CC BY 4.0), Light property und Fighting Style: Two-Weapon Fighting.

Dieser erste ausführbare Schritt gilt für Kämpfer mit ausdrücklich gewähltem Kampfstil und zwei eindeutigen, bestätigten **leichten Nahkampfwaffen**. Eine andere leichte Waffe muss neben der ausgerüsteten Hauptwaffe im Inventar liegen. Ein ausgerüsteter Schild schließt die Aktion aus.

Nach einem regulären Angriff (Treffer oder Fehlschlag) wird der eigene Zug nicht sofort beendet, wenn die Bonusaktion und eine passende Nebenhandwaffe verfügbar sind. Der Spieler kann `Nebenhandangriff mit Dolch` oder `Nebenhandangriff: <Gegenstand-ID>` eingeben und den angeforderten W20 würfeln. Die Bonusaktion ist für diesen Wurf reserviert, kann nur einmal pro Zug verwendet werden und wird beim Rundenwechsel zurückgesetzt.

Der offizielle Waffenschaden und beim gewählten Kampfstil der passende Attributsmodifikator zählen; kritische Treffer würfeln die Waffenwürfel doppelt. Die bestätigten Waffenwerte werden nicht aus Freitexten erfunden. Offene Würfe und Rundenzustand werden mit dem Spielstand gespeichert.

**Noch offen:** Die normale Light-Aktion für andere Klassen ohne gewählten Kämpfer-Kampfstil, Nick-Meisterschaft, Dual-Wielder-Talent und geworfene Nebenhandwaffen als Fernkampfaktionen. Diese Effekte werden in dieser Etappe bewusst nicht ungeprüft freigeschaltet.

Tests: `app/test/two_weapon_fighting_test.dart`.

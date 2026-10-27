# Akolyth: konkrete Heilige-Symbol-Auswahl (27.10.2026)

## Umfang
Eigenständiges Inkrement auf dem noch nicht nach main integrierten Charakterpaket PR #273; Integrationsfolge #264 → #272 → #273 → neuer PR.

SRD 5.2.1, *Equipment / Holy Symbols* (S. 97) definiert Amulett (1 lb), Emblem (ohne Gewichtsangabe), Reliquiar (2 lb), jeweils 5 GM. Diese drei ausdrücklich auswählbaren Katalogeinträge werden als Gegenstands-ID, Name, Preis und Gewicht in der bestätigten Akolythen-Ausrüstung A gespeichert. Eine Fokussierungsberechtigung entsteht nicht allein durch das Inventar; Klasse und Regeln entscheiden weiterhin selbst.

Beim Akolythen ist die konkrete Wahl für **neue** Ausrüstungspakete A erforderlich. 50-GM-Alternative B benötigt kein Symbol. Alle anderen Hintergründe dürfen keine Symbol-ID unterstellen. Manipulierte Fremd-IDs, JSON-Typen und unpassende Varianten werden verworfen. Bisherige Helden-/Hintergrund-JSONs ohne optionales Feld bleiben lesbar und unverändert; ein erneutes Hintergrundpaket wird nicht verliehen. SQLite 2 / JSON 1 unverändert.

Automatisierte Domain-/Widgettests prüfen die drei Typen, Bestätigungssperre, Alternative B, ungültige Felder, keine Zauberbonuswirkung und JSON-Roundtrip. Vollständige Flutter-/Android-Abnahme auf finaler SHA separat per GitHub Actions; reales Android-Gerät, Talentwahl und Magic-Initiate-Zauber weiterhin offen.

Quelle: https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf (S.97), CC BY 4.0.

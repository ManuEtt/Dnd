# SRD 5.2.1 – Materialverbrauch mit SQLite-Revision und Ereignis

Stand: 21.10.2026 · **Quelle:** D&D SRD 5.2.1, *Spells / Casting Spells / Components*, [SRD-Verweis](https://www.dndbeyond.com/srd), CC BY 4.0.

## Dieser Integrationsschritt

Auf dem bereits gemergten reinen Regelmodul `SrdSpellInventoryRules` baut eine explizite Integrationsschnittstelle auf:

- `GameEngine.commitConfirmedSpellMaterialCast` akzeptiert **nur** einen zuvor von `SrdSpellPreflightRules.preflight` erzeugten Plan sowie ausdrücklich bestätigte externe Regelauflösung und Materialidentität/-mengen. Es verändert keine Ziele, Trefferpunkte oder Questzustände, sondern ausschließlich die bestätigten Zauberressourcen und Inventarbestände.
- Die Engine erzeugt genau eine Revision und einen überprüfbaren `spell.materialsCommitted`-Journaleintrag mit Zaubername, eigener Klasse, Platzstufe, Paktangabe und verbrauchten Inventar-Instanz-IDs/Mengen. `_commit` erstellt einen `stateAfter`-Checkpoint für Wiederherstellung.
- `GameController.commitConfirmedSpellMaterialCast` validiert Kampagnen-ID und erwartete Revision und führt den bestehenden `repository.saveCampaign(...expectedRevision...)`-Aufruf aus. Diese SQLite-Transaktion schreibt Snapshot, Revisionshistorie und Ereignis gemeinsam; bei Konflikt, Fehlmenge oder Fehler bleibt der letzte bestätigte Zustand erhalten.
- Vorhandene UI- und KI-Erzählzugänge lösen diese Spezialaktion **nicht automatisch** aus. Ein regelgeprüfter externer Zaubereffekt ist weiterhin Voraussetzung.

**Einschränkung:** Ein aktiver Kampf, offene Würfelprobe oder Schildreaktion blockiert diesen Ressourcen-Commit. Eine vollständige Kampfzauber-Aktionsökonomie und Ziellogik wird durch den neuen Weg **nicht** umgangen. Die bestehenden spezialisierten Heil-/Angriffszauber benutzen weiterhin ihre eigene Regelimplementierung.

## Abnahme und Grenzen

Tests: `app/test/srd_spell_inventory_persistence_test.dart` – Controller+SQLite+Ereignis, Revisions-Replay, Neustart, doppelte Bestätigung, unzureichendes Material, unbestätigter Effekt, konkurrierender SQLite-Schreiber und Kampfblockade. Hinzu kommen die bestehenden Material- und Preflight-Tests.

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_spell_inventory_persistence_test.dart
flutter test
flutter build apk --debug
```

**Nicht enthalten:** Prüfung der tatsächlichen Inventaridentität und des exakten Komponentenpreises gegen den offiziellen SRD-Wirkungstext; automatische Effektauflösung; Zauberwirkungsziele, Linie/Sicht/Position; GUI für die Bestätigung; vollständige Casting-Time/Combat-Einbindung; Android-Geräteabnahme; vollständige SRD-Quelleninventur. Ein gültiges Bestätigungsflag ist keine aus dem Inventar selbst abgeleitete Identitätsgarantie.

Anforderungs-ID: `RULE-SPELLS-MATERIAL-COMPONENTS`, Status weiterhin **partial**. Für diesen Branch muss die vollständige GitHub-CI **erst erfolgreich durchlaufen**, bevor ein Merge vertretbar ist.

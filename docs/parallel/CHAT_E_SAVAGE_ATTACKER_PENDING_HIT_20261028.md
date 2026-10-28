# Wilder Angreifer – gesicherte ausstehende Würfelentscheidung (28.10.2026)

Dieses Paket ergänzt ein optionales, validiertes und JSON-/SQLite-fähiges `pendingSavageAttackerHit` im bestehenden Kampagnenschema 1. Es speichert die Identität von Angriff/Gegner, Runde, Zielrevision und beide unabhängig gewürfelten Waffenpakete einschließlich separater Kritwürfel. Import prüft kanonische Notation, genaue Würfel und Summen, unverbrauchtes Herkunftstalent, aktuellen eigenen Zug, Ziel-/Runden-/Revisionsbezug und lehnt gleichzeitig offene W20-Proben ab.

Alte JSONs ohne Feld bleiben unverändert. `copyWith` erhält die Entscheidung, die explizit wieder entfernt werden kann. Der Charakter- oder Gegnerzustand wird durch dieses Paket **niemals** geändert. Die Testfälle schließen veränderte Würfelsummen, ungültige kritische Würfel, fehlendes Talent, Gegnerwechsel, fremde Runde und veraltete Revision aus.

**Nicht implementiert:** Das echte Erzeugen und Befüllen des Feldes nach einem von der GameEngine bestätigten Waffentreffer, revisionsgeschützte Controller-Bestätigung, Anzeigen des Dialogs in der Abenteueransicht sowie atomare Schaden-/Talentverbrauchsbuchung. Strukturierte Würfelnachweise sind keine kryptographische Echtheitsgarantie: Nur ein von der lokalen Engine ausgeführter Treffer darf künftig eine solche Entscheidung eröffnen.

Regel: D&D SRD 5.2.1, Savage Attacker (CC BY 4.0).

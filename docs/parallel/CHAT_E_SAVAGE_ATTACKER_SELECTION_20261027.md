# Chat E – Wilder Angreifer: verifizierter Würfeldialog (27.10.2026)

Der neue, isolierte Android-/Flutter-Dialog `SavageAttackerSelectionDialog` nimmt **ausschließlich bereits tatsächlich erzeugte** Waffenwürfel von einem vertrauenswürdigen Aufrufer entgegen. Er prüft den aktuellen eigenen Zug, die bestätigte Soldaten-Herkunft, einen unverbrauchten Talentstatus, die Identität des aktiven Gegnerkampfs und die beiden originalen/alternativen Würfelbelege erneut durch `SrdSavageAttackerRules.choose`.

Ohne ausdrückliches Antippen ist kein Wurf ausgewählt. Der Benutzer kann regelkonform auch den **niedrigeren** Wurf wählen. Bei kritischen Treffern werden beide vollständigen Waffenwürfel-Sets separat angezeigt; flache Waffenmodifikatoren werden separat und nur einmal erwähnt. Ungültige Varianten bleiben gesperrt. Der Dialog ist scrollbar, mit kompaktem Android-Viewport und großer Schrift getestet; Abbrechen hat keine Auswirkungen.

Die Rückgabe `SavageAttackerSelectionRequest` enthält ausschließlich `attackRollId`, `encounterId`, `expectedRevision` und die boolesche Alternativwahl; **keine** Würfelwerte, Schadenssummen oder TP-Änderungen aus der UI werden autoritativ übernommen.

**Wichtig: Es handelt sich um einen eigenständig getesteten, noch nicht an die Abenteuer-Oberfläche oder GameEngine angebundenen Dialog.** Um ihn im Spiel nutzen zu können, muss ein zukünftiges Paket nach bestätigtem Waffentreffer die Original- und Alternativwürfel **revisionssicher und persistent** bereitstellen und erst nach der Entscheidung den Verbrauch und Schadensübergang atomar committen. Keine bestehende Angriffsabwicklung wird hier verändert. SQLite-Version 2, Kampagnen-JSON 1, App-Version und andere parallele Chats bleiben unberührt.

Regelgrundlage: [SRD 5.2.1](https://www.dndbeyond.com/srd), *Savage Attacker* (CC BY 4.0).

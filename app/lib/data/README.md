# Lokales Kampagnengedächtnis

`SqliteCampaignRepository` hält SQLite-Schema 1, Charaktere, Einstellungen,
Kampagnensnapshots, ein unveränderliches Ereignisprotokoll und bestätigte
Revisionssnapshots. Spielleiter-Provider erhalten keinen Datenbankzugriff.

Die Domain liefert Revision 0 für neue Kampagnen und erhöht die Revision pro
bestätigter Aktion. Snapshot, Revisionsjournal und neue Ereignisse werden in
derselben Transaktion geschrieben. Veraltete Schreiber, veränderte Ereignisse
und global kollidierende Ereignis-IDs werden zurückgewiesen. Die erneute
Übermittlung einer bereits bestätigten identischen Revision ist idempotent.

`reconstructCampaign` liest eine bestätigte Revision unabhängig vom aktuellen
Snapshot. Der JSON-Export enthält den aktuellen bestätigten Zustand und alle
Ereignisse. Ein Import legt diesen Zustand als Ausgangsrevision an; frühere
Revisionssnapshots sind nicht Bestandteil des Exportformats. Vorhandene
Kampagnen werden beim Import nicht überschrieben. Ungültige Importe werden vor
dem Schreiben verworfen. Zukünftige SQLite-Schemaversionen werden abgelehnt,
nicht auf Version 1 zurückgesetzt.

Die Daten liegen lokal im App-Datenbereich. SQLite-Verschlüsselung und
Cloud-Synchronisierung sind noch nicht implementiert. Mikrofonaufnahmen werden
hier weder gespeichert noch benötigt.

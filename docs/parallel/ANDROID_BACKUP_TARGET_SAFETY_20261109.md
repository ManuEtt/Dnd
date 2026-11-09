# Android-SAF-Backupziele vor unbeabsichtigtem Überschreiben schützen

## Ausgangsproblem
`JsonBackupBridge` öffnete den vom Storage Access Framework zurückgegebenen URI unmittelbar mit `openOutputStream(uri, "w")` und löschte das Dokument bei Schreibfehlern oder Abbruch. Die Android-API-Referenz hält fest, dass `ACTION_CREATE_DOCUMENT` ein neues oder ein bereits vorhandenes Dokument zurückgeben kann. Ein vorhandenes Dokument darf daher nicht ungeprüft truncierend geöffnet oder bei Fehlern gelöscht werden.

Quelle: [Android Intent.ACTION_CREATE_DOCUMENT](https://developer.android.com/reference/android/content/Intent#ACTION_CREATE_DOCUMENT).

## Implementierung
- Vor dem Öffnen wird die Dokumentgröße über `OpenableColumns.SIZE` abgefragt.
- Nur eine nachweislich vorhandene Größe von exakt 0 Byte wird als sicheres Ziel akzeptiert.
- Nicht verfügbare, negative oder positive Größen werden fail-closed abgelehnt.
- Fehler- und Abbruchpfade löschen den zurückgegebenen URI nicht mehr. Damit bleibt eine mögliche partielle neue Datei erhalten, statt ein möglicherweise vorhandenes Nutzerdokument zu löschen.
- Bei fehlgeschlagenem Speichern wird darauf hingewiesen, dass eine unvollständige Datei zurückbleiben kann.

## Regressionstests
- Bestätigtes 0-Byte-Ziel wird akzeptiert.
- Unbekannte, negative und positive Dateigrößen werden abgelehnt.
- Bestehende Stream-, Größenlimit-, Abbruch- und Fehlerbehandlungstests bleiben erhalten.

## Grenzen
Die Metadatenprüfung kann externe Änderungen zwischen Abfrage und Öffnen nicht atomar verhindern. Es wird keine URI-Persistenz eingeführt. Bestehende Backups werden nicht migriert oder verändert. Die kombinierte CI ist nach PR-Erstellung abzunehmen; keine reale SAF-Provider-/Geräteabnahme in dieser Sitzung.

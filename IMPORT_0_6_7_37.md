# Import Würfelraunen 0.6.7+37

Grundlage: `ManuEtt/Dnd`, Commit `de88027f842a9dca80dd58ffccedb5a961551338` (0.6.6+36). Import nur auf diesem Stand oder mit sorgfältigem Drei-Wege-Abgleich.

- Gesamtprojekt: ZIP im Repository-Stamm entpacken; vorhandene Dateien wie gewohnt aktualisieren, **nicht** das Projektverzeichnis rekursiv löschen.
- Alternativ `git apply --check Dnd_Wuerfelraunen_0.6.7_37_Aenderungen.patch` und danach `git apply ...` im Repository-Stamm.
- `cd app && flutter pub get && flutter analyze && flutter test && flutter build apk --debug`.
- Sollte es Konflikte durch parallele Commits geben: Änderungen anhand des Patches einzeln abgleichen, nicht blind überschreiben.
- Die Ausführung/Testergebnisse für Flutter und APK werden erst nach CI-Abnahme als erfolgreich gekennzeichnet.

# Projekt-Import – Aetheria 0.3.4+10

1. Das ZIP auf dem Rechner entpacken. Der Inhalt hat **keinen** aeusseren Dnd-Ordner.
2. Auf https://github.com/ManuEtt/Dnd einen neuen Branch von `main` erstellen.
3. Den Inhalt dieses Verzeichnisses in die Repository-Wurzel hochladen. Bei
   bereits vorhandenen Pfaden die neue Dateiversion uebernehmen.
   Achtung: `.github/workflows/android-build.yml` ist versteckt; mit uebertragen.
4. Nicht nur das ZIP als einzelne Datei in GitHub ablegen.
5. Unter **Actions** den Workflow **Android-Alpha bauen** pruefen.
6. Nur bei gruener CI mergen; APKs unter **Artifacts** herunterladen.

Verifizierte Ausgangsbasis: commit `3b91a9778abe14184f35ac1db16f5acf121a84b5`
(Treeshash `fffbdeeb9624263cd7e2caa1427b11e5cea11e22`).

Anpassungen:
- Test zur Hausregel-Checkbox scrollt in die korrekte Richtung.
- Live-Vorschau fuer Staerke, Geschicklichkeit, Konstitution, Intelligenz,
  Weisheit und Charisma mit denselben Berechnungen wie RulesEngine.
- Neuer Widgettest sowie Versions- und Statusdokumentation.

Keine Flutter-/Android-Laufzeittests in der Paketumgebung: CI muss den
neuen Quellstand pruefen. Vor einem produktiven Einsatz Spielstaende sichern.

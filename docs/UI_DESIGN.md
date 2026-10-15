# Aetheria – deutscher Dark-Fantasy-Charakterbogen (0.3.9+15)

Die Implementierung in `app/lib/ui/fantasy_character_sheet.dart` übersetzt das abgestimmte Charakterbogen-Mockup in **echte Flutter-Widgets**, nicht in ein statisches Screenshot-Hintergrundbild. Dadurch sind die Beschriftungen deutsch, die Werte dynamisch, die Bereiche bedienbar und die Ansicht passt sich Android-Smartphones und Tablets an.

- **Kopfbereich:** Heldenname, Volk, Klasse, Stufe, stilisierter Initialen-Avatar, aktuelle/maximale Trefferpunkte samt Lebensbalken (nur bei gesicherten Werten).
- **Statuskacheln:** Übungsbonus, Bewegung in Metern, Initiative aus bestätigter Geschicklichkeit, Rüstungsklasse.
- **Attribute:** Stärke, Geschicklichkeit, Konstitution, Intelligenz, Weisheit, Charisma. Farblich voneinander unterschiedene Kacheln mit Modifikator und Grundwert.
- **Rettungswürfe:** Modifikator + Übungsbonus nur bei vorhandener Rettungswurf-Übung. Andere Sonderboni sind im Modell nicht erfasst und werden nicht vorgetäuscht.
- **Zustände:** Eingetragene Zustände und Merkmale; **Verteidigung:** RK, TP, Bewegung, Todesrettungswürfe.
- **Navigation:** Aus dem Heldentab „Bogen ansehen“ und aus dem Abenteuer „Charakterbogen ansehen“. Über das Stiftsymbol ist der bestehende Editor weiter erreichbar.

Das visuelle Vorbild enthält ein illustriertes Beispielporträt. Da es noch kein gespeichertem Charakterporträt zugeordnetes Feld gibt, nutzt die App bewusst Initialen statt jedem Helden das gleiche Bild zu geben. Ein eigenes, dauerhaft gespeichertes Porträt-Upload/Avatarfeature wäre eine getrennte spätere Erweiterung.

Die neue UI ändert keine Regeln, Datenbankschemata, KI-Verbindung oder gespeicherten Charakterwerte. Der nächste Schritt ist die CI-Abnahme und der echte Android-Designcheck.

# Würfelraunen 0.6.4+34 – Zauberressourcen und Konzentration

**Regelgrundlage:** D&D System Reference Document 5.2.1 unter CC BY 4.0, „Multiclassing“, „Spellcasting“, „Pact Magic“, „Concentration“, „Resting“; https://www.dndbeyond.com/srd.

## Jetzt implementiert

- Normaler Platzvorrat der im Projekt bereits implementierten Mehrklassen-Zaubertabelle von Grad 1 bis 9. Alle fünf Vollzauberklassen, Paladin und Waldläufer verwenden den zentralen Stufenrechner; ein gemischter Hexenmeister nutzt die Paktmagie separat.
- Paktmagie für die Hexenmeisterstufen 1 bis 20: Stufe 1 = 1 Platz, ab 2 = 2, ab 11 = 3 und ab 17 = 4; Platzgrad 1/2/3/4/5 je nach Klassenstufe.
- Persistenter, gegen Stufe und maximalen Pool validierter `spentSpellSlots`, `spentPactSlots`; ein aktiver Konzentrationszauber in `concentratingOn`. Altspeicher im bisherigen Schema 1 haben keine dieser Felder und beginnen mit unbenutzten Plätzen.
- Charaktereditor: bestätigte Zauberauswahl aus der ausdrücklich gespeicherten bekannten Liste, ausdrücklicher Grad und Konzentrationsstatus; Ressourcen werden erst mit Speicherung des Editors übernommen. Im Charakterbogen werden **verfügbare / maximale** Zauberplätze getrennt nach normal und Pakt angezeigt.
- Kurze Rast erneuert Paktmagie, auch wenn wegen voller Trefferpunkte keine Trefferwürfel verbraucht werden. Eine lange Rast stellt alle normalen Plätze und Paktmagie wieder her und beendet Konzentration. Die Zeitdauer wird derzeit nicht als Uhr geführt.
- Bei von der lokalen Kampfroutine erlittenem Schaden wird bei laufender Konzentration ein Konstitutionsrettungswurf gegen SG max(10, abgerundeter halber Schaden) protokolliert. Erschöpfung und Rettungswurfübung werden einmal angewandt, der natürliche W20 und der Gesamtwurf getrennt erhalten. Bei 0 TP, Tod oder bestimmter Handlungsunfähigkeit endet Konzentration ohne Rettung.
- Ein neuer Konzentrationszauber beendet den bisherigen. Die aktuell bekannten Fertigkeits-/Ausrüstungsverbote verhindern Zauberwirken in der Ressourcenregel.

## Noch bewusst nicht automatisiert

- **Die Liste bekannter Zauber ist Freitext ohne bestätigte SRD-Metadaten.** Daher müssen Grad, Material-/Zeitbedarf, Wirkbereich, Zauberdauer, Konzentrationspflicht und Klassenzugehörigkeit durch Spieler/Spielleiter ausdrücklich geprüft werden. Der Dialog bucht **nur** einen Platz, er löst **keine** Zauberwirkung, Ziele, Schaden oder Heilung aus.
- Keine vorbereiteten Zauber/Klassenzauber-Berechtigung, Ritual- und freie Klassenzauberprüfungen; keine Stufenbeschränkung für erlernbare Zauber jenseits des ausgewählten Platzes. Insbesondere ist das Menü **kein Regelbeweis**, dass ein Zauber auf dieser Charakterstufe erlaubt ist.
- Kein Durchsetzen von Aktionsökonomie/Bonusaktion/Reaktion, Zauberkomponenten, Sichtlinie, Reichweite, Upcasting-Effekten, Zaubertrick-Skalierung, Magiegegenstandsladungen oder Sonderwiederherstellung einzelner Klassenfähigkeiten.
- Der automatische Konzentrationsrettungswurf ist zunächst nur für lokal ausgeführte Gegnerangriffe integriert. Andere Schadensquellen müssen die reine `SpellcastingRules.saveAfterDamage`-Funktion ebenfalls aufrufen. Manuelle Würfe für diesen Fall benötigen später eine separate PendingRoll-Aktion.
- Keine KI-gestützte autonome Resource-Buchung oder freie Textausführung eines beliebigen Zaubers. Die UI führt nur bestätigte Ressourcenänderungen aus.

## Prüfung

- Neue Domain- und Widgettests: `app/test/spellcasting_rules_test.dart`, `app/test/spellcasting_dialog_test.dart`.
- Vor Android-Freigabe: `cd app && flutter pub get && flutter analyze && flutter test && flutter build apk --debug` ausführen. Lokal ist kein Flutter/Dart-SDK installiert. Projektstruktur und Python-Tests sind davon unabhängig.
- Bestehender Versionscode und Datenbankschema bleiben erhalten; nur App-Version `0.6.4+34` wird erhöht. Keine Änderung des lokalen Paketnamens oder des Backend-Protokolls.

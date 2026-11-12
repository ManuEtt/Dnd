# Unheimlicher Stoffwechsel: Klassenprüfung vor Initiative

Stand: 07.11.2026. Arbeitspaket für den Regeltrack; keine vollständige
SRD- oder Charaktererstellungsabnahme.

## Grundlage und Ausgangsfehler

- Requirement: `CLASS-M-NCH-2-BASE-UNCANNY-METABOLISM-2`.
- Wizards of the Coast, SRD 5.2.1, gedruckte Seite 51, Mönch Stufe 2,
  „Uncanny Metabolism“; [offizielle Quelle](https://www.dndbeyond.com/srd),
  CC BY 4.0. Lizenzhinweise in `THIRD_PARTY_NOTICES.md` bleiben erhalten.
- Ausgangs-Main: `0a813df100aa649c2204018349b0db9af09fb83f`.
- Branch: `fix/chat-a/monk-metabolism-preflight-20261106`.
- Wiederverwendete Abhängigkeit: PR [#589](https://github.com/ManuEtt/Dnd/pull/589),
  geprüfter Head `3cb3b0a08f8b0c478dd911c9efe460ec775b4d51`, regulär in
  den eigenen Branch übernommen. Keine fremden Branches verändert.

Der bisherige aktive Merkmalsaufruf leitete die Mönchsstufe auch aus
inkonsistenten Klassenprofilen ab. Beispielsweise konnte eine importierbare
historische Erstklasse mit Mönch 2 Fokus und TP erhalten. Außerdem würfelten
die drei Kampfeinstiege bereits Initiative, bevor sie die Nutzung prüften.

## Implementiert

`MonkInitiativeFeatures.prepareUncannyMetabolism` verwendet den öffentlichen
Klassenvalidator aus PR #589. Es prüft bestätigte Klassen und Klassenstufen,
Mönchsstufe, Kampffähigkeit und Ressourcen ohne Würfel oder Zustandsänderung.
`onInitiative` verwendet dieselbe Prüfung unmittelbar vor der ausgewählten
Regelwirkung. Die drei bestehenden Engine-Einstiege (KI-Abenteuerannahme,
Rabenwacht und Waldschrein) prüfen vor beiden Initiativewürfen.

Ein gültiger, ausdrücklich gewählter Einsatz heilt weiterhin um tatsächlichen
Kampfkünste-Würfel plus Mönchsklassenstufe bis zum bestätigten TP-Maximum,
erneuert alle Fokuspunkte und verbraucht genau eine Nutzung pro langer Rast.
Klassenaliasnamen, beide Klassenreihenfolgen und fremde Ressourcen bleiben
erhalten. Die bestehende deutsche KI-Angebotsschaltfläche benutzt diesen
Pfad. Normale Annahme aktiviert das Merkmal weiterhin nicht.

Keine Änderungen an Modell, Controller, SQLite-Schema, Importformat,
Ereignisformat oder passiver Perfekter-Fokus-Logik. Ältere Spielstände werden
nicht beim Öffnen verändert. Eine Datenmigration ist nicht erforderlich.

## Konkrete Nachweise

47 neue Tests:

- `app/test/monk_uncanny_metabolism_profile_test.dart`: 27 Domainfälle,
  ungültige Profile vor jedem Wurf, Aliase, Mehrklassen, getrennte Ressourcen,
  reine Vorprüfung, Fokusgrenzen, W6/W8/W10/W12 und TP-Obergrenze.
- `app/test/monk_uncanny_metabolism_profile_engine_test.dart`: 12 Fälle an
  allen drei tatsächlichen Kampfeinstiegen einschließlich fehlender Einwilligung.
- `app/test/monk_uncanny_metabolism_profile_flow_test.dart`: 6 echte SQLite-Fälle,
  historische Importe, Neustart, JSON-Roundtrip, doppelte Annahme, veraltete
  Revision und erzwungener später Transaktionsfehler mit vollständigem Rollback.
- `app/test/monk_uncanny_metabolism_profile_ui_test.dart`: 2 echte
  Oberflächenabläufe mit 360 dp, tatsächlichen Schaltflächen, deutschem
  Klassenfehler und Speicherung/Neustart.

Am 07.11.2026 bestanden alle **66 gezielten Tests**: diese 47, die vorhandenen
10 Stoffwechsel- und 5 Perfekter-Fokus-Tests sowie 4 Tests der Abhängigkeit.
Gesamtsuite, Android und CI sind damit noch nicht als bestanden ausgewiesen;
der Pull Request und der abschließende Checkpoint führen deren tatsächliche
Ergebnisse am geprüften Commit auf.

Bei veralteter Repositoryrevision und einem späten SQL-Fehler bleiben alle
sechs Tabellen unverändert. Der gültige Regelaufruf hat dann bereits drei
Würfe ausgeführt; Entropie wird durch ein Datenbankrollback nicht rückgängig
gemacht. Null Würfe sind für die frühe Klassenablehnung nachgewiesen.

## Grenzen und Wiederaufnahme

Die vorherige UI-Bestätigung für kampfauslösenden Freitext/Skriptaktionen
bleibt offen; deren bestehender Engine-Parameter ist abgesichert und getestet.
Passiver Perfekter Fokus wird separat in PR #586 bearbeitet. Keine doppelte
Implementierung dieses Pakets. Geräte-, TalkBack- und reale Android-
Updateprüfungen sind offen. Der Anforderungsstatus bleibt `partial`.

Gemeinsame README-/Checkpoint-Nachträge werden bei parallelen Änderungen
verlustfrei in einem eigenen Dokumentations-PR koordiniert. Vor Integration
aktuellen Main, PR #589 und die finale CI dieses kombinierten Branches prüfen;
grüne Einzel-CI der Abhängigkeit ersetzt keine kombinierte Abnahme.

Nächster fachlicher Schritt: nach Abgleich offener UI-/Integrations-PRs eine
ausdrückliche Bestätigung für Unheimlichen Stoffwechsel vor Skript-/Freitext-
Kampfbeginn koordinieren; Abbruch muss ohne Initiative, Ressourcenverbrauch
und bestätigte Zustandsänderung bleiben.

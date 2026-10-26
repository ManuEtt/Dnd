# Chat A – Säurespritzer-Zielidentitäten (26.10.2026)

## Ausgang und Akzeptanz
- Main: `dbeac3f7da4fa3a9759d447ef9e9eeb41d575970`, Branch: `fix/chat-a/acid-splash-target-identities-20261026`.
- Fehler: `AcidSplashRules.cast` akzeptierte Whitespace-Padding und Steuerzeichen in Ziel-IDs. In Mehrzielereignissen könnten dadurch optisch identische, aber technisch verschiedene Kennungen dokumentiert werden.
- Akzeptanz: Zwei normale einzigartige Kennungen führen zu unabhängigen Rettungswürfen mit einmaligem gemeinsamen Schadenswurf. Ungültige oder ambige Kennungen werden beim vollständigen Target-Preflight vor RNG, Ressourcenverbrauch und möglichen Event-Schreibvorgängen verworfen.

## Implementiert
- Nichtleere, an den Rändern unveränderte Ziel-IDs; ASCII-Steuerzeichen 0x00–0x1F und 0x7F verboten.
- Zwei deterministische Testfälle: gültige eindeutige IDs; Whitespace-/Steuerzeichen-Gegenfälle ohne RNG.
- Nur `app/lib/domain/acid_splash_rules.dart` und `app/test/acid_splash_rules_test.dart` fachlich verändert. SQL/JSON/öffentliche DTOs unverändert.
- SRD 5.2.1 `Acid Splash` (*Spell Descriptions*), Wizards of the Coast LLC, CC BY 4.0. Diese ID-Prüfung ist Projektdatenintegrität, keine zusätzliche SRD-Wirkung. `SPELL-ENTRY-ACID-SPLASH` bleibt `partial`.

## Getestet / Nicht getestet
- Lokale Flutter-/Dart-Ausführung: nicht möglich (SDK in aktueller Umgebung nicht installiert).
- Neue CI auf Paket-Commit: noch nicht ausgewertet.
- Android-Gerät, Upgrade und Produktivsignierung: nicht getestet.
- Vorherige grüne CI anderer Commits beweist keine Freigabe dieses Pakets.

## Koordination
PR #221 verändert Feuerpfeil, Controller, README und zentralen Checkpoint; dieses Paket berührt keine seiner Regellaufzeitdateien. README-/Checkpoint-Nachträge bei Integration koordinieren, nicht blind überschreiben. PRs #220/#222/#223/#224/#225 nicht verändert. Keine direkten Main-Commits oder Branchlöschungen.

## Nächster Schritt
Nach finalem CI-Lauf den PR prüfen lassen. Danach Säurespritzer-Zeitpunkt der klassenbezogenen Zauber-SG-Prüfung auf einen reproduzierbaren Fehler untersuchen.

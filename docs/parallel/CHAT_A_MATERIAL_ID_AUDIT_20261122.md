# Chat A – Übergabe: Unauffällige Inventar-IDs bei Zaubermaterialien

**Datum:** 22.11.2026 (Europe/Berlin)  
**Ausgangs-main:** `be011b52a7e785421387f47271876d67c6d12d5f`  
**Branch:** `feat/chat-a/material-id-invisible-variants-20261122`  
**Code/Test-Commit vor Dokumentation:** `c521911e5179d53f26910bf598067a4ba89b84cb`  
**Pull Request:** wird aus diesem Branch gegen `main` erstellt; maßgebliche Nummer in der PR-Ansicht.

## Ausgangsproblem

`SrdSpellInventoryIdRules.isSafe` lehnte bereits Format-/BiDi-Codes ab, ließ aber
Hangul- und Braille-Füllzeichen sowie BMP-/supplementäre Variationsselektoren zu.
Damit können verschiedene Inventarstapelkennungen bei einer expliziten
Materialbestätigung visuell gleich aussehen. Das betrifft bereits existierende
geprüfte Zaubermaterialbindungen, nicht die SRD-Zauberwerte selbst.

## Abgrenzung / Akzeptanzkriterien

- Für ein materielles Zauber-Audit werden visuell leere ID-Erweiterungen
  unverändert zurückgewiesen (fail closed).
- Verifizierte gültige Unicode-Kennungen einschließlich CJK, Akzenten und
  gewöhnlichen Leerzeichen bleiben zugelassen.
- Ungültige Bindungen dürfen weder Zauberplätze verbrauchen noch das Inventar
  ändern. Auch ein unbeteiligter ungültiger Stapel blockiert einen Commit.
- Keine Erzähl-/UI-Änderung, keine Migration, keine Änderung an SQLite/JSON,
  öffentlicher Fassade oder Ressourcenberechnung.

## Implementiert

- `app/lib/domain/srd_spell_inventory_id_rules.dart`: Filter um bekannte
  visuell leere Füllzeichen und Unicode-Variationsselektoren ergänzt.
  Supplementäre Selektoren werden mit Unicode-RegExp-Modus erkannt.
- `app/test/srd_spell_inventory_id_guard_test.dart`: drei Tests zu elf
  problematischen Codepoints, akzeptierten internationalen Kennungen,
  geprüften Mehrmaterialbindungen und nicht auditierten Zauber-Commits.

## Quellen, Nachweis, Grenzen

- Bestehende Regelgrundlage: Wizards of the Coast LLC, *SRD 5.2.1*,
  Abschnitt **Spells / Casting Spells / Components**, CC BY 4.0.
  <https://www.dndbeyond.com/srd>
- Dies ist eine Sicherheitsvalidierung vorhandener bestätigter
  Inventarmaterialien. Keine weitere SRD-Regelwirkung wurde als `tested`
  eingestuft, und die Inventurlücken bleiben offen.
- **GETESTET (eingeschränkt):** ECMAScript-/JavaScript-RegExp-Smoke mit
  dem tatsächlich geschriebenen Muster, 11 abgelehnte und 5 erlaubte
  Fälle bestanden. Dies ist ausdrücklich kein Dart-/Flutter-Test.
- **NICHT GETESTET:** Dart-Formatierung, Flutter-Analyse, neue Flutter-Tests,
  gesamte Testsuite, Python-Skripte, Backend und Android-APK; lokales
  Flutter-/Dart-SDK nicht verfügbar. PR-CI nach Erstellung prüfen.
- **CI-Baseline:** jüngster geprüfter `main`-Lauf
  <https://github.com/ManuEtt/Dnd/actions/runs/44712986953> schlug
  beim Android-Debug-APK-Build fehl. Keine Aussage zu den neuen Änderungen.
- **Migration:** keine; bestehende Spielstände werden nicht konvertiert,
  bleiben lesbar. Ein bisher erlaubter, visuell unklarer Stapel-ID-Wert
  muss vor einem neuen Material-Commit korrigiert werden.

## Konflikte und Dokumentationskoordination

Offene PRs #783, #773 und weitere ändern `README.md` und
`docs/CODEX_CHECKPOINT.md`; #783 ändert außerdem
`docs/parallel/CHAT_A_CHECKPOINT.md`. Um deren Historie und
Append-only-Regel nicht zu überschreiben, wird der Stand konfliktfrei
in **dieser eigenständigen Übergabedatei** und in der PR-Beschreibung
gesichert. Die zentralen Nachträge sind von der koordinierten Integration
verlustfrei am absoluten README-Dateiende bzw. in den Checkpoints einzupflegen.

## Nächster konkreter Schritt

Drei neuen Flutter-Tests plus die vorhandenen Material-/Inventar-Tests in
der PR-CI ausführen und die Meldungen prüfen; Akzeptanz nur bei
tatsächlich bestandener Formatierung, Analyse und Tests. Bei Fehlern
ausschließlich diesen Branch korrigieren, kein ungeprüfter Merge.

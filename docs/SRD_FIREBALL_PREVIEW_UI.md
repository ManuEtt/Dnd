# Feuerball-Kartenvorschau in der Abenteueransicht (SRD 5.2.1)

Stand 21. Oktober 2026. Regellizenz: SRD 5.2.1, CC BY 4.0, [offizielle SRD-Übersicht](https://www.dndbeyond.com/srd); Feuerball: *Casting Time Action, Range 150 feet, 20-foot-radius Sphere*. Das Repository führt die vollständige SRD-Attribution im App-Quelltext.

## Neu in der Benutzeroberfläche

In der laufenden Abenteueransicht ist die Aktion **„Feuerball-Kartenvorschau“** verfügbar. Sie öffnet einen Dialog, in dem die Spielleitung eine **explizit kartierte** taktische Ebene als 12×12-, 20×20- oder 32×32-Fußraster (je Feld = 5 Fuß) auswählen kann. Standardmäßig dienen die Felder (2,5) und (6,5) als rein beispielhafte Start-/Ursprungspositionen. Mit drei Werkzeugen können die Figur (S), der Zielursprung (Z) und voll blockierende Hindernisfelder (X) durch Antippen gesetzt oder umgeschaltet werden.

**Vor jeder Berechnung** muss ausdrücklich bestätigt sein, dass sämtliche für die betrachtete Ebene relevanten voll blockierenden Felder erfasst wurden. Nach **jeder** Kartenänderung oder Kartenvergrößerung erlischt diese Bestätigung und ein zuvor berechnetes Overlay wird verworfen.

Die Berechnung benutzt **nur** den SRD-katalogisierten `Fireball` und die separate, bekannte Feuerball-Wirkungsform (20-Fuß-Kugel). Die zuvor vorhandenen Regeln `SrdSpellGridTargetRules.validateOrigin` und `SrdSphereAreaRules.previewConfirmedSpell` prüfen den Weg zur Wirkungsursprungsposition und die Kandidatenfelder. Andere Zauber können nicht ungeprüft die Feuerball-Form erhalten.

Die interaktive Darstellung kennzeichnet:
- Mittelpunkt innerhalb des 2D-Kugelradius (●),
- nur möglicherweise überlappende Randfelder (·),
- ungeklärten Deckungs-/Mittelpunktstrahl (?),
- Figur, Zielursprung und Vollhindernisse.

Es werden nur **mögliche Rasterfelder zur Vorbereitung** angezeigt. Kein Ziel wird automatisch als getroffen eingestuft. Insbesondere beweist ein blockierter Mittelpunktstrahl keine vollständige Deckung; die SRD-Sphäre ist dreidimensional und ihre Wirkung bedarf noch gesonderter regelgeprüfter Feld-, Höhe-, Deckungs-, Rettungswurf-, Kreaturen- und Effektlogik.

## Architektur und Sicherheit

Der Dialog ist vollständig **lokaler, flüchtiger UI-Zustand**. Öffnen, Berechnen, Bearbeiten und Schließen verändern niemals `Campaign`, `HeroCharacter`, `Encounter`, `CampaignRepository`, Zauberplätze, Inventar oder Ereignisjournal. Die Funktion plant keinen automatischen Zaubervorgang und umgeht keinen Zug bzw. keine Aktionsökonomie. Sie erscheint als separat gekennzeichnetes Planungswerkzeug in der Abenteueransicht; die eigentlichen Kampfzauber-Aktionen bleiben unverändert.

Die Dialog-ID, Werkzeuge, Kartenfelder, Bestätigungsfunktion, Berechnung und Schließen besitzen stabile Widget-Test-Keys. `app/test/srd_fireball_grid_preview_dialog_test.dart` prüft explizite Kartenfreigabe, Invalidierung beim Editieren, gesperrten Weg, Wiederherstellung nach Entfernen des Blockers, fehlende Berechtigung zur Formübernahme durch einen anderen Zauber und Abbruch ohne Wirkung.

Code: `app/lib/ui/srd_fireball_grid_preview_dialog.dart`, `app/lib/ui/app.dart`; unveränderte Regeldomäne: `app/lib/domain/srd_spell_grid_target_rules.dart`, `app/lib/domain/srd_sphere_area_rules.dart`. Audit `RULE-SPELLS-SPELL-AREAS-OF-EFFECT` weiterhin **partial**, weil eine UI-Vorschau keine vollständige SRD-Regelabdeckung bedeutet.

### CI-Abnahme

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/srd_fireball_grid_preview_dialog_test.dart
flutter test
flutter build apk --debug
```

Ein grüner CI-Build ersetzt keine manuelle Prüfung auf Android-Geräten, mit Touch-Eingabe und verschiedenen Bildschirmgrößen.

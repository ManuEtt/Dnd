# Würfelraunen – Fixierte Schnellaktionen (0.5.3+23)

Die vier bestehenden Aktionen (`Sprache`, `Untersuchen`, `Angriff`, `W20`) werden nun als `FantasyPinnedActionBar` am unteren Ende von `_AdventurePage` angezeigt, unabhängig vom scrollbaren `ListView` beziehungsweise der `CombatView`. Der Haupt-`Scaffold` platziert darunter die Bottom-Navigation.

## Verhalten

- Die Fantasyszene und Chatnachrichten sind scrollbar, die Schnellaktionen bleiben am unteren Bildschirmrand über der Navigation.
- Die Abenteuereingabe bleibt oberhalb der Schnellaktionen erreichbar.
- Die Buttons behalten ihre früheren Callback-Funktionen: Mikrofon, lokale Untersuchung als Aktionstext, Angriff als Aktionstext und Würfeldialog.
- Bei geöffneter Tastatur verschwindet lediglich die Leistenüberschrift; redundante Buttons im Texteingabepanel werden dann ausgeblendet, um Platz zu sparen.
- Die Aktionen bleiben auch in der Kampfübersicht verfügbar.
- `FantasyShortcutTile(compact: true)` stellt eine niedrige Variante für kleine Bildschirme bereit.

## Qualitätssicherung

Der Test `app/test/fantasy_pinned_actions_test.dart` prüft die Position trotz Scrollen, alle vier Callback-Aktionen, Bildschirmgrößen von 320/360/400 dp sowie die Sichtbarkeit bei geöffneter Tastatur. Ein zusätzlicher Test in `app/test/ui_app_test.dart` kontrolliert das Verhalten in der tatsächlichen Abenteuerseite.

Bitte in GitHub Actions `flutter analyze`, `flutter test` und `flutter build apk --debug` ausführen. Ohne erfolgreichen Lauf gilt dieses Quellpaket nicht als Android-abgenommen.

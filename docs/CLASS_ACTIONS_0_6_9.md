# Würfelraunen 0.6.9+39 — Ausführbare Klassenaktionen

**Basis:** Vollprojekt 0.6.8+38 / GitHub `main` `3ecf536f7fdc1549cf11ffd6139483f7b72c0b71` (16.10.2026). **Quelle:** SRD 5.2.1 (CC BY 4.0), Barbarian (Rage), Rogue (Sneak Attack/Cunning Action), Damage, Combat.

## Neu im bestätigten Kampfsystem

- **Barbar: Kampfrausch** durch Eingabe `Kampfrausch`: benötigt Barbarstufe, Bonusaktion und keine schwere Rüstung; verbraucht eine `rage`-Ressource, beendet Konzentration, setzt eine zeitlich begrenzte Rage im `Encounter`. Erfolgreicher Stärke-Nahkampftreffer mit bestätigter Katalogwaffe erhält den alters-/stufengerechten Schadensbonus. Auch **verfehlte Angriffswürfe** verlängern Kampfrausch. Über `Kampfrausch verlängern` lässt sich ein aktiver Kampfrausch auch durch die Bonusaktion verlängern, ohne einen zusätzlichen Nutzungspunkt auszugeben. Maximal 100 Kampfrunden. Die Rage endet automatisch am Ende des nicht verlängerten Zuges.
- **Kampfrausch-Resistenz:** Nur wenn `Encounter.enemyDamageType` eindeutig als `bludgeoning`, `piercing` oder `slashing` hinterlegt ist, wird der Schaden vor dem TP-Abzug halbiert und die Reduktion protokolliert. Bei unbekannter Schadensart wird **keine** Resistenz angenommen. Diese neue Eigenschaft ist optional und ältere Spielstände bleiben kompatibel.
- **Schurke: Flinke Aktion — Sprinten** durch `Flinke Aktion: Sprinten`: ab Schurkenstufe 2, einmal pro Zug als Bonusaktion; addiert die aktuelle effektive Bewegungsrate und lässt die reguläre Aktion unangetastet. Andere Bonusaktionen konkurrieren weiterhin darum.
- **Schurke: Hinterhältiger Angriff:** Bei bestätigtem Vorteil, passender ausgerüsteter Finesse- oder Fernkampfwaffe und einem Treffer werden zusätzliche W6 ausgewürfelt (bei kritischen Treffern doppelte Zahl). Höchstens einmal pro Zug, auch bei Zusatzaktionen. Das Ereignisjournal enthält die Bonuswürfel. Das neue Flag wird je Zug zurückgesetzt und mit der Kampagne gespeichert. Die Option durch einen benachbarten handlungsfähigen Verbündeten bleibt ungenutzt, da das vorhandene Kampfmodell keine bestätigte Verbündetenposition speichert. Vorteil wird **nicht** aus beliebiger Erzählung angenommen.
- **Vorteil/Nachteil:** Beide gleichzeitig heben sich auf; ein danach neutraler Angriff mit bestätigtem Verbündeten kann nach der SRD-Regel Hinterhältiger Angriff auslösen (reiner Regelhelfer, noch ohne Verbündeten-Positionsmodell).

## Noch nicht vollständig automatisiert

- **Barbar:** Der allgemeine Charakterproben- und Zauber-Dialog kennt die nur im `Encounter` gespeicherte Kampfrauschdauer noch nicht; Stärke-Proben-Vorteil, Zaubersperre, schweren Rüstungwechsel sowie weitere Auslöser (z. B. erzwingender Rettungswurf) benötigen die nächste Integration in die gemeinsame Effektengine. Keine Behauptung eines vollständigen Rage-Modells.
- **Schurke:** Flinke Aktion „Verstecken“ und „Rückzug“ benötigen Sicht- und Gelegenheitangriffsregeln; Positionsbezug und bewusste Spielerwahl zum Verzichten auf Sneak Attack stehen noch aus.
- **Kreaturen:** Alte Gegnerwerte haben keine bestätigte Schadensart. Die neue Resistenz wird für solche Gegner bewusst **nicht** angewendet.
- **Tests:** Neue Domain- und Integrationstests in `app/test/combat_class_actions_test.dart` sowie aktualisierte Kern-Tests. Python-Projekttests bestanden. Flutter-/Android-Tests wurden ohne Flutter SDK **nicht** ausgeführt.

## Import und Prüfung

Die Projektdateien aus diesem ZIP gehören in das Repository-Verzeichnis (einschließlich der versteckten `.github`-Dateien). Vor dem Import ist der aktuelle GitHub-Stand zu sichern. Danach im Projektverzeichnis:

```bash
python3 scripts/verify_project.py .
python3 -m unittest discover -s scripts/tests
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Die Änderungen auf GitHub zu committen erfordert GitHub-Schreibrechte. `main` wurde hier nicht verändert.

## CI-Korrekturen aus GitHub-0.6.8

Der GitHub-Actions-Lauf `38854472360` scheiterte bei `flutter analyze` an drei Lint-Hinweisen in `srd_class_feature_catalog.dart` (Stringverkettung, unnötige Interpolationsklammern, fehlende `if`-Klammern). Diese Stellen wurden ohne Änderung der erzeugten Feature-IDs oder des Zuordnungsverhaltens überarbeitet. Ein neuer GitHub-Analyse-Lauf ist für dieses ZIP **noch nicht erfolgt**.

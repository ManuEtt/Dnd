# Kämpfer-Kampfstile – erste ausführbare Regeln

Regelquelle: [D&D SRD 5.2.1, Fighting Style Feats](https://www.dndbeyond.com/srd), CC BY 4.0.

**Bogenschießen:** +2 auf bestätigte Fernkampfwaffen-Angriffsproben. Wurfnahkampfwaffen lösen den Bonus nicht aus. Gilt im echten Kampf und bei der Vorschau der Ausrüstung.

**Verteidigung:** +1 Rüstungsklasse beim Anlegen einer leichten, mittleren oder schweren Rüstung. Ein Schild allein genügt nicht. Die Ausrüstungsvorschau und Bestätigung übernehmen den Bonus.

Bedingungen: Kämpferklasse vorhanden, Stil ausdrücklich auf dem Charakterbogen vermerkt und Item über Inventar-ID plus offiziellen SRD-Katalog bestätigt. Frühere Spielstände ohne die Auswahl bleiben unberührt.

**Noch offen:** Die Sonderwürfel von „Kampf mit großen Waffen“ und der Zusatzangriff mit „Kampf mit zwei Waffen“ benötigen weitere isolierte Implementierungen und Tests. Die Auswahl allein aktiviert keine erfundene Mechanik.

Tests: `app/test/fighter_style_combat_rules_test.dart`. GitHub Actions prüft Flutter, Backend und Android.

## Kampf mit großen Waffen – nächster ausführbarer Stil

Beim tatsächlichen Waffenschaden zählt jede natürliche 1 oder 2 auf einem
Waffenschadenswürfel als 3. Das gilt ebenso für zusätzliche Waffenschadenswürfel
eines kritischen Treffers; der Attributsmodifikator wird nur einmal addiert.
Voraussetzung: gewählter Kämpfer-Kampfstil, bestätigte zweihändig geführte
SRD-Nahkampfwaffe und passender Schadenswürfelausdruck. Vielseitige Waffen
brauchen ihre Zweihand-Schadensvariante. Wurfwaffen sind vorsorglich ausgenommen,
solange kein Angriffsmodus gespeichert wird.

**Weiter offen:** Kampf mit zwei Waffen benötigt einen eigenen, bestätigten
Zusatzangriff einer anderen leichten Waffe einschließlich Aktionsökonomie.
Die bloße Kampfstil-Auswahl erzeugt noch keinen solchen Angriff.

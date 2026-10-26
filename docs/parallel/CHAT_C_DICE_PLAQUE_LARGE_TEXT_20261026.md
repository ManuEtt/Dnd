# Chat C – Würfelplaketten bei 200 % Systemschrift

Bei 320 und 360 dp mit 200 % Android-Schriftgröße werden die dekorativen Würfel-Icons in der read-only Würfelchronik ausgeblendet. Dadurch bleibt die gesamte Breite für bestätigte Einzelwürfel, ausgewählten W20, Bonus und kritische Treffer. Bei normaler Schrift bleiben die bisherigen Icons sichtbar.

Die Darstellung wird nur über `MediaQuery.textScalerOf(context).scale(1) >= 1.8` angepasst. Weder Würfelwerte noch die strenge Allowlist für bestätigte Ereignisfelder, kritische Treffer oder technische `stateAfter`-Daten ändern sich.

Tests: `app/test/fantasy_dice_breakdown_test.dart` prüft 320/360 dp, 200 % Schrift, vollständige Angriffs-/Schadenswerte und ausgeblendete Ziericons. Eine vollständige Android-CI und ein echter Gerätetest sind gesondert zu bestätigen. Keine Änderungen an SRD, Kampagne, Backend, Persistenz oder App-Version.

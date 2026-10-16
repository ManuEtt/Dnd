# Projektimport – Version 0.6.8+38

Diese Version basiert auf dem **vollständigen Quellstand 0.6.7+37** (nicht auf dem älteren `main`-Commit 0.6.6). Sie enthält neue SRD-Klassenregister, Ressourcen, Kampf- und Charakterbogenberechnungen.

## Vollprojekt-ZIP

Das ZIP enthält alle bisherigen Projektdateien. Entpacke den Inhalt in ein neues oder bewusst aktualisiertes Arbeitsverzeichnis; prüfe vor dem Überschreiben eigene Änderungen. Die `.git`-Daten werden absichtlich nicht mitgeliefert.

## Patch

Der Patch ist **nur** für den Stand 0.6.7+37 bestimmt. Vorherige Versionen müssen zuerst auf 0.6.7+37 gebracht werden.

```bash
git apply --check Dnd_Wuerfelraunen_0.6.8_38_Aenderungen.patch
git apply Dnd_Wuerfelraunen_0.6.8_38_Aenderungen.patch
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Wenn GitHub Schreibrechte verweigert, kann das lokale Projekt mit dem ZIP importiert und in einem eigenen Commit hochgeladen werden. Es gibt hier **keinen bestätigten GitHub-Push** und **keine geprüfte APK**.

Siehe `docs/CLASS_FEATURES_0_6_8.md` für den Unterschied zwischen Merkmal-Auflistung und ausführbaren Merkmalwirkungen.

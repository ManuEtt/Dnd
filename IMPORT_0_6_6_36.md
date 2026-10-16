# Würfelraunen 0.6.6+36 – Import und Tests

**Ausgangsversion:** Repo `ManuEtt/Dnd`, Commit `26d1d8b949555ea12ad55d6ed173528397157351` (0.6.5+35).
**Aktualisierung:** neue Klassenmeilenstein- und Mehrfachangriffsregeln.

## Variante A: ganzes Projekt importieren

1. Sicherung/Branch deines aktuellen Repositories erstellen.
2. Das ZIP `Dnd_Wuerfelraunen_0.6.6_36_Vollprojekt.zip` entpacken. `README.md`, `app/`, `backend/` und `.github/` liegen **direkt im ZIP-Stamm**.
3. Alle Dateien **in die Repositorywurzel kopieren** und vorhandene Dateien ersetzen. Dateien, die nur lokal im Repo vorliegen, nicht blind löschen.
4. Neue Dateien mit committen, insbesondere `app/lib/domain/class_progression_rules.dart` und die beiden Dart-Tests.
5. CI ausführen. Nur nach `flutter analyze`, `flutter test`, erfolgreichem Android-Build ist eine APK als geprüft anzusehen.

## Variante B: Patch auf genau den Ausgangscommit

```bash
git fetch origin
git checkout -b feature/class-progress-0.6.6 26d1d8b949555ea12ad55d6ed173528397157351
git apply --check Dnd_Wuerfelraunen_0.6.6_36_Aenderungen.patch
git apply Dnd_Wuerfelraunen_0.6.6_36_Aenderungen.patch
git add -A
git commit -m "feat: SRD class milestones and extra attacks"
git push -u origin feature/class-progress-0.6.6
```

**Hinweis:** Kein automatischer GitHub-Push durch diesen Arbeitslauf. Die GitHub-App-Verbindung erlaubt Lesen, aber das Anlegen eines Branches schlägt mit HTTP 403 fehl. Der Quellstand enthält **keine kompilierte APK**.

## Eigenständige Prüfungen

```bash
python3 scripts/verify_project.py .
python3 -m unittest discover -s scripts/tests -v
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Details zu SRD-Anforderungen und Grenzen: `docs/CLASS_PROGRESSION_0_6_6.md`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _startEditor(
  WidgetTester tester,
  HeroCharacter? hero,
  void Function(HeroCharacter?) saved, {
  bool autoFillExistingCombatValues = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              saved(
                await Navigator.push<HeroCharacter>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CharacterEditor(
                      hero: hero,
                      autoFillExistingCombatValues: autoFillExistingCombatValues,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Editor öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Editor öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Bestehender Charakter: fehlende RK und Bewegung werden berechnet',
    (tester) async {
      HeroCharacter? result;
      final original = HeroCharacter(
        id: 'without-ac',
        name: 'Liora',
        species: 'Mensch',
        className: 'Waldläufer',
        abilities: const {'dexterity': 16},
      );
      await _startEditor(tester, original, (value) => result = value);
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('character-recalculate-combat-values')),
      );
      final speedField = find.byKey(const ValueKey('character-speed-meters'));
      await tester.scrollUntilVisible(
        speedField,
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextFormField>(speedField).controller!.text, '9');
      await _tapVisible(tester, find.text('Charakter speichern'));
      expect(result, isNotNull);
      expect(result!.armorClass, 13);
      expect(result!.speed, 9);
      expect(result!.speedRemainderDecimeters, 0);
    },
  );

  testWidgets(
    'Neue menschliche Figur: Bewegung sofort und RK nach GE-Eingabe',
    (tester) async {
      HeroCharacter? result;
      await _startEditor(tester, null, (value) => result = value);
      final speed = find.byKey(const ValueKey('character-speed-meters'));
      await tester.scrollUntilVisible(
        speed,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextFormField>(speed).controller!.text, '9');

      final dexterity = find.widgetWithText(TextFormField, 'Geschicklichkeit');
      await tester.scrollUntilVisible(
        dexterity,
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(dexterity, '16');
      await tester.pumpAndSettle();
      final armorField = find.widgetWithText(TextFormField, 'Rüstungsklasse');
      await tester.scrollUntilVisible(
        armorField,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextFormField>(armorField).controller!.text, '13');

      // Manual ability values need the existing explicit rules exception.
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('allow-manual-abilities')),
      );
      final name = find.widgetWithText(TextFormField, 'Charaktername');
      await tester.scrollUntilVisible(
        name,
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(name, 'Aelia');
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Charakter speichern'));
      expect(result, isNotNull);
      expect(result!.armorClass, 13);
      expect(result!.speed, 9);
    },
  );

  testWidgets(
    'Vorhandene manuelle RK und Bewegung werden nicht überschrieben',
    (tester) async {
      HeroCharacter? result;
      final original = HeroCharacter(
        id: 'manual-values',
        name: 'Skara',
        species: 'Mensch',
        className: 'Waldläufer',
        abilities: const {'dexterity': 16},
        armorClass: 18,
        speed: 12,
      );
      await _startEditor(tester, original, (value) => result = value);
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('character-recalculate-combat-values')),
      );
      await _tapVisible(tester, find.text('Charakter speichern'));
      expect(result!.armorClass, 18);
      expect(result!.speed, 12);
    },
  );

  testWidgets('Goliath-Spezies wird mit 10,5 Metern vorgeschlagen', (
    tester,
  ) async {
    await _startEditor(tester, null, (_) {});
    final species = find.widgetWithText(TextFormField, 'Spezies');
    await tester.scrollUntilVisible(
      species,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(species);
    await tester.pumpAndSettle();
    await tester.enterText(species, 'Goliath');
    await tester.pumpAndSettle();
    final speed = find.byKey(const ValueKey('character-speed-meters'));
    await tester.scrollUntilVisible(
      speed,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextFormField>(speed).controller!.text, '10,5');
  });

  testWidgets(
    'Bestehender Held: bekannte Kampfwerte ohne Knopfdruck ergänzen',
    (tester) async {
      HeroCharacter? result;
      final hero = HeroCharacter(
        id: 'old-hero-missing-values',
        name: 'Borin',
        species: 'Goliath',
        className: 'Kämpfer',
        abilities: const {'dexterity': 14},
      );
      await _startEditor(
        tester,
        hero,
        (value) => result = value,
        autoFillExistingCombatValues: true,
      );
      final speed = find.byKey(const ValueKey('character-speed-meters'));
      await tester.scrollUntilVisible(
        speed,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextFormField>(speed).controller!.text, '10,5');
      final armor = find.widgetWithText(TextFormField, 'Rüstungsklasse');
      await tester.scrollUntilVisible(
        armor,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextFormField>(armor).controller!.text, '12');
      await _tapVisible(tester, find.text('Charakter speichern'));
      expect(result!.armorClass, 12);
      expect(result!.speed, 10);
      expect(result!.speedRemainderDecimeters, 5);
    },
  );

  testWidgets('Unbekannte SRD-Werte bleiben auch beim Bearbeiten unbestätigt', (
    tester,
  ) async {
    HeroCharacter? result;
    await _startEditor(
      tester,
      HeroCharacter(
        id: 'unknown-stats',
        name: 'Kera',
        species: 'Eigene Spezies',
        className: 'Kämpfer',
      ),
      (value) => result = value,
    );
    final speed = find.byKey(const ValueKey('character-speed-meters'));
    await tester.scrollUntilVisible(
      speed,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextFormField>(speed).controller!.text, '');
    final armor = find.widgetWithText(TextFormField, 'Rüstungsklasse');
    await tester.scrollUntilVisible(
      armor,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextFormField>(armor).controller!.text, '');
    await _tapVisible(tester, find.text('Charakter speichern'));
    expect(result!.armorClass, isNull);
    expect(result!.speed, isNull);
  });
}

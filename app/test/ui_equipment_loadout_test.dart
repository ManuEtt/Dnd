import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/equipment_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/equipment_loadout_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  testWidgets('Ausrüstung nur mit bestätigter Vorschau übernehmen', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'h',
      name: 'Held',
      abilities: {
        'strength': 16,
        'dexterity': 14,
        'constitution': 10,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
      },
      inventory: const [
        InventoryItem(
          id: 'armor',
          name: 'Lederrüstung',
          catalogId: 'armor-leather-armor',
        ),
      ],
    );
    EquipmentRulePreview? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showDialog<EquipmentRulePreview>(
                    context: context,
                    builder: (_) => EquipmentLoadoutDialog(hero: hero),
                  ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('loadout-confirm')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('loadout-armor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lederrüstung').last);
    await tester.pumpAndSettle();
    expect(find.text('Rüstungsklasse: 13'), findsOneWidget);
    final confirm = tester.widget<FantasyTextButton>(
      find.byKey(const ValueKey('loadout-confirm')),
    );
    expect(confirm.onPressed, isNotNull);
    expect(confirm.style, FantasyButtonStyle.woodGold);
    await tester.ensureVisible(find.byKey(const ValueKey('loadout-confirm')));
    await tester.tap(find.byKey(const ValueKey('loadout-confirm')));
    await tester.pumpAndSettle();
    expect(result?.armorClass, 13);
    expect(hero.equippedArmorId, isEmpty);
  });
}

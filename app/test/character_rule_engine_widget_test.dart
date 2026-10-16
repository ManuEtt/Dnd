import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

void main() {
  testWidgets('Charakterbogen zeigt dieselbe effektive Bewegung und Erschöpfung',
      (tester) async {
    tester.view.physicalSize = const Size(400, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final hero = HeroCharacter(
      id: 'h', name: 'Liora', species: 'Mensch', className: 'Kämpfer',
      level: 5, speed: 9, armorClass: 16, hitPoints: 30, maxHitPoints: 30,
      exhaustionLevel: 2, conditions: ['vergiftet'],
      abilities: const {'strength': 12, 'dexterity': 14,
        'constitution': 12, 'wisdom': 12},
      savingThrowProficiencies: const ['strength'],
    );
    await tester.pumpWidget(MaterialApp(home: CharacterSheetPage(hero: hero)));
    await tester.pumpAndSettle();
    expect(find.text('6 m'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sheet-tab-1')));
    await tester.pumpAndSettle();
    final fatigue = find.byKey(const ValueKey('sheet-exhaustion-effects'));
    expect(fatigue, findsOneWidget);
    expect(tester.widget<Text>(fatigue).data, contains('W20-Tests −4'));
    expect(find.textContaining('Nachteil auf Angriffswürfe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/primary_class_level_up.dart';
import 'package:lebendiger_spielleiter/ui/primary_class_level_up_dialog.dart';

HeroCharacter _hero(int level, {int experience = 0}) => HeroCharacter(
  id: 'dialog-hero',
  name: 'Sera',
  className: 'Kämpfer',
  level: level,
  experience: experience,
  maxHitPoints: 22,
  hitPoints: 18,
  abilities: {
    'strength': 16,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 11,
    'charisma': 8,
  },
);

Future<void> _open(
  WidgetTester tester, HeroCharacter hero,
  void Function(SrdPrimaryLevelUpProposal?) save,
) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Builder(builder: (context) => TextButton(
      onPressed: () async {
        save(await showDialog<SrdPrimaryLevelUpProposal>(
          context: context,
          builder: (_) => PrimaryClassLevelUpDialog(hero: hero),
        ));
      },
      child: const Text('Aufstieg öffnen'),
    ))),
  ));
  await tester.tap(find.text('Aufstieg öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Ohne EP keine Änderung, bestätigter Meilenstein erlaubt Aufstieg',
      (tester) async {
    SrdPrimaryLevelUpProposal? result;
    final before = _hero(1);
    await _open(tester, before, (value) => result = value);
    await tester.tap(find.byKey(const ValueKey('primary-level-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('primary-level-error')), findsOneWidget);
    expect(result, isNull);
    await tester.tap(find.byKey(const ValueKey('primary-level-milestone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('primary-level-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(PrimaryClassLevelUpDialog), findsNothing);
    expect(result!.applyTo(before).level, 2);
    expect(result!.applyTo(before).experience, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Klassenstufe drei verlangt explizit die SRD-Unterklasse',
      (tester) async {
    SrdPrimaryLevelUpProposal? result;
    final before = _hero(2, experience: 900);
    await _open(tester, before, (value) => result = value);
    await tester.tap(find.byKey(const ValueKey('primary-level-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('primary-level-error')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('primary-level-subclass')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('primary-level-confirm')));
    await tester.pumpAndSettle();
    expect(result!.applyTo(before).subclass, 'Champion');
    expect(result!.applyTo(before).level, 3);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/fighter_creation_rules.dart';
import 'package:lebendiger_spielleiter/ui/srd_class_selection_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  testWidgets(
    'new fighter needs a constitution score to confirm all level-1 traits',
    (tester) async {
      SrdClassSetupResult? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await showDialog<SrdClassSetupResult>(
                      context: context,
                      builder: (_) => const SrdClassSelectionDialog(
                        currentClass: 'Kämpfer',
                        existingSkills: [],
                        existingSavingThrows: [],
                        characterLevel: 1,
                        constitutionScore: null,
                        hasExistingHitPoints: false,
                        allowEquipment: true,
                        isNewCharacter: true,
                      ),
                    ),
                child: const Text('Klasse wählen'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Klasse wählen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kämpfer Stufe 1'), findsOneWidget);
      expect(find.text('Start-EP: 0 · Übungsbonus: +2'), findsOneWidget);
      expect(
        tester
            .widget<FantasyButton>(
              find.byKey(const ValueKey('srd-confirm-class')),
            )
            .onPressed,
        isNull,
      );
      expect(result, isNull);
    },
  );

  test('fighter exposes enough different documented SRD weapon masteries', () {
    expect(
      FighterCreationRules.masteryWeapons.map((w) => w.id).toSet().length,
      greaterThanOrEqualTo(3),
    );
  });
}

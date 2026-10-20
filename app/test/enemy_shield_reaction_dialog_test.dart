import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/magic_missile_dialog.dart';

void main() {
  testWidgets(
    'Shield wird nur mit bestätigten Ressourcen und Komponenten gewählt',
    (tester) async {
      MagicMissileChoice? selection;
      final hero = HeroCharacter(
        id: 'mage',
        name: 'Ada',
        className: 'Magier',
        level: 1,
        spells: const ['Magisches Geschoss'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selection = await showDialog<MagicMissileChoice>(
                    context: context,
                    builder: (_) => MagicMissileDialog(
                      hero: hero,
                      encounter: const Encounter(
                        id: 'enemy',
                        enemyName: 'Zaubernder Gegner',
                        enemyHitPoints: 20,
                        enemyMaxHitPoints: 20,
                      ),
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      Future<void> tapConfirmed(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      for (final key in [
        'missile-visible',
        'missile-range',
        'missile-verbal',
        'missile-somatic',
      ]) {
        await tapConfirmed(key);
      }
      await tapConfirmed('missile-force-defense');
      await tester.tap(find.text('Normaler Energieschaden').last);
      await tester.pumpAndSettle();
      await tapConfirmed('missile-shield-reaction');
      expect(
        find.byKey(const ValueKey('missile-shield-components')),
        findsOneWidget,
      );
      await tapConfirmed('missile-shield-components');

      final confirm = find.byKey(const ValueKey('missile-confirm'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(selection, isNull);
      expect(find.textContaining('Bitte alle tatsächlichen'), findsOneWidget);

      await tapConfirmed('missile-shield-slots');
      await tester.tap(find.text('2 freie Plätze (Grad 1+)').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(selection, isNotNull);
      expect(selection!.shieldReactionConfirmed, isTrue);
      expect(selection!.shieldPreparedAndComponentsConfirmed, isTrue);
      expect(selection!.noProtectionConfirmed, isFalse);
      expect(selection!.confirmedEnemyShieldSlots, 2);
      expect(selection!.confirmedForceDefense, EnemyForceDefense.normal);
    },
  );
}

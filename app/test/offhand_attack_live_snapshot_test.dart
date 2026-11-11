import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/offhand_attack_dialog.dart';

HeroCharacter _hero({bool withAxe = true, String id = 'rogue'}) {
  return HeroCharacter(
    id: id,
    name: 'Nara',
    className: 'Schurke',
    level: 3,
    abilities: const {
      'strength': 12,
      'dexterity': 16,
      'constitution': 14,
      'intelligence': 10,
      'wisdom': 10,
      'charisma': 10,
    },
    hitPoints: 24,
    maxHitPoints: 24,
    armorClass: 14,
    speed: 9,
    weaponDamage: '1d6',
    weaponAbility: 'dexterity',
    weaponProficient: true,
    equippedWeaponId: 'main',
    inventory: [
      const InventoryItem(
        id: 'main',
        name: 'Hauptkurzschwert',
        catalogId: 'weapon-shortsword',
      ),
      const InventoryItem(
        id: 'dagger',
        name: 'Nebendolch',
        catalogId: 'weapon-dagger',
      ),
      if (withAxe)
        const InventoryItem(
          id: 'axe',
          name: 'Nebenhandaxt',
          catalogId: 'weapon-handaxe',
        ),
    ],
  );
}

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  final target = tester.widget(finder) is CheckboxListTile
      ? find.descendant(of: finder, matching: find.byType(Checkbox))
      : finder;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String key, String label) async {
  await _tap(tester, _key(key));
  await _tap(tester, find.text(label).last);
}

Future<void> _approveAxe(WidgetTester tester) async {
  await _select(tester, 'offhand-weapon', 'Nebenhandaxt');
  await _select(
    tester,
    'offhand-proficiency-axe',
    'Mit dieser Waffe geübt',
  );
  await _tap(tester, _key('offhand-weapons-held'));
  await _tap(tester, _key('offhand-attack-approved'));
  final confirmButton = tester.widget<FantasyTextButton>(
    _key('offhand-attack-confirm'),
  );
  expect(confirmButton.onPressed, isNotNull);
}

Future<void> _showDialog(
  WidgetTester tester, {
  required HeroCharacter Function() hero,
  required String Function() targetName,
  required void Function(StateSetter) exposeRebuild,
  required ValueChanged<OffhandAttackChoice?> onClosed,
}) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final choice = await showDialog<OffhandAttackChoice>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, repaint) {
                    exposeRebuild(repaint);
                    return OffhandAttackDialog(
                      hero: hero(),
                      targetName: targetName(),
                    );
                  },
                ),
              );
              onClosed(choice);
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Öffnen'));
}

void main() {
  testWidgets('Same hero retains explicit consent', (tester) async {
    final currentHero = _hero();
    StateSetter? repaint;
    final results = <OffhandAttackChoice?>[];
    await _showDialog(
      tester,
      hero: () => currentHero,
      targetName: () => 'Goblin',
      exposeRebuild: (value) => repaint = value,
      onClosed: results.add,
    );
    await _approveAxe(tester);
    repaint!(() {});
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(_key('offhand-attack-approved')).value,
      isTrue,
    );
    final confirmButton = tester.widget<FantasyTextButton>(
      _key('offhand-attack-confirm'),
    );
    expect(confirmButton.onPressed, isNotNull);
    await _tap(tester, _key('offhand-attack-confirm'));
    expect(results, hasLength(1));
    expect(results.single?.weaponId, 'axe');
    expect(results.single?.playerConfirmed, isTrue);
  });

  testWidgets('New hero revokes obsolete weapon choice', (tester) async {
    var currentHero = _hero();
    StateSetter? repaint;
    final results = <OffhandAttackChoice?>[];
    await _showDialog(
      tester,
      hero: () => currentHero,
      targetName: () => 'Goblin',
      exposeRebuild: (value) => repaint = value,
      onClosed: results.add,
    );
    await _approveAxe(tester);
    repaint!(() => currentHero = _hero(withAxe: false, id: 'new-rogue'));
    await tester.pumpAndSettle();

    expect(find.text('Nebenhandaxt'), findsNothing);
    final selectedWeapon = tester.widget<DropdownButtonFormField<String>>(
      _key('offhand-weapon'),
    );
    expect(selectedWeapon.initialValue, isNull);
    expect(
      tester.widget<CheckboxListTile>(_key('offhand-weapons-held')).value,
      isFalse,
    );
    expect(
      tester.widget<CheckboxListTile>(_key('offhand-attack-approved')).value,
      isFalse,
    );
    expect(_key('offhand-attack-preview'), findsNothing);
    final confirmButton = tester.widget<FantasyTextButton>(
      _key('offhand-attack-confirm'),
    );
    expect(confirmButton.onPressed, isNull);
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);

    await _select(tester, 'offhand-weapon', 'Nebendolch');
    await _select(
      tester,
      'offhand-ability-dagger',
      'Geschicklichkeit (Finesse)',
    );
    await _select(
      tester,
      'offhand-proficiency-dagger',
      'Mit dieser Waffe geübt',
    );
    await _tap(tester, _key('offhand-weapons-held'));
    await _tap(tester, _key('offhand-attack-approved'));
    await _tap(tester, _key('offhand-attack-confirm'));
    expect(results.single?.weaponId, 'dagger');
    expect(results.single?.playerConfirmed, isTrue);
  });

  testWidgets('New target revokes confirmed attack', (tester) async {
    final currentHero = _hero();
    var targetName = 'Goblin';
    StateSetter? repaint;
    final results = <OffhandAttackChoice?>[];
    await _showDialog(
      tester,
      hero: () => currentHero,
      targetName: () => targetName,
      exposeRebuild: (value) => repaint = value,
      onClosed: results.add,
    );
    await _approveAxe(tester);
    repaint!(() => targetName = 'Wolf');
    await tester.pumpAndSettle();

    expect(find.text('Angriffsziel: Wolf'), findsOneWidget);
    final selectedWeapon = tester.widget<DropdownButtonFormField<String>>(
      _key('offhand-weapon'),
    );
    expect(selectedWeapon.initialValue, isNull);
    expect(
      tester.widget<CheckboxListTile>(_key('offhand-attack-approved')).value,
      isFalse,
    );
    final confirmButton = tester.widget<FantasyTextButton>(
      _key('offhand-attack-confirm'),
    );
    expect(confirmButton.onPressed, isNull);
    await _tap(tester, _key('offhand-attack-cancel'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/ability_assignment_dialog.dart';
import 'package:lebendiger_spielleiter/ui/character_effect_dialog.dart';
import 'package:lebendiger_spielleiter/ui/condition_effect_dialog.dart';
import 'package:lebendiger_spielleiter/ui/equipment_catalog_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/multiclass_selection_dialog.dart';
import 'package:lebendiger_spielleiter/ui/spellcasting_dialog.dart';

void main() {
  Future<void> show(WidgetTester tester, Widget dialog) async {
    tester.view.physicalSize = const Size(480, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: dialog)),
      ),
    );
    await tester.pumpAndSettle();
  }

  FantasyTextButton action(WidgetTester tester, String name) {
    return tester.widget<FantasyTextButton>(find.byKey(ValueKey(name)));
  }

  testWidgets('Zauberaktion ist magisch, aber ohne Zauber nicht verfügbar', (
    tester,
  ) async {
    await show(
      tester,
      SpellcastingDialog(
        hero: HeroCharacter(id: 'mage', name: 'Mira'),
      ),
    );
    final cast = action(tester, 'spell-dialog-cast');
    expect(cast.label, 'Verbrauch bestätigen');
    expect(cast.style, FantasyButtonStyle.arcane);
    expect(cast.onPressed, isNull);
    expect(find.text('Abbrechen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zweitklassenbestätigung ist magisch und explizit', (
    tester,
  ) async {
    await show(
      tester,
      MulticlassSelectionDialog(
        hero: HeroCharacter(
          id: 'warrior',
          name: 'Tira',
          className: 'Kämpfer',
          level: 3,
          experience: 2700,
        ),
      ),
    );
    final button = action(tester, 'multiclass-accept');
    expect(button.label, 'Stufenaufstieg übernehmen');
    expect(button.style, FantasyButtonStyle.arcane);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Attributzuweisung kann vor vollständiger Wahl nicht speichern', (
    tester,
  ) async {
    await show(tester, const AbilityAssignmentDialog());
    final apply = action(tester, 'apply-ability-assignment');
    expect(apply.style, FantasyButtonStyle.woodGold);
    expect(apply.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schaden und Heilung werden erst ausdrücklich bestätigt', (
    tester,
  ) async {
    await show(
      tester,
      CharacterEffectDialog(
        hero: HeroCharacter(
          id: 'hero',
          name: 'Mira',
          hitPoints: 7,
          maxHitPoints: 12,
        ),
      ),
    );
    expect(
      action(tester, 'character-effect-confirm').style,
      FantasyButtonStyle.arcane,
    );
    expect(
      action(tester, 'character-effect-cancel').style,
      FantasyButtonStyle.iron,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zustand und Abbruch haben unterscheidbare Materialien', (
    tester,
  ) async {
    await show(
      tester,
      ConditionEffectDialog(
        hero: HeroCharacter(id: 'hero', name: 'Mira'),
        encounter: null,
      ),
    );
    expect(
      action(tester, 'condition-effect-confirm').style,
      FantasyButtonStyle.arcane,
    );
    expect(
      action(tester, 'condition-effect-cancel').style,
      FantasyButtonStyle.iron,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inventarkatalog besitzt einen echten Abbrechen-Button', (
    tester,
  ) async {
    await show(tester, const EquipmentCatalogDialog());
    final cancel = tester.widget<FantasyTextButton>(
      find.byWidgetPredicate(
        (widget) => widget is FantasyTextButton && widget.label == 'Abbrechen',
      ),
    );
    expect(cancel.style, FantasyButtonStyle.iron);
    expect(cancel.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

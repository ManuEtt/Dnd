import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/experience_progression.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/experience_reward_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

Finder _field(String name) => find.byKey(ValueKey('xp-reward-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterReward(
  WidgetTester tester, {
  String id = 'quest-erfolg',
  String amount = '300',
}) async {
  await tester.enterText(_field('id'), id);
  await tester.enterText(_field('amount'), amount);
  await tester.pumpAndSettle();
}

Future<void> _approve(WidgetTester tester) async {
  await _tap(tester, _field('consent'));
}

bool _approved(WidgetTester tester) =>
    tester.widget<CheckboxListTile>(_field('consent')).value ?? false;

bool _canConfirm(WidgetTester tester) =>
    tester.widget<FantasyTextButton>(_field('confirm')).onPressed != null;

String _value(WidgetTester tester, String field) =>
    tester.widget<TextField>(_field(field)).controller!.text;

Future<void> _open(
  WidgetTester tester, {
  required Campaign Function() campaign,
  required ValueChanged<StateSetter> onRebuild,
  required ValueChanged<ExperienceRewardChoice?> onResult,
}) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final choice = await showDialog<ExperienceRewardChoice>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, rebuild) {
                    onRebuild(rebuild);
                    return ExperienceRewardDialog(campaign: campaign());
                  },
                ),
              );
              onResult(choice);
            },
            child: const Text('EP öffnen'),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('EP öffnen'));
}

void main() {
  testWidgets('Same campaign keeps the deliberate draft and consent', (
    tester,
  ) async {
    final campaign = GameEngine().createDemo();
    final initial = campaign.toJson();
    StateSetter? rebuild;
    final choices = <ExperienceRewardChoice?>[];
    await _open(
      tester,
      campaign: () => campaign,
      onRebuild: (setter) => rebuild = setter,
      onResult: choices.add,
    );
    await _enterReward(tester);
    await _approve(tester);
    expect(_canConfirm(tester), isTrue);

    rebuild!(() {});
    await tester.pumpAndSettle();

    expect(_value(tester, 'id'), 'quest-erfolg');
    expect(_value(tester, 'amount'), '300');
    expect(_approved(tester), isTrue);
    expect(_field('snapshot-notice'), findsNothing);
    await _tap(tester, _field('confirm'));

    expect(choices, hasLength(1));
    expect(choices.single?.rewardId, 'quest-erfolg');
    expect(choices.single?.requestId, 'xp_quest-erfolg');
    expect(campaign.toJson(), initial);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New campaign revision revokes the approved XP draft', (
    tester,
  ) async {
    var campaign = GameEngine().createDemo();
    StateSetter? rebuild;
    final choices = <ExperienceRewardChoice?>[];
    await _open(
      tester,
      campaign: () => campaign,
      onRebuild: (setter) => rebuild = setter,
      onResult: choices.add,
    );
    await _enterReward(tester);
    await _approve(tester);
    expect(_canConfirm(tester), isTrue);

    rebuild!(
      () => campaign = campaign.copyWith(revision: campaign.revision + 1),
    );
    await tester.pumpAndSettle();

    expect(_field('snapshot-notice'), findsOneWidget);
    expect(_value(tester, 'id'), isEmpty);
    expect(_value(tester, 'amount'), isEmpty);
    expect(_approved(tester), isFalse);
    expect(_canConfirm(tester), isFalse);
    expect(choices, isEmpty);

    await _enterReward(tester, id: 'quest-neu', amount: '200');
    expect(_canConfirm(tester), isFalse);
    await _approve(tester);
    expect(_canConfirm(tester), isTrue);
    await _tap(tester, _field('confirm'));
    expect(choices.single?.rewardId, 'quest-neu');
    expect(choices.single?.amount, 200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Changed hero with unknown XP rejects old approval', (
    tester,
  ) async {
    var campaign = GameEngine().createDemo();
    StateSetter? rebuild;
    final choices = <ExperienceRewardChoice?>[];
    await _open(
      tester,
      campaign: () => campaign,
      onRebuild: (setter) => rebuild = setter,
      onResult: choices.add,
    );
    await _enterReward(tester);
    await _approve(tester);

    rebuild!(
      () => campaign = campaign.copyWith(
        hero: campaign.hero.copyWith(experience: null),
      ),
    );
    await tester.pumpAndSettle();

    expect(_field('snapshot-notice'), findsOneWidget);
    expect(_value(tester, 'id'), isEmpty);
    expect(_approved(tester), isFalse);
    expect(find.textContaining('bisherigen EP-Stand'), findsOneWidget);
    await _enterReward(tester);
    await _approve(tester);
    expect(_canConfirm(tester), isFalse);
    await _tap(tester, _field('cancel'));
    expect(choices, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New receipt snapshot requires explicit fresh review', (
    tester,
  ) async {
    var campaign = GameEngine().createDemo();
    StateSetter? rebuild;
    final choices = <ExperienceRewardChoice?>[];
    await _open(
      tester,
      campaign: () => campaign,
      onRebuild: (setter) => rebuild = setter,
      onResult: choices.add,
    );
    await _enterReward(tester, id: 'quest-doppelt');
    await _approve(tester);
    expect(_canConfirm(tester), isTrue);

    rebuild!(
      () => campaign = ExperienceProgression.grant(
        campaign,
        rewardId: 'quest-doppelt',
        amount: 300,
      ),
    );
    await tester.pumpAndSettle();

    expect(_field('snapshot-notice'), findsOneWidget);
    expect(_value(tester, 'id'), isEmpty);
    expect(_approved(tester), isFalse);
    expect(_canConfirm(tester), isFalse);

    await _enterReward(tester, id: 'quest-doppelt');
    expect(find.textContaining('Bereits gebucht'), findsOneWidget);
    expect(_canConfirm(tester), isFalse);
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).label,
      'Buchung prüfen',
    );
    await _approve(tester);
    await _tap(tester, _field('confirm'));
    expect(choices.single?.requestId, 'xp_quest-doppelt');
    expect(campaign.hero.experience, 300);
    expect(tester.takeException(), isNull);
  });
}

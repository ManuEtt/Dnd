import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_bard_font_of_inspiration.dart';
import 'package:lebendiger_spielleiter/ui/srd_bard_font_of_inspiration_dialog.dart';

HeroCharacter testBard({
  int level = 5,
  int spent = 1,
  String second = '',
  int secondLevel = 0,
}) => HeroCharacter(
  id: 'font-campaign-bard',
  name: 'Skaldin',
  className: 'Barde',
  level: level,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  hitPoints: 20,
  maxHitPoints: 20,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 10,
    'charisma': 16,
  },
  spentClassResources: {'bardicInspiration': spent},
);

void main() {
  test('Bardenaktion: beide Ressourcen und ein Audit-Ereignis pro Commit', () {
    final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 28));
    final campaign = engine.createDemo(hero: testBard());
    final proposal = SrdBardFontOfInspirationRules.propose(
      hero: campaign.hero,
      slotLevel: 1,
    );
    final result = engine.confirmBardFontOfInspiration(
      campaign,
      proposal,
      playerConfirmed: true,
    );
    final saved = Campaign.fromJson(result.campaign.toJson());

    expect(saved.revision, campaign.revision + 1);
    expect(result.events, hasLength(1));
    expect(result.events.single.type, 'class.bardFontOfInspiration');
    expect(result.events.single.payload['inspirationRecovered'], 1);
    expect(saved.hero.spentSpellSlots['1'], 1);
    expect(saved.hero.spentClassResources['bardicInspiration'], isNull);
    expect(campaign.hero.spentSpellSlots, isEmpty);
    expect(campaign.hero.spentClassResources['bardicInspiration'], 1);
    expect(
      () => engine.confirmBardFontOfInspiration(
        saved,
        proposal,
        playerConfirmed: true,
      ),
      throwsFormatException,
    );
  });

  test('ohne Spielerbestätigung bleibt der gesamte Zustand unverändert', () {
    final engine = GameEngine();
    final campaign = engine.createDemo(hero: testBard());
    final before = campaign.toJson();
    final proposal = SrdBardFontOfInspirationRules.propose(
      hero: campaign.hero,
      slotLevel: 1,
    );
    expect(
      () => engine.confirmBardFontOfInspiration(
        campaign,
        proposal,
        playerConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(campaign.toJson(), before);
  });

  testWidgets('Auswahl und Abbrechen ändern keine Inspiration', (tester) async {
    final hero = testBard();
    SrdBardFontProposal? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showBardFontOfInspirationDialog(context, hero);
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Quelle der Inspiration'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(hero.spentSpellSlots, isEmpty);

    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bard-font-confirm')));
    await tester.pumpAndSettle();
    expect(selected, isNotNull);
    expect(hero.spentSpellSlots, isEmpty);
    final committed = selected!.applyTo(hero);
    expect(committed.spentSpellSlots['1'], 1);
    expect(committed.spentClassResources['bardicInspiration'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unter Stufe fünf erscheint keine Umwandlungsentscheidung', (
    tester,
  ) async {
    final hero = testBard(level: 4);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Nicht verfügbar'))),
    );
    final result = await showBardFontOfInspirationDialog(
      tester.element(find.text('Nicht verfügbar')),
      hero,
    );
    expect(result, isNull);
    expect(find.byKey(const ValueKey('bard-font-confirm')), findsNothing);
  });
}

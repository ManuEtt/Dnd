import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/sending_attempt_dialog.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'sending-ime-hero',
  name: 'Nora',
  className: 'Magier',
  level: 5,
  spells: const ['Sending'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 14,
    'charisma': 12,
  },
  maxHitPoints: 28,
  hitPoints: 28,
);

Finder _field(String name) => find.byKey(ValueKey('sending-$name'));

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required HeroCharacter hero,
  required SrdSpellDefinition sending,
  required ValueChanged<SendingAttemptChoice?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await showDialog<SendingAttemptChoice>(
                  context: context,
                  builder: (_) =>
                      SendingAttemptDialog(hero: hero, sending: sending),
                ),
              );
            },
            child: const Text('Sending öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Sending öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final scrollable = find
      .descendant(
        of: find.byType(SendingAttemptDialog),
        matching: find.byType(Scrollable),
      )
      .first;
  for (var attempt = 0; attempt < 14; attempt++) {
    if (target.hitTestable().evaluate().isNotEmpty) break;
    await tester.drag(scrollable, const Offset(0, -140));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellDefinition sending;

  setUpAll(() async {
    sending = (await SrdSpellCatalogLoader.load()).find('Sending')!;
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('Sending $width dp/200 %/IME: sicher abbrechen', (
      tester,
    ) async {
      final hero = _hero();
      final snapshot = hero.toJson();
      final results = <SendingAttemptChoice?>[];
      await _open(
        tester,
        width: width,
        hero: hero,
        sending: sending,
        onResult: results.add,
      );
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      expect(
        find.ancestor(of: _field('message'), matching: find.byType(Scrollable)),
        findsOneWidget,
      );
      expect(
        tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
        isNull,
      );
      await tester.enterText(_field('recipient'), 'npc-tarek');
      await _tap(tester, _field('cancel'));
      expect(results, [null]);
      expect(hero.toJson(), snapshot);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('200 %/IME: bewusste Auswahl ohne Heldenmutation', (
    tester,
  ) async {
    final hero = _hero();
    final snapshot = hero.toJson();
    final results = <SendingAttemptChoice?>[];
    await _open(
      tester,
      width: 320,
      hero: hero,
      sending: sending,
      onResult: results.add,
    );
    await tester.enterText(_field('recipient'), 'npc-tarek');
    await tester.enterText(_field('message'), 'Bitte melde dich.');
    await _tap(tester, _field('knowledge'));
    await tester.tap(find.text('Persönlich getroffen').last);
    await tester.pumpAndSettle();

    expect(
      (tester.widget<CheckboxListTile>(_field('action')).title! as Text)
          .semanticsLabel,
      contains('höchstens ein Zauberplatz'),
    );
    expect(find.text('Aktion und Zauberplatz bestätigt'), findsOneWidget);
    await _tap(tester, _field('creature'));
    await _tap(tester, _field('action'));
    await _tap(tester, _field('components'));

    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNull,
    );
    await _tap(tester, _field('consent'));
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNotNull,
    );
    await tester.enterText(_field('message'), 'Bitte antworte.');
    await tester.pump();
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNull,
    );
    await _tap(tester, _field('consent'));
    await _tap(tester, _field('confirm'));
    expect(results, hasLength(1));
    expect(results.single!.preview.recipient.message, 'Bitte antworte.');
    expect(results.single!.preview.recipient.recipientId, 'npc-tarek');
    expect(results.single!.requestId, startsWith('sending_'));
    expect(hero.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_effect_ward.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

const _spells = ValueKey('ward-manage-spell-effects');
const _conditions = ValueKey('ward-manage-effects');

Widget _screen({
  required HeroCharacter hero,
  required double scale,
  VoidCallback? onManage,
  VoidCallback? onManageSpells,
}) => MaterialApp(
  theme: buildFantasyTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: ListView(
      children: [
        FantasyEffectWard(
          hero: hero,
          onManage: onManage,
          onManageSpells: onManageSpells,
        ),
      ],
    ),
  ),
);

void _smallScreen(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final button = find.byKey(key);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  expect(button.hitTestable(), findsOneWidget);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Zustandskreis $width dp bei 200 % Schrift und IME: beide Aktionen umbrechen',
      (tester) async {
        _smallScreen(tester, width);
        final hero = HeroCharacter(
          id: 'ward-hero',
          name: 'Liora',
          concentratingOn: 'Schutzzauber',
        );
        final snapshot = hero.toJson();
        var spells = 0;
        var conditions = 0;

        await tester.pumpWidget(
          _screen(
            hero: hero,
            scale: 2,
            onManageSpells: () => spells++,
            onManage: () => conditions++,
          ),
        );
        await tester.pumpAndSettle();
        expect(spells, 0);
        expect(conditions, 0);

        for (final entry in <Key, String>{
          _spells: 'Zauberwirkungen verwalten',
          _conditions: 'Zustandsquellen verwalten',
        }.entries) {
          final button = find.byKey(entry.key);
          expect(button, findsOneWidget);
          final row = tester.widget<Row>(
            find.descendant(of: button, matching: find.byType(Row)).first,
          );
          final expandedText = row.children.whereType<Expanded>().single;
          final text = expandedText.child as Text;
          expect(text.data, entry.value);
          expect(text.maxLines, isNull);
          expect(text.softWrap, isTrue);
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          final rect = tester.getRect(button);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(button.hitTestable(), findsOneWidget);
        }

        await _tapVisible(tester, _spells);
        expect(spells, 1);
        expect(conditions, 0);
        await _tapVisible(tester, _conditions);
        expect(spells, 1);
        expect(conditions, 1);
        expect(hero.toJson(), snapshot);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Zustandskreis $width dp ohne Verwaltungsrechte: keine erfundenen Aktionen',
      (tester) async {
        _smallScreen(tester, width);
        final hero = HeroCharacter(id: 'old', name: 'Alt');
        final snapshot = hero.toJson();
        await tester.pumpWidget(_screen(hero: hero, scale: 2));
        await tester.pumpAndSettle();
        expect(find.byKey(_spells), findsNothing);
        expect(find.byKey(_conditions), findsNothing);
        expect(find.text('Keine aktive Konzentration'), findsOneWidget);
        expect(hero.toJson(), snapshot);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Normale Schrift behält kompakte Icon-TextButtons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var count = 0;
    await tester.pumpWidget(
      _screen(
        hero: HeroCharacter(id: 'hero', name: 'Liora'),
        scale: 1,
        onManage: () => count++,
        onManageSpells: () => count++,
      ),
    );
    await tester.pumpAndSettle();
    final buttons = find.byType(TextButton);
    expect(buttons, findsNWidgets(2));
    for (final key in [_spells, _conditions]) {
      final button = find.byKey(key);
      expect(button, findsOneWidget);
      expect(
        find.ancestor(of: button, matching: find.byType(Align)),
        findsWidgets,
      );
      await tester.tap(button);
    }
    expect(count, 2);
    expect(tester.takeException(), isNull);
  });
}

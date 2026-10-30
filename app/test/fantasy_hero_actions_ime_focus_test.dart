import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_campaign_dashboard.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  final hero = HeroCharacter(
    id: 'hero-action-focus',
    name: 'Arescan',
    species: 'Elf',
    className: 'Waldläufer',
    level: 3,
    hitPoints: 18,
    maxHitPoints: 24,
    armorClass: 16,
    speed: 9,
  );

  Future<void> mountCard(
    WidgetTester tester, {
    required double width,
    required double textScale,
    required VoidCallback? onContinue,
    required VoidCallback onHeroes,
    bool keyboard = true,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    if (keyboard) {
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            children: [
              const TextField(key: ValueKey('hero-action-keyboard-field')),
              Expanded(
                child: ListView(
                  children: [
                    FantasyActiveHeroCard(
                      hero: hero,
                      campaignName: 'Nebelwacht',
                      onContinue: onContinue,
                      onHeroes: onHeroes,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool focusedWithin(WidgetTester tester, String key) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return find
        .descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byElementPredicate(
            (element) => identical(element, context),
          ),
        )
        .evaluate()
        .isNotEmpty;
  }

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Heldenaktionen bei $width dp, 200 % und IME gestapelt bedienbar',
      (tester) async {
        var continued = 0;
        var heroes = 0;
        final oldHero = hero.toJson();
        await mountCard(
          tester,
          width: width,
          textScale: 2,
          onContinue: () => continued++,
          onHeroes: () => heroes++,
        );
        await tester.showKeyboard(
          find.byKey(const ValueKey('hero-action-keyboard-field')),
        );
        await tester.pumpAndSettle();

        final resume = find.byKey(const ValueKey('fantasy-hero-continue'));
        final archive = find.byKey(const ValueKey('fantasy-hero-archive'));
        expect(
          tester.getTopLeft(archive).dy,
          greaterThan(tester.getBottomLeft(resume).dy),
        );
        expect(
          tester.getSize(resume).width,
          closeTo(tester.getSize(archive).width, 1),
        );
        await tester.ensureVisible(resume);
        await tester.pumpAndSettle();
        expect(resume.hitTestable(), findsOneWidget);
        await tester.tap(resume);
        await tester.ensureVisible(archive);
        await tester.pumpAndSettle();
        expect(archive.hitTestable(), findsOneWidget);
        await tester.tap(archive);
        expect([continued, heroes], [1, 1]);
        expect(hero.toJson(), oldHero);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Tab und Enter folgen der Heldenaktions-Reihenfolge bei IME', (
    tester,
  ) async {
    final invoked = <String>[];
    await mountCard(
      tester,
      width: 320,
      textScale: 2,
      onContinue: () => invoked.add('continue'),
      onHeroes: () => invoked.add('heroes'),
    );
    await tester.showKeyboard(
      find.byKey(const ValueKey('hero-action-keyboard-field')),
    );
    await tester.pumpAndSettle();

    for (final action in ['continue', 'archive']) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        focusedWithin(tester, 'fantasy-hero-$action'),
        isTrue,
        reason: 'Tastaturfokus bei $action',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }
    expect(invoked, ['continue', 'heroes']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Deaktivierte Fortsetzung wird beim Tab-Fokus übersprungen', (
    tester,
  ) async {
    var heroes = 0;
    await mountCard(
      tester,
      width: 320,
      textScale: 2,
      onContinue: null,
      onHeroes: () => heroes++,
    );
    await tester.showKeyboard(
      find.byKey(const ValueKey('hero-action-keyboard-field')),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedWithin(tester, 'fantasy-hero-archive'), isTrue);
    expect(focusedWithin(tester, 'fantasy-hero-continue'), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(heroes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bei normaler Schrift bleibt die kompakte Aktionsreihe', (
    tester,
  ) async {
    await mountCard(
      tester,
      width: 960,
      textScale: 1,
      keyboard: false,
      onContinue: () {},
      onHeroes: () {},
    );
    final resume = find.byKey(const ValueKey('fantasy-hero-continue'));
    final archive = find.byKey(const ValueKey('fantasy-hero-archive'));
    expect(
      tester.getTopLeft(resume).dy,
      closeTo(tester.getTopLeft(archive).dy, 1),
    );
    expect(tester.takeException(), isNull);
  });
}

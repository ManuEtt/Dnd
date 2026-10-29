import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_campaign_dashboard.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

const longName =
    'Aramith die Hüterin des Silbermondes und der verlorenen Ruinen';
const longCampaign =
    'Die Chroniken des untergegangenen Königreichs jenseits der Nebelberge';

HeroCharacter _hero() => HeroCharacter(
  id: 'long-name-hero',
  name: longName,
  species: 'Waldelf',
  className: 'Waldläufer',
  level: 4,
  hitPoints: 24,
  maxHitPoints: 30,
  armorClass: 16,
  speed: 9,
);

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Heldenidentität bei $width dp und 200 % vollständig lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var continued = 0;
      var archives = 0;
      final hero = _hero();
      final before = hero.toJson();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              children: [
                FantasyActiveHeroCard(
                  hero: hero,
                  campaignName: longCampaign,
                  onContinue: () => continued++,
                  onHeroes: () => archives++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final name = tester.widget<Text>(find.text(longName));
      final campaign = tester.widget<Text>(find.text(longCampaign));
      expect(name.maxLines, isNull);
      expect(campaign.maxLines, isNull);
      expect(name.overflow, TextOverflow.visible);
      expect(campaign.overflow, TextOverflow.visible);
      final portrait = find.byKey(const ValueKey('active-hero-portrait'));
      final identity = find.byKey(const ValueKey('active-hero-identity'));
      expect(
        tester.getTopLeft(identity).dy,
        greaterThan(tester.getBottomLeft(portrait).dy),
      );
      expect(find.text('24 / 30'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('9 m'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final continueButton = find.byKey(
        const ValueKey('fantasy-hero-continue'),
      );
      // A long identity legitimately extends below the screen: scroll the
      // surrounding list like a user instead of relying on ensureVisible for
      // one oversized sliver child.
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.ensureVisible(continueButton);
      expect(continueButton.hitTestable(), findsOneWidget);
      await tester.tap(continueButton);
      final archiveButton = find.byKey(const ValueKey('fantasy-hero-archive'));
      await tester.ensureVisible(archiveButton);
      expect(archiveButton.hitTestable(), findsOneWidget);
      await tester.tap(archiveButton);
      expect(continued, 1);
      expect(archives, 1);
      expect(hero.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Standardansicht behält Porträt und kompakte Textzeilen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: ListView(
            children: [
              FantasyActiveHeroCard(
                hero: _hero(),
                campaignName: longCampaign,
                onContinue: () {},
                onHeroes: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final portrait = find.byKey(const ValueKey('active-hero-portrait'));
    final identity = find.byKey(const ValueKey('active-hero-identity'));
    expect(
      tester.getTopLeft(identity).dx,
      greaterThan(tester.getTopRight(portrait).dx),
    );
    expect(tester.widget<Text>(find.text(longName)).maxLines, 2);
    expect(tester.widget<Text>(find.text(longCampaign)).maxLines, 1);
    expect(tester.takeException(), isNull);
  });
}

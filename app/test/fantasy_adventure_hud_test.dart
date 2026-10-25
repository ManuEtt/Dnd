import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_adventure_hud.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

Campaign _campaign(HeroCharacter hero, {List<Quest> quests = const []}) =>
    Campaign(
      id: 'hud-campaign',
      name: 'Rabenwacht',
      world: 'Nordmark',
      sessionId: 'hud-session',
      hero: hero,
      scene: 'Ein Weg durch den Wald.',
      quests: quests,
    );

void main() {
  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Abenteuer-HUD zeigt echte Werte und Aufträge bei $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 880);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hero = HeroCharacter(
        id: 'a',
        name: 'Elowen',
        level: 1,
        experience: 300,
        hitPoints: 6,
        maxHitPoints: 10,
        armorClass: 15,
        speed: 9,
        temporaryHitPoints: 3,
        conditions: const ['liegend'],
      );
      final campaign = _campaign(
        hero,
        quests: const [
          Quest(
            id: 'quest-one',
            title: 'Die vergessene Glocke finden',
            description: 'Suche den Ursprung des Klangs.',
          ),
          Quest(
            id: 'quest-two',
            title: 'Den alten Brunnen erkunden',
            status: 'completed',
          ),
          Quest(
            id: 'quest-three',
            title: 'Das verlassene Tor schützen',
            status: 'failed',
          ),
        ],
      );
      var journalOpens = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: ListView(
              children: [
                FantasyAdventureStatusHud(hero: hero),
                FantasyAdventureQuestBoard(
                  campaign: campaign,
                  onOpenJournal: () => journalOpens++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('adventure-live-status')),
        findsOneWidget,
      );
      expect(find.text('6 / 10'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('9 m'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.textContaining('temporäre TP'), findsOneWidget);
      expect(find.textContaining('liegend'), findsOneWidget);
      expect(find.textContaining('Stufenaufstieg möglich'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('adventure-xp-progress')),
        findsOneWidget,
      );
      // The decorated HUD bars must not masquerade as a pending file export.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        find.textContaining('Die vergessene Glocke finden'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Auftragsübersicht'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('adventure-quest-quest-one')),
        findsOneWidget,
      );
      expect(find.text('Den alten Brunnen erkunden'), findsOneWidget);
      expect(find.text('Das verlassene Tor schützen'), findsOneWidget);

      final action = find.byKey(const ValueKey('adventure-quest-open-journal'));
      expect(
        tester.widget<FantasyTextButton>(action).style,
        FantasyButtonStyle.iron,
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      expect(journalOpens, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Nicht bestätigte Werte und fehlende Quests werden nicht erfunden',
    (tester) async {
      final hero = HeroCharacter(
        id: 'unknown-hero',
        name: 'Unbekannter Held',
        level: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: ListView(
              children: [
                FantasyAdventureStatusHud(hero: hero),
                FantasyAdventureQuestBoard(
                  campaign: _campaign(hero),
                  onOpenJournal: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('? / ?'), findsOneWidget);
      expect(find.text('?'), findsNWidgets(3));
      expect(find.byKey(const ValueKey('adventure-xp-progress')), findsNothing);
      expect(find.text('Keine aktiven Aufträge bestätigt'), findsOneWidget);
      expect(find.text('Die vergessene Glocke finden'), findsNothing);
      await tester.tap(find.text('Auftragsübersicht'));
      await tester.pumpAndSettle();
      expect(
        find.text('Noch keine Aufträge im Spielstand dokumentiert.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Große Systemschrift verändert keine Quest- oder Trefferpunktwerte',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hero = HeroCharacter(
        id: 'big-text',
        name: 'Held',
        level: 3,
        hitPoints: 12,
        maxHitPoints: 24,
        armorClass: 16,
        speed: 9,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              children: [
                FantasyAdventureStatusHud(hero: hero),
                FantasyAdventureQuestBoard(
                  campaign: _campaign(
                    hero,
                    quests: const [
                      Quest(
                        id: 'large-font-quest',
                        title: 'Eine Reise durch die Nebel der Nacht',
                      ),
                    ],
                  ),
                  onOpenJournal: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12 / 24'), findsOneWidget);
      expect(find.textContaining('Eine Reise durch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 360.0]) {
    testWidgets('HUD bleibt bei $width dp und 200 % Schrift lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      final hero = HeroCharacter(
        id: 'accessible-hud',
        name: 'Elowen',
        level: 3,
        experience: 950,
        hitPoints: 12,
        maxHitPoints: 24,
        armorClass: 16,
        speed: 9,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(children: [FantasyAdventureStatusHud(hero: hero)]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final statKeys = [
        const ValueKey('adventure-stat-hp'),
        const ValueKey('adventure-stat-ac'),
        const ValueKey('adventure-stat-speed'),
        const ValueKey('adventure-stat-xp'),
      ];
      final topLefts = [
        for (final key in statKeys) tester.getTopLeft(find.byKey(key)),
      ];
      for (var i = 1; i < topLefts.length; i++) {
        expect(topLefts[i].dx, closeTo(topLefts.first.dx, 1));
        expect(topLefts[i].dy, greaterThan(topLefts[i - 1].dy));
      }

      expect(find.text('12 / 24'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('9 m'), findsOneWidget);
      expect(find.text('950'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('12 / 24'),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Trefferpunkte: 12 von 24'), findsOneWidget);
      expect(find.bySemanticsLabel('Rüstungsklasse: 16'), findsOneWidget);
      expect(find.bySemanticsLabel('Bewegung: 9 m'), findsOneWidget);
      expect(find.bySemanticsLabel('Erfahrungspunkte: 950'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Erfahrungsfortschritt: [0-9]+ Prozent'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('HUD sagt unbekannte Werte auch bei 200 % korrekt an', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    final hero = HeroCharacter(id: 'unknown-hud', name: 'Unbekannt');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: ListView(children: [FantasyAdventureStatusHud(hero: hero)]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('? / ?'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(3));
    for (final statName in [
      'Trefferpunkte',
      'Rüstungsklasse',
      'Bewegung',
      'Erfahrungspunkte',
    ]) {
      expect(
        find.bySemanticsLabel('$statName: nicht bestätigt'),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('adventure-xp-progress')), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Erfahrungsfortschritt:')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

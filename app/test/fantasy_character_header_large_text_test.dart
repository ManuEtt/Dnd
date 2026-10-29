import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

const longName =
    'Aramith die Hüterin des Silbermondes und der verlorenen Ruinen';
const longSubclass =
    'Hüterin der uralten und beinahe vergessenen Pfade';
const longBackground =
    'Eine Chronik der langen Reise über die Nebelberge und durch die '
    'verlassenen Königreiche bis zur letzten Festung';

HeroCharacter _hero() => HeroCharacter(
  id: 'sheet-large-identity',
  name: longName,
  species: 'Waldelf',
  className: 'Waldläufer',
  subclass: longSubclass,
  background: longBackground,
  level: 4,
  hitPoints: 24,
  maxHitPoints: 30,
  armorClass: 16,
  speed: 9,
);

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('200 % Schrift: vollständige Identität bei $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final hero = _hero();
      final saved = hero.toJson();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: CharacterSheetPage(hero: hero),
        ),
      );
      await tester.pumpAndSettle();

      final name = tester.widget<Text>(find.text(longName));
      final subclass = tester.widget<Text>(find.text(longSubclass));
      final background = tester.widget<Text>(find.text(longBackground));
      final identityLine = tester.widget<Text>(
        find.text('Waldelf  •  Waldläufer  •  Stufe 4'),
      );
      for (final field in [name, identityLine, subclass, background]) {
        expect(field.maxLines, isNull);
        expect(field.overflow, TextOverflow.visible);
      }

      final portrait = find.byKey(const ValueKey('sheet-header-portrait'));
      final identity = find.byKey(const ValueKey('sheet-header-identity'));
      expect(
        tester.getTopLeft(identity).dy,
        greaterThan(tester.getBottomLeft(portrait).dy),
      );
      expect(hero.toJson(), saved);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Standardtext behält kompakten Kopf mit Porträt links', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var edits = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: CharacterSheetPage(hero: _hero(), onEdit: () => edits++),
      ),
    );
    await tester.pumpAndSettle();

    final portrait = find.byKey(const ValueKey('sheet-header-portrait'));
    final identity = find.byKey(const ValueKey('sheet-header-identity'));
    expect(
      tester.getTopLeft(identity).dx,
      greaterThan(tester.getTopRight(portrait).dx),
    );
    expect(tester.widget<Text>(find.text(longName)).maxLines, 2);
    expect(
      tester.widget<Text>(find.text(longName)).overflow,
      TextOverflow.ellipsis,
    );
    final edit = find.byTooltip('Charakter bearbeiten');
    expect(edit.hitTestable(), findsOneWidget);
    await tester.tap(edit);
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unbenannter Altcharakter bleibt bei 200 % unverändert', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final hero = HeroCharacter(id: 'legacy-empty', name: '');
    final saved = hero.toJson();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: CharacterSheetPage(hero: hero),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unbenannter Held'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Unbenannter Held')).maxLines, isNull);
    expect(hero.toJson(), saved);
    expect(tester.takeException(), isNull);
  });
}

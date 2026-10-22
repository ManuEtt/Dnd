import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_portrait_picker.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  test('Die Bildvorlage überlebt JSON-Export und -Import unverändert', () {
    final hero = HeroCharacter(id: 'hero', name: 'Liora', portraitPreset: 7);
    final restored = HeroCharacter.fromJson(hero.toJson());
    expect(restored.portraitPreset, 7);
    expect(restored.portraitPhotoBase64, isEmpty);
    expect(restored.toJson(), hero.toJson());
  });

  test('Eigene Bilddaten werden im Charakter gespeichert, ohne lokale Pfade', () {
    const image =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/PTcAAAAASUVORK5CYII=';
    final hero = HeroCharacter(
      id: 'hero',
      name: 'Tira',
      portraitPhotoBase64: image,
    );
    final restored = HeroCharacter.fromJson(hero.toJson());
    expect(restored.portraitPreset, -1);
    expect(restored.portraitPhotoBase64, image);
    expect(restored.toJson(), hero.toJson());
  });

  test('Alte Spielstände bleiben byteweise in ihrer Struktur unverändert', () {
    final hero = HeroCharacter(id: 'old', name: 'Alt');
    final json = hero.toJson();
    expect(json.containsKey('portraitPreset'), isFalse);
    expect(json.containsKey('portraitPhotoBase64'), isFalse);
    expect(HeroCharacter.fromJson(json).toJson(), json);
  });

  test('Manipulierte Vorlagen und große/ungültige Bilder werden abgelehnt', () {
    final hero = HeroCharacter(id: 'old', name: 'Alt');
    for (final invalid in [-2, 9, '3']) {
      expect(
        () => HeroCharacter.fromJson({
          ...hero.toJson(),
          'portraitPreset': invalid,
        }),
        throwsFormatException,
      );
    }
    for (final invalid in ['not base64!', List.filled(64004, 'x').join()]) {
      expect(
        () => HeroCharacter.fromJson({
          ...hero.toJson(),
          'portraitPhotoBase64': invalid,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => HeroCharacter.fromJson({
        ...hero.toJson(),
        'portraitPreset': 1,
        'portraitPhotoBase64': 'AAAA',
      }),
      throwsFormatException,
    );
  });

  testWidgets(
    'Galerie lässt eine Vorlage wählen und kann sie wieder entfernen',
    (tester) async {
      CharacterPortraitChoice? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  chosen = await Navigator.of(context)
                      .push<CharacterPortraitChoice>(
                        MaterialPageRoute(
                          builder: (_) => const CharacterPortraitPicker(
                            initialPreset: -1,
                            initialPhotoBase64: '',
                          ),
                        ),
                      );
                },
                child: const Text('Wählen'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Wählen'));
      await tester.pumpAndSettle();
      final fourth = find.byKey(const ValueKey('portrait-option-3'));
      await tester.scrollUntilVisible(
        fourth,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(fourth);
      await tester.pumpAndSettle();
      await tester.tap(fourth);
      await tester.pumpAndSettle();
      final apply = tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('portrait-apply')),
      );
      expect(apply.style, FantasyButtonStyle.woodGold);
      await tester.tap(find.byKey(const ValueKey('portrait-apply')));
      await tester.pumpAndSettle();
      expect(chosen?.preset, 3);
      expect(chosen?.photoBase64, isEmpty);
    },
  );
}

import 'package:flutter/material.dart';

import '../domain/class_resource_rules.dart';
import '../domain/models.dart';
import '../domain/spellcasting_rules.dart';
import '../domain/srd_bard_font_of_inspiration.dart';

/// An explicit selection and confirmation. No resources are spent by opening
/// this dialog; its result is only a stale-checked proposal for the controller.
Future<SrdBardFontProposal?> showBardFontOfInspirationDialog(
  BuildContext context,
  HeroCharacter hero,
) {
  if (ClassResourceRules.level(hero, 'Barde') < 5 ||
      (hero.spentClassResources['bardicInspiration'] ?? 0) < 1 ||
      hero.isDead ||
      hero.hitPoints == null ||
      hero.hitPoints! <= 0) {
    return Future.value(null);
  }
  final options = <({int grade, bool pact, String label})>[];
  for (final entry in SpellcastingRules.availableSlots(hero).entries) {
    if (entry.value > 0) {
      options.add((
        grade: entry.key,
        pact: false,
        label: 'Zauberplatz Grad ${entry.key} (${entry.value} frei)',
      ));
    }
  }
  if (SpellcastingRules.availablePactSlots(hero) > 0) {
    options.add((
      grade: SpellcastingRules.pactSlotLevel(hero),
      pact: true,
      label:
          'Paktplatz Grad ${SpellcastingRules.pactSlotLevel(hero)} '
          '(${SpellcastingRules.availablePactSlots(hero)} frei)',
    ));
  }
  if (options.isEmpty) return Future.value(null);

  var selected = 0;
  return showDialog<SrdBardFontProposal>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Quelle der Inspiration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barde ab Stufe 5: Einen Zauberplatz ausgeben, '
              'um eine verbrauchte Bardische Inspiration zurückzuerhalten. '
              'Hierfür ist keine Aktion erforderlich.',
            ),
            const SizedBox(height: 12),
            DropdownButton<int>(
              key: const ValueKey('bard-font-slot-select'),
              value: selected,
              isExpanded: true,
              items: [
                for (var i = 0; i < options.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      options[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setDialogState(() => selected = value);
              },
            ),
            const Text(
              'Der gewählte Platz wird erst nach Bestätigung verbraucht.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const ValueKey('bard-font-confirm'),
            onPressed: () {
              final choice = options[selected];
              final proposal = SrdBardFontOfInspirationRules.propose(
                hero: hero,
                slotLevel: choice.grade,
                usePactSlot: choice.pact,
              );
              Navigator.of(dialogContext).pop(proposal);
            },
            child: const Text('Umwandlung bestätigen'),
          ),
        ],
      ),
    ),
  );
}

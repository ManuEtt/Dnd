import 'package:flutter/material.dart';
import '../domain/ability_generation.dart';
import '../domain/srd_background_package.dart';

/// Confirms one SRD 5.2.1 background's fixed skill/tool proficiencies and
/// an explicit choice between equipment A and 50 GP (option B).
/// Origin feat mechanics, spell choices and holy symbol variant remain open.
class SrdBackgroundPackageDialog extends StatefulWidget {
  const SrdBackgroundPackageDialog({super.key, required this.background});

  final SrdBackground background;

  @override
  State<SrdBackgroundPackageDialog> createState() =>
      _SrdBackgroundPackageDialogState();
}

class _SrdBackgroundPackageDialogState
    extends State<SrdBackgroundPackageDialog> {
  bool _takeGold = false;
  String? _gamingSetId;

  SrdBackgroundPackageChoice? get _choice {
    if (widget.background == SrdBackground.soldier && _gamingSetId == null) {
      return null;
    }
    return SrdBackgroundPackageChoice(
      background: widget.background,
      takeGold: _takeGold,
      gamingSetCatalogId: _gamingSetId ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final choice = _choice;
    return AlertDialog(
      title: Text('Hintergrund: ${widget.background.label}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'D&D SRD 5.2.1: Zwei feste Fertigkeiten, eine '
                'Werkzeugübung und ein Herkunftstalent. '
                'Das Talent wird zunächst nur vermerkt; '
                'seine Regelwirkung ist noch nicht automatisiert.',
              ),
              const SizedBox(height: 12),
              Text(
                'Fertigkeiten: ${widget.background == SrdBackground.acolyte
                    ? 'Motiv erkennen, Religion'
                    : widget.background == SrdBackground.criminal
                    ? 'Fingerfertigkeit, Heimlichkeit'
                    : widget.background == SrdBackground.sage
                    ? 'Arkane Kunde, Geschichte'
                    : 'Athletik, Einschüchtern'}',
              ),
              const SizedBox(height: 12),
              if (widget.background == SrdBackground.soldier)
                DropdownButtonFormField<String>(
                  key: const ValueKey('background-gaming-set'),
                  initialValue: _gamingSetId,
                  decoration: const InputDecoration(
                    labelText: 'Spielset für Werkzeugübung auswählen',
                  ),
                  items: [
                    for (final item in SrdBackgroundPackageChoice.gamingSets)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (id) => setState(() => _gamingSetId = id),
                ),
              SwitchListTile(
                key: const ValueKey('background-gold-option'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Option B: 50 Gold statt Ausrüstung'),
                value: _takeGold,
                onChanged: (selected) => setState(() => _takeGold = selected),
              ),
              if (choice != null) ...[
                Text(
                  'Werkzeugübung: ${choice.toolProficiency}. '
                  'Herkunftstalent: ${choice.originFeat}.',
                ),
                const SizedBox(height: 8),
                Text('Startgeld aus Hintergrund: ${choice.startingGold} GM.'),
                if (!choice.takeGold)
                  for (final item in choice.kitItems)
                    Text(
                      '• ${item.quantity} × ${item.name == 'Spielset (nach Wahl)' ? choice.toolProficiency : item.name}',
                    ),
                if (choice.requiresFeatSpellChoices)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Offen: Für Magieinitiierter müssen noch zwei '
                      'Zaubertricks, ein Zauber des 1. Grades und '
                      'das Zauberattribut gewählt werden.',
                    ),
                  ),
                if (widget.background == SrdBackground.acolyte && !_takeGold)
                  const Text(
                    'Offen: Das konkrete Heilige Symbol muss noch '
                    'ausgewählt werden. Der Platzhalter gibt keine '
                    'Katalogwerte vor.',
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const ValueKey('confirm-background-package'),
          onPressed: choice == null
              ? null
              : () => Navigator.of(context).pop(choice),
          child: const Text('Hintergrundpaket übernehmen'),
        ),
      ],
    );
  }
}

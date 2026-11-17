import 'package:flutter/material.dart';

import '../domain/srd_character_creation_audit.dart';
import 'fantasy_ui.dart';

/// Read-only inspection of one editor snapshot. No confirmation or persistence.
class SrdCreationAuditDialog extends StatefulWidget {
  const SrdCreationAuditDialog({super.key, required this.steps});

  final List<CreationStep> steps;

  static String _label(CreationStepStatus status) => switch (status) {
    CreationStepStatus.confirmed => 'Bestätigt',
    CreationStepStatus.missing => 'Fehlt',
    CreationStepStatus.invalid => 'Ungültig',
    CreationStepStatus.dependent => 'Weitere Auswahl nötig',
    CreationStepStatus.notAutomated => 'Nicht automatisiert',
    CreationStepStatus.houseRule => 'Hausregel',
    CreationStepStatus.notInSrd => 'Nicht im SRD',
  };

  static IconData _icon(CreationStepStatus status) => switch (status) {
    CreationStepStatus.confirmed => Icons.check_circle_outline,
    CreationStepStatus.missing => Icons.pending_outlined,
    CreationStepStatus.invalid => Icons.error_outline,
    CreationStepStatus.dependent => Icons.account_tree_outlined,
    CreationStepStatus.notAutomated => Icons.info_outline,
    CreationStepStatus.houseRule => Icons.edit_note_outlined,
    CreationStepStatus.notInSrd => Icons.help_outline,
  };

  static Color _color(CreationStepStatus status) => switch (status) {
    CreationStepStatus.confirmed => FantasyPalette.success,
    CreationStepStatus.invalid => FantasyPalette.danger,
    CreationStepStatus.missing ||
    CreationStepStatus.dependent ||
    CreationStepStatus.houseRule => FantasyPalette.gold,
    CreationStepStatus.notAutomated ||
    CreationStepStatus.notInSrd => FantasyPalette.muted,
  };

  @override
  State<SrdCreationAuditDialog> createState() =>
      _SrdCreationAuditDialogState();
}

class _SrdCreationAuditDialogState extends State<SrdCreationAuditDialog> {
  bool _showUnconfirmedOnly = false;

  @override
  Widget build(BuildContext context) {
    // A catalog entry, house rule or manually recorded value must never be
    // presented as confirmed merely because the editor has a value for it.
    final unconfirmed = widget.steps
        .where((step) => step.status != CreationStepStatus.confirmed)
        .toList(growable: false);
    final visible = _showUnconfirmedOnly ? unconfirmed : widget.steps;

    return AlertDialog(
      key: const ValueKey('srd-creation-audit-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      title: const Text('SRD-Charaktererstellung prüfen'),
      content: SizedBox(
        width: 430,
        child: ListView(
          key: const ValueKey('srd-creation-audit-list'),
          shrinkWrap: true,
          children: [
            const Text(
              'Prüfung des aktuellen Entwurfs. Gespeicherte Daten bleiben '
              'unverändert. Diese Teilprüfung bescheinigt keine vollständige '
              'SRD-Regeltreue.',
            ),
            const SizedBox(height: 12),
            Text(
              'Noch nicht bestätigt: ${unconfirmed.length} von ${widget.steps.length}',
              key: const ValueKey('creation-audit-open-count'),
              style: const TextStyle(
                color: FantasyPalette.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('creation-audit-filter-all'),
                  label: const Text('Alle'),
                  selected: !_showUnconfirmedOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _showUnconfirmedOnly = false);
                    }
                  },
                ),
                ChoiceChip(
                  key: const ValueKey('creation-audit-filter-unconfirmed'),
                  label: const Text('Unbestätigt'),
                  selected: _showUnconfirmedOnly,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _showUnconfirmedOnly = true);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_showUnconfirmedOnly && visible.isEmpty)
              const Text(
                'Alle angezeigten Prüfschritte sind bestätigt. '
                'Dies ist keine vollständige SRD-Zertifizierung.',
                key: ValueKey('creation-audit-no-unconfirmed'),
              ),
            for (final step in visible)
              Semantics(
                key: ValueKey('creation-audit-${step.id}'),
                container: true,
                label:
                    '${step.title}. ${SrdCreationAuditDialog._label(step.status)}. '
                    '${step.detail}',
                child: ExcludeSemantics(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: SrdCreationAuditDialog._color(
                          step.status,
                        ).withValues(alpha: .6),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              SrdCreationAuditDialog._icon(step.status),
                              color: SrdCreationAuditDialog._color(step.status),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                SrdCreationAuditDialog._label(step.status),
                                style: TextStyle(
                                  color: SrdCreationAuditDialog._color(
                                    step.status,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(step.detail),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('close-srd-creation-audit'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}

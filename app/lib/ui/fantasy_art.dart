import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'fantasy_ui.dart';
import 'fantasy_buttons.dart';
import 'fantasy_experience.dart';
import 'fantasy_approved_icons.dart';

/// Artwork cropped from the project's original Aetheria visual concepts.
/// These images are decorative; displayed story and character data is real.
abstract final class FantasyArtwork {
  static const ruins = 'assets/art/ruins.webp';
  static const castle = 'assets/art/castle.webp';
  static const shadowForest = 'assets/art/shadow_forest.webp';
  static const bloodMountains = 'assets/art/blood_mountains.webp';
  static const forgottenWoods = 'assets/art/forgotten_woods.webp';
  static const sword = 'assets/art/item_sword.webp';
  static const shield = 'assets/art/item_shield.webp';
  static const potion = 'assets/art/item_potion.webp';
  static const book = 'assets/art/item_book.webp';
  static const bag = 'assets/art/item_bag.webp';
  static const scroll = 'assets/art/item_scroll.webp';
  static const crystal = 'assets/art/item_crystal.webp';

  static String campaign(int index) => switch (index % 3) {
    0 => shadowForest,
    1 => bloodMountains,
    _ => forgottenWoods,
  };

  /// Only map real saved item names to generic illustrations. The illustration
  /// does not assert an equipment bonus, magical status, or additional item.
  static String? inventoryItem(String name) {
    final n = name.toLowerCase();
    if (n.contains('schwert') ||
        n.contains('klinge') ||
        n.contains('dolch') ||
        n.contains('säbel')) {
      return sword;
    }
    if (n.contains('schild')) return shield;
    if (n.contains('trank') || n.contains('elixier') || n.contains('flasche')) {
      return potion;
    }
    if (n.contains('buch') || n.contains('kodex') || n.contains('tagebuch')) {
      return book;
    }
    if (n.contains('tasche') ||
        n.contains('rucksack') ||
        n.contains('beutel')) {
      return bag;
    }
    if (n.contains('schriftrolle') ||
        n.contains('brief') ||
        n.contains('karte')) {
      return scroll;
    }
    if (n.contains('kristall') ||
        n.contains('edelstein') ||
        n.contains('amulett')) {
      return crystal;
    }
    return null;
  }
}

/// Gold corner ornaments are painted, rather than stored as an image of a UI.
/// The design scales to real Android viewport dimensions and text sizes.
class FantasyOrnamentPainter extends CustomPainter {
  const FantasyOrnamentPainter({this.color = FantasyPalette.gold});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = color.withValues(alpha: .84);
    final pen = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final inner = Paint()
      ..color = c.withValues(alpha: .40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final w = size.width;
    final h = size.height;
    if (w < 40 || h < 35) return;
    final d = math.min(17.0, math.min(w, h) / 4);
    for (final corner in [0, 1, 2, 3]) {
      final right = corner == 1 || corner == 3;
      final bottom = corner >= 2;
      final sx = right ? w : 0.0;
      final sy = bottom ? h : 0.0;
      final dx = right ? -1.0 : 1.0;
      final dy = bottom ? -1.0 : 1.0;
      final p = Path()
        ..moveTo(sx + dx * (d + 7), sy)
        ..lineTo(sx + dx * d, sy)
        ..quadraticBezierTo(
          sx + dx * d * .65,
          sy + dy * d * .65,
          sx,
          sy + dy * d,
        )
        ..lineTo(sx, sy + dy * (d + 7));
      canvas.drawPath(p, pen);
      final q = Path()
        ..moveTo(sx + dx * (d + 5), sy + dy * 4)
        ..lineTo(sx + dx * (d + 2), sy + dy * 4)
        ..lineTo(sx + dx * 4, sy + dy * (d + 2))
        ..lineTo(sx + dx * 4, sy + dy * (d + 5));
      canvas.drawPath(q, inner);
    }
    final midX = w / 2;
    final diamond = Path()
      ..moveTo(midX, 0)
      ..lineTo(midX + 5, 5)
      ..lineTo(midX, 10)
      ..lineTo(midX - 5, 5)
      ..close();
    canvas.drawPath(diamond, pen);
  }

  @override
  bool shouldRepaint(covariant FantasyOrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Framed image with accessible, real Flutter text over an illustration.
class FantasyIllustratedBanner extends StatelessWidget {
  const FantasyIllustratedBanner({
    super.key,
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.onPressed,
    this.actionLabel,
    this.icon = Icons.explore_outlined,
    this.height = 258,
  });

  final String image, eyebrow, title, description;
  final VoidCallback? onPressed;
  final String? actionLabel;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: height),
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(image),
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
      border: Border.all(
        color: FantasyPalette.gold.withValues(alpha: .75),
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x80000000),
          blurRadius: 17,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: CustomPaint(
        foregroundPainter: const FantasyOrnamentPainter(),
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xfa07121e), Color(0xde0a1928), Color(0x45061524)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FantasyRuneEmblem(rune: FantasyRune.moon, size: 42),
                  const SizedBox(width: 9),
                  Icon(icon, color: FantasyPalette.gold, size: 17),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: FantasyPalette.gold,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 9),
              Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FantasyPalette.ivory,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 17),
                FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Illustrated story scene: image remains decorative, while scene text is data.
class FantasyScenePanel extends StatelessWidget {
  const FantasyScenePanel({
    super.key,
    required this.scene,
    this.image = FantasyArtwork.ruins,
  });
  final String scene;
  final String image;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: FantasyPalette.ink,
      border: Border.all(color: FantasyPalette.gold.withValues(alpha: .7)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: CustomPaint(
        foregroundPainter: const FantasyOrnamentPainter(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              image,
              height: 186,
              fit: BoxFit.cover,
              semanticLabel: 'Atmosphärische Fantasy-Landschaft',
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      FantasyRuneEmblem(rune: FantasyRune.quill, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'AKTUELLE SZENE',
                        style: TextStyle(
                          color: FantasyPalette.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SelectableText(
                    scene,
                    style: const TextStyle(
                      height: 1.55,
                      color: FantasyPalette.ivory,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class FantasyCampaignCard extends StatelessWidget {
  const FantasyCampaignCard({
    super.key,
    required this.name,
    required this.detail,
    required this.image,
    this.onTap,
    this.onDelete,
    this.accent = FantasyPalette.gold,
  });
  final String name, detail, image;
  final VoidCallback? onTap, onDelete;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: accent.withValues(alpha: .75)),
      color: FantasyPalette.ink,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        foregroundPainter: FantasyOrnamentPainter(color: accent),
        child: FantasyOptionalImageFrame(
          image: FantasyOptionalArt.card,
          centerSlice: const Rect.fromLTWH(43, 43, 464, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Image.asset(
                    image,
                    height: 142,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: 'Fantasy-Kampagnenillustration',
                  ),
                  const Positioned(
                    left: 12,
                    bottom: 8,
                    child: FantasyRuneEmblem(
                      rune: FantasyRune.compass,
                      size: 40,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Kampagne löschen',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 19),
                    ),
                  ),
                ],
              ),
              ListTile(
                onTap: onTap,
                leading: const Icon(
                  Icons.explore_outlined,
                  color: FantasyPalette.gold,
                ),
                title: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  detail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: FantasyPalette.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FantasyShortcutTile extends StatefulWidget {
  const FantasyShortcutTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.width = 112,
    this.compact = false,
    this.approvedIconIndex,
    this.style = FantasyButtonStyle.woodGold,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double width;
  final int? approvedIconIndex;
  final bool compact;

  /// The plate material; only decorative art changes, not action behavior.
  final FantasyButtonStyle style;

  /// For persistent states such as the actively listening microphone.
  final bool selected;

  @override
  State<FantasyShortcutTile> createState() => _FantasyShortcutTileState();
}

class _FantasyShortcutTileState extends State<FantasyShortcutTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  FantasyButtonState get _visualState {
    if (widget.onTap == null) return FantasyButtonState.disabled;
    if (_pressed) return FantasyButtonState.pressed;
    if (widget.selected) return FantasyButtonState.active;
    if (_hovered || _focused) return FantasyButtonState.hover;
    return FantasyButtonState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final accent = enabled ? widget.color : FantasyPalette.muted;
    return SizedBox(
      width: widget.width,
      // Keep the existing large-text and keyboard-safe dimensions.
      height: widget.compact
          ? (74 + MediaQuery.textScalerOf(context).scale(11) * 3.2)
                .clamp(110.0, 190.0)
                .toDouble()
          : null,
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: widget.selected,
        label: widget.label,
        child: AnimatedScale(
          scale: enabled && _pressed ? .965 : 1,
          duration: const Duration(milliseconds: 105),
          curve: Curves.easeOut,
          child: FantasyApprovedCornerFrame(
            cornerSize: widget.compact ? 22 : 27,
            opacity: enabled ? .90 : .40,
            child: Material(
              color: FantasyPalette.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: accent.withValues(alpha: .75)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FantasyButtonSurface(
                        style: widget.style,
                        state: _visualState,
                        square: false,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onTap,
                    onHover: (value) {
                      if (mounted) setState(() => _hovered = value);
                    },
                    onFocusChange: (value) {
                      if (mounted) setState(() => _focused = value);
                    },
                    onHighlightChanged: (value) {
                      if (mounted) setState(() => _pressed = value);
                    },
                    child: CustomPaint(
                      foregroundPainter: FantasyOrnamentPainter(color: accent),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.compact ? 4 : 8,
                          vertical: widget.compact ? 8 : 13,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.approvedIconIndex != null)
                              Opacity(
                                opacity: enabled ? 1 : .45,
                                child: FantasyApprovedIcon(
                                  index: widget.approvedIconIndex!,
                                  size: widget.compact ? 38 : 52,
                                ),
                              )
                            else
                              CircleAvatar(
                                radius: widget.compact ? 17 : 24,
                                backgroundColor: accent.withValues(alpha: .14),
                                child: Icon(
                                  widget.icon,
                                  color: accent,
                                  size: widget.compact ? 21 : 29,
                                ),
                              ),
                            SizedBox(height: widget.compact ? 4 : 9),
                            Text(
                              widget.label,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: enabled
                                    ? FantasyPalette.ivory
                                    : FantasyPalette.muted,
                                fontSize: widget.compact ? 11 : 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Always-present quick actions along the bottom of an active adventure.
/// Its parent must place it outside the story scrollable and immediately above
/// the app's navigation. The keyboard reduces its chrome but not its actions.
class FantasyPinnedActionBar extends StatelessWidget {
  const FantasyPinnedActionBar({
    super.key,
    required this.busy,
    required this.listening,
    required this.onSpeech,
    required this.onInspect,
    required this.onAttack,
    required this.onRoll,
    this.attackEnabled = true,
    this.attackUnavailableReason,
  });

  final bool attackEnabled;
  final String? attackUnavailableReason;
  final bool busy;
  final bool listening;
  final VoidCallback onSpeech;
  final VoidCallback onInspect;
  final VoidCallback onAttack;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    // Scaffold can consume the body's MediaQuery.viewInsets. Inspect the
    // underlying FlutterView as well, so a nested Scaffold still detects IME.
    final keyboardOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0 ||
        View.of(context).viewInsets.bottom > 0;
    // Keep the existing InkWell tree untouched while the action is enabled:
    // an always-on Tooltip would alter the pointer-down/pressed interaction.
    final attackShortcut = FantasyShortcutTile(
      key: const ValueKey('adventure-shortcut-attack'),
      label: 'Angriff',
      style: FantasyButtonStyle.wax,
      approvedIconIndex: 1,
      icon: Icons.sports_martial_arts,
      color: FantasyPalette.danger,
      width: double.infinity,
      compact: true,
      onTap: busy || !attackEnabled ? null : onAttack,
    );
    return DecoratedBox(
      key: const ValueKey('adventure-fixed-shortcuts'),
      decoration: const BoxDecoration(
        color: FantasyPalette.night,
        border: Border(top: BorderSide(color: Color(0x77ddb96c))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          keyboardOpen ? 4 : 8,
          12,
          keyboardOpen ? 4 : 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!keyboardOpen) ...[
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: FantasyPalette.gold,
                  ),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Schnellaktionen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FantasyPalette.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
            ],
            Row(
              children: [
                Expanded(
                  child: FantasyShortcutTile(
                    key: const ValueKey('adventure-shortcut-speech'),
                    label: listening ? 'Stopp' : 'Sprache',
                    selected: listening,
                    style: FantasyButtonStyle.woodGold,
                    icon: listening
                        ? Icons.mic_off_outlined
                        : Icons.chat_bubble_outline,
                    color: FantasyPalette.gold,
                    width: double.infinity,
                    compact: true,
                    onTap: busy ? null : onSpeech,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: FantasyShortcutTile(
                    key: const ValueKey('adventure-shortcut-inspect'),
                    label: 'Untersuchen',
                    style: FantasyButtonStyle.arcane,
                    approvedIconIndex: 3,
                    icon: Icons.search,
                    color: FantasyPalette.blue,
                    width: double.infinity,
                    compact: true,
                    onTap: busy ? null : onInspect,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: busy || !attackEnabled
                      ? Tooltip(
                          message: busy
                              ? 'Eine Handlung wird bereits verarbeitet.'
                              : attackUnavailableReason ??
                                  'Hier ist derzeit kein Angriff möglich.',
                          child: attackShortcut,
                        )
                      : attackShortcut,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: FantasyShortcutTile(
                    key: const ValueKey('adventure-shortcut-roll'),
                    label: 'W20',
                    style: FantasyButtonStyle.arcane,
                    approvedIconIndex: 7,
                    icon: Icons.casino_outlined,
                    color: Color(0xffae90d8),
                    width: double.infinity,
                    compact: true,
                    onTap: busy ? null : onRoll,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FantasyHeroMedallion extends StatelessWidget {
  const FantasyHeroMedallion({super.key, required this.name, this.radius = 31});
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final pieces = name.trim().split(RegExp(r'\s+'));
    final initials = pieces
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p.substring(0, 1).toUpperCase())
        .join();
    return CircleAvatar(
      radius: radius + 2,
      backgroundColor: FantasyPalette.gold,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: FantasyPalette.raised,
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            color: FantasyPalette.gold,
            fontFamily: 'serif',
            fontSize: radius * .67,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class FantasyInventoryCards extends StatelessWidget {
  const FantasyInventoryCards({super.key, required this.items});
  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('Noch keine Gegenstände eingetragen.');
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 640
            ? 5
            : width >= 430
            ? 4
            : 3;
        return GridView.builder(
          key: const ValueKey('fantasy-inventory-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent:
                (145 + (MediaQuery.textScalerOf(context).scale(18) - 18) * 2)
                    .clamp(145.0, 230.0),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final art = FantasyArtwork.inventoryItem(item.name);
            return Material(
              color: FantasyPalette.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: FantasyPalette.gold.withValues(alpha: .5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(item.name),
                    content: Text(
                      'Anzahl: ${item.quantity}\n${item.description.isEmpty ? 'Keine weitere Beschreibung gespeichert.' : item.description}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Schließen'),
                      ),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Expanded(
                        child: art == null
                            ? const Icon(
                                Icons.backpack_outlined,
                                color: FantasyPalette.gold,
                                size: 40,
                              )
                            : Image.asset(art, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FantasyPalette.ivory,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '× ${item.quantity}',
                        style: const TextStyle(
                          color: FantasyPalette.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import 'fantasy_ui.dart';

/// Visual-only state. Game actions stay in their original controller callbacks.
enum FantasyButtonState { normal, hover, pressed, active, disabled }

enum FantasyButtonStyle { woodGold, arcane, iron, wax, dice, iconGold }

/// The PNGs are optional: a vector/gradient fallback makes offline installs
/// and partial asset packs safe. Wide source frames are 192x64 with an
/// unchanging 24px edge; icon-only frames are 64x64.
abstract final class FantasyButtonAssets {
  static const root = 'assets/fantasy/buttons/';

  static String path(FantasyButtonStyle style, FantasyButtonState state) {
    final name = switch (style) {
      FantasyButtonStyle.woodGold => 'btn_wood_gold',
      FantasyButtonStyle.arcane => 'btn_rune_arcane',
      FantasyButtonStyle.iron => 'btn_iron',
      FantasyButtonStyle.wax => 'btn_wax',
      FantasyButtonStyle.dice => 'btn_dice',
      FantasyButtonStyle.iconGold => 'btn_icon_gold',
    };
    return '$root${name}_${state.name}.png';
  }

  static const wideCenterSlice = Rect.fromLTWH(24, 20, 144, 24);
}

/// Reusable asset-backed action. Focus/hover/press/toggle/disabled each select
/// a distinct graphic. InkWell preserves keyboard, touch and semantics support.
class FantasyButton extends StatefulWidget {
  const FantasyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = FantasyButtonStyle.woodGold,
    this.selected = false,
    this.iconOnly = false,
    this.tooltip,
    this.onSound,
    this.minWidth,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FantasyButtonStyle style;
  final bool selected;
  final bool iconOnly;
  final String? tooltip;
  final VoidCallback? onSound;
  final double? minWidth;

  /// Narrow vertically stacked icon/label layout for three-column tab bars.
  final bool compact;

  @override
  State<FantasyButton> createState() => _FantasyButtonState();
}

class _FantasyButtonState extends State<FantasyButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  FantasyButtonState get _visualState {
    if (widget.onPressed == null) return FantasyButtonState.disabled;
    if (_pressed) return FantasyButtonState.pressed;
    if (widget.selected) return FantasyButtonState.active;
    if (_hovered || _focused) return FantasyButtonState.hover;
    return FantasyButtonState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final state = _visualState;
    final iconOnly = widget.iconOnly;
    final size = iconOnly ? 48.0 : 52.0;
    final content = iconOnly
        ? Icon(widget.icon ?? Icons.auto_awesome, size: 23)
        : widget.compact
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) Icon(widget.icon, size: 18),
              if (widget.icon != null) const SizedBox(height: 2),
              Text(
                widget.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 19),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          );
    final action = Semantics(
      button: true,
      enabled: enabled,
      label: iconOnly ? widget.label : null,
      toggled: widget.selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(iconOnly ? 13 : 12),
          onTap: enabled
              ? () {
                  widget.onSound?.call();
                  widget.onPressed?.call();
                }
              : null,
          onHover: (value) {
            if (mounted) setState(() => _hovered = value);
          },
          onFocusChange: (value) {
            if (mounted) setState(() => _focused = value);
          },
          onHighlightChanged: (value) {
            if (mounted) setState(() => _pressed = value);
          },
          child: AnimatedScale(
            scale: _pressed && enabled ? .965 : 1,
            duration: const Duration(milliseconds: 105),
            curve: Curves.easeOut,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size,
                minWidth:
                    widget.minWidth ??
                    (widget.compact ? 0 : (iconOnly ? size : 108)),
              ),
              child: Stack(
                fit: StackFit.passthrough,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: FantasyButtonSurface(
                      style: widget.style,
                      state: state,
                      square:
                          iconOnly ||
                          widget.style == FantasyButtonStyle.iconGold,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.compact ? 5 : (iconOnly ? 11 : 20),
                      vertical: widget.compact ? 8 : (iconOnly ? 11 : 14),
                    ),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: enabled
                            ? FantasyPalette.ivory
                            : FantasyPalette.muted,
                        fontSize: 14,
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          color: enabled
                              ? FantasyPalette.gold
                              : FantasyPalette.muted,
                        ),
                        child: content,
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
    return widget.tooltip == null
        ? action
        : Tooltip(message: widget.tooltip!, child: action);
  }
}

/// Asset-backed artwork shared by text buttons and illustrated shortcuts.
/// The background is decorative; callers must supply their own InkWell.
class FantasyButtonSurface extends StatelessWidget {
  const FantasyButtonSurface({
    super.key,
    required this.style,
    required this.state,
    required this.square,
  });

  final FantasyButtonStyle style;
  final FantasyButtonState state;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final path = FantasyButtonAssets.path(style, state);
    return FutureBuilder<Set<String>>(
      future: FantasyOptionalArt.available,
      builder: (context, snapshot) {
        final fallback = _FantasyButtonFallback(style: style, state: state);
        if (!(snapshot.data?.contains(path) ?? false)) return fallback;
        return Image.asset(
          path,
          key: ValueKey('fantasy-btn-$path'),
          fit: BoxFit.fill,
          centerSlice: square ? null : FantasyButtonAssets.wideCenterSlice,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, error, stack) => fallback,
        );
      },
    );
  }
}

class _FantasyButtonFallback extends StatelessWidget {
  const _FantasyButtonFallback({required this.style, required this.state});

  final FantasyButtonStyle style;
  final FantasyButtonState state;

  @override
  Widget build(BuildContext context) {
    final disabled = state == FantasyButtonState.disabled;
    final active =
        state == FantasyButtonState.active ||
        state == FantasyButtonState.pressed;
    final arcane =
        style == FantasyButtonStyle.arcane || style == FantasyButtonStyle.dice;
    final wax = style == FantasyButtonStyle.wax;
    final iron = style == FantasyButtonStyle.iron;
    final base = wax
        ? const Color(0xff602126)
        : arcane
        ? const Color(0xff103a60)
        : iron
        ? const Color(0xff273340)
        : const Color(0xff452919);
    final accent = disabled
        ? const Color(0xff777777)
        : wax
        ? FantasyPalette.danger
        : arcane
        ? FantasyPalette.blue
        : FantasyPalette.gold;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: disabled
              ? [const Color(0xff343739), const Color(0xff212427)]
              : [Color.lerp(base, accent, active ? .35 : .15)!, base],
        ),
        border: Border.all(
          color: accent.withValues(alpha: disabled ? .35 : .83),
          width: active ? 2 : 1.4,
        ),
        boxShadow: active || state == FantasyButtonState.hover
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: .24),
                  blurRadius: active ? 14 : 8,
                  spreadRadius: active ? 1 : 0,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _ButtonEngraving(color: accent.withValues(alpha: .58)),
      ),
    );
  }
}

class _ButtonEngraving extends CustomPainter {
  const _ButtonEngraving({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 24 || size.height < 24) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, w - 8, h - 8),
        const Radius.circular(8),
      ),
      paint,
    );
    for (final x in [12.0, w - 12]) {
      final diamond = Path()
        ..moveTo(x, h / 2 - 5)
        ..lineTo(x + 4, h / 2)
        ..lineTo(x, h / 2 + 5)
        ..lineTo(x - 4, h / 2)
        ..close();
      canvas.drawPath(diamond, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ButtonEngraving oldDelegate) =>
      oldDelegate.color != color;
}

class FantasyTextButton extends StatelessWidget {
  const FantasyTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = FantasyButtonStyle.woodGold,
    this.onSound,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FantasyButtonStyle style;
  final VoidCallback? onSound;

  @override
  Widget build(BuildContext context) => FantasyButton(
    label: label,
    icon: icon,
    style: style,
    onPressed: onPressed,
    onSound: onSound,
  );
}

class FantasyIconButton extends StatelessWidget {
  const FantasyIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onSound,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final VoidCallback? onSound;

  @override
  Widget build(BuildContext context) => FantasyButton(
    label: tooltip,
    tooltip: tooltip,
    icon: icon,
    iconOnly: true,
    style: FantasyButtonStyle.iconGold,
    onPressed: onPressed,
    onSound: onSound,
  );
}

class FantasyDiceButton extends StatelessWidget {
  const FantasyDiceButton({
    super.key,
    required this.sides,
    required this.onPressed,
    this.onSound,
  });

  final int sides;
  final VoidCallback? onPressed;
  final VoidCallback? onSound;

  @override
  Widget build(BuildContext context) => FantasyButton(
    label: 'W$sides würfeln',
    icon: Icons.casino_outlined,
    style: FantasyButtonStyle.dice,
    onPressed: onPressed,
    onSound: onSound,
  );
}

class FantasyToggleButton extends StatelessWidget {
  const FantasyToggleButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) => FantasyButton(
    label: label,
    icon: icon,
    compact: compact,
    selected: selected,
    style: FantasyButtonStyle.arcane,
    onPressed: onPressed,
  );
}

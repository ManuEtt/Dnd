import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'fantasy_approved_icons.dart';

/// Gemeinsames Oberflaechensystem. Keine Regeln oder gespeicherten Werte.
abstract final class FantasyPalette {
  static const night = Color(0xff09121f);
  static const ink = Color(0xff0d1927);
  static const surface = Color(0xff142536);
  static const raised = Color(0xff1a3146);
  static const gold = Color(0xffddb96c);
  static const ivory = Color(0xfff4ead6);
  static const muted = Color(0xffadc0cf);
  static const blue = Color(0xff79b8dd);
  static const danger = Color(0xffd76d72);
  static const success = Color(0xff64c4a1);
}

ThemeData buildFantasyTheme() {
  final gold = FantasyPalette.gold;
  final border = gold.withValues(alpha: .40);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FantasyPalette.night,
    colorScheme: ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
      primary: gold,
      secondary: FantasyPalette.blue,
      surface: FantasyPalette.ink,
      onSurface: FantasyPalette.ivory,
      error: FantasyPalette.danger,
    ),
    dividerColor: gold.withValues(alpha: .24),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'serif',
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: FantasyPalette.ivory,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'serif',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: FantasyPalette.ivory,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'serif',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: FantasyPalette.ivory,
      ),
      titleLarge: TextStyle(
        fontFamily: 'serif',
        fontSize: 23,
        fontWeight: FontWeight.bold,
        color: FantasyPalette.ivory,
      ),
      titleMedium: TextStyle(
        fontFamily: 'serif',
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: FantasyPalette.ivory,
      ),
      titleSmall: TextStyle(
        fontFamily: 'serif',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: FantasyPalette.ivory,
      ),
      bodyMedium: TextStyle(color: FantasyPalette.ivory, height: 1.45),
      bodySmall: TextStyle(color: FantasyPalette.muted, height: 1.35),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FantasyPalette.ink,
      foregroundColor: FantasyPalette.ivory,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'serif',
        fontSize: 21,
        fontWeight: FontWeight.bold,
        color: FantasyPalette.ivory,
      ),
      shape: Border(bottom: BorderSide(color: Color(0x5cddb96c))),
    ),
    cardTheme: CardThemeData(
      color: FantasyPalette.surface,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: FantasyPalette.ink,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'serif',
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: FantasyPalette.ivory,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: FantasyPalette.ink,
      modalBackgroundColor: FantasyPalette.ink,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xff101f30),
      labelStyle: const TextStyle(color: FantasyPalette.muted),
      hintStyle: const TextStyle(color: FantasyPalette.muted),
      prefixIconColor: gold,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: FantasyPalette.muted.withValues(alpha: .34),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FantasyPalette.gold, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: FantasyPalette.raised,
      side: BorderSide(color: border),
      labelStyle: const TextStyle(color: FantasyPalette.ivory),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: FantasyPalette.gold,
      textColor: FantasyPalette.ivory,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: FantasyPalette.ink,
      collapsedBackgroundColor: FantasyPalette.surface,
      iconColor: gold,
      collapsedIconColor: gold,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
    ),
    dividerTheme: DividerThemeData(color: gold.withValues(alpha: .25)),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: FantasyPalette.gold,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: FantasyPalette.raised,
      contentTextStyle: const TextStyle(color: FantasyPalette.ivory),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FantasyPalette.gold,
        foregroundColor: FantasyPalette.night,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FantasyPalette.ivory,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: gold,
        minimumSize: const Size(48, 42),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: FantasyPalette.gold),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: FantasyPalette.ink,
      indicatorColor: gold.withValues(alpha: .23),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: FantasyPalette.ivory,
        ),
      ),
      height: 73,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: FantasyPalette.ink,
      selectedIconTheme: const IconThemeData(color: FantasyPalette.gold),
      unselectedIconTheme: const IconThemeData(color: FantasyPalette.muted),
      selectedLabelTextStyle: const TextStyle(color: FantasyPalette.gold),
      unselectedLabelTextStyle: const TextStyle(color: FantasyPalette.muted),
      indicatorColor: gold.withValues(alpha: .17),
    ),
  );
}

/// Unaufdringlicher Fantasy-Verlauf fuer alle Hauptseiten.
class FantasyBackdrop extends StatelessWidget {
  const FantasyBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xff142a40),
              FantasyPalette.night,
              Color(0xff0b1726),
            ],
            stops: [0, .46, 1],
          ),
        ),
      ),
      const Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _FantasyStarlightPainter()),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 205,
        child: IgnorePointer(
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.transparent],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: Opacity(
              opacity: 0.38,
              child: Image.asset(
                'assets/fantasy/night_sky.webp',
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

/// Reusable corner ornaments inspired by the approved moonlit fantasy UI
/// artwork. Painted vectors remain crisp at every Android density.
class FantasyGoldFiligree extends CustomPainter {
  const FantasyGoldFiligree();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FantasyPalette.gold.withValues(alpha: .77)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    const edge = 19.0;
    void corner(double x, double y, double dx, double dy) {
      final p = Path()
        ..moveTo(x + dx * edge, y)
        ..lineTo(x + dx * 5, y)
        ..quadraticBezierTo(x, y, x, y + dy * 5)
        ..lineTo(x, y + dy * edge);
      canvas.drawPath(p, paint);
      canvas.drawLine(
        Offset(x + dx * 7, y + dy * 7),
        Offset(x + dx * 13, y + dy * 13),
        paint,
      );
      final cx = x + dx * 22;
      final cy = y + dy * 22;
      canvas.drawLine(Offset(cx - 3, cy), Offset(cx + 3, cy), paint);
      canvas.drawLine(Offset(cx, cy - 3), Offset(cx, cy + 3), paint);
    }

    corner(2, 2, 1, 1);
    corner(size.width - 2, 2, -1, 1);
    corner(2, size.height - 2, 1, -1);
    corner(size.width - 2, size.height - 2, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _approvedGoldCorner = 'assets/fantasy/ornate_gold_corner.webp';

/// Uses the gold filigree from the approved image package, not an emoji or
/// improvised placeholder. Mirrors one cropped corner to avoid stretching it.
class FantasyApprovedCornerFrame extends StatelessWidget {
  const FantasyApprovedCornerFrame({
    super.key,
    required this.child,
    this.cornerSize = 34,
    this.opacity = .80,
  });

  final Widget child;
  final double cornerSize;
  final double opacity;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      child,
      for (final corner in [0, 1, 2, 3])
        Positioned(
          top: corner < 2 ? 0 : null,
          bottom: corner >= 2 ? 0 : null,
          left: corner.isEven ? 0 : null,
          right: corner.isOdd ? 0 : null,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Opacity(
                opacity: opacity,
                child: Transform.flip(
                  flipX: corner.isOdd,
                  flipY: corner >= 2,
                  child: Image.asset(
                    _approvedGoldCorner,
                    key: ValueKey('approved-corner-$corner'),
                    width: cornerSize,
                    height: cornerSize,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// File names from the user's complete fantasy artwork ZIP.
abstract final class FantasyOptionalArt {
  static const panel = 'assets/fantasy/ornate_panel_background.webp';
  static const button = 'assets/fantasy/ornate_button_background.webp';
  static const card = 'assets/fantasy/ornate_card_background.webp';
  static const portrait = 'assets/fantasy/ornate_portrait_border.webp';

  static final Future<Set<String>> available =
      AssetManifest.loadFromAssetBundle(
        rootBundle,
      ).then((manifest) => manifest.listAssets().toSet());
}

/// Paints an optional original fantasy asset without intercepting touches.
/// Content remains genuine Flutter widgets. Missing graphics fall back to the
/// normal fantasy color/filigree theme, including older installed APKs.
class FantasyOptionalImageFrame extends StatelessWidget {
  const FantasyOptionalImageFrame({
    super.key,
    required this.child,
    required this.image,
    this.foreground = false,
    this.opacity = .95,
    this.centerSlice,
  });

  final Widget child;
  final String image;
  final bool foreground;
  final double opacity;
  final Rect? centerSlice;

  @override
  Widget build(BuildContext context) {
    final artwork = Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: FutureBuilder<Set<String>>(
            future: FantasyOptionalArt.available,
            builder: (context, snapshot) {
              if (!(snapshot.data?.contains(image) ?? false)) {
                return const SizedBox.shrink();
              }
              return Opacity(
                opacity: opacity,
                child: Image.asset(
                  image,
                  key: ValueKey('fantasy-art-$image'),
                  // These source WebPs are design crops, not nine-patch images.
                  // centerSlice causes a Flutter paint assertion for small
                  // cards, buttons, and portrait tiles. Stretch the optional
                  // decorative layer safely; the interactive content remains
                  // independent and the gold corner overlay stays intact.
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, error, stack) => const SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
      ),
    );
    return Stack(
      fit: StackFit.passthrough,
      children: foreground ? [child, artwork] : [artwork, child],
    );
  }
}

/// Wiederverwendeter gerahmter Bereich mit dezenten goldenen Verzierungen.
class FantasyPanel extends StatelessWidget {
  const FantasyPanel({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.accent = FantasyPalette.gold,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final String? title;
  final IconData? icon;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => FantasyApprovedCornerFrame(
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1a3045), Color(0xff0e1b29)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: .5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2e000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FantasyOptionalImageFrame(
        image: FantasyOptionalArt.panel,
        centerSlice: const Rect.fromLTWH(34, 32, 292, 54),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: accent, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              Divider(color: accent.withValues(alpha: .3), height: 24),
            ],
            child,
          ],
        ),
      ),
    ),
  );
}

class FantasySectionTitle extends StatelessWidget {
  const FantasySectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.approvedIconIndex,
    this.subtitle,
  });
  final String title;
  final IconData? icon;
  final int? approvedIconIndex;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (approvedIconIndex != null) ...[
              FantasyApprovedIcon(index: approvedIconIndex!, size: 34),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(icon, color: FantasyPalette.gold, size: 25),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.auto_awesome,
              color: FantasyPalette.gold,
              size: 15,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(height: 1, color: FantasyPalette.gold.withValues(alpha: .3)),
        if (subtitle != null) ...[
          const SizedBox(height: 7),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

class FantasyHeroBanner extends StatelessWidget {
  const FantasyHeroBanner({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.icon = Icons.auto_awesome,
  });
  final String title;
  final String description;
  final Widget child;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FantasyPanel(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: FantasyPalette.gold, size: 33),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(description),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

class FantasyStatTile extends StatelessWidget {
  const FantasyStatTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.color = FantasyPalette.gold,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 108),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: FantasyPalette.ink,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .44)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

/// Quiet, deterministic golden star tracery; graphics remain offline and do
/// not intercept any gestures or semantics.
class _FantasyStarlightPainter extends CustomPainter {
  const _FantasyStarlightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final ink = Paint()
      ..color = FantasyPalette.gold.withValues(alpha: .19)
      ..strokeWidth = .8;
    final flare = Paint()
      ..color = FantasyPalette.blue.withValues(alpha: .14)
      ..strokeWidth = .7;
    for (var i = 0; i < 38; i++) {
      final x = ((i * 97 + 13) % 101) / 101 * size.width;
      final y = ((i * 47 + 21) % 97) / 97 * size.height;
      final center = Offset(x, y);
      final arm = (i % 5 == 0) ? 3.3 : 1.2;
      final pen = i.isEven ? ink : flare;
      canvas.drawLine(center.translate(-arm, 0), center.translate(arm, 0), pen);
      canvas.drawLine(center.translate(0, -arm), center.translate(0, arm), pen);
    }
    final orbitPaint = Paint()
      ..color = FantasyPalette.gold.withValues(alpha: .055)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final radius = math.min(size.width, size.height) * .27;
    final center = Offset(size.width * .89, size.height * .11);
    canvas.drawCircle(center, radius, orbitPaint);
    canvas.drawCircle(center, radius * .8, orbitPaint);
  }

  @override
  bool shouldRepaint(covariant _FantasyStarlightPainter oldDelegate) => false;
}

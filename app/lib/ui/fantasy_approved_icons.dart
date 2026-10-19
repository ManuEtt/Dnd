import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Approved gold-on-navy icons, extracted from the user's accepted design.
/// The grid is an offline 4 x 2 WebP atlas embedded as an ASCII Flutter asset.
class FantasyApprovedIcon extends StatelessWidget {
  const FantasyApprovedIcon({
    super.key,
    required this.index,
    this.size = 30,
  });

  final int index;
  final double size;

  static final Future<ui.Image> _atlas = _load();

  static Future<ui.Image> _load() async {
    final source = await rootBundle.loadString(
      'assets/fantasy/ui_icon_atlas.webp.b64',
    );
    final codec = await ui.instantiateImageCodec(base64Decode(source.trim()));
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: FutureBuilder<ui.Image>(
      future: _atlas,
      builder: (context, snapshot) {
        if (!snapshot.hasData || index < 0 || index > 7) {
          return const Icon(Icons.auto_awesome, color: Color(0xffd4b574));
        }
        return CustomPaint(
          painter: _AtlasIconPainter(snapshot.data!, index),
          size: Size(size, size),
        );
      },
    ),
  );
}

class _AtlasIconPainter extends CustomPainter {
  const _AtlasIconPainter(this.atlas, this.index);
  final ui.Image atlas;
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final w = atlas.width / 4;
    final h = atlas.height / 2;
    canvas.drawImageRect(
      atlas,
      Rect.fromLTWH((index % 4) * w, (index ~/ 4) * h, w, h),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_AtlasIconPainter oldDelegate) =>
      oldDelegate.atlas != atlas || oldDelegate.index != index;
}

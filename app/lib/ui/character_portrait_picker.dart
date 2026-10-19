import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'fantasy_art.dart';
import 'fantasy_ui.dart';

// The approved portraits and scenery are native WebP Flutter assets.
// Portrait selection is independent of network access.
abstract final class FantasyApprovedAssets {
  static final Future<ui.Image> portraitAtlas = _loadAtlas();

  /// The original 256px portraits are bundled by the graphics package.
  /// Existing saves retain their preset indices even without those files.
  static String highResolutionPortraitPath(int preset) =>
      'assets/fantasy/portrait_${preset + 1}.webp';

  static final Future<Set<String>> availableAssetPaths =
      AssetManifest.loadFromAssetBundle(rootBundle)
          .then((manifest) => manifest.listAssets().toSet());
  static final Future<Uint8List> moonlitSky = rootBundle
      .load('assets/fantasy/night_sky.webp')
      .then(
        (value) =>
            value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes),
      );

  static Future<ui.Image> _loadAtlas() async {
    final bytes = await rootBundle.load('assets/fantasy/portrait_atlas.webp');
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }
}

class _PortraitAtlasPainter extends CustomPainter {
  const _PortraitAtlasPainter(this.atlas, this.index);
  final ui.Image atlas;
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final width = atlas.width / 3;
    final height = atlas.height / 3;
    canvas.drawImageRect(
      atlas,
      Rect.fromLTWH((index % 3) * width, (index ~/ 3) * height, width, height),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_PortraitAtlasPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.atlas != atlas;
}

class FantasyMoonlitBanner extends StatelessWidget {
  const FantasyMoonlitBanner({super.key, this.height = 100});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<Uint8List>(
        future: FantasyApprovedAssets.moonlitSky,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ColoredBox(color: FantasyPalette.ink);
          }
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            semanticLabel: 'Mondnacht über dem Fantasy-Schloss',
          );
        },
      ),
    ),
  );
}

class CharacterPortraitChoice {
  const CharacterPortraitChoice(this.preset, this.photoBase64);
  final int preset;
  final String photoBase64;
}

/// Decorative view, no implicit character edits.
class FantasyCharacterPortrait extends StatelessWidget {
  const FantasyCharacterPortrait({
    super.key,
    required this.preset,
    required this.photoBase64,
    this.name = '',
    this.size = 96,
  });

  final int preset;
  final String photoBase64;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget picture;
    if (photoBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(photoBase64);
        picture = Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, error, stackTrace) =>
              const Icon(Icons.person_outline, color: FantasyPalette.gold),
        );
      } catch (_) {
        picture = const Icon(Icons.person_outline, color: FantasyPalette.gold);
      }
    } else if (preset >= 0 && preset < 9) {
      // Prefer original 256px portraits; preserve the shipped atlas fallback.
      final atlasFallback = FutureBuilder<ui.Image>(
        future: FantasyApprovedAssets.portraitAtlas,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CustomPaint(
              painter: _PortraitAtlasPainter(snapshot.data!, preset),
              size: Size(size - 10, size - 10),
            );
          }
          return Image.asset(
            FantasyArtwork.campaign(preset),
            fit: BoxFit.cover,
          );
        },
      );
      picture = FutureBuilder<Set<String>>(
        future: FantasyApprovedAssets.availableAssetPaths,
        builder: (context, snapshot) {
          final asset = FantasyApprovedAssets.highResolutionPortraitPath(preset);
          if (!(snapshot.data?.contains(asset) ?? false)) {
            return atlasFallback;
          }
          return Image.asset(
            asset,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, error, stackTrace) => atlasFallback,
          );
        },
      );
    } else {
      picture = const Icon(Icons.person_outline, color: FantasyPalette.gold);
    }
    return SizedBox(
      height: size,
      width: size,
      child: FantasyApprovedCornerFrame(
        cornerSize: (size * .31).clamp(20.0, 40.0).toDouble(),
        opacity: .94,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FantasyPalette.ink,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: FantasyPalette.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: FantasyPalette.gold.withValues(alpha: .22),
                blurRadius: 9,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: size - 10,
                  height: size - 10,
                  child: picture,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CharacterPortraitPicker extends StatefulWidget {
  const CharacterPortraitPicker({
    super.key,
    required this.initialPreset,
    required this.initialPhotoBase64,
  });
  final int initialPreset;
  final String initialPhotoBase64;

  @override
  State<CharacterPortraitPicker> createState() =>
      _CharacterPortraitPickerState();
}

class _CharacterPortraitPickerState extends State<CharacterPortraitPicker> {
  late int _preset = widget.initialPreset;
  late String _photo = widget.initialPhotoBase64;
  String? _message;

  Future<void> _pickOwnPicture() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 50,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 45000 || bytes.isEmpty) {
        setState(
          () => _message =
              'Bild ist zu groß. Bitte eine kleinere JPG-Datei wählen (maximal 45 KB nach Verkleinerung).',
        );
        return;
      }
      // Validate that the supplied data is an actual decodable image, not
      // an arbitrary file with a .jpg or .png extension.
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (frame.image.width > 256 || frame.image.height > 256) {
        frame.image.dispose();
        codec.dispose();
        setState(() => _message = 'Bildauflösung überschreitet 256 Pixel.');
        return;
      }
      frame.image.dispose();
      codec.dispose();
      if (!mounted) return;
      setState(() {
        _preset = -1;
        _photo = base64Encode(bytes);
        _message = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Bild konnte nicht geöffnet werden.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Charakterbild wählen')),
    body: FantasyBackdrop(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const FantasyMoonlitBanner(height: 98),
          const SizedBox(height: 12),
          FantasyPanel(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final portrait = FantasyCharacterPortrait(
                  key: const ValueKey('portrait-current-preview'),
                  preset: _preset,
                  photoBase64: _photo,
                  size: 124,
                );
                final options = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktuelles Charakterbild',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dieses Bild erscheint auf deinem Charakterbogen.',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        OutlinedButton.icon(
                          key: const ValueKey('portrait-own-image'),
                          onPressed: _pickOwnPicture,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Eigenes Bild wählen'),
                        ),
                        TextButton.icon(
                          key: const ValueKey('portrait-remove'),
                          onPressed: () => setState(() {
                            _preset = -1;
                            _photo = '';
                            _message = null;
                          }),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Entfernen'),
                        ),
                      ],
                    ),
                  ],
                );
                if (constraints.maxWidth < 410) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: portrait),
                      const SizedBox(height: 12),
                      options,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    portrait,
                    const SizedBox(width: 14),
                    Expanded(child: options),
                  ],
                );
              },
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _message!,
                style: const TextStyle(color: FantasyPalette.danger),
              ),
            ),
          const SizedBox(height: 18),
          const FantasySectionTitle(
            title: 'Vorschläge',
            icon: Icons.auto_awesome_outlined,
            subtitle:
                'Wähle eines der neun Fantasy-Porträts oder ein eigenes Bild.',
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: 0.87,
            ),
            itemCount: 9,
            itemBuilder: (context, i) => Semantics(
              label: 'Fantasy-Porträt ${i + 1}',
              button: true,
              selected: _preset == i,
              child: InkWell(
                key: ValueKey('portrait-option-$i'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _preset = i;
                  _photo = '';
                  _message = null;
                }),
                onLongPress: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text('Fantasy-Porträt ${i + 1}'),
                    content: FantasyCharacterPortrait(
                      preset: i,
                      photoBase64: '',
                      size: 220,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Schließen'),
                      ),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            FantasyCharacterPortrait(
                              preset: i,
                              photoBase64: '',
                              size: constraints.biggest.shortestSide,
                            ),
                      ),
                    ),
                    if (_preset == i)
                      const Icon(Icons.check_circle, color: FantasyPalette.gold)
                    else
                      const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('portrait-apply'),
                onPressed: () => Navigator.of(
                  context,
                ).pop(CharacterPortraitChoice(_preset, _photo)),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Übernehmen'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

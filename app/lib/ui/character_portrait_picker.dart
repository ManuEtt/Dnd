import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show instantiateImageCodec;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'fantasy_art.dart';
import 'fantasy_ui.dart';

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
      // The exact approved portraits are delivered with the graphic pack.
      // Existing artwork provides an offline fallback until each picture is
      // installed in assets/fantasy/portraits/.
      picture = Image.asset(
        'assets/fantasy/portraits/portrait_${preset + 1}.webp',
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Image.asset(
          FantasyArtwork.campaign(preset),
          fit: BoxFit.cover,
        ),
      );
    } else {
      picture = const Icon(Icons.person_outline, color: FantasyPalette.gold);
    }
    return SizedBox(
      height: size,
      width: size,
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
            child: FittedBox(fit: BoxFit.cover, child: SizedBox(
              width: size - 10, height: size - 10, child: picture,
            )),
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
  State<CharacterPortraitPicker> createState() => _CharacterPortraitPickerState();
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
        setState(() => _message =
            'Bild ist zu groß. Bitte eine kleinere JPG-Datei wählen (maximal 45 KB nach Verkleinerung).');
        return;
      }
      // Validate that the supplied data is an actual decodable image, not
      // an arbitrary file with a .jpg or .png extension.
      final codec = await instantiateImageCodec(bytes);
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
          FantasyPanel(
            child: Row(
              children: [
                FantasyCharacterPortrait(
                  key: const ValueKey('portrait-current-preview'),
                  preset: _preset,
                  photoBase64: _photo,
                  size: 124,
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aktuelles Charakterbild',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Dieses Bild erscheint auf deinem Charakterbogen.'),
                    const SizedBox(height: 10),
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
                )),
              ],
            ),
          ),
          if (_message != null)
            Padding(padding: const EdgeInsets.all(8),
              child: Text(_message!, style: const TextStyle(color: FantasyPalette.danger))),
          const SizedBox(height: 18),
          const FantasySectionTitle(
            title: 'Vorschläge',
            icon: Icons.auto_awesome_outlined,
            subtitle: 'Wähle eines der neun Fantasy-Porträts oder ein eigenes Bild.',
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 12,
              childAspectRatio: 0.87,
            ),
            itemCount: 9,
            itemBuilder: (context, i) => InkWell(
              key: ValueKey('portrait-option-$i'),
              onTap: () => setState(() {
                _preset = i;
                _photo = '';
                _message = null;
              }),
              child: Column(children: [
                Expanded(child: LayoutBuilder(builder: (context, constraints) =>
                  FantasyCharacterPortrait(
                    preset: i, photoBase64: '', size: constraints.maxWidth,
                  ),
                )),
                if (_preset == i) const Icon(Icons.check_circle, color: FantasyPalette.gold),
              ]),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          )),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(
            key: const ValueKey('portrait-apply'),
            onPressed: () => Navigator.of(context).pop(
              CharacterPortraitChoice(_preset, _photo),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Übernehmen'),
          )),
        ]),
      ),
    ),
  );
}

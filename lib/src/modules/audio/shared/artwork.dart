/// Shared poster / artwork chrome for audio surfaces.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';

/// Resolves track artwork from an [ImageProvider], URL, or placeholder.
class ConsonaAudioArtwork extends StatelessWidget {
  const ConsonaAudioArtwork({
    super.key,
    this.image,
    this.url,
    this.size = 48.0,
    this.radiusRole = ConsonaRadiusRole.macro,
    this.circular = false,
    this.semanticLabel = 'Track artwork',
  });

  final ImageProvider? image;
  final String? url;
  final double size;
  final ConsonaRadiusRole radiusRole;
  final bool circular;
  final String semanticLabel;

  ImageProvider? get _resolved {
    if (image != null) return image;
    if (url != null && url!.isNotEmpty) return NetworkImage(url!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final radius = circular
        ? theme.radius.resolve(ConsonaRadiusRole.full)
        : theme.radius.resolve(radiusRole);
    final provider = _resolved;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: radius,
          border: theme.border.resolve(ConsonaBorderRole.subtle),
          boxShadow: theme.shadow.resolve(ConsonaShadowLevel.subtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: provider == null
            ? Icon(
                Icons.music_note_rounded,
                size: size * 0.42,
                color: colors.mutedFg,
              )
            : Image(
                image: provider,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.music_note_rounded,
                  size: size * 0.42,
                  color: colors.mutedFg,
                ),
              ),
      ),
    );
  }
}

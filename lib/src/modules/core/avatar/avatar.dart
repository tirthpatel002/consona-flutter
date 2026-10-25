/// Consona Avatar & AvatarGroup — Identity badges with presence dots and stacked groups.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';

/// Presence status indicator for [ConsonaAvatar].
enum ConsonaAvatarStatus { online, busy, away, offline }

/// Size presets for [ConsonaAvatar].
enum ConsonaAvatarSize { sm, md, lg, xl }

/// Circular or squircle user identity avatar with image provider, initials
/// fallback, and optional presence status badge.
class ConsonaAvatar extends StatelessWidget {
  const ConsonaAvatar({
    super.key,
    this.name,
    this.initials,
    this.imageProvider,
    this.icon,
    this.size = ConsonaAvatarSize.md,
    this.status,
    this.squircle = false,
  });

  final String? name;
  final String? initials;
  final ImageProvider? imageProvider;
  final Widget? icon;
  final ConsonaAvatarSize size;
  final ConsonaAvatarStatus? status;
  final bool squircle;

  double _resolveDimension(double scale) {
    final base = switch (size) {
      ConsonaAvatarSize.sm => 28.0,
      ConsonaAvatarSize.md => 36.0,
      ConsonaAvatarSize.lg => 48.0,
      ConsonaAvatarSize.xl => 64.0,
    };
    return base * scale;
  }

  String _computeInitials() {
    if (initials != null && initials!.trim().isNotEmpty) {
      return initials!.trim().toUpperCase();
    }
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final dim = _resolveDimension(theme.density.factor);
    final radiusRole =
        squircle ? ConsonaRadiusRole.base : ConsonaRadiusRole.full;
    final borderRadius = theme.radius.resolve(radiusRole);

    final statusColor = switch (status) {
      ConsonaAvatarStatus.online => theme.colors.success,
      ConsonaAvatarStatus.busy => theme.colors.danger,
      ConsonaAvatarStatus.away => theme.colors.warning,
      ConsonaAvatarStatus.offline => theme.colors.mutedFg,
      null => null,
    };

    return Semantics(
      label: name ?? initials ?? 'Avatar',
      image: imageProvider != null,
      child: SizedBox(
        width: dim,
        height: dim,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: dim,
              height: dim,
              decoration: BoxDecoration(
                color: theme.colors.primary.withAlpha(32),
                borderRadius: borderRadius,
                border: theme.border.resolve(
                  ConsonaBorderRole.surfaceEdge,
                  context: context,
                ),
                image: imageProvider != null
                    ? DecorationImage(
                        image: imageProvider!,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: imageProvider == null
                  ? (icon ??
                        Text(
                          _computeInitials(),
                          style: theme.typography.label.copyWith(
                            color: theme.colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: dim * 0.36,
                          ),
                        ))
                  : null,
            ),
            if (statusColor != null)
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: Container(
                  width: dim * 0.28,
                  height: dim * 0.28,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                    border: Border.all(
                      color: theme.colors.background,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Overlapping horizontal stack of [ConsonaAvatar] items with a `+N` overflow
/// counter pill.
class ConsonaAvatarGroup extends StatelessWidget {
  const ConsonaAvatarGroup({
    super.key,
    required this.avatars,
    this.maxVisible = 4,
    this.size = ConsonaAvatarSize.md,
    this.overlapFactor = 0.28,
  });

  final List<ConsonaAvatar> avatars;
  final int maxVisible;
  final ConsonaAvatarSize size;
  final double overlapFactor;

  double _resolveDimension(double scale) {
    final base = switch (size) {
      ConsonaAvatarSize.sm => 28.0,
      ConsonaAvatarSize.md => 36.0,
      ConsonaAvatarSize.lg => 48.0,
      ConsonaAvatarSize.xl => 64.0,
    };
    return base * scale;
  }

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    final theme = ConsonaTheme.of(context);
    final dim = _resolveDimension(theme.density.factor);
    final step = dim * (1.0 - overlapFactor.clamp(0.0, 0.7));
    final visibleCount =
        avatars.length > maxVisible ? maxVisible : avatars.length;
    final overflow = avatars.length - visibleCount;
    final totalItems = visibleCount + (overflow > 0 ? 1 : 0);
    final totalWidth = dim + (totalItems - 1) * step;

    return SizedBox(
      width: totalWidth,
      height: dim,
      child: Stack(
        children: [
          for (int i = 0; i < visibleCount; i++)
            PositionedDirectional(
              start: i * step,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                  border: Border.all(
                    color: theme.colors.background,
                    width: 2,
                  ),
                ),
                child: ConsonaAvatar(
                  name: avatars[i].name,
                  initials: avatars[i].initials,
                  imageProvider: avatars[i].imageProvider,
                  icon: avatars[i].icon,
                  size: size,
                  status: avatars[i].status,
                  squircle: avatars[i].squircle,
                ),
              ),
            ),
          if (overflow > 0)
            PositionedDirectional(
              start: visibleCount * step,
              child: Container(
                width: dim,
                height: dim,
                decoration: BoxDecoration(
                  color: theme.colors.surfaceSecondary,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                  border: Border.all(
                    color: theme.colors.background,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflow',
                  style: theme.typography.label.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

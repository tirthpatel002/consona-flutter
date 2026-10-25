/// Consona Image — Memory-safe, adaptive progressive image with fail-closed fallbacks.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/button/button.dart';
import '../../core/skeleton/skeleton.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Progressive image loader with memory downsampling, blur/shimmer placeholder,
/// and fail-closed error fallback.
class ConsonaImage extends StatefulWidget {
  const ConsonaImage({
    super.key,
    this.uri,
    this.bytes,
    this.imageProvider,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.radiusRole = ConsonaRadiusRole.base,
    this.borderRole = ConsonaBorderRole.subtle,
    this.zoomOnHover = false,
    this.semanticLabel,
    this.placeholder,
    this.errorBuilder,
    this.onTap,
  });

  /// Remote URL ('https://...'), asset path ('assets/...'), or local file path.
  final String? uri;

  /// Raw image bytes for in-memory rendering.
  final Uint8List? bytes;

  /// Explicit custom [ImageProvider].
  final ImageProvider? imageProvider;

  /// Explicit layout width.
  final double? width;

  /// Explicit layout height.
  final double? height;

  /// Optional aspect ratio (e.g. 16/9, 4/3, 1.0).
  final double? aspectRatio;

  /// Scaling behavior inside container.
  final BoxFit fit;

  /// Maximum decoded pixel width in memory to prevent OOM.
  final int? cacheWidth;

  /// Maximum decoded pixel height in memory to prevent OOM.
  final int? cacheHeight;

  /// Corner radius role. Pass `null` for sharp corners (e.g. lightbox stage).
  final ConsonaRadiusRole? radiusRole;

  /// Border role. Pass `null` to omit the border (parent chrome owns edges).
  final ConsonaBorderRole? borderRole;

  /// On desktop, lightly scales image by 1.03x on hover.
  final bool zoomOnHover;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  /// Custom loading widget. Defaults to [ConsonaSkeleton].
  final Widget? placeholder;

  /// Custom error fallback builder.
  final Widget Function(BuildContext context, VoidCallback retry)? errorBuilder;

  /// Callback when image is tapped (e.g. to open [ConsonaLightbox]).
  final VoidCallback? onTap;

  @override
  State<ConsonaImage> createState() => _ConsonaImageState();
}

class _ConsonaImageState extends State<ConsonaImage> {
  bool _isHovered = false;
  int _retryKey = 0;

  void _retry() {
    setState(() => _retryKey++);
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap);
  }

  ImageProvider? _resolveProvider() {
    if (widget.imageProvider != null) {
      return _applyResize(widget.imageProvider!);
    }
    if (widget.bytes != null && widget.bytes!.isNotEmpty) {
      return _applyResize(MemoryImage(widget.bytes!));
    }
    final rawUri = widget.uri;
    if (rawUri == null || rawUri.trim().isEmpty) return null;

    final trimmed = rawUri.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _applyResize(NetworkImage(trimmed));
    }
    return _applyResize(AssetImage(trimmed));
  }

  ImageProvider _applyResize(ImageProvider provider) {
    if (widget.cacheWidth != null || widget.cacheHeight != null) {
      return ResizeImage(
        provider,
        width: widget.cacheWidth,
        height: widget.cacheHeight,
        allowUpscaling: false,
      );
    }
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);
    final borderRadius = widget.radiusRole != null
        ? theme.radius.resolve(widget.radiusRole!)
        : BorderRadius.zero;
    final border = widget.borderRole != null
        ? theme.border.resolve(widget.borderRole!, context: context)
        : null;

    final provider = _resolveProvider();

    Widget content;

    if (provider == null) {
      content = _buildErrorContainer(theme, colors, 'No image source provided');
    } else {
      content = Image(
        key: ValueKey('${widget.uri}_$_retryKey'),
        image: provider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        semanticLabel: widget.semanticLabel,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return AnimatedOpacity(
              opacity: 1.0,
              duration: motion.duration,
              curve: motion.curve,
              child: child,
            );
          }
          return widget.placeholder ??
              ConsonaSkeleton(
                width: widget.width ?? double.infinity,
                height: widget.height ?? double.infinity,
              );
        },
        errorBuilder: (context, error, stackTrace) {
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context, _retry);
          }
          return _buildErrorContainer(
            theme,
            colors,
            'Unable to load image',
            canRetry: true,
          );
        },
      );
    }

    if (widget.aspectRatio != null && widget.aspectRatio! > 0) {
      content = AspectRatio(
        aspectRatio: widget.aspectRatio!,
        child: content,
      );
    }

    // Hover zoom interaction for desktop
    if (widget.zoomOnHover) {
      final pressMotion = theme.motion.resolve(ConsonaMotionRole.press, context);
      content = AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: pressMotion.duration,
        curve: pressMotion.curve,
        child: content,
      );
    }

    final container = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: borderRadius,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    return Semantics(
      image: true,
      label: widget.semanticLabel ?? 'Image',
      button: widget.onTap != null,
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          if (widget.zoomOnHover && !_isHovered) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (widget.zoomOnHover && _isHovered) {
            setState(() => _isHovered = false);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap != null
              ? () {
                  ConsonaFeedbackScope.maybeOf(context)
                      ?.trigger(FeedbackEvent.tap);
                  widget.onTap!();
                }
              : null,
          child: container,
        ),
      ),
    );
  }

  Widget _buildErrorContainer(
    ConsonaThemeData theme,
    ConsonaColors colors,
    String message, {
    bool canRetry = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxHeight < 80.0 || constraints.maxWidth < 80.0;
        if (isCompact) {
          return Container(
            color: colors.surfaceSecondary,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 20.0,
              color: colors.mutedFg,
            ),
          );
        }

        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 180.0,
          color: colors.surfaceSecondary,
          padding: const EdgeInsets.all(ConsonaSpacing.base),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
                  border: theme.border.resolve(
                    ConsonaBorderRole.subtle,
                    context: context,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 22.0,
                  color: colors.mutedFg,
                ),
              ),
              const SizedBox(height: ConsonaSpacing.sm),
              Text(
                'Image Unavailable',
                style: theme.typography.label.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: ConsonaSpacing.xxs),
              Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                ),
              ),
              if (canRetry) ...[
                const SizedBox(height: ConsonaSpacing.sm),
                ConsonaButton.subtle(
                  label: 'Retry',
                  leading: const Icon(Icons.refresh_outlined, size: 14.0),
                  size: ConsonaOpticalSize.xs,
                  onTap: _retry,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Consona Before/After Slider — Split-screen image comparison with interactive handle.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Interactive before-and-after comparison slider with draggable hairline handle,
/// directional keyboard navigation, and tactile feedback.
class ConsonaBeforeAfterSlider extends StatefulWidget {
  const ConsonaBeforeAfterSlider({
    super.key,
    required this.before,
    required this.after,
    this.initialSplit = 0.5,
    this.aspectRatio = 16 / 9,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.showLabels = true,
    this.radiusRole = ConsonaRadiusRole.base,
    this.borderRole = ConsonaBorderRole.subtle,
    this.onSplitChanged,
  });

  /// The widget representing the 'Before' state (e.g. unedited, original photo).
  final Widget before;

  /// The widget representing the 'After' state (e.g. edited, filtered photo).
  final Widget after;

  /// Initial split fraction (0.0 = all after, 1.0 = all before).
  final double initialSplit;

  /// Aspect ratio for container.
  final double aspectRatio;

  /// Text label for the 'Before' side.
  final String beforeLabel;

  /// Text label for the 'After' side.
  final String afterLabel;

  /// Whether corner labels should be visible.
  final bool showLabels;

  /// Corner radius role.
  final ConsonaRadiusRole radiusRole;

  /// Outer border role.
  final ConsonaBorderRole borderRole;

  /// Optional callback when split position changes.
  final ValueChanged<double>? onSplitChanged;

  @override
  State<ConsonaBeforeAfterSlider> createState() =>
      _ConsonaBeforeAfterSliderState();
}

class _ConsonaBeforeAfterSliderState extends State<ConsonaBeforeAfterSlider> {
  late double _split;
  bool _isDragging = false;
  bool _isHovered = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _split = widget.initialSplit.clamp(0.05, 0.95);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSplit(double next) {
    final clamped = next.clamp(0.02, 0.98);
    if ((clamped - _split).abs() > 0.001) {
      final crossedCenter = (_split < 0.5 && clamped >= 0.5) ||
          (_split > 0.5 && clamped <= 0.5);
      setState(() => _split = clamped);
      widget.onSplitChanged?.call(clamped);

      if (crossedCenter) {
        ConsonaFeedbackScope.maybeOf(context)
            ?.trigger(FeedbackEvent.selection);
      }
    }
  }

  void _handleDrag(DragUpdateDetails details, double totalWidth) {
    if (totalWidth <= 0) return;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final deltaFraction = (details.delta.dx / totalWidth) * (isRtl ? -1 : 1);
    _updateSplit(_split + deltaFraction);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _updateSplit(_split - 0.05);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _updateSplit(_split + 0.05);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final borderRadius = theme.radius.resolve(widget.radiusRole);
    final border = theme.border.resolve(widget.borderRole, context: context);

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (_, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final splitPx = width * _split;

            return Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: border,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: 'After' view (Background)
                  widget.after,

                  // Layer 2: 'Before' view (Clipped horizontally)
                  ClipRect(
                    clipper: _HorizontalSplitClipper(splitPx),
                    child: widget.before,
                  ),

                  // Optional Labels
                  if (widget.showLabels) ...[
                    Positioned(
                      top: ConsonaSpacing.md,
                      left: ConsonaSpacing.md,
                      child: _buildLabel(theme, colors, widget.beforeLabel),
                    ),
                    Positioned(
                      top: ConsonaSpacing.md,
                      right: ConsonaSpacing.md,
                      child: _buildLabel(theme, colors, widget.afterLabel),
                    ),
                  ],

                  // Layer 3: Interactive Divider Handle
                  Positioned(
                    left: splitPx - 22.0,
                    top: 0,
                    bottom: 0,
                    width: 44.0,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      onEnter: (_) => setState(() => _isHovered = true),
                      onExit: (_) => setState(() => _isHovered = false),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (_) {
                          setState(() => _isDragging = true);
                          ConsonaFeedbackScope.maybeOf(context)
                              ?.trigger(FeedbackEvent.selection);
                          _focusNode.requestFocus();
                        },
                        onHorizontalDragUpdate: (d) => _handleDrag(d, width),
                        onHorizontalDragEnd: (_) {
                          setState(() => _isDragging = false);
                        },
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Vertical hairline divider with shadow
                              Container(
                                width: (_isDragging || _isHovered) ? 2.5 : 1.5,
                                height: height,
                                decoration: BoxDecoration(
                                  color: (_isDragging || _isHovered)
                                      ? colors.primary
                                      : colors.surface.withAlpha(240),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.foreground.withAlpha(40),
                                      blurRadius: 4,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),

                              // Tactile grab pill in center
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 34.0,
                                height: 34.0,
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  shape: BoxShape.circle,
                                  border: theme.border.resolve(
                                    (_isDragging || _isHovered)
                                        ? ConsonaBorderRole.focus
                                        : ConsonaBorderRole.subtle,
                                    context: context,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.foreground.withAlpha(40),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.swap_horiz_outlined,
                                  size: 19.0,
                                  color: (_isDragging || _isHovered)
                                      ? colors.primary
                                      : colors.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(
    ConsonaThemeData theme,
    ConsonaColors colors,
    String label,
  ) {
    return ClipRRect(
      borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ConsonaSpacing.sm,
            vertical: ConsonaSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withAlpha(190),
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
            border: theme.border.resolve(
              ConsonaBorderRole.subtle,
              context: context,
            ),
          ),
          child: Text(
            label,
            style: theme.typography.caption.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11.0,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  const _HorizontalSplitClipper(this.splitWidth);

  final double splitWidth;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, splitWidth, size.height);
  }

  @override
  bool shouldReclip(_HorizontalSplitClipper oldClipper) {
    return oldClipper.splitWidth != splitWidth;
  }
}

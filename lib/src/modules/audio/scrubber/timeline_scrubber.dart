/// Consona TimelineScrubber — Touch-magnified precision timeline scrubber with time readout.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Tactile precision audio timeline scrubber with time readout.
class ConsonaTimelineScrubber extends StatefulWidget {
  const ConsonaTimelineScrubber({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.buffered = Duration.zero,
    this.enabled = true,
    this.compact = false,
    this.showLabels = true,
  });

  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ValueChanged<Duration> onSeek;
  final bool enabled;

  /// Tighter track + labels for dense cards.
  final bool compact;
  final bool showLabels;

  @override
  State<ConsonaTimelineScrubber> createState() => _ConsonaTimelineScrubberState();
}

class _ConsonaTimelineScrubberState extends State<ConsonaTimelineScrubber> {
  double? _dragFraction;
  bool _isHovered = false;

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  void _onDragUpdate(Offset localPosition, double totalWidth, double inset) {
    if (!widget.enabled || totalWidth <= 0) return;
    final railW = (totalWidth - inset * 2).clamp(1.0, totalWidth);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final rawFraction = ((localPosition.dx - inset) / railW).clamp(0.0, 1.0);
    final fraction = isRtl ? 1.0 - rawFraction : rawFraction;
    setState(() => _dragFraction = fraction);
    final targetMs = (fraction * widget.duration.inMilliseconds).round();
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
    widget.onSeek(Duration(milliseconds: targetMs));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    final totalMs = widget.duration.inMilliseconds;
    final currentMs = widget.position.inMilliseconds;
    final progress = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final effectiveProgress = _dragFraction ?? progress;
    final isActive = _dragFraction != null || _isHovered;

    final trackH = widget.compact ? 18.0 : 24.0;
    // Horizontal pill thumb dimensions (width > height)
    final thumbW = isActive
        ? (widget.compact ? 20.0 : 24.0)
        : (widget.compact ? 16.0 : 20.0);
    final thumbH = isActive
        ? (widget.compact ? 12.0 : 14.0)
        : (widget.compact ? 10.0 : 12.0);
    final borderWidth = widget.compact ? 2.0 : 2.2;
    final railH = widget.compact ? 3.5 : 4.5;

    final nextDuration = Duration(
      milliseconds: (currentMs + 5000).clamp(0, totalMs),
    );
    final prevDuration = Duration(
      milliseconds: (currentMs - 5000).clamp(0, totalMs),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          slider: true,
          enabled: widget.enabled,
          value: '${_format(widget.position)} of ${_format(widget.duration)}',
          increasedValue:
              '${_format(nextDuration)} of ${_format(widget.duration)}',
          decreasedValue:
              '${_format(prevDuration)} of ${_format(widget.duration)}',
          onIncrease: widget.enabled && totalMs > 0
              ? () => widget.onSeek(nextDuration)
              : null,
          onDecrease: widget.enabled && totalMs > 0
              ? () => widget.onSeek(prevDuration)
              : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // Horizontal inset so the pill thumb isn't clipped at 0% / 100%.
              final inset = thumbW / 2;
              final railW = (width - inset * 2).clamp(0.0, width);
              final thumbStart = inset + railW * effectiveProgress - thumbW / 2;

              return MouseRegion(
                cursor: widget.enabled
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                onEnter: (_) {
                  if (widget.enabled) setState(() => _isHovered = true);
                },
                onExit: (_) {
                  if (_isHovered) setState(() => _isHovered = false);
                },
                child: GestureDetector(
                  onTapDown: (d) =>
                      _onDragUpdate(d.localPosition, width, inset),
                  onTapUp: (_) => setState(() => _dragFraction = null),
                  onTapCancel: () => setState(() => _dragFraction = null),
                  onHorizontalDragUpdate: (d) =>
                      _onDragUpdate(d.localPosition, width, inset),
                  onHorizontalDragEnd: (_) =>
                      setState(() => _dragFraction = null),
                  onHorizontalDragCancel: () =>
                      setState(() => _dragFraction = null),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: trackH,
                    width: width,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        PositionedDirectional(
                          start: inset,
                          end: inset,
                          child: Container(
                            height: railH,
                            decoration: BoxDecoration(
                              color: colors.borderLight,
                              borderRadius:
                                  theme.radius.resolve(ConsonaRadiusRole.full),
                            ),
                          ),
                        ),
                        if (totalMs > 0 && widget.buffered > Duration.zero)
                          PositionedDirectional(
                            start: inset,
                            child: Container(
                              height: railH,
                              width: railW *
                                  (widget.buffered.inMilliseconds / totalMs)
                                      .clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                color: colors.primary.withAlpha(
                                  (255 * 0.28).round(),
                                ),
                                borderRadius: theme.radius
                                    .resolve(ConsonaRadiusRole.full),
                              ),
                            ),
                          ),
                        PositionedDirectional(
                          start: inset,
                          child: Container(
                            height: railH,
                            width: railW * effectiveProgress,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius:
                                  theme.radius.resolve(ConsonaRadiusRole.full),
                            ),
                          ),
                        ),
                        // Modern horizontal pill thumb: theme background fill + primary border.
                        PositionedDirectional(
                          start: thumbStart.clamp(
                            0.0,
                            (width - thumbW).clamp(0.0, double.infinity),
                          ),
                          top: (trackH - thumbH) / 2,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: thumbW,
                            height: thumbH,
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius:
                                  theme.radius.resolve(ConsonaRadiusRole.full),
                              border: Border.all(
                                color: colors.primary,
                                width: borderWidth,
                              ),
                              boxShadow: theme.shadow
                                  .resolve(ConsonaShadowLevel.subtle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.showLabels) ...[
          SizedBox(
            height: widget.compact ? ConsonaSpacing.xxs : ConsonaSpacing.xs,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(widget.position),
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                  fontSize: widget.compact ? 11.0 : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _format(widget.duration),
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                  fontSize: widget.compact ? 11.0 : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

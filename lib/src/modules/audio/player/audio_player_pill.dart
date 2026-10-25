/// Consona AudioPlayerPill — Morphing progress stadium player.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../engine/audio_engine.dart';
import '../engine/audio_format.dart';
import '../shared/mini_visualizer.dart';
import '../shared/morph_fill.dart';
import 'audio_builders.dart';

export 'audio_builders.dart';

enum ConsonaAudioPlayerPillSize { sm, md, lg }

/// Stadium player: one solid left capsule + morphing timeline track.
class ConsonaAudioPlayerPill extends StatefulWidget {
  const ConsonaAudioPlayerPill({
    super.key,
    required this.engine,
    this.title,
    this.artwork,
    this.artworkUrl,
    this.showArtwork = true,
    this.showTimestamp = true,
    this.showWaveform = true,
    this.size = ConsonaAudioPlayerPillSize.md,
    this.intent = ConsonaIntent.primary,
    this.onSeek,
    this.onEnded,
    this.artworkBuilder,
    this.titleBuilder,
    this.controlsBuilder,
    this.trailing,
    this.errorBuilder,
    this.posterFallback,
  });

  final AudioEngine engine;
  final String? title;
  final ImageProvider? artwork;
  final String? artworkUrl;
  final bool showArtwork;
  final bool showTimestamp;
  final bool showWaveform;
  final ConsonaAudioPlayerPillSize size;
  final ConsonaIntent intent;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onEnded;
  final ConsonaAudioPillArtworkBuilder? artworkBuilder;
  final ConsonaAudioPillTitleBuilder? titleBuilder;
  final ConsonaAudioPillControlsBuilder? controlsBuilder;
  final Widget? trailing;
  final ConsonaAudioErrorBuilder? errorBuilder;
  final Widget? posterFallback;

  @override
  State<ConsonaAudioPlayerPill> createState() => _ConsonaAudioPlayerPillState();
}

class _ConsonaAudioPlayerPillState extends State<ConsonaAudioPlayerPill> {
  double? _dragProgress;
  AudioPlaybackStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _lastStatus = widget.engine.state.status;
    widget.engine.addListener(_onEngineEnded);
  }

  @override
  void didUpdateWidget(covariant ConsonaAudioPlayerPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      oldWidget.engine.removeListener(_onEngineEnded);
      _lastStatus = widget.engine.state.status;
      widget.engine.addListener(_onEngineEnded);
    }
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngineEnded);
    super.dispose();
  }

  void _onEngineEnded() {
    final status = widget.engine.state.status;
    if (_lastStatus != AudioPlaybackStatus.completed &&
        status == AudioPlaybackStatus.completed) {
      widget.onEnded?.call();
    }
    _lastStatus = status;
  }

  ({double height, double pad, double icon, double overlap, double minW})
      get _geo {
    return switch (widget.size) {
      ConsonaAudioPlayerPillSize.sm => (
          height: 36.0,
          pad: 4.0,
          icon: 14.0,
          overlap: 14.0,
          minW: 220.0,
        ),
      ConsonaAudioPlayerPillSize.md => (
          height: 42.0,
          pad: 5.0,
          icon: 16.0,
          overlap: 18.0,
          minW: 268.0,
        ),
      ConsonaAudioPlayerPillSize.lg => (
          height: 48.0,
          pad: 6.0,
          icon: 18.0,
          overlap: 20.0,
          minW: 300.0,
        ),
    };
  }

  void _seekFromDx(double dx, double width, Duration duration) {
    if (width <= 0 || duration <= Duration.zero) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    setState(() => _dragProgress = ratio);
    final target = Duration(
      milliseconds: (ratio * duration.inMilliseconds).round(),
    );
    widget.engine.seek(target);
    widget.onSeek?.call(target);
  }

  void _endDrag() {
    if (_dragProgress == null) return;
    setState(() => _dragProgress = null);
  }

  ImageProvider? _art(AudioTrack? track) {
    if (widget.artwork != null) return widget.artwork;
    if (track?.artwork != null) return track!.artwork;
    final url = widget.artworkUrl ?? track?.artworkUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final geo = _geo;
    final h = geo.height;
    final intentColors = colors.resolveIntent(widget.intent);
    final fill = intentColors.fill;
    final onFill = intentColors.content;
    final pillRadius = theme.radius.resolve(ConsonaRadiusRole.full);
    final orb = h - geo.pad * 2;

    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;
        final track = state.currentTrack;
        final isPlaying = state.status == AudioPlaybackStatus.playing;
        final progress = _dragProgress ?? state.progress;
        final time = _dragProgress != null && state.duration > Duration.zero
            ? Duration(
                milliseconds:
                    (_dragProgress! * state.duration.inMilliseconds).round(),
              )
            : state.position;
        final title = widget.title ?? track?.title ?? 'Audio track';
        final art = _art(track);
        final showArt = widget.showArtwork;

        Widget trackContent({required Color fg, required Color muted}) {
          return Padding(
            padding: EdgeInsets.only(
              left: geo.overlap + ConsonaSpacing.sm,
              right: ConsonaSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.label.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                          fontSize: widget.size == ConsonaAudioPlayerPillSize.sm
                              ? 12.0
                              : 13.5,
                          height: 1.15,
                        ),
                      ),
                      if (widget.showTimestamp) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${formatAudioTimestamp(time)} / ${formatAudioTimestamp(state.duration)}',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.caption.copyWith(
                            color: muted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontSize: 11.0,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.showWaveform) ...[
                  const SizedBox(width: ConsonaSpacing.sm),
                  ConsonaMiniVisualizer(
                    active: isPlaying,
                    height: h * 0.4,
                    color: fg,
                  ),
                ],
              ],
            ),
          );
        }

        // Single solid capsule — artwork orb + play icon share one fill.
        final capsule = ConsonaSpringPress(
          onTap: () => widget.engine.toggle(),
          feedbackEvent: FeedbackEvent.selection,
          child: Container(
            height: h,
            padding: EdgeInsets.all(geo.pad),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: pillRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showArt) ...[
                  ClipOval(
                    child: SizedBox(
                      width: orb,
                      height: orb,
                      child: art == null
                          ? ColoredBox(
                              color: onFill.withAlpha(28),
                              child: Icon(
                                Icons.music_note_rounded,
                                size: geo.icon,
                                color: onFill,
                              ),
                            )
                          : Image(
                              image: art,
                              fit: BoxFit.cover,
                              width: orb,
                              height: orb,
                              errorBuilder: (_, __, ___) => ColoredBox(
                                color: onFill.withAlpha(28),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: geo.icon,
                                  color: onFill,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: geo.pad),
                ],
                SizedBox(
                  width: orb,
                  height: orb,
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: geo.icon,
                    color: onFill,
                  ),
                ),
              ],
            ),
          ),
        );

        return Semantics(
          container: true,
          label: title,
          child: Container(
            height: h,
            constraints: BoxConstraints(minWidth: geo.minW),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: pillRadius,
              border: theme.border.resolve(ConsonaBorderRole.subtle),
              boxShadow: theme.shadow.resolve(ConsonaShadowLevel.subtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Timeline underlaps the capsule tip.
                Positioned(
                  left: (showArt ? orb * 2 + geo.pad * 3 : orb + geo.pad * 2) -
                      geo.overlap,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => _seekFromDx(
                          d.localPosition.dx,
                          constraints.maxWidth,
                          state.duration,
                        ),
                        onHorizontalDragUpdate: (d) => _seekFromDx(
                          d.localPosition.dx,
                          constraints.maxWidth,
                          state.duration,
                        ),
                        onHorizontalDragEnd: (_) => _endDrag(),
                        onHorizontalDragCancel: _endDrag,
                        onTapUp: (_) => _endDrag(),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            trackContent(
                              fg: colors.foreground,
                              muted: colors.mutedFg,
                            ),
                            ConsonaMorphFill(
                              progress: progress,
                              color: fill,
                              child: trackContent(
                                fg: onFill,
                                muted: onFill.withAlpha(220),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: capsule,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

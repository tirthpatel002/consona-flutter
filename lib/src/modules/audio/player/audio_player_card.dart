/// Consona AudioPlayerCard — Poster + slider timeline workstation.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/button/button.dart';
import '../../core/button/icon_button.dart';
import '../../core/typography/text.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../engine/audio_engine.dart';
import '../engine/audio_format.dart';
import '../scrubber/timeline_scrubber.dart';
import '../shared/artwork.dart';
import '../waveform/waveform.dart';
import 'audio_builders.dart';

export 'audio_builders.dart';

enum ConsonaAudioPlayerTimeline {
  /// Geometric slider scrubber (default).
  slider,

  /// Waveform bar scrubber.
  waveform,
}

/// Full audio player card with optional poster, track info, and timeline.
class ConsonaAudioPlayerCard extends StatefulWidget {
  const ConsonaAudioPlayerCard({
    super.key,
    required this.engine,
    this.title,
    this.artist,
    this.artwork,
    this.artworkUrl,
    this.showPoster = true,
    this.posterHeight = 160.0,
    this.posterFallback,
    this.timeline = ConsonaAudioPlayerTimeline.slider,
    this.showSpeed = true,
    this.showMute = true,
    this.speeds = const [0.75, 1.0, 1.25, 1.5, 2.0],
    this.onPlay,
    this.onEnded,
    this.artworkBuilder,
    this.titleBuilder,
    this.controlsBuilder,
    this.trailing,
    this.timelineBuilder,
    this.errorBuilder,
  });

  final AudioEngine engine;
  final String? title;
  final String? artist;
  final ImageProvider? artwork;
  final String? artworkUrl;
  final bool showPoster;
  final double posterHeight;
  final Widget? posterFallback;
  final ConsonaAudioPlayerTimeline timeline;
  final bool showSpeed;
  final bool showMute;
  final List<double> speeds;
  final VoidCallback? onPlay;
  final VoidCallback? onEnded;
  final ConsonaAudioArtworkBuilder? artworkBuilder;
  final ConsonaAudioTitleBuilder? titleBuilder;
  final ConsonaAudioControlsBuilder? controlsBuilder;
  final Widget? trailing;
  final ConsonaAudioTimelineBuilder? timelineBuilder;
  final ConsonaAudioErrorBuilder? errorBuilder;

  @override
  State<ConsonaAudioPlayerCard> createState() => _ConsonaAudioPlayerCardState();
}

class _ConsonaAudioPlayerCardState extends State<ConsonaAudioPlayerCard> {
  AudioPlaybackStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _lastStatus = widget.engine.state.status;
    widget.engine.addListener(_onEngine);
  }

  @override
  void didUpdateWidget(covariant ConsonaAudioPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      oldWidget.engine.removeListener(_onEngine);
      _lastStatus = widget.engine.state.status;
      widget.engine.addListener(_onEngine);
    }
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngine);
    super.dispose();
  }

  void _onEngine() {
    final status = widget.engine.state.status;
    if (_lastStatus != AudioPlaybackStatus.completed &&
        status == AudioPlaybackStatus.completed) {
      widget.onEnded?.call();
    }
    _lastStatus = status;
    if (mounted) setState(() {});
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
    final pad = theme.density.resolvePadding(
      const EdgeInsets.all(ConsonaSpacing.base),
    );
    final radius = theme.radius.resolve(ConsonaRadiusRole.macro);
    final state = widget.engine.state;
    final track = state.currentTrack;
    final isPlaying = state.status == AudioPlaybackStatus.playing;
    final displayTitle = widget.title ?? track?.title ?? 'No track';
    final displayArtist = widget.artist ?? track?.artist;
    final art = _art(track);

    void onPlayPause() {
      if (isPlaying) {
        widget.engine.pause();
      } else {
        widget.onPlay?.call();
        widget.engine.play();
      }
    }

    final errorMessage = state.errorMessage;
    if (errorMessage != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, state, errorMessage);
    }

    final poster = widget.showPoster
        ? (widget.artworkBuilder != null
            ? widget.artworkBuilder!(context, state, art)
            : SizedBox(
                height: widget.posterHeight,
                width: double.infinity,
                child: art != null
                    ? Image(
                        image: art,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            widget.posterFallback ??
                            _PosterFallback(height: widget.posterHeight),
                      )
                    : (widget.posterFallback ??
                        _PosterFallback(height: widget.posterHeight)),
              ))
        : null;

    final titleBlock = widget.titleBuilder != null
        ? widget.titleBuilder!(context, state, displayTitle, displayArtist)
        : Row(
            children: [
              if (!widget.showPoster) ...[
                ConsonaAudioArtwork(
                  image: art,
                  size: ConsonaGeometries.heightFor(ConsonaOpticalSize.md),
                ),
                const SizedBox(width: ConsonaSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConsonaText.label(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    if (displayArtist != null) ...[
                      const SizedBox(height: ConsonaSpacing.xxs),
                      ConsonaText.caption(
                        displayArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: colors.mutedFg,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          );

    final timeline = widget.timelineBuilder != null
        ? widget.timelineBuilder!(context, state)
        : (widget.timeline == ConsonaAudioPlayerTimeline.waveform
            ? ConsonaWaveform(
                amplitudes: track?.amplitudes ?? const [],
                progress: state.progress,
                onSeek: (fraction) {
                  final ms =
                      (fraction * state.duration.inMilliseconds).round();
                  widget.engine.seek(Duration(milliseconds: ms));
                },
              )
            : ConsonaTimelineScrubber(
                position: state.position,
                duration: state.duration,
                buffered: state.buffered,
                onSeek: widget.engine.seek,
              ));

    final controls = widget.controlsBuilder != null
        ? widget.controlsBuilder!(context, state, onPlayPause)
        : Row(
            children: [
              _PlayButton(
                isPlaying: isPlaying,
                onTap: onPlayPause,
              ),
              const Spacer(),
              if (widget.showSpeed)
                _SpeedChip(
                  rate: state.playbackRate,
                  speeds: widget.speeds,
                  onCycle: () {
                    final speeds = widget.speeds.isEmpty
                        ? const [1.0]
                        : widget.speeds;
                    final i = speeds.indexOf(state.playbackRate);
                    final next = speeds[(i < 0 ? 0 : i + 1) % speeds.length];
                    widget.engine.setPlaybackRate(next);
                  },
                ),
              if (widget.showMute) ...[
                const SizedBox(width: ConsonaSpacing.xs),
                ConsonaIconButton.plain(
                  size: ConsonaOpticalSize.sqSm,
                  shapeVariant: ConsonaShapeVariant.pill,
                  icon: Icon(
                    state.isMuted || state.volume <= 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: colors.mutedFg,
                  ),
                  onTap: () => widget.engine.toggleMute(),
                ),
              ],
            ],
          );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: theme.border.resolve(ConsonaBorderRole.subtle),
        boxShadow: theme.shadow.resolve(ConsonaShadowLevel.soft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (poster != null) poster,
          Padding(
            padding: pad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: ConsonaSpacing.md),
                timeline,
                const SizedBox(height: ConsonaSpacing.md),
                controls,
                if (errorMessage != null) ...[
                  const SizedBox(height: ConsonaSpacing.sm),
                  ConsonaText.caption(
                    errorMessage,
                    color: colors.danger,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surfaceSecondary,
      child: SizedBox(
        height: height,
        child: Center(
          child: Icon(
            Icons.album_rounded,
            size: height * 0.28,
            color: colors.mutedFg,
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final side = ConsonaGeometries.heightFor(ConsonaOpticalSize.md);

    return ConsonaSpringPress(
      onTap: onTap,
      feedbackEvent: FeedbackEvent.selection,
      child: AnimatedContainer(
        duration: theme.motion
            .resolve(ConsonaMotionRole.toggle, context)
            .duration,
        width: side,
        height: side,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
          boxShadow: theme.shadow.resolve(ConsonaShadowLevel.subtle),
        ),
        alignment: Alignment.center,
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.md),
          color: colors.onPrimary,
        ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.rate,
    required this.speeds,
    required this.onCycle,
  });

  final double rate;
  final List<double> speeds;
  final VoidCallback onCycle;

  @override
  Widget build(BuildContext context) {
    final label = rate == 1.0 ? '1x' : '${rate}x';
    return ConsonaButton.outline(
      label: label,
      size: ConsonaOpticalSize.xs,
      shapeVariant: ConsonaShapeVariant.pill,
      onTap: onCycle,
    );
  }
}

/// Convenience re-export of timestamp helper for card consumers.
String audioPlayerFormatTime(Duration d) => formatAudioTimestamp(d);

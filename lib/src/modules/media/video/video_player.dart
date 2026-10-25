/// Consona VideoPlayer — Minimal tactile video surface with overlay controls.
library;

import 'dart:async';

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../audio/scrubber/timeline_scrubber.dart';
import '../../core/slider/slider.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../overlay/drawer/drawer.dart';
import '../image/smart_image.dart';
import 'video_controller.dart';

/// Compact video player with poster, scrubber, volume, and extensible settings.
///
/// Pass [controller] for an owned/shared session, or [uri] to create one
/// internally (network URL or `asset:` path).
class ConsonaVideoPlayer extends StatefulWidget {
  const ConsonaVideoPlayer({
    super.key,
    this.controller,
    this.uri,
    this.posterUri,
    this.title,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.active = true,
    this.aspectRatio,
    this.borderRadiusRole = ConsonaRadiusRole.base,
    this.settingsChildren = const [],
    this.onEnded,
  }) : assert(
          controller != null || (uri != null && uri.length > 0),
          'Provide either a controller or a uri.',
        );

  /// Existing controller. When null, one is created from [uri].
  final ConsonaVideoController? controller;

  /// Network URL or `asset:path/to/file.mp4`.
  final String? uri;

  /// Optional still shown until the first frame is ready / while paused at 0.
  final String? posterUri;

  /// Optional caption under the player chrome.
  final String? title;

  final bool autoPlay;
  final bool looping;
  final bool showControls;

  /// When false (e.g. off-stage lightbox page), playback is paused.
  final bool active;

  /// Override natural aspect ratio (defaults to controller / 16:9).
  final double? aspectRatio;

  final ConsonaRadiusRole borderRadiusRole;

  /// Extra rows / widgets appended inside the settings sheet.
  /// Downstream hosts use this for quality, captions, share, etc.
  final List<Widget> settingsChildren;

  final VoidCallback? onEnded;

  static const List<double> speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  State<ConsonaVideoPlayer> createState() => _ConsonaVideoPlayerState();
}

class _ConsonaVideoPlayerState extends State<ConsonaVideoPlayer> {
  late ConsonaVideoController _controller;
  bool _ownsController = false;
  bool _controlsVisible = true;
  bool _volumeExpanded = true;
  bool _hasEverPlayed = false;
  bool _settingsRouteOpen = false;
  Timer? _hideTimer;
  ConsonaVideoStatus? _lastStatus;

  static const double _centerPlaySize = 48.0;

  @override
  void initState() {
    super.initState();
    _bindController(create: true);
  }

  @override
  void didUpdateWidget(covariant ConsonaVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.uri != widget.uri) {
      _teardown();
      _hasEverPlayed = false;
      _bindController(create: true);
    }
    if (!widget.active && _controller.isPlaying) {
      unawaited(_controller.pause());
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _teardown();
    super.dispose();
  }

  void _teardown() {
    _controller.removeListener(_onController);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _bindController({required bool create}) {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      final raw = widget.uri!.trim();
      _controller = raw.startsWith('asset:')
          ? ConsonaVideoController.asset(raw.substring(6))
          : ConsonaVideoController.network(raw);
      _ownsController = true;
    }
    _lastStatus = _controller.status;
    if (_controller.isPlaying || _controller.position > Duration.zero) {
      _hasEverPlayed = true;
    }
    _controller.addListener(_onController);
    if (!_controller.isInitialized && create) {
      unawaited(
        _controller.initialize(
          autoPlay: widget.autoPlay,
          looping: widget.looping,
        ),
      );
    }
    if (widget.autoPlay) _scheduleHide();
  }

  void _onController() {
    final status = _controller.status;
    if (_controller.isPlaying || _controller.position > Duration.zero) {
      _hasEverPlayed = true;
    }
    if (_lastStatus != ConsonaVideoStatus.completed &&
        status == ConsonaVideoStatus.completed) {
      widget.onEnded?.call();
      setState(() => _controlsVisible = true);
    }
    _lastStatus = status;
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_controller.isPlaying || _settingsRouteOpen) return;
    _hideTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted && _controller.isPlaying && !_settingsRouteOpen) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _revealControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _onStageTap() {
    if (!widget.showControls) {
      unawaited(_togglePlay());
      return;
    }
    if (_controlsVisible) {
      if (_controller.isPlaying) {
        setState(() => _controlsVisible = false);
      } else {
        unawaited(_togglePlay());
      }
    } else {
      _revealControls();
    }
  }

  Future<void> _togglePlay() async {
    final feedback = ConsonaFeedbackScope.maybeOf(context)?.trigger(
      FeedbackEvent.tap,
    );
    if (feedback != null) unawaited(feedback);
    await _controller.togglePlay();
    _hasEverPlayed = true;
    _revealControls();
  }

  Future<void> _toggleMute() async {
    final feedback = ConsonaFeedbackScope.maybeOf(context)?.trigger(
      FeedbackEvent.selection,
    );
    if (feedback != null) unawaited(feedback);
    await _controller.setMuted(!_controller.isMuted);
    setState(() => _volumeExpanded = true);
    _revealControls();
  }

  Future<void> _openSettings() async {
    if (_settingsRouteOpen) return;
    final feedback = ConsonaFeedbackScope.maybeOf(context)?.trigger(
      FeedbackEvent.tap,
    );
    if (feedback != null) unawaited(feedback);
    _hideTimer?.cancel();
    setState(() {
      _controlsVisible = true;
      _settingsRouteOpen = true;
    });

    await ConsonaDrawer.show<void>(
      context,
      snapPoints: const [0.36, 0.55, 0.88],
      initialSnapIndex: 0,
      header: const ConsonaDrawerHeader(title: 'Settings'),
      child: _VideoSettingsBody(
        controller: _controller,
        extraChildren: widget.settingsChildren,
      ),
    );

    if (!mounted) return;
    setState(() => _settingsRouteOpen = false);
    _scheduleHide();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final radius = theme.radius.resolve(widget.borderRadiusRole);
    final ratio = widget.aspectRatio ?? _controller.aspectRatio;
    final showPoster = widget.posterUri != null &&
        (!_controller.isInitialized ||
            (!_controller.isPlaying &&
                _controller.position == Duration.zero));

    final hasTitle = widget.title != null;
    const titleBlock = ConsonaSpacing.sm + 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 640.0;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight - (hasTitle ? titleBlock : 0)
            : maxW / ratio;
        var stageW = maxW;
        var stageH = stageW / ratio;
        if (stageH > maxH && maxH > 0) {
          stageH = maxH;
          stageW = stageH * ratio;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: stageW,
              height: stageH,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: radius,
                  border: theme.border.resolve(
                    ConsonaBorderRole.subtle,
                    context: context,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onStageTap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_controller.isInitialized)
                        FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _controller.aspectRatio * 240,
                            height: 240,
                            child: _controller.buildView(),
                          ),
                        )
                      else
                        const ColoredBox(color: Color(0x00000000)),

                      if (showPoster)
                        ConsonaImage(
                          uri: widget.posterUri,
                          fit: BoxFit.cover,
                          radiusRole: null,
                          borderRole: null,
                          zoomOnHover: false,
                        ),

                      if (_controller.status == ConsonaVideoStatus.loading ||
                          _controller.status == ConsonaVideoStatus.buffering)
                        Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: _PulseRing(color: colors.foreground),
                          ),
                        ),

                      if (_controller.status == ConsonaVideoStatus.error)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(ConsonaSpacing.base),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 28,
                                  color: colors.mutedFg,
                                ),
                                const SizedBox(height: ConsonaSpacing.xs),
                                Text(
                                  _controller.errorMessage ??
                                      'Unable to play video',
                                  textAlign: TextAlign.center,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.typography.caption.copyWith(
                                    color: colors.mutedFg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (widget.showControls)
                        AnimatedOpacity(
                          opacity: _controlsVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: IgnorePointer(
                            ignoring: !_controlsVisible,
                            child: _buildOverlay(theme, colors),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasTitle) ...[
              const SizedBox(height: ConsonaSpacing.sm),
              SizedBox(
                width: stageW,
                child: Text(
                  widget.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.label.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOverlay(ConsonaThemeData theme, ConsonaColors colors) {
    final playing = _controller.isPlaying;
    final ready = _controller.isInitialized &&
        _controller.status != ConsonaVideoStatus.error;
    const onVideo = Color(0xFFFFFFFF);
    final showCenterPlay = !_hasEverPlayed && ready;
    final showBottomChrome = _hasEverPlayed;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showBottomChrome)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x99000000),
                ],
                stops: [0.55, 1.0],
              ),
            ),
          ),

        // Initial play only — bottom chrome stays hidden until first play.
        if (showCenterPlay)
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              child: Container(
                width: _centerPlaySize,
                height: _centerPlaySize,
                decoration: BoxDecoration(
                  color: colors.surface.withAlpha(220),
                  shape: BoxShape.circle,
                  border: theme.border.resolve(
                    ConsonaBorderRole.subtle,
                    context: context,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.play_arrow_outlined,
                  size: 26,
                  color: colors.foreground,
                ),
              ),
            ),
          ),

        if (showBottomChrome)
          Positioned(
            left: ConsonaSpacing.sm,
            right: ConsonaSpacing.sm,
            bottom: ConsonaSpacing.sm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ready)
                  ConsonaTimelineScrubber(
                    position: _controller.position,
                    duration: _controller.duration,
                    buffered: _controller.buffered,
                    compact: true,
                    showLabels: false,
                    onSeek: (d) {
                      unawaited(_controller.seekTo(d));
                      _revealControls();
                    },
                  ),
                const SizedBox(height: 2),
                LayoutBuilder(
                  builder: (context, rowConstraints) {
                    final showSlider = ready &&
                        _volumeExpanded &&
                        rowConstraints.maxWidth >= 280;
                    final sliderW =
                        (rowConstraints.maxWidth * 0.2).clamp(52.0, 80.0);

                    return Row(
                      children: [
                        _ChromeIconButton(
                          icon: playing
                              ? Icons.pause_outlined
                              : Icons.play_arrow_outlined,
                          semanticLabel: playing ? 'Pause' : 'Play',
                          onTap: ready ? _togglePlay : null,
                        ),
                        Text(
                          ready
                              ? '${_format(_controller.position)} / ${_format(_controller.duration)}'
                              : '--:-- / --:--',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.caption.copyWith(
                            color: onVideo,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),
                        _buildVolumeCluster(
                          ready: ready,
                          showSlider: showSlider,
                          sliderWidth: sliderW,
                        ),
                        _ChromeIconButton(
                          icon: Icons.settings_outlined,
                          semanticLabel: 'Settings',
                          onTap: ready ? () => unawaited(_openSettings()) : null,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVolumeCluster({
    required bool ready,
    required bool showSlider,
    required double sliderWidth,
  }) {
    final muted = _controller.isMuted;
    final vol = muted ? 0.0 : _controller.volume;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ChromeIconButton(
          icon: muted || vol <= 0.001
              ? Icons.volume_off_outlined
              : vol < 0.5
                  ? Icons.volume_down_outlined
                  : Icons.volume_up_outlined,
          semanticLabel: muted ? 'Unmute' : 'Mute',
          onTap: ready
              ? () {
                  if (showSlider || _volumeExpanded) {
                    unawaited(_toggleMute());
                  } else {
                    setState(() => _volumeExpanded = true);
                    _revealControls();
                  }
                }
              : null,
          onLongPress: ready
              ? () {
                  setState(() => _volumeExpanded = !_volumeExpanded);
                  _revealControls();
                }
              : null,
        ),
        if (showSlider)
          SizedBox(
            width: sliderWidth,
            child: ConsonaSlider(
              value: vol,
              min: 0,
              max: 1,
              compact: true,
              semanticLabel: 'Volume',
              onChanged: (v) {
                unawaited(_controller.setVolume(v));
                _revealControls();
              },
            ),
          ),
      ],
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}

/// Body for [ConsonaDrawer] video settings — edge-to-edge chrome owned by the drawer.
class _VideoSettingsBody extends StatefulWidget {
  const _VideoSettingsBody({
    required this.controller,
    required this.extraChildren,
  });

  final ConsonaVideoController controller;
  final List<Widget> extraChildren;

  @override
  State<_VideoSettingsBody> createState() => _VideoSettingsBodyState();
}

class _VideoSettingsBodyState extends State<_VideoSettingsBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant _VideoSettingsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTick);
      widget.controller.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  String _chipLabel(double option) {
    if (option == 1.0) return '1×';
    if (option == option.roundToDouble()) return '${option.toInt()}×';
    return '$option×';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    const speeds = ConsonaVideoPlayer.speedOptions;
    final mid = (speeds.length / 2).ceil();
    final speed = widget.controller.playbackSpeed;
    final looping = widget.controller.isLooping;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Speed',
          style: theme.typography.caption.copyWith(
            color: colors.mutedFg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ConsonaSpacing.sm),
        _SpeedRow(
          options: speeds.sublist(0, mid),
          speed: speed,
          labelOf: _chipLabel,
          onSpeed: (v) => unawaited(widget.controller.setPlaybackSpeed(v)),
        ),
        const SizedBox(height: ConsonaSpacing.sm),
        _SpeedRow(
          options: speeds.sublist(mid),
          speed: speed,
          labelOf: _chipLabel,
          onSpeed: (v) => unawaited(widget.controller.setPlaybackSpeed(v)),
        ),
        const SizedBox(height: ConsonaSpacing.sm),
        _SettingsTile(
          label: 'Loop',
          trailing: looping ? 'On' : 'Off',
          selected: looping,
          onTap: () => unawaited(widget.controller.setLooping(!looping)),
        ),
        if (widget.extraChildren.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ConsonaSpacing.sm),
            child: Container(
              height: 1,
              color: colors.border.withAlpha(100),
            ),
          ),
          ...widget.extraChildren,
        ],
      ],
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({
    required this.options,
    required this.speed,
    required this.labelOf,
    required this.onSpeed,
  });

  final List<double> options;
  final double speed;
  final String Function(double) labelOf;
  final ValueChanged<double> onSpeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _SpeedChip(
              label: labelOf(options[i]),
              selected: (speed - options[i]).abs() < 0.01,
              onTap: () => onSpeed(options[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withAlpha(36)
              : colors.surfaceSecondary,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
          border: Border.all(
            color: selected ? colors.primary : colors.border.withAlpha(120),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.typography.caption.copyWith(
            color: selected ? colors.primary : colors.foreground,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    required this.onTap,
    this.trailing,
    this.selected = false,
  });

  final String label;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.typography.label.copyWith(
                  color: colors.foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.color});
  final Color color;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          painter: _RingPainter(
            color: widget.color.withAlpha(40 + (140 * _c.value).round()),
            progress: 0.7,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(2), -1.2, progress * 6.0, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      color != oldDelegate.color || progress != oldDelegate.progress;
}

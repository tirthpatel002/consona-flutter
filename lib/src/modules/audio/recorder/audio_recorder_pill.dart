/// Consona AudioRecorderPill — Morphing stadium recorder with resume.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../../overlay/context_menu/context_menu.dart';
import '../engine/audio_engine.dart';
import '../engine/audio_format.dart';
import '../engine/recorder_engine.dart';
import '../shared/mini_visualizer.dart';
import '../shared/morph_fill.dart';
import '../waveform/waveform.dart';
import 'recording_preview.dart';

enum ConsonaAudioRecorderPillSize { sm, md, lg }

/// Compact stadium recorder: idle → recording → review (morph + resume).
class ConsonaAudioRecorderPill extends StatefulWidget {
  const ConsonaAudioRecorderPill({
    super.key,
    required this.engine,
    this.label = 'Voice Note',
    this.size = ConsonaAudioRecorderPillSize.md,
    this.intent = ConsonaIntent.primary,
    this.showWaveform = true,
    this.preview,
    this.previewBackend,
    this.onRecordingComplete,
    this.onDiscard,
  });

  final AudioRecorderEngine engine;
  final String label;
  final ConsonaAudioRecorderPillSize size;
  final ConsonaIntent intent;
  final bool showWaveform;
  final ConsonaRecordingPreview? preview;
  final AudioBackend? previewBackend;
  final ValueChanged<AudioRecordingResult>? onRecordingComplete;
  final VoidCallback? onDiscard;

  @override
  State<ConsonaAudioRecorderPill> createState() =>
      _ConsonaAudioRecorderPillState();
}

class _ConsonaAudioRecorderPillState extends State<ConsonaAudioRecorderPill> {
  ConsonaRecordingPreview? _ownedPreview;
  late ConsonaRecordingPreview _preview;
  double? _dragProgress;
  final GlobalKey _menuKey = GlobalKey();

  ({double height, double btn, double icon, double minW}) get _geo {
    return switch (widget.size) {
      ConsonaAudioRecorderPillSize.sm => (
          height: 36.0,
          btn: 36.0,
          icon: 16.0,
          minW: 220.0,
        ),
      ConsonaAudioRecorderPillSize.md => (
          height: 44.0,
          btn: 44.0,
          icon: 18.0,
          minW: 270.0,
        ),
      ConsonaAudioRecorderPillSize.lg => (
          height: 52.0,
          btn: 52.0,
          icon: 22.0,
          minW: 320.0,
        ),
    };
  }

  @override
  void initState() {
    super.initState();
    _bindPreview();
    widget.engine.addListener(_onEngine);
  }

  @override
  void didUpdateWidget(covariant ConsonaAudioRecorderPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      oldWidget.engine.removeListener(_onEngine);
      widget.engine.addListener(_onEngine);
    }
    if (oldWidget.preview != widget.preview ||
        oldWidget.previewBackend != widget.previewBackend) {
      _preview.removeListener(_onPreview);
      _ownedPreview?.dispose();
      _ownedPreview = null;
      _bindPreview();
    }
  }

  void _bindPreview() {
    if (widget.preview != null) {
      _preview = widget.preview!;
    } else {
      _ownedPreview = ConsonaRecordingPreview(backend: widget.previewBackend);
      _preview = _ownedPreview!;
    }
    _preview.addListener(_onPreview);
  }

  void _onEngine() {
    if (mounted) setState(() {});
  }

  void _onPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngine);
    _preview.removeListener(_onPreview);
    _ownedPreview?.dispose();
    super.dispose();
  }

  Future<void> _primaryAction() async {
    final state = widget.engine.state;
    if (state.isRecording) {
      final result = await widget.engine.stop();
      widget.onRecordingComplete?.call(result);
      return;
    }
    final review = state.lastRecording;
    if (review != null) {
      if (_preview.playing) {
        await _preview.pause();
      } else {
        await _preview.play(review);
      }
      return;
    }
    await widget.engine.start();
  }

  Future<void> _discard() async {
    await _preview.stop();
    widget.engine.clear();
    widget.onDiscard?.call();
    setState(() => _dragProgress = null);
  }

  Future<void> _resumeRecording() async {
    await _preview.stop();
    await widget.engine.resumeRecording();
  }

  Future<void> _restart() async {
    await _preview.stop();
    await widget.engine.start();
  }

  void _seekReview(double dx, double width, Duration duration) {
    if (width <= 0 || duration <= Duration.zero) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    setState(() => _dragProgress = ratio);
    _preview.seek(
      Duration(milliseconds: (ratio * duration.inMilliseconds).round()),
    );
  }

  Future<void> _openReviewMenu() async {
    final box = _menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset(0, box.size.height));
    final review = widget.engine.state.lastRecording;
    await ConsonaContextMenu.show<void>(
      context,
      position: origin,
      items: [
        ConsonaContextMenuItem(
          id: 'resume',
          label: review == null
              ? 'Resume recording'
              : 'Resume (${formatAudioTimestamp(review.duration)})',
          icon: Icons.mic_rounded,
          onTap: _resumeRecording,
        ),
        ConsonaContextMenuItem(
          id: 'rerecord',
          label: 'Re-record',
          icon: Icons.refresh_rounded,
          onTap: _restart,
        ),
        ConsonaContextMenuItem(
          id: 'discard',
          label: 'Discard recording',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onTap: _discard,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final geo = _geo;
    final intentColors = colors.resolveIntent(widget.intent);
    final danger = colors.resolveIntent(ConsonaIntent.danger);
    final pillRadius = theme.radius.resolve(ConsonaRadiusRole.full);

    // State is read directly — the engine and preview listeners above
    // call setState(), so this build is always up to date.
    final state = widget.engine.state;
    final review = state.lastRecording;
    final recording = state.isRecording;
    final inReview = review != null && !recording && !state.isPaused;

    final shellFill = recording ? danger.fill : colors.surface;
    final shellFg = recording ? danger.content : colors.foreground;
    final btnFill = recording
        ? danger.fill
        : (inReview ? intentColors.fill : intentColors.fill);
    final btnFg = recording ? danger.content : intentColors.content;

    final previewTime = _dragProgress != null &&
            review != null &&
            review.duration > Duration.zero
        ? Duration(
            milliseconds:
                (_dragProgress! * review.duration.inMilliseconds).round(),
          )
        : _preview.position;
    final progress = inReview
        ? (_dragProgress ??
            (review.duration > Duration.zero
                ? (previewTime.inMilliseconds / review.duration.inMilliseconds)
                    .clamp(0.0, 1.0)
                : 0.0))
        : 0.0;

    Widget reviewContent({required Color fg, required Color muted}) {
      return Padding(
        padding: const EdgeInsets.only(
          left: ConsonaSpacing.lg,
          right: ConsonaSpacing.md,
          top: ConsonaSpacing.xs,
          bottom: ConsonaSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.label.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatAudioTimestamp(previewTime)} / ${formatAudioTimestamp(review!.duration)}',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.caption.copyWith(
                      color: muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showWaveform)
              ConsonaMiniVisualizer(
                active: _preview.playing,
                height: geo.height * 0.4,
                color: fg,
              ),
          ],
        ),
      );
    }

    // Outer ClipRRect makes both ends true stadium tips.
    return Semantics(
      container: true,
      label: widget.label,
      child: Container(
        key: _menuKey,
        height: geo.height,
        constraints: BoxConstraints(minWidth: geo.minW),
        decoration: BoxDecoration(
          borderRadius: pillRadius,
          border: theme.border.resolve(ConsonaBorderRole.subtle),
          boxShadow: theme.shadow.resolve(
            recording ? ConsonaShadowLevel.soft : ConsonaShadowLevel.subtle,
          ),
        ),
        child: ClipRRect(
          borderRadius: pillRadius,
          child: ColoredBox(
            color: shellFill,
            child: Row(
              children: [
                ConsonaSpringPress(
                  onTap: _primaryAction,
                  feedbackEvent: FeedbackEvent.selection,
                  child: ColoredBox(
                    color: btnFill,
                    child: SizedBox(
                      width: geo.btn,
                      height: geo.height,
                      child: Icon(
                        recording
                            ? Icons.stop_rounded
                            : inReview
                                ? (_preview.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded)
                                : Icons.mic_rounded,
                        size: geo.icon,
                        color: btnFg,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: recording
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ConsonaSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: shellFg,
                                  borderRadius: pillRadius,
                                ),
                              ),
                              const SizedBox(width: ConsonaSpacing.sm),
                              Text(
                                formatAudioTimestamp(state.duration),
                                style: theme.typography.label.copyWith(
                                  color: shellFg,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (widget.showWaveform)
                                SizedBox(
                                  width: 96,
                                  height: geo.height * 0.45,
                                  child: ConsonaWaveform(
                                    amplitudes: state.levels,
                                    progress: 1.0,
                                    interactive: false,
                                    height: geo.height * 0.45,
                                    barWidth: 2.0,
                                    barSpacing: 1.5,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : inReview
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (d) => _seekReview(
                                    d.localPosition.dx,
                                    constraints.maxWidth,
                                    review.duration,
                                  ),
                                  onHorizontalDragUpdate: (d) => _seekReview(
                                    d.localPosition.dx,
                                    constraints.maxWidth,
                                    review.duration,
                                  ),
                                  onHorizontalDragEnd: (_) => setState(
                                    () => _dragProgress = null,
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ColoredBox(
                                        color: colors.surface,
                                        child: reviewContent(
                                          fg: colors.foreground,
                                          muted: colors.mutedFg,
                                        ),
                                      ),
                                      ConsonaMorphFill(
                                        progress: progress,
                                        color: intentColors.fill,
                                        height: geo.height,
                                        child: reviewContent(
                                          fg: intentColors.content,
                                          muted: intentColors.content
                                              .withAlpha(220),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ConsonaSpacing.md,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.typography.label.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Tap to record',
                                    style: theme.typography.caption.copyWith(
                                      color: colors.mutedFg,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
                ConsonaSpringPress(
                  onTap: recording
                      ? _discard
                      : inReview
                          ? _openReviewMenu
                          : null,
                  feedbackEvent: FeedbackEvent.selection,
                  child: ColoredBox(
                    color: btnFill,
                    child: SizedBox(
                      width: geo.btn,
                      height: geo.height,
                      child: Icon(
                        recording
                            ? Icons.close_rounded
                            : inReview
                                ? Icons.more_horiz_rounded
                                : Icons.keyboard_arrow_down_rounded,
                        size: geo.icon,
                        color: btnFg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

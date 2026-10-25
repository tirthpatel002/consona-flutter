/// Consona AudioRecorderCard — Capture workstation with resume / review.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/button/button.dart';
import '../../core/button/icon_button.dart';
import '../../core/typography/text.dart';
import '../engine/audio_engine.dart';
import '../engine/audio_format.dart';
import '../engine/recorder_engine.dart';
import '../scrubber/timeline_scrubber.dart';
import '../waveform/waveform.dart';
import 'recording_preview.dart';

/// Full recorder card: live levels, stop/pause, review, resume, restart.
class ConsonaAudioRecorderCard extends StatefulWidget {
  const ConsonaAudioRecorderCard({
    super.key,
    required this.engine,
    this.title = 'Voice Recorder',
    this.preview,
    this.previewBackend,
    this.onRecordingComplete,
    this.onDiscard,
  });

  final AudioRecorderEngine engine;
  final String title;

  /// Shared preview player (preferred when card + pill share one surface).
  final ConsonaRecordingPreview? preview;

  /// Used when [preview] is null — pass a real backend for speaker output.
  final AudioBackend? previewBackend;

  final ValueChanged<AudioRecordingResult>? onRecordingComplete;
  final VoidCallback? onDiscard;

  @override
  State<ConsonaAudioRecorderCard> createState() =>
      _ConsonaAudioRecorderCardState();
}

class _ConsonaAudioRecorderCardState extends State<ConsonaAudioRecorderCard> {
  ConsonaRecordingPreview? _ownedPreview;
  late ConsonaRecordingPreview _preview;

  @override
  void initState() {
    super.initState();
    _bindPreview();
    widget.engine.addListener(_onEngine);
  }

  @override
  void didUpdateWidget(covariant ConsonaAudioRecorderCard oldWidget) {
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

  Future<void> _start() async {
    try {
      await _preview.stop();
      await widget.engine.start();
    } catch (e) {
      // Engine stores errorMessage; keep chrome in sync.
      if (mounted) setState(() {});
    }
  }

  Future<void> _stop() async {
    try {
      final result = await widget.engine.stop();
      widget.onRecordingComplete?.call(result);
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _preview.stop();
      await widget.engine.resumeRecording();
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _clear() async {
    await _preview.stop();
    widget.engine.clear();
    widget.onDiscard?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final pad = theme.density.resolvePadding(
      const EdgeInsets.all(ConsonaSpacing.base),
    );
    final radius = theme.radius.resolve(ConsonaRadiusRole.macro);

    // State is read directly — the engine and preview listeners above
    // call setState(), so this build is always up to date.
    final state = widget.engine.state;
    final recording = state.isRecording || state.isPaused;
    final review = state.lastRecording;
    final inReview = review != null && !recording;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: theme.border.resolve(ConsonaBorderRole.subtle),
        boxShadow: theme.shadow.resolve(ConsonaShadowLevel.soft),
      ),
      padding: pad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title + status / review actions (discard & restart as icons).
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: ConsonaText.label(
                        widget.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (state.isRecording) ...[
                      const SizedBox(width: ConsonaSpacing.sm),
                      _StatusChip(label: 'REC', color: colors.danger),
                    ] else if (state.isPaused) ...[
                      const SizedBox(width: ConsonaSpacing.sm),
                      _StatusChip(label: 'PAUSED', color: colors.warning),
                    ],
                  ],
                ),
              ),
              if (inReview) ...[
                ConsonaIconButton.plain(
                  size: ConsonaOpticalSize.sqSm,
                  shapeVariant: ConsonaShapeVariant.pill,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: colors.mutedFg,
                  ),
                  onTap: _start,
                ),
                ConsonaIconButton.plain(
                  size: ConsonaOpticalSize.sqSm,
                  shapeVariant: ConsonaShapeVariant.pill,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.danger,
                  ),
                  onTap: _clear,
                ),
              ],
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: ConsonaSpacing.sm),
            ConsonaText.caption(
              state.errorMessage!,
              color: colors.danger,
              maxLines: 3,
            ),
          ],
          const SizedBox(height: ConsonaSpacing.md),
          Container(
            height: inReview ? 52.0 : 56.0,
            padding: EdgeInsets.symmetric(
              horizontal: ConsonaSpacing.sm,
              vertical: inReview ? ConsonaSpacing.xs : ConsonaSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
              border: theme.border.resolve(ConsonaBorderRole.subtle),
            ),
            alignment: Alignment.center,
            child: inReview
                ? ConsonaTimelineScrubber(
                    compact: true,
                    position: _preview.position,
                    duration: review.duration,
                    onSeek: _preview.seek,
                  )
                : recording
                    ? Row(
                        children: [
                          Expanded(
                            child: ConsonaWaveform(
                              amplitudes: state.levels.isEmpty
                                  ? const [0.2, 0.35, 0.25, 0.4, 0.3]
                                  : state.levels,
                              progress: 1.0,
                              interactive: false,
                              height: 36.0,
                            ),
                          ),
                          const SizedBox(width: ConsonaSpacing.sm),
                          Text(
                            formatAudioTimestamp(state.duration),
                            style: theme.typography.caption.copyWith(
                              color: colors.mutedFg,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      )
                    : const ConsonaWaveform(
                        amplitudes: [0.2, 0.35, 0.25, 0.4, 0.3],
                        progress: 0.0,
                        interactive: false,
                        height: 36.0,
                      ),
          ),
          const SizedBox(height: ConsonaSpacing.md),
          if (inReview)
            Row(
              children: [
                Expanded(
                  child: ConsonaButton.primary(
                    label: _preview.playing ? 'Pause' : 'Play',
                    size: ConsonaOpticalSize.sm,
                    shapeVariant: ConsonaShapeVariant.pill,
                    fullWidth: true,
                    leading: Icon(
                      _preview.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: ConsonaGeometries.iconSizeFor(
                        ConsonaOpticalSize.sm,
                      ),
                      color: colors.onPrimary,
                    ),
                    onTap: () {
                      if (_preview.playing) {
                        _preview.pause();
                      } else {
                        _preview.play(review);
                      }
                    },
                  ),
                ),
                const SizedBox(width: ConsonaSpacing.sm),
                Expanded(
                  child: ConsonaButton.subtle(
                    label: 'Resume',
                    size: ConsonaOpticalSize.sm,
                    shapeVariant: ConsonaShapeVariant.pill,
                    fullWidth: true,
                    leading: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.danger,
                        borderRadius:
                            theme.radius.resolve(ConsonaRadiusRole.full),
                      ),
                    ),
                    onTap: _resumeRecording,
                  ),
                ),
              ],
            )
          else if (recording)
            Row(
              children: [
                Expanded(
                  child: ConsonaButton.primary(
                    label: 'Stop',
                    size: ConsonaOpticalSize.sm,
                    shapeVariant: ConsonaShapeVariant.pill,
                    fullWidth: true,
                    leading: Icon(
                      Icons.stop_rounded,
                      size: ConsonaGeometries.iconSizeFor(
                        ConsonaOpticalSize.sm,
                      ),
                      color: colors.onPrimary,
                    ),
                    onTap: _stop,
                  ),
                ),
                const SizedBox(width: ConsonaSpacing.sm),
                Expanded(
                  child: ConsonaButton.subtle(
                    label: state.isPaused ? 'Resume' : 'Pause',
                    size: ConsonaOpticalSize.sm,
                    shapeVariant: ConsonaShapeVariant.pill,
                    fullWidth: true,
                    onTap: state.isPaused
                        ? widget.engine.resume
                        : widget.engine.pause,
                  ),
                ),
              ],
            )
          else
            ConsonaButton.primary(
              label: 'Start Recording',
              size: ConsonaOpticalSize.sm,
              shapeVariant: ConsonaShapeVariant.pill,
              fullWidth: true,
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.onPrimary,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                ),
              ),
              onTap: _start,
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ConsonaSpacing.sm,
        vertical: ConsonaSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
            ),
          ),
          const SizedBox(width: ConsonaSpacing.xs),
          Text(
            label,
            style: theme.typography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

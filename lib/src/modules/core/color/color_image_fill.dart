/// Consona Color — Image fill editor (URL source, scale modes, adjustments).
///
/// Port of the interface `color-image-fill.tsx`. `image_picker` is not a
/// dependency, so the source is supplied via URL (network or data URI); the
/// preview supports drag-to-reposition, crop zoom, 90° rotation, and the full
/// set of non-destructive adjustment sliders mapped to a [ColorFilter] matrix.
library;

import 'package:flutter/gestures.dart'
    show PointerScaleEvent, PointerScrollEvent;
import 'package:flutter/material.dart'
    show Icon, Icons, Material, MaterialType, showDialog;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../button/button.dart';
import '../slider/slider.dart';
import 'color_format_inputs.dart';
import 'color_utils.dart';

const List<({String label, ConsonaImageScaleMode value})> _kScaleModes = [
  (label: 'Fill', value: ConsonaImageScaleMode.fill),
  (label: 'Fit', value: ConsonaImageScaleMode.fit),
  (label: 'Crop', value: ConsonaImageScaleMode.crop),
  (label: 'Tile', value: ConsonaImageScaleMode.tile),
];

/// Image fill editor with preview, scale modes and adjustment sliders.
class ColorImageFill extends StatefulWidget {
  const ColorImageFill({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final ConsonaImageFillConfig config;
  final ValueChanged<ConsonaImageFillConfig> onChanged;

  @override
  State<ColorImageFill> createState() => _ColorImageFillState();
}

class _ColorImageFillState extends State<ColorImageFill> {
  /// True while one-finger pan or pinch/scale is active.
  bool _interacting = false;
  Offset _startFocal = Offset.zero;
  double _startPosX = 50;
  double _startPosY = 50;
  double _startZoom = 100;

  /// Local draft so the in-editor preview updates even when the parent
  /// shell skips setState (chip / live fill still get [onChanged]).
  late ConsonaImageFillConfig _local = widget.config;

  ConsonaImageFillConfig get _config => _local;

  @override
  void didUpdateWidget(covariant ColorImageFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interacting && !identical(widget.config, oldWidget.config)) {
      _local = widget.config;
    }
  }

  void _update(ConsonaImageFillConfig c) {
    setState(() => _local = c);
    widget.onChanged(c);
  }

  void _rotate() {
    final next = ((_config.rotation + 90) % 360);
    _update(_config.copyWith(rotation: next));
  }

  void _showUrlDialog() async {
    final controller = TextEditingController(text: _config.url);
    final result = await _UrlPromptSheet.show(context, controller);
    if (result != null) {
      _update(_config.copyWith(
        url: result,
        positionX: 50,
        positionY: 50,
        zoom: 130,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPreview(theme),
        const SizedBox(height: ConsonaSpacing.sm),
        _buildHeaderRow(theme),
        const SizedBox(height: ConsonaSpacing.sm),
        ..._buildSliders(),
      ],
    );
  }

  Widget _buildPreview(ConsonaThemeData theme) {
    final colors = theme.colors;
    final hasImage = _config.url.isNotEmpty;
    final filter = imageFillColorFilter(_config);
    final opacity = (_config.opacity / 100).clamp(0.0, 1.0);

    // Compact preview — tall 4:5 forced the whole sheet to scroll.
    return SizedBox(
      height: 148,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = constraints.biggest;
        return ClipRRect(
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
          child: Listener(
            onPointerSignal: (signal) {
              if (!hasImage) return;
              // Trackpad pinch (desktop) + scroll-wheel zoom.
              if (signal is PointerScaleEvent) {
                _setZoom(_config.zoom * signal.scale);
                return;
              }
              if (signal is PointerScrollEvent) {
                _nudgeZoom(signal.scrollDelta.dy < 0 ? 12.0 : -12.0);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Pan + pinch target — chrome overlays sit outside so +/- /
                // Change do not start a gesture.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    if (!hasImage) return;
                    setState(() {
                      _interacting = true;
                      _startFocal = details.focalPoint;
                      _startPosX = _config.positionX;
                      _startPosY = _config.positionY;
                      _startZoom = _config.zoom;
                    });
                  },
                  onScaleUpdate: (details) {
                    if (!_interacting || size.isEmpty) return;
                    final dx = (details.focalPoint.dx - _startFocal.dx) /
                        size.width *
                        100;
                    final dy = (details.focalPoint.dy - _startFocal.dy) /
                        size.height *
                        100;
                    // 1-finger: pan. 2-finger pinch: scale * pan focal.
                    _update(_config.copyWith(
                      positionX: clampColorValue(_startPosX + dx, 0, 100)
                          .roundToDouble(),
                      positionY: clampColorValue(_startPosY + dy, 0, 100)
                          .roundToDouble(),
                      zoom: clampColorValue(_startZoom * details.scale, 50, 400)
                          .roundToDouble(),
                    ));
                  },
                  onScaleEnd: (_) => setState(() => _interacting = false),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const CustomPaint(
                        painter: ColorCheckerboardPainter(cell: 12),
                      ),
                      if (hasImage)
                        ConsonaImageFillLayer(
                          config: _config,
                          colorFilter: filter,
                          opacity: opacity,
                        )
                      else
                        Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _showUrlDialog,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_outlined,
                                    size: 32, color: colors.mutedFg),
                                const SizedBox(height: 6),
                                Text('Add image URL',
                                    style: theme.typography.label.copyWith(
                                      color: colors.foreground,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.none,
                                    )),
                                const SizedBox(height: 2),
                                Text('Network or data URI',
                                    style: theme.typography.labelSmall
                                        .copyWith(color: colors.mutedFg)),
                              ],
                            ),
                          ),
                        ),
                      if (_config.mode == ConsonaImageScaleMode.crop)
                        const Positioned.fill(
                          child: IgnorePointer(child: _RuleOfThirds()),
                        ),
                    ],
                  ),
                ),
                if (_interacting)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IgnorePointer(
                      child: _Badge(
                        text:
                            'X: ${_config.positionX.round()}%  Y: ${_config.positionY.round()}%'
                            '  Zoom: ${_config.zoom.round()}%',
                      ),
                    ),
                  ),
                if (hasImage)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _ZoomControls(
                      zoom: _config.zoom,
                      onZoomOut: () => _nudgeZoom(-20),
                      onZoomIn: () => _nudgeZoom(20),
                    ),
                  ),
                if (hasImage && !_interacting)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _showUrlDialog,
                      child: const _Badge(
                        text: 'Change',
                        leading: Icon(Icons.upload_rounded,
                            size: 14, color: Color(0xFFFFFFFF)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _nudgeZoom(double delta) => _setZoom(_config.zoom + delta);

  void _setZoom(double zoom) {
    _update(_config.copyWith(
      zoom: clampColorValue(zoom, 50, 400).roundToDouble(),
    ));
  }

  Widget _buildHeaderRow(ConsonaThemeData theme) {
    final colors = theme.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ColorDropdown<ConsonaImageScaleMode>(
          value: _config.mode,
          menuWidth: 120,
          items: _kScaleModes
              .map((m) => (value: m.value, label: m.label))
              .toList(),
          onChanged: (m) => _update(_config.copyWith(mode: m)),
          trigger: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _kScaleModes.firstWhere((m) => m.value == _config.mode).label,
                style: theme.typography.label.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: colors.mutedFg),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _rotate,
          child: Icon(Icons.rotate_right_rounded,
              size: 18, color: colors.mutedFg),
        ),
      ],
    );
  }

  List<Widget> _buildSliders() {
    return [
      _AdjustmentSlider(
        label: 'Zoom',
        value: _config.zoom,
        min: 50,
        max: 400,
        defaultValue: 100,
        onChanged: (v) => _update(_config.copyWith(zoom: v)),
      ),
      _AdjustmentSlider(
        label: 'Opacity',
        value: _config.opacity,
        min: 0,
        max: 100,
        defaultValue: 100,
        onChanged: (v) => _update(_config.copyWith(opacity: v)),
      ),
      _AdjustmentSlider(
        label: 'Exposure',
        value: _config.exposure,
        onChanged: (v) => _update(_config.copyWith(exposure: v)),
      ),
      _AdjustmentSlider(
        label: 'Contrast',
        value: _config.contrast,
        onChanged: (v) => _update(_config.copyWith(contrast: v)),
      ),
      _AdjustmentSlider(
        label: 'Saturation',
        value: _config.saturation,
        onChanged: (v) => _update(_config.copyWith(saturation: v)),
      ),
      _AdjustmentSlider(
        label: 'Temperature',
        value: _config.temperature,
        onChanged: (v) => _update(_config.copyWith(temperature: v)),
      ),
      _AdjustmentSlider(
        label: 'Tint',
        value: _config.tint,
        onChanged: (v) => _update(_config.copyWith(tint: v)),
      ),
      _AdjustmentSlider(
        label: 'Highlights',
        value: _config.highlights,
        onChanged: (v) => _update(_config.copyWith(highlights: v)),
      ),
      _AdjustmentSlider(
        label: 'Shadows',
        value: _config.shadows,
        onChanged: (v) => _update(_config.copyWith(shadows: v)),
      ),
    ];
  }
}

class _RuleOfThirds extends StatelessWidget {
  const _RuleOfThirds();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25,
      child: CustomPaint(painter: _ThirdsPainter()),
    );
  }
}

class _ThirdsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ThirdsPainter oldDelegate) => false;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.leading});
  final String text;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xBF000000),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontFamily: 'Menlo',
              fontFamilyFallback: ['Consolas', 'monospace'],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xBF000000),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomBtn(
            icon: Icons.remove_rounded,
            onTap: zoom <= 50 ? null : onZoomOut,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${zoom.round()}%',
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Menlo',
                fontFamilyFallback: ['Consolas', 'monospace'],
              ),
            ),
          ),
          _ZoomBtn(
            icon: Icons.add_rounded,
            onTap: zoom >= 400 ? null : onZoomIn,
          ),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 14,
          color: Color(enabled ? 0xFFFFFFFF : 0x66FFFFFF),
        ),
      ),
    );
  }
}

/// A label + Consona slider adjustment row with double-tap reset.
class _AdjustmentSlider extends StatelessWidget {
  const _AdjustmentSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = -100,
    this.max = 100,
    this.defaultValue = 0,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double defaultValue;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.label.copyWith(
                  color: colors.foreground, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onDoubleTap: () => onChanged(defaultValue),
              child: ConsonaSlider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                compact: true,
                semanticLabel: label,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple modal prompt collecting an image URL.
class _UrlPromptSheet {
  static Future<String?> show(
      BuildContext context, TextEditingController controller) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final focus = FocusNode();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(ConsonaSpacing.base),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
                  border: theme.border
                      .resolve(ConsonaBorderRole.defaultBorder, context: ctx),
                  boxShadow: theme.shadow.resolve(ConsonaShadowLevel.strong),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Image URL',
                        style: theme.typography.label.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: ConsonaSpacing.sm),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius:
                            theme.radius.resolve(ConsonaRadiusRole.base),
                        border: theme.border.resolve(
                            ConsonaBorderRole.inputOutline,
                            context: ctx),
                      ),
                      child: EditableText(
                        controller: controller,
                        focusNode: focus,
                        autofocus: true,
                        maxLines: 1,
                        autocorrect: false,
                        enableSuggestions: false,
                        spellCheckConfiguration:
                            const SpellCheckConfiguration.disabled(),
                        style: theme.typography.label.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.none,
                        ),
                        cursorColor: colors.primary,
                        backgroundCursorColor: colors.mutedFg,
                        onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
                      ),
                    ),
                    const SizedBox(height: ConsonaSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ConsonaButton.subtle(
                          label: 'Cancel',
                          size: ConsonaOpticalSize.xs,
                          onTap: () => Navigator.of(ctx).pop(),
                        ),
                        const SizedBox(width: ConsonaSpacing.sm),
                        ConsonaButton.primary(
                          label: 'Apply',
                          size: ConsonaOpticalSize.xs,
                          onTap: () =>
                              Navigator.of(ctx).pop(controller.text.trim()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

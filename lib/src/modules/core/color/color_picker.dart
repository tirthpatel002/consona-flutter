/// Consona ColorPicker — Solid / Gradient / Image fill picker.
///
/// Flutter port of the Consona interface color picker family. The trigger shows
/// the current solid color; tapping opens an editor (drawer on narrow layouts,
/// popover on wide) with underline fill-type tabs (Solid | Gradient | Image),
/// a segmented Editor | Presets switch in solid mode, the gradient editor, and
/// the image fill editor.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../navigation/segmented_control.dart';
import '../../overlay/drawer/drawer.dart';
import '../../overlay/popover/popover.dart';
import 'color_format_inputs.dart';
import 'color_gradient_editor.dart';
import 'color_image_fill.dart';
import 'color_presets.dart';
import 'color_utils.dart';

export 'color_presets_data.dart';
export 'color_utils.dart'
    show
        ConsonaColorFormat,
        ConsonaFillType,
        ConsonaGradientType,
        ConsonaGradientStop,
        ConsonaGradientConfig,
        ConsonaImageScaleMode,
        ConsonaImageFillConfig,
        RgbaColor,
        kDefaultImageFillConfig,
        kGradientPresets,
        gradientToCss,
        parseCssGradient,
        imageFillColorMatrix,
        ConsonaImageFillLayer,
        rgbToHex;

const List<Color> _kDefaultPresets = [
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFFDC2626),
  Color(0xFFEA580C),
  Color(0xFFCA8A04),
  Color(0xFF16A34A),
  Color(0xFF0D9488),
  Color(0xFF0891B2),
  Color(0xFF4B5563),
  Color(0xFF111827),
  Color(0xFFFFFFFF),
];

/// Color selection control. The swatch trigger opens a Solid / Gradient / Image
/// editor. [value]/[onChanged] drive the solid color; gradient & image fills are
/// emitted through [onGradientChange] / [onImageFillChange].
class ConsonaColorPicker extends StatefulWidget {
  const ConsonaColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.presets = _kDefaultPresets,
    this.enabled = true,
    this.fillTypes,
    this.defaultFillType,
    this.onFillTypeChange,
    this.defaultGradient,
    this.onGradientChange,
    this.defaultImageFill,
    this.onImageFillChange,
    this.customSwatches,
    this.onCustomSwatchesChange,
    this.onAddCustomSwatch,
    this.onRemoveCustomSwatch,
  });

  final Color value;
  final ValueChanged<Color> onChanged;
  final String? label;

  /// Legacy flat preset list (kept for API compatibility).
  final List<Color> presets;
  final bool enabled;

  /// Allowed fill modes. Defaults to all three (solid, gradient, image).
  final List<ConsonaFillType>? fillTypes;
  final ConsonaFillType? defaultFillType;
  final ValueChanged<ConsonaFillType>? onFillTypeChange;

  final ConsonaGradientConfig? defaultGradient;
  final ValueChanged<ConsonaGradientConfig>? onGradientChange;

  final ConsonaImageFillConfig? defaultImageFill;
  final ValueChanged<ConsonaImageFillConfig>? onImageFillChange;

  /// Seed list of encoded custom swatches (JSON `{name, hex}`, hex, or CSS).
  final List<String>? customSwatches;
  final ValueChanged<List<String>>? onCustomSwatchesChange;
  final ValueChanged<String>? onAddCustomSwatch;
  final ValueChanged<String>? onRemoveCustomSwatch;

  @override
  State<ConsonaColorPicker> createState() => _ConsonaColorPickerState();
}

class _ConsonaColorPickerState extends State<ConsonaColorPicker> {
  final GlobalKey _triggerKey = GlobalKey();
  late List<String> _customSwatches = [...?widget.customSwatches];

  List<ConsonaFillType> get _fillTypes =>
      widget.fillTypes ??
      const [
        ConsonaFillType.solid,
        ConsonaFillType.gradient,
        ConsonaFillType.image,
      ];

  void _handleSwatchesChanged(List<String> next) {
    _customSwatches = next;
    widget.onCustomSwatchesChange?.call(next);
  }

  Future<void> _open() async {
    if (!widget.enabled) return;
    final width = MediaQuery.sizeOf(context).width;
    final useDrawer = width < 520;
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? anchor;
    if (box != null && box.hasSize) {
      anchor = box.localToGlobal(Offset.zero) & box.size;
    }

    final shell = _ColorPickerShell(
      initialColor: widget.value,
      availableFillTypes: _fillTypes,
      initialFillType: widget.defaultFillType ?? _fillTypes.first,
      initialGradient: widget.defaultGradient,
      initialImage: widget.defaultImageFill ?? kDefaultImageFillConfig,
      initialSwatches: _customSwatches,
      onColorChanged: widget.onChanged,
      onFillTypeChanged: widget.onFillTypeChange,
      onGradientChanged: widget.onGradientChange,
      onImageChanged: widget.onImageFillChange,
      onSwatchesChanged: _handleSwatchesChanged,
      onAddSwatch: widget.onAddCustomSwatch,
      onRemoveSwatch: widget.onRemoveCustomSwatch,
    );

    await ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap);
    if (!mounted) return;

    if (useDrawer) {
      await ConsonaDrawer.show<void>(
        context,
        snapPoints: const [0.52, 0.72, 0.92],
        initialSnapIndex: 0,
        scrollable: true,
        // User-dragged height sticks — no snap-back retract.
        retainHeight: true,
        header: _PickerHeader(title: widget.label ?? 'Color'),
        child: shell,
      );
      return;
    }

    final maxH = MediaQuery.sizeOf(context).height * 0.78;
    await ConsonaPopover.show<void>(
      context,
      anchorRect: anchor,
      width: 320,
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(child: shell),
      ),
    );
  }

  ConsonaFillType get _activeFill =>
      widget.defaultFillType ?? _fillTypes.first;

  String get _triggerLabel {
    switch (_activeFill) {
      case ConsonaFillType.solid:
        return _toHex(widget.value);
      case ConsonaFillType.gradient:
        final g = widget.defaultGradient;
        if (g == null) return 'Gradient';
        final type = switch (g.type) {
          ConsonaGradientType.linear => 'Linear',
          ConsonaGradientType.radial => 'Radial',
          ConsonaGradientType.angular => 'Angular',
          ConsonaGradientType.diamond => 'Diamond',
        };
        return '$type · ${g.angle.round()}°';
      case ConsonaFillType.image:
        final img = widget.defaultImageFill;
        if (img == null || img.url.isEmpty) return 'Image';
        return img.fileName ?? 'Image';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final radius = theme.radius.resolve(ConsonaRadiusRole.base);
    final micro = theme.radius.resolve(ConsonaRadiusRole.micro);
    final swatchSide = 22 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: EdgeInsets.only(
              left: ConsonaSpacing.xxs * scale,
              bottom: ConsonaSpacing.sm * scale,
            ),
            child: Text(
              widget.label!,
              style: theme.typography.labelSmall.copyWith(
                color: colors.mutedFg,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
        GestureDetector(
          key: _triggerKey,
          behavior: HitTestBehavior.opaque,
          onTap: _open,
          child: Opacity(
            opacity: widget.enabled ? 1 : ConsonaOpacities.disabled,
            child: Container(
              height: 34 * scale,
              padding: EdgeInsets.symmetric(horizontal: ConsonaSpacing.sm * scale),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: radius,
                border: theme.border.resolve(
                  ConsonaBorderRole.inputOutline,
                  context: context,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: micro,
                    child: SizedBox(
                      width: swatchSide,
                      height: swatchSide,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: theme.border.resolve(
                            ConsonaBorderRole.subtle,
                            context: context,
                          ),
                          borderRadius: micro,
                        ),
                        child: _TriggerSwatch(
                          fillType: _activeFill,
                          solid: widget.value,
                          gradient: widget.defaultGradient,
                          image: widget.defaultImageFill,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ConsonaSpacing.sm * scale),
                  Text(
                    _triggerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w400,
                      fontSize: 13 * scale,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontFamily: 'Menlo',
                      fontFamilyFallback: const ['Consolas', 'monospace'],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mini swatch that mirrors the active fill (solid / gradient / image).
class _TriggerSwatch extends StatelessWidget {
  const _TriggerSwatch({
    required this.fillType,
    required this.solid,
    required this.gradient,
    required this.image,
  });

  final ConsonaFillType fillType;
  final Color solid;
  final ConsonaGradientConfig? gradient;
  final ConsonaImageFillConfig? image;

  @override
  Widget build(BuildContext context) {
    switch (fillType) {
      case ConsonaFillType.solid:
        return ColoredBox(color: solid);
      case ConsonaFillType.gradient:
        final g = gradient;
        if (g == null) return ColoredBox(color: solid);
        return DecoratedBox(
          decoration: BoxDecoration(gradient: g.toFlutterGradient()),
        );
      case ConsonaFillType.image:
        final url = image?.url ?? '';
        if (url.isEmpty) {
          return ColoredBox(
            color: ConsonaTheme.of(context).colors.surfaceSecondary,
          );
        }
        final cfg = image ?? kDefaultImageFillConfig;
        return ConsonaImageFillLayer(
          config: cfg,
          opacity: (cfg.opacity / 100).clamp(0.0, 1.0),
        );
    }
  }
}

/* ==========================================================================
   Editor shell
   ========================================================================== */

class _ColorPickerShell extends StatefulWidget {
  const _ColorPickerShell({
    required this.initialColor,
    required this.availableFillTypes,
    required this.initialFillType,
    required this.initialGradient,
    required this.initialImage,
    required this.initialSwatches,
    required this.onColorChanged,
    required this.onFillTypeChanged,
    required this.onGradientChanged,
    required this.onImageChanged,
    required this.onSwatchesChanged,
    required this.onAddSwatch,
    required this.onRemoveSwatch,
  });

  final Color initialColor;
  final List<ConsonaFillType> availableFillTypes;
  final ConsonaFillType initialFillType;
  final ConsonaGradientConfig? initialGradient;
  final ConsonaImageFillConfig initialImage;
  final List<String> initialSwatches;

  final ValueChanged<Color> onColorChanged;
  final ValueChanged<ConsonaFillType>? onFillTypeChanged;
  final ValueChanged<ConsonaGradientConfig>? onGradientChanged;
  final ValueChanged<ConsonaImageFillConfig>? onImageChanged;
  final ValueChanged<List<String>> onSwatchesChanged;
  final ValueChanged<String>? onAddSwatch;
  final ValueChanged<String>? onRemoveSwatch;

  @override
  State<_ColorPickerShell> createState() => _ColorPickerShellState();
}

class _ColorPickerShellState extends State<_ColorPickerShell> {
  late ConsonaFillType _fillType = widget.initialFillType;
  late RgbaColor _solid = RgbaColor.fromColor(widget.initialColor);
  late ConsonaGradientConfig _gradient = widget.initialGradient ??
      const ConsonaGradientConfig(
        type: ConsonaGradientType.radial,
        angle: 135,
        stops: [
          ConsonaGradientStop(id: '1', color: '#7F56D9', position: 0),
          ConsonaGradientStop(id: '2', color: '#432E73', position: 100),
        ],
      );
  late ConsonaImageFillConfig _image = widget.initialImage;
  late List<String> _swatches = [...widget.initialSwatches];
  int _solidTab = 0; // 0 editor, 1 presets

  void _setFillType(ConsonaFillType t) {
    setState(() => _fillType = t);
    widget.onFillTypeChanged?.call(t);
  }

  void _addSwatch(String payload) {
    final clean = payload.trim();
    if (clean.isEmpty || _swatches.contains(clean)) return;
    setState(() => _swatches = [..._swatches, clean]);
    widget.onAddSwatch?.call(clean);
    widget.onSwatchesChanged(_swatches);
  }

  void _removeSwatch(String payload) {
    setState(() => _swatches = _swatches.where((s) => s != payload).toList());
    widget.onRemoveSwatch?.call(payload);
    widget.onSwatchesChanged(_swatches);
  }

  void _applySolid(RgbaColor rgba) {
    // Solid editor paints locally during drag and only invokes this on
    // change-end / text commit — sync shell + parent once per gesture.
    _solid = rgba;
    widget.onColorChanged(rgba.toColor());
  }

  void _applyGradient(ConsonaGradientConfig config) {
    // Gradient editor holds a drag draft; this runs on commit / non-drag edits.
    _gradient = config;
    widget.onGradientChanged?.call(config);
  }

  void _applyImage(ConsonaImageFillConfig config) {
    _image = config;
    widget.onImageChanged?.call(config);
  }

  @override
  Widget build(BuildContext context) {
    // No close control — drawer/popover already dismiss via handle / outside tap.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.availableFillTypes.length > 1) ...[
          ColorUnderlineTabs<ConsonaFillType>(
            value: _fillType,
            onChanged: _setFillType,
            items: widget.availableFillTypes
                .map((t) => (value: t, label: _fillTypeLabel(t)))
                .toList(),
          ),
          const SizedBox(height: ConsonaSpacing.md),
        ],
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    switch (_fillType) {
      case ConsonaFillType.gradient:
        return ColorGradientEditor(
          config: _gradient,
          customSwatches: _swatches,
          onAddSwatch: _addSwatch,
          onRemoveSwatch: _removeSwatch,
          onChanged: _applyGradient,
        );
      case ConsonaFillType.image:
        return ColorImageFill(
          config: _image,
          onChanged: _applyImage,
        );
      case ConsonaFillType.solid:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConsonaSegmentedControl<int>(
              fullWidth: true,
              selected: _solidTab,
              segments: const [
                ConsonaSegment(value: 0, label: 'Editor'),
                ConsonaSegment(value: 1, label: 'Presets'),
              ],
              onChanged: (v) => setState(() => _solidTab = v),
            ),
            const SizedBox(height: ConsonaSpacing.md),
            if (_solidTab == 0)
              ColorSolidEditor(
                value: _solid,
                onChanged: _applySolid,
              )
            else
              ColorPresetsContainer(
                activeColor: _solid,
                customSwatches: _swatches,
                currentGradient: _gradient,
                onAddSwatch: _addSwatch,
                onRemoveSwatch: _removeSwatch,
                onSelect: (value) {
                  final parsed = parseCustomSwatchItem(value);
                  if (parsed.isGradient) {
                    final grad = parseCssGradient(parsed.value);
                    if (grad != null) {
                      _applyGradient(grad);
                      _setFillType(ConsonaFillType.gradient);
                    }
                  } else {
                    _applySolid(hexToRgba(parsed.value));
                  }
                },
              ),
          ],
        );
    }
  }

  static String _fillTypeLabel(ConsonaFillType t) => switch (t) {
        ConsonaFillType.solid => 'Solid',
        ConsonaFillType.gradient => 'Gradient',
        ConsonaFillType.image => 'Image',
      };
}

/// Slim drawer header — title only (sheet dismisses via handle / drag).
class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final scale = theme.density.factor;
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.titleMedium.copyWith(
        color: theme.colors.foreground,
        fontWeight: FontWeight.w500,
        fontSize: 16 * scale,
        height: 1.2,
        letterSpacing: -0.2,
      ),
    );
  }
}

/* ==========================================================================
   Hex helpers
   ========================================================================== */

String _toHex(Color color) {
  final value = color.toARGB32();
  final r = ((value >> 16) & 0xff).toRadixString(16).padLeft(2, '0');
  final g = ((value >> 8) & 0xff).toRadixString(16).padLeft(2, '0');
  final b = (value & 0xff).toRadixString(16).padLeft(2, '0');
  return '#${(r + g + b).toUpperCase()}';
}

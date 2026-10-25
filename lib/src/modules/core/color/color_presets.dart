/// Consona Color — Preset palette browser + custom preset creation form.
///
/// Port of the interface `color-presets.tsx`: tabbed Soft / Dark / Custom
/// palettes rendered as a 2-column named-swatch grid, plus an inline
/// create-preset form supporting solid colors and gradients.
library;

import 'package:flutter/material.dart' show Icon, Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../button/button.dart';
import 'color_format_inputs.dart';
import 'color_gradient_editor.dart';
import 'color_presets_data.dart';
import 'color_utils.dart';

/* ==========================================================================
   Presets container
   ========================================================================== */

/// Tabbed preset browser (Soft / Dark / Custom) with a 2-column named grid.
class ColorPresetsContainer extends StatefulWidget {
  const ColorPresetsContainer({
    super.key,
    required this.activeColor,
    required this.onSelect,
    required this.customSwatches,
    this.onAddSwatch,
    this.onRemoveSwatch,
    this.currentGradient,
    this.initialPresetType,
    this.softColors = kSoftColorPresets,
    this.darkColors = kDarkColorPresets,
  });

  final RgbaColor activeColor;

  /// Fired with a hex or CSS gradient string when a swatch is chosen.
  final ValueChanged<String> onSelect;
  final List<String> customSwatches;
  final ValueChanged<String>? onAddSwatch;
  final ValueChanged<String>? onRemoveSwatch;
  final ConsonaGradientConfig? currentGradient;
  final ConsonaFillType? initialPresetType;
  final List<ConsonaColorPresetItem> softColors;
  final List<ConsonaColorPresetItem> darkColors;

  @override
  State<ColorPresetsContainer> createState() => _ColorPresetsContainerState();
}

enum _PresetTab { soft, dark, custom }

class _ColorPresetsContainerState extends State<ColorPresetsContainer> {
  _PresetTab _tab = _PresetTab.soft;
  bool _isAdding = false;

  String get _activeHex =>
      rgbToHex(widget.activeColor.r, widget.activeColor.g, widget.activeColor.b)
          .toLowerCase();

  void _startAdd() => setState(() => _isAdding = true);

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);

    if (_isAdding) {
      return ColorCreatePresetForm(
        initialType: widget.initialPresetType ??
            (widget.currentGradient != null
                ? ConsonaFillType.gradient
                : ConsonaFillType.solid),
        currentColor: widget.activeColor,
        currentGradient: widget.currentGradient,
        onBack: () => setState(() => _isAdding = false),
        onSave: (payload) {
          widget.onAddSwatch?.call(payload);
          final parsed = parseCustomSwatchItem(payload);
          widget.onSelect(parsed.value);
          setState(() {
            _isAdding = false;
            _tab = _PresetTab.custom;
          });
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ColorUnderlineTabs<_PresetTab>(
                value: _tab,
                onChanged: (t) => setState(() => _tab = t),
                items: [
                  (value: _PresetTab.soft, label: 'Soft (${widget.softColors.length})'),
                  (value: _PresetTab.dark, label: 'Dark (${widget.darkColors.length})'),
                  (
                    value: _PresetTab.custom,
                    label: 'Custom (${widget.customSwatches.length})'
                  ),
                ],
              ),
            ),
            const SizedBox(width: ConsonaSpacing.sm),
            _AddButton(onTap: _startAdd),
          ],
        ),
        const SizedBox(height: ConsonaSpacing.md),
        SizedBox(
          height: 232,
          child: switch (_tab) {
            _PresetTab.soft => _NamedGrid(
                items: widget.softColors,
                activeHex: _activeHex,
                onSelect: widget.onSelect,
                theme: theme,
              ),
            _PresetTab.dark => _NamedGrid(
                items: widget.darkColors,
                activeHex: _activeHex,
                onSelect: widget.onSelect,
                theme: theme,
              ),
            _PresetTab.custom => _CustomGrid(
                swatches: widget.customSwatches,
                activeHex: _activeHex,
                onSelect: widget.onSelect,
                onRemove: widget.onRemoveSwatch,
                onStartAdd: _startAdd,
                theme: theme,
              ),
          },
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
          border:
              theme.border.resolve(ConsonaBorderRole.inputOutline, context: context),
        ),
        child: Icon(Icons.add_rounded, size: 14, color: colors.foreground),
      ),
    );
  }
}

class _NamedGrid extends StatelessWidget {
  const _NamedGrid({
    required this.items,
    required this.activeHex,
    required this.onSelect,
    required this.theme,
  });

  final List<ConsonaColorPresetItem> items;
  final String activeHex;
  final ValueChanged<String> onSelect;
  final ConsonaThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(right: 2, top: 2, bottom: 2),
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        mainAxisExtent: 40,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final selected = activeHex == item.hex.toLowerCase();
        return _SwatchCard(
          name: item.name,
          subtitle: item.hex.toUpperCase(),
          swatchColor: hexToRgba(item.hex).toColor(),
          selected: selected,
          onTap: () => onSelect(item.hex),
          theme: theme,
        );
      },
    );
  }
}

class _CustomGrid extends StatelessWidget {
  const _CustomGrid({
    required this.swatches,
    required this.activeHex,
    required this.onSelect,
    required this.onRemove,
    required this.onStartAdd,
    required this.theme,
  });

  final List<String> swatches;
  final String activeHex;
  final ValueChanged<String> onSelect;
  final ValueChanged<String>? onRemove;
  final VoidCallback onStartAdd;
  final ConsonaThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    if (swatches.isEmpty) {
      return DottedBorderBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No custom colors saved yet.',
                style: theme.typography.label
                    .copyWith(color: colors.mutedFg, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('Pick and name your favorite colors & gradients',
                textAlign: TextAlign.center,
                style: theme.typography.labelSmall.copyWith(color: colors.mutedFg)),
            const SizedBox(height: ConsonaSpacing.md),
            ConsonaButton.subtle(
              label: 'Create Custom Preset',
              size: ConsonaOpticalSize.xs,
              leading: const Icon(Icons.add_rounded, size: 14),
              onTap: onStartAdd,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(right: 2, top: 2, bottom: 2),
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        mainAxisExtent: 40,
      ),
      itemCount: swatches.length,
      itemBuilder: (context, i) {
        final parsed = parseCustomSwatchItem(swatches[i], i);
        final selected =
            activeHex.isNotEmpty && parsed.value.toLowerCase() == activeHex;
        final gradient = parsed.isGradient
            ? parseCssGradient(parsed.value)?.toFlutterGradient()
            : null;
        return _SwatchCard(
          name: parsed.name,
          subtitle: parsed.isGradient ? 'CSS' : parsed.value.toUpperCase(),
          swatchColor: parsed.isGradient ? null : hexToRgba(parsed.value).toColor(),
          swatchGradient: gradient,
          selected: selected,
          onTap: () => onSelect(parsed.value),
          onRemove: onRemove == null ? null : () => onRemove!(swatches[i]),
          theme: theme,
        );
      },
    );
  }
}

class _SwatchCard extends StatelessWidget {
  const _SwatchCard({
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.theme,
    this.swatchColor,
    this.swatchGradient,
    this.onRemove,
  });

  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final ConsonaThemeData theme;
  final Color? swatchColor;
  final Gradient? swatchGradient;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.1)
              : const Color(0x00000000),
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
          border: Border.all(
            color: selected ? colors.primary : colors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: swatchColor,
                gradient: swatchGradient,
                borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
                border: theme.border
                    .resolve(ConsonaBorderRole.subtle, context: context),
              ),
            ),
            const SizedBox(width: ConsonaSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.label.copyWith(
                        color: colors.foreground, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Menlo',
                      fontFamilyFallback: const ['Consolas', 'monospace'],
                      fontSize: 10,
                      height: 1.1,
                      color: colors.mutedFg,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 14, color: colors.mutedFg),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dashed-border empty-state container.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return CustomPaint(
      painter: _DashedRectPainter(
        color: theme.colors.border,
        radius: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(ConsonaSpacing.base),
        child: Center(child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final dashed = Path();
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + dash;
        dashed.addPath(
            metric.extractPath(dist, next.clamp(0, metric.length)), Offset.zero);
        dist = next + gap;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color || old.radius != radius;
}

/* ==========================================================================
   Create preset form
   ========================================================================== */

/// Inline form to create a named solid-color or gradient preset.
class ColorCreatePresetForm extends StatefulWidget {
  const ColorCreatePresetForm({
    super.key,
    this.initialType = ConsonaFillType.solid,
    required this.currentColor,
    this.currentGradient,
    required this.onSave,
    required this.onBack,
    this.title = 'New Preset',
  });

  final ConsonaFillType initialType;
  final RgbaColor currentColor;
  final ConsonaGradientConfig? currentGradient;

  /// Fired with the encoded swatch payload (JSON `{name, hex}`).
  final ValueChanged<String> onSave;
  final VoidCallback onBack;
  final String title;

  @override
  State<ColorCreatePresetForm> createState() => _ColorCreatePresetFormState();
}

class _ColorCreatePresetFormState extends State<ColorCreatePresetForm> {
  late ConsonaFillType _type;
  late RgbaColor _solid;
  late ConsonaGradientConfig _gradient;
  final TextEditingController _name = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == ConsonaFillType.gradient
        ? ConsonaFillType.gradient
        : ConsonaFillType.solid;
    _solid = widget.currentColor;
    _gradient = widget.currentGradient ?? kGradientPresets.first.config;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _save() {
    if (_type == ConsonaFillType.solid) {
      final hex =
          rgbToHex(_solid.r, _solid.g, _solid.b, _solid.a).toUpperCase();
      final name = _name.text.trim().isEmpty ? 'Custom Color' : _name.text.trim();
      widget.onSave(encodeCustomSwatch(name, hex));
    } else {
      final css = gradientToCss(_gradient);
      final name =
          _name.text.trim().isEmpty ? 'Custom Gradient' : _name.text.trim();
      widget.onSave(encodeCustomSwatch(name, css));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: back + title + Save
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onBack,
              child: Icon(Icons.arrow_back_rounded,
                  size: 16, color: colors.mutedFg),
            ),
            const SizedBox(width: ConsonaSpacing.sm),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.label.copyWith(
                    color: colors.foreground, fontWeight: FontWeight.w500),
              ),
            ),
            ConsonaButton.primary(
              label: 'Save',
              size: ConsonaOpticalSize.xs,
              onTap: _save,
            ),
          ],
        ),
        const SizedBox(height: ConsonaSpacing.md),
        // Solid|Gradient underline tabs
        ColorUnderlineTabs<ConsonaFillType>(
          value: _type,
          onChanged: (t) => setState(() => _type = t),
          items: const [
            (value: ConsonaFillType.solid, label: 'Solid Color'),
            (value: ConsonaFillType.gradient, label: 'Gradient'),
          ],
        ),
        const SizedBox(height: ConsonaSpacing.md),
        // Name input
        _NameInput(
          controller: _name,
          focusNode: _nameFocus,
          hint: _type == ConsonaFillType.gradient
              ? 'Preset Name (e.g. Sunset Glow)'
              : 'Preset Name (e.g. Brand Purple)',
        ),
        const SizedBox(height: ConsonaSpacing.md),
        if (_type == ConsonaFillType.solid)
          ColorSolidEditor(
            value: _solid,
            areaHeight: 112,
            onChanged: (c) => setState(() => _solid = c),
          )
        else
          ColorGradientEditor(
            config: _gradient,
            showPresetsRow: false,
            onChanged: (c) => setState(() => _gradient = c),
          ),
      ],
    );
  }
}

class _NameInput extends StatelessWidget {
  const _NameInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
        border:
            theme.border.resolve(ConsonaBorderRole.inputOutline, context: context),
      ),
      alignment: Alignment.centerLeft,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? Text(hint,
                    style: theme.typography.label.copyWith(color: colors.mutedFg))
                : const SizedBox.shrink(),
          ),
          EditableText(
            controller: controller,
            focusNode: focusNode,
            maxLines: 1,
            autocorrect: false,
            enableSuggestions: false,
            spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
            style: theme.typography.label.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
            cursorColor: colors.primary,
            backgroundCursorColor: colors.mutedFg,
          ),
        ],
      ),
    );
  }
}

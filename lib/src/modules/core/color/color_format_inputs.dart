/// Consona Color — Solid editor surfaces (SV area, hue/alpha sliders) and the
/// dynamic format inputs row (HEX / RGB / CSS / HSL / HSB).
library;

import 'dart:async';

import 'package:flutter/material.dart' show Icon, Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import 'color_utils.dart';

/// Shared optical sizes for SV / hue / alpha thumbs and channel tracks.
const double _kColorThumb = 30.0;
const double _kChannelTrackH = 24.0;
const double _kChannelHitH = 40.0;

/* ==========================================================================
   Checkerboard painter (alpha backdrop)
   ========================================================================== */

/// Paints a light/dark checkerboard used behind translucent color surfaces.
class ColorCheckerboardPainter extends CustomPainter {
  const ColorCheckerboardPainter({this.cell = 6});

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRect(Offset.zero & size, light);
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        final even = (((x / cell).floor() + (y / cell).floor()) % 2) == 0;
        if (even) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, cell, cell),
            dark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(ColorCheckerboardPainter oldDelegate) =>
      oldDelegate.cell != cell;
}

/* ==========================================================================
   Underline tab bar (Solid|Gradient|Image, Soft|Dark|Custom, Solid|Gradient)
   ========================================================================== */

/// A row of text tabs with an active underline, matching the interface shell.
class ColorUnderlineTabs<T> extends StatelessWidget {
  const ColorUnderlineTabs({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.gap = 16,
  });

  final T value;
  final List<({T value, String label})> items;
  final ValueChanged<T> onChanged;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _UnderlineTab(
              label: items[i].label,
              active: items[i].value == value,
              onTap: () => onChanged(items[i].value),
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  const _UnderlineTab({
    required this.label,
    required this.active,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final ConsonaThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final primary = colors.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.typography.label.copyWith(
                color: active ? primary : colors.mutedFg,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: active ? primary : const Color(0x00000000),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================================================================
   Reusable token-styled dropdown
   ========================================================================== */

/// Lightweight overlay dropdown that matches Consona tokens (no Material chrome).
class ColorDropdown<T> extends StatefulWidget {
  const ColorDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.trigger,
    this.menuWidth = 128,
  });

  final T value;
  final List<({T value, String label})> items;
  final ValueChanged<T> onChanged;
  final Widget trigger;
  final double menuWidth;

  @override
  State<ColorDropdown<T>> createState() => _ColorDropdownState<T>();
}

class _ColorDropdownState<T> extends State<ColorDropdown<T>> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _removeMenu() {
    _entry?.remove();
    _entry = null;
  }

  void _toggle() {
    if (_entry != null) {
      _removeMenu();
      return;
    }
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeMenu,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: widget.menuWidth,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius:
                        theme.radius.resolve(ConsonaRadiusRole.base),
                    border: theme.border
                        .resolve(ConsonaBorderRole.defaultBorder, context: ctx),
                    boxShadow: theme.shadow.resolve(ConsonaShadowLevel.strong),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in widget.items)
                        _MenuRow(
                          label: item.label,
                          selected: item.value == widget.value,
                          onTap: () {
                            _removeMenu();
                            if (item.value != widget.value) {
                              widget.onChanged(item.value);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: widget.trigger,
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          color: widget.selected
              ? colors.primary.withValues(alpha: 0.1)
              : _hover
                  ? colors.surfaceSecondary
                  : const Color(0x00000000),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.typography.label.copyWith(
                    color: widget.selected ? colors.primary : colors.foreground,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_rounded, size: 14, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/* ==========================================================================
   Monospace channel input
   ========================================================================== */

class _ChannelInput extends StatefulWidget {
  const _ChannelInput({
    required this.value,
    required this.onCommit,
    this.width,
    this.prefix,
    this.textAlign = TextAlign.center,
    this.leftRadius = false,
    this.rightRadius = false,
    this.readOnly = false,
    this.allowHex = false,
  });

  final String value;
  final ValueChanged<String> onCommit;
  final double? width;
  final String? prefix;
  final TextAlign textAlign;
  final bool leftRadius;
  final bool rightRadius;
  final bool readOnly;
  final bool allowHex;

  @override
  State<_ChannelInput> createState() => _ChannelInputState();
}

class _ChannelInputState extends State<_ChannelInput> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focus = FocusNode();
    _focus.addListener(() {
      setState(() => _focused = _focus.hasFocus);
      if (!_focus.hasFocus) {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ChannelInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onCommit(_controller.text);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final radius = theme.radius.resolve(ConsonaRadiusRole.base);
    final br = BorderRadius.horizontal(
      left: widget.leftRadius ? radius.topLeft : Radius.zero,
      right: widget.rightRadius ? radius.topRight : Radius.zero,
    );

    final mono = TextStyle(
      fontFamily: 'Menlo',
      fontFamilyFallback: const ['Consolas', 'monospace'],
      fontSize: 11.5,
      height: 1.1,
      fontWeight: FontWeight.w400,
      color: colors.foreground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget field = EditableText(
      controller: _controller,
      focusNode: _focus,
      readOnly: widget.readOnly,
      style: mono,
      textAlign: widget.textAlign,
      cursorColor: colors.primary,
      backgroundCursorColor: colors.mutedFg,
      maxLines: 1,
      keyboardType: TextInputType.text,
      autocorrect: false,
      enableSuggestions: false,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      inputFormatters: widget.allowHex
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(8),
            ]
          : null,
      onSubmitted: (_) => _commit(),
    );

    final child = Row(
      children: [
        if (widget.prefix != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 2),
            child: Text(widget.prefix!,
                style: mono.copyWith(color: colors.mutedFg)),
          ),
        Expanded(child: field),
      ],
    );

    final box = Container(
      height: 28,
      padding: EdgeInsets.symmetric(
        horizontal: widget.prefix == null ? 4 : 0,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: br,
        border: Border.all(
          color: _focused ? colors.primary : colors.border,
          width: 1,
        ),
      ),
      child: Center(child: child),
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: box);
    }
    return Expanded(child: box);
  }
}

/* ==========================================================================
   Format inputs row
   ========================================================================== */

/// Dynamic channel inputs with a leading format dropdown. Full width, h~28.
class ColorFormatInputs extends StatefulWidget {
  const ColorFormatInputs({
    super.key,
    required this.color,
    required this.onChanged,
    required this.format,
    required this.onFormatChanged,
  });

  final RgbaColor color;
  final ValueChanged<RgbaColor> onChanged;
  final ConsonaColorFormat format;
  final ValueChanged<ConsonaColorFormat> onFormatChanged;

  @override
  State<ColorFormatInputs> createState() => _ColorFormatInputsState();
}

class _ColorFormatInputsState extends State<ColorFormatInputs> {
  bool _copied = false;

  int? _toInt(String raw) => int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final rgba = widget.color;

    final dropdown = ColorDropdown<ConsonaColorFormat>(
      value: widget.format,
      menuWidth: 96,
      items: const [
        (value: ConsonaColorFormat.hex, label: 'HEX'),
        (value: ConsonaColorFormat.rgb, label: 'RGB'),
        (value: ConsonaColorFormat.css, label: 'CSS'),
        (value: ConsonaColorFormat.hsl, label: 'HSL'),
        (value: ConsonaColorFormat.hsb, label: 'HSB'),
      ],
      onChanged: widget.onFormatChanged,
      trigger: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
          border:
              theme.border.resolve(ConsonaBorderRole.inputOutline, context: context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatLabel(widget.format),
              style: theme.typography.labelSmall.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.unfold_more_rounded, size: 14, color: colors.mutedFg),
          ],
        ),
      ),
    );

    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dropdown,
          const SizedBox(width: 6),
          Expanded(child: _buildChannels(rgba)),
        ],
      ),
    );
  }

  Widget _buildChannels(RgbaColor rgba) {
    switch (widget.format) {
      case ConsonaColorFormat.hex:
        return Row(
          children: [
            _ChannelInput(
              value: rgbToHex(rgba.r, rgba.g, rgba.b)
                  .replaceFirst('#', '')
                  .toUpperCase(),
              prefix: '#',
              textAlign: TextAlign.left,
              leftRadius: true,
              allowHex: true,
              onCommit: (v) {
                final val = v.trim();
                if (val.length == 3 || val.length == 6 || val.length == 8) {
                  final parsed = hexToRgba('#$val');
                  widget.onChanged(parsed.copyWith(
                      a: val.length == 8 ? parsed.a : rgba.a));
                }
              },
            ),
            _ChannelInput(
              width: 48,
              rightRadius: true,
              value: '${(rgba.a * 100).round()}%',
              onCommit: (v) {
                final n = _toInt(v);
                if (n != null) {
                  widget.onChanged(
                      rgba.copyWith(a: clampColorValue(n, 0, 100) / 100));
                }
              },
            ),
          ],
        );
      case ConsonaColorFormat.rgb:
        return Row(
          children: [
            _channel('${rgba.r}', leftRadius: true,
                onCommit: (n) => widget.onChanged(
                    rgba.copyWith(r: clampColorValue(n, 0, 255).round()))),
            _channel('${rgba.g}',
                onCommit: (n) => widget.onChanged(
                    rgba.copyWith(g: clampColorValue(n, 0, 255).round()))),
            _channel('${rgba.b}',
                onCommit: (n) => widget.onChanged(
                    rgba.copyWith(b: clampColorValue(n, 0, 255).round()))),
            _channel('${(rgba.a * 100).round()}%',
                width: 44, rightRadius: true,
                onCommit: (n) => widget.onChanged(
                    rgba.copyWith(a: clampColorValue(n, 0, 100) / 100))),
          ],
        );
      case ConsonaColorFormat.hsl:
        final hsl = rgbaToHsla(rgba.r, rgba.g, rgba.b, rgba.a);
        return Row(
          children: [
            _channel('${hsl.h}', leftRadius: true, onCommit: (n) {
              final c = clampColorValue(n, 0, 360).round();
              widget.onChanged(hslaToRgba(c, hsl.s, hsl.l, rgba.a));
            }),
            _channel('${hsl.s}', onCommit: (n) {
              final c = clampColorValue(n, 0, 100).round();
              widget.onChanged(hslaToRgba(hsl.h, c, hsl.l, rgba.a));
            }),
            _channel('${hsl.l}', onCommit: (n) {
              final c = clampColorValue(n, 0, 100).round();
              widget.onChanged(hslaToRgba(hsl.h, hsl.s, c, rgba.a));
            }),
            _channel('${(rgba.a * 100).round()}%',
                width: 44, rightRadius: true,
                onCommit: (n) => widget.onChanged(
                    rgba.copyWith(a: clampColorValue(n, 0, 100) / 100))),
          ],
        );
      case ConsonaColorFormat.hsb:
        final hsb = rgbaToHsba(rgba.r, rgba.g, rgba.b, rgba.a);
        return Row(
          children: [
            _channel('${hsb.h}', leftRadius: true, onCommit: (n) {
              final c = clampColorValue(n, 0, 360).round();
              widget.onChanged(hsbaToRgba(c, hsb.s, hsb.b, rgba.a));
            }),
            _channel('${hsb.s}', onCommit: (n) {
              final c = clampColorValue(n, 0, 100).round();
              widget.onChanged(hsbaToRgba(hsb.h, c, hsb.b, rgba.a));
            }),
            _channel('${hsb.b}', onCommit: (n) {
              final c = clampColorValue(n, 0, 100).round();
              widget.onChanged(hsbaToRgba(hsb.h, hsb.s, c, rgba.a));
            }),
            _channel('${(rgba.a * 100).round()}%',
                width: 44, rightRadius: true,
                onCommit: (n) => widget.onChanged(
                    rgba.copyWith(a: clampColorValue(n, 0, 100) / 100))),
          ],
        );
      case ConsonaColorFormat.css:
        final css = formatColorString(rgba, ConsonaColorFormat.css);
        final theme = ConsonaTheme.of(context);
        final colors = theme.colors;
        return Row(
          children: [
            _ChannelInput(
              value: css,
              readOnly: true,
              textAlign: TextAlign.left,
              leftRadius: true,
              onCommit: (_) {},
            ),
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: css));
                if (!mounted) return;
                setState(() => _copied = true);
                final scope = ConsonaFeedbackScope.maybeOf(context);
                if (scope != null) {
                  unawaited(scope.trigger(FeedbackEvent.selection));
                }
                unawaited(Future.delayed(
                    const Duration(milliseconds: 1400), () {
                  if (mounted) setState(() => _copied = false);
                }));
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _copied
                      ? colors.success.withValues(alpha: 0.12)
                      : colors.surfaceSecondary,
                  borderRadius: BorderRadius.horizontal(
                    right: theme.radius.resolve(ConsonaRadiusRole.base).topRight,
                  ),
                  border: Border.all(
                    color: _copied ? colors.success : colors.border,
                    width: 1,
                  ),
                ),
                child: Icon(
                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 14,
                  color: _copied ? colors.success : colors.mutedFg,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _channel(
    String value, {
    double? width,
    bool leftRadius = false,
    bool rightRadius = false,
    required ValueChanged<int> onCommit,
  }) {
    return _ChannelInput(
      value: value,
      width: width,
      leftRadius: leftRadius,
      rightRadius: rightRadius,
      onCommit: (v) {
        final n = _toInt(v);
        if (n != null) onCommit(n);
      },
    );
  }

  static String _formatLabel(ConsonaColorFormat f) => switch (f) {
        ConsonaColorFormat.hex => 'HEX',
        ConsonaColorFormat.rgb => 'RGB',
        ConsonaColorFormat.css => 'CSS',
        ConsonaColorFormat.hsl => 'HSL',
        ConsonaColorFormat.hsb => 'HSB',
      };
}

/* ==========================================================================
   SV area + hue + alpha sliders
   ========================================================================== */

class _SvArea extends StatelessWidget {
  const _SvArea({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.alpha,
    required this.onChanged,
    required this.onChangeEnd,
    required this.radius,
    required this.height,
  });

  final double hue;
  final double saturation; // 0..1
  final double value; // 0..1
  final double alpha;
  final void Function(double s, double v) onChanged;
  final VoidCallback onChangeEnd;
  final BorderRadius radius;
  final double height;

  void _update(Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = 1.0 - (local.dy / size.height).clamp(0.0, 1.0);
    onChanged(s, v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    const thumb = _kColorThumb;
    const half = thumb / 2;
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final left = (saturation * size.width).clamp(half, size.width - half) - half;
        final top =
            ((1 - value) * size.height).clamp(half, size.height - half) - half;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _update(d.localPosition, size),
          onPanUpdate: (d) => _update(d.localPosition, size),
          onPanEnd: (_) => onChangeEnd(),
          onPanCancel: onChangeEnd,
          child: ClipRRect(
            borderRadius: radius,
            child: CustomPaint(
              size: size,
              painter: _SvPainter(hue: hue),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: thumb,
                      height: thumb,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HSVColor.fromAHSV(1, hue, saturation, value)
                            .toColor(),
                        border: Border.all(
                            color: const Color(0xFFFFFFFF), width: 3),
                        boxShadow:
                            theme.shadow.resolve(ConsonaShadowLevel.soft),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SvPainter extends CustomPainter {
  _SvPainter({required this.hue});
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFFFFFFF), hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xFF000000)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SvPainter oldDelegate) => oldDelegate.hue != hue;
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hue,
    required this.onChanged,
    required this.onChangeEnd,
  });
  final double hue;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  static const _spectrum = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    const h = _kChannelHitH, trackH = _kChannelTrackH, thumb = _kColorThumb;
    return SizedBox(
      height: h,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final t = (hue / 360.0).clamp(0.0, 1.0);
        final thumbLeft =
            (t * width).clamp(thumb / 2, width - thumb / 2) - thumb / 2;
        void update(Offset local) =>
            onChanged((local.dx / width).clamp(0.0, 1.0) * 360.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          onPanEnd: (_) => onChangeEnd(),
          onPanCancel: onChangeEnd,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Container(
                  height: trackH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(trackH / 2),
                    gradient: const LinearGradient(colors: _spectrum),
                    border: theme.border
                        .resolve(ConsonaBorderRole.subtle, context: context),
                  ),
                ),
              ),
              Positioned(
                left: thumbLeft,
                child: _Thumb(color: HSVColor.fromAHSV(1, hue, 1, 1).toColor()),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _AlphaSlider extends StatelessWidget {
  const _AlphaSlider({
    required this.color,
    required this.alpha,
    required this.onChanged,
    required this.onChangeEnd,
  });
  final Color color; // opaque base
  final double alpha;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    const h = _kChannelHitH, trackH = _kChannelTrackH, thumb = _kColorThumb;
    final opaque = Color.fromARGB(255, (color.toARGB32() >> 16) & 0xff,
        (color.toARGB32() >> 8) & 0xff, color.toARGB32() & 0xff);
    return SizedBox(
      height: h,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final t = alpha.clamp(0.0, 1.0);
        final thumbLeft =
            (t * width).clamp(thumb / 2, width - thumb / 2) - thumb / 2;
        void update(Offset local) =>
            onChanged((local.dx / width).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          onPanEnd: (_) => onChangeEnd(),
          onPanCancel: onChangeEnd,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(trackH / 2),
                  child: SizedBox(
                    height: trackH,
                    width: width,
                    child: CustomPaint(
                      painter: const ColorCheckerboardPainter(cell: 6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [opaque.withValues(alpha: 0), opaque],
                          ),
                          border: theme.border.resolve(
                              ConsonaBorderRole.subtle,
                              context: context),
                          borderRadius: BorderRadius.circular(trackH / 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: thumbLeft,
                child: _Thumb(color: opaque.withValues(alpha: alpha)),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    const thumb = _kColorThumb;
    return Container(
      width: thumb,
      height: thumb,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
        boxShadow: theme.shadow.resolve(ConsonaShadowLevel.soft),
      ),
    );
  }
}

/* ==========================================================================
   Solid color editor (area + hue + alpha + format inputs)
   ========================================================================== */

/// Full solid-color editor: SV area, hue + alpha sliders, and format inputs.
/// Controlled via [value] / [onChanged]; keeps an internal hue so dragging to
/// achromatic extremes does not lose the selected hue.
class ColorSolidEditor extends StatefulWidget {
  const ColorSolidEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.areaHeight = 136,
    this.format,
    this.onFormatChanged,
  });

  final RgbaColor value;
  final ValueChanged<RgbaColor> onChanged;
  final double areaHeight;

  /// Optional shared format state. When null the editor keeps its own.
  final ConsonaColorFormat? format;
  final ValueChanged<ConsonaColorFormat>? onFormatChanged;

  @override
  State<ColorSolidEditor> createState() => _ColorSolidEditorState();
}

class _ColorSolidEditorState extends State<ColorSolidEditor> {
  late double _hue;
  late double _sat;
  late double _val;
  late double _alpha;
  ConsonaColorFormat _format = ConsonaColorFormat.hex;

  /// While true, only this editor setStates — parents / format fields stay quiet.
  bool _dragging = false;
  late RgbaColor _formatSnapshot;

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.value);
    _formatSnapshot = widget.value;
  }

  @override
  void didUpdateWidget(covariant ColorSolidEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ignore parent echoes while the user is dragging a thumb.
    if (_dragging) return;
    if (oldWidget.value != widget.value && widget.value != _currentRgba()) {
      _syncFrom(widget.value);
      _formatSnapshot = widget.value;
    }
  }

  void _syncFrom(RgbaColor rgba) {
    final hsv = HSVColor.fromColor(rgba.toColor());
    _hue = hsv.hue;
    _sat = hsv.saturation;
    _val = hsv.value;
    _alpha = rgba.a;
  }

  RgbaColor _currentRgba() {
    final c = HSVColor.fromAHSV(1, _hue, _sat, _val).toColor();
    final argb = c.toARGB32();
    return RgbaColor(
        (argb >> 16) & 0xff, (argb >> 8) & 0xff, argb & 0xff, _alpha);
  }

  void _beginDrag() {
    if (!_dragging) setState(() => _dragging = true);
  }

  void _paintDrag(void Function() mutate) {
    _beginDrag();
    setState(mutate);
  }

  void _endDrag() {
    if (!_dragging) {
      // Tap without move still needs a commit (panDown moved value).
      _commit();
      return;
    }
    setState(() => _dragging = false);
    _commit();
  }

  void _commit() {
    final rgba = _currentRgba();
    _formatSnapshot = rgba;
    widget.onChanged(rgba);
  }

  void _setFromRgba(RgbaColor rgba) {
    final hsv = HSVColor.fromColor(rgba.toColor());
    setState(() {
      if (hsv.saturation > 0) _hue = hsv.hue;
      _sat = hsv.saturation;
      _val = hsv.value;
      _alpha = rgba.a;
      _dragging = false;
      _formatSnapshot = rgba;
    });
    widget.onChanged(rgba);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final radius = theme.radius.resolve(ConsonaRadiusRole.macro);
    final opaque = HSVColor.fromAHSV(1, _hue, _sat, _val).toColor();
    final format = widget.format ?? _format;
    // Freeze format row mid-drag so TextEditingControllers are not rewritten
    // on every pointer move (the main source of sticky thumbs).
    final formatColor = _dragging ? _formatSnapshot : _currentRgba();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SvArea(
          hue: _hue,
          saturation: _sat,
          value: _val,
          alpha: _alpha,
          radius: radius,
          height: widget.areaHeight,
          onChanged: (s, v) => _paintDrag(() {
            _sat = s;
            _val = v;
          }),
          onChangeEnd: _endDrag,
        ),
        const SizedBox(height: ConsonaSpacing.sm),
        _HueSlider(
          hue: _hue,
          onChanged: (h) => _paintDrag(() => _hue = h),
          onChangeEnd: _endDrag,
        ),
        const SizedBox(height: ConsonaSpacing.xs + 2),
        _AlphaSlider(
          color: opaque,
          alpha: _alpha,
          onChanged: (a) => _paintDrag(() => _alpha = a),
          onChangeEnd: _endDrag,
        ),
        const SizedBox(height: ConsonaSpacing.sm),
        ColorFormatInputs(
          color: formatColor,
          format: format,
          onFormatChanged: (f) {
            if (widget.onFormatChanged != null) {
              widget.onFormatChanged!(f);
            } else {
              setState(() => _format = f);
            }
          },
          onChanged: _setFromRgba,
        ),
      ],
    );
  }
}

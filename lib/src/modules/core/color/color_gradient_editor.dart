/// Consona Color — Interactive gradient editor (canvas vector + track stops).
///
/// Port of the interface `color-gradient-editor.tsx`: a gradient preview canvas
/// with a draggable vector line and synchronized stop handles, a horizontal
/// track with draggable stops, a type dropdown + angle + flip controls, a stop
/// list with per-stop color popover / position / opacity, and an optional saved
/// presets row.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' show Icon, Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../navigation/segmented_control.dart';
import '../../overlay/popover/popover.dart';
import 'color_format_inputs.dart';
import 'color_presets.dart';
import 'color_utils.dart';

const List<({String label, ConsonaGradientType value})> _kGradientTypes = [
  (label: 'Radial', value: ConsonaGradientType.radial),
  (label: 'Linear', value: ConsonaGradientType.linear),
  (label: 'Angular', value: ConsonaGradientType.angular),
  (label: 'Diamond', value: ConsonaGradientType.diamond),
];

/// Match solid-editor channel/thumb optical sizes.
const double _kStopThumb = 24.0;
const double _kStopTrackH = 18.0;
const double _kStopHitH = 32.0;

/// Interactive multi-stop gradient editor.
class ColorGradientEditor extends StatefulWidget {
  const ColorGradientEditor({
    super.key,
    required this.config,
    required this.onChanged,
    this.activeStopId,
    this.onActiveStopChanged,
    this.showPresetsRow = true,
    this.customSwatches = const [],
    this.onAddSwatch,
    this.onRemoveSwatch,
  });

  final ConsonaGradientConfig config;
  final ValueChanged<ConsonaGradientConfig> onChanged;
  final String? activeStopId;
  final ValueChanged<String>? onActiveStopChanged;
  final bool showPresetsRow;
  final List<String> customSwatches;
  final ValueChanged<String>? onAddSwatch;
  final ValueChanged<String>? onRemoveSwatch;

  @override
  State<ColorGradientEditor> createState() => _ColorGradientEditorState();
}

class _ColorGradientEditorState extends State<ColorGradientEditor> {
  String? _internalActiveStopId;
  bool _viewingPresets = false;
  bool _addingPreset = false;

  /// Local draft while dragging stops — avoids parent rebuilds every move.
  ConsonaGradientConfig? _draft;
  bool _dragging = false;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _trackKey = GlobalKey();

  ConsonaGradientConfig get _config => _draft ?? widget.config;

  @override
  void didUpdateWidget(covariant ColorGradientEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Accept new controlled config only when not mid-drag.
    if (!_dragging && !identical(widget.config, oldWidget.config)) {
      _draft = null;
    }
  }

  String get _activeStopId =>
      widget.activeStopId ??
      _internalActiveStopId ??
      (_config.stops.isNotEmpty ? _config.stops.first.id : '1');

  void _selectStop(String id) {
    setState(() => _internalActiveStopId = id);
    widget.onActiveStopChanged?.call(id);
  }

  void _update(ConsonaGradientConfig next, {bool drag = false}) {
    if (drag) {
      // Paint locally only — parent (studio live-fill / shell) waits for end.
      _dragging = true;
      setState(() => _draft = next);
      return;
    }
    _dragging = false;
    _draft = null;
    widget.onChanged(next);
  }

  void _endDrag() {
    if (!_dragging) return;
    final pending = _draft ?? _config;
    _dragging = false;
    _draft = null;
    widget.onChanged(pending);
  }

  // --- Stop operations -------------------------------------------------------

  void _addStop() {
    final sorted = _config.sortedStops;
    double newPos = 50;
    if (sorted.length >= 2) {
      newPos = ((sorted.first.position + sorted.last.position) / 2).roundToDouble();
    }
    final color = getColorAtPosition(_config.stops, newPos);
    final id = 'stop_${DateTime.now().microsecondsSinceEpoch}';
    final stops = [
      ..._config.stops,
      ConsonaGradientStop(id: id, color: color, position: newPos),
    ]..sort((a, b) => a.position.compareTo(b.position));
    _update(_config.copyWith(stops: stops));
    _selectStop(id);
  }

  void _deleteStop(String id) {
    if (_config.stops.length <= 2) return;
    final stops = _config.stops.where((s) => s.id != id).toList();
    _update(_config.copyWith(stops: stops));
    if (_activeStopId == id && stops.isNotEmpty) _selectStop(stops.first.id);
  }

  void _flip() {
    final flipped = _config.stops
        .map((s) => s.copyWith(position: 100 - s.position))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    _update(_config.copyWith(angle: (_config.angle + 180) % 360, stops: flipped));
  }

  void _updateStopColor(String id, String color) {
    var targetId = id;
    if (!_config.stops.any((s) => s.id == targetId)) {
      targetId = _config.stops.isNotEmpty ? _config.stops.first.id : '1';
    }
    final stops = _config.stops
        .map((s) => s.id == targetId ? s.copyWith(color: color) : s)
        .toList();
    _update(_config.copyWith(stops: stops));
  }

  void _updateStopPosition(String id, double pos, {bool drag = false}) {
    final clamped = clampColorValue(pos, 0, 100);
    final stops = _config.stops
        .map((s) => s.id == id ? s.copyWith(position: clamped) : s)
        .toList();
    _update(_config.copyWith(stops: stops), drag: drag);
  }

  // --- Canvas geometry -------------------------------------------------------

  (Offset, Offset) get _vector => gradientVector(_config.angle);

  List<({String id, String color, double x, double y})> get _stopCanvasPos {
    final (start, end) = _vector;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    return _config.stops
        .map((s) => (
              id: s.id,
              color: s.color,
              x: (start.dx + (s.position / 100) * dx).clamp(0.0, 1.0),
              y: (start.dy + (s.position / 100) * dy).clamp(0.0, 1.0),
            ))
        .toList();
  }

  void _dragCanvasStop(String id, bool isEndpoint, String? endpointKind,
      Offset localFraction) {
    final mx = localFraction.dx.clamp(0.0, 1.0) * 100;
    final my = localFraction.dy.clamp(0.0, 1.0) * 100;

    if (isEndpoint) {
      const cx = 50.0, cy = 50.0;
      final deltaX = endpointKind == 'end' ? mx - cx : cx - mx;
      final deltaY = endpointKind == 'end' ? my - cy : cy - my;
      final rad = math.atan2(deltaY, deltaX);
      final newAngle = ((rad * 180 / math.pi + 90 + 360) % 360).roundToDouble();

      final (start, end) = gradientVector(newAngle);
      final sX = start.dx * 100, sY = start.dy * 100;
      final eX = end.dx * 100, eY = end.dy * 100;
      final ddx = eX - sX, ddy = eY - sY;
      final lenSq = ddx * ddx + ddy * ddy;
      double newPos = endpointKind == 'end' ? 100 : 0;
      if (lenSq > 0) {
        final t = ((mx - sX) * ddx + (my - sY) * ddy) / lenSq;
        newPos = clampColorValue((t * 100).round(), 0, 100);
      }
      final stops = _config.stops
          .map((s) => s.id == id ? s.copyWith(position: newPos) : s)
          .toList();
      _update(_config.copyWith(angle: newAngle, stops: stops), drag: true);
    } else {
      final (start, end) = _vector;
      final sX = start.dx * 100, sY = start.dy * 100;
      final ddx = end.dx * 100 - sX, ddy = end.dy * 100 - sY;
      final lenSq = ddx * ddx + ddy * ddy;
      if (lenSq > 0) {
        final t = ((mx - sX) * ddx + (my - sY) * ddy) / lenSq;
        final newPos = clampColorValue((t * 100).round(), 0, 100);
        _updateStopPosition(id, newPos, drag: true);
      }
    }
  }

  void _trackPointer(Offset local, double width, {bool allowCreate = false}) {
    final position = clampColorValue((local.dx / width) * 100, 0, 100);
    if (allowCreate) {
      final nearest = _config.stops
          .where((s) => (s.position - position).abs() < 8)
          .toList();
      if (nearest.isNotEmpty) {
        _selectStop(nearest.first.id);
      } else {
        final color = getColorAtPosition(_config.stops, position);
        final id = 'stop_${DateTime.now().microsecondsSinceEpoch}';
        final stops = [
          ..._config.stops,
          ConsonaGradientStop(id: id, color: color, position: position.roundToDouble()),
        ]..sort((a, b) => a.position.compareTo(b.position));
        _update(_config.copyWith(stops: stops));
        _selectStop(id);
      }
    }
  }

  // --- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    if (_addingPreset) {
      return ColorCreatePresetForm(
        title: 'New Gradient Preset',
        initialType: ConsonaFillType.gradient,
        currentColor: RgbaColor.fromColor(
            hexToRgba(_config.stops.first.color).toColor()),
        currentGradient: _config,
        onBack: () => setState(() => _addingPreset = false),
        onSave: (payload) {
          widget.onAddSwatch?.call(payload);
          final parsed = parseCustomSwatchItem(payload);
          if (parsed.isGradient) {
            final grad = parseCssGradient(parsed.value);
            if (grad != null) _update(grad);
          } else {
            _updateStopColor(_activeStopId, parsed.value);
          }
          setState(() => _addingPreset = false);
        },
      );
    }

    if (_viewingPresets) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _viewingPresets = false),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        size: 14, color: colors.mutedFg),
                    const SizedBox(width: 4),
                    Text('Back to Gradient',
                        style: theme.typography.label.copyWith(
                            color: colors.mutedFg, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ConsonaSpacing.sm),
          ColorPresetsContainer(
            activeColor: RgbaColor.fromColor(
                hexToRgba(_config.stops.first.color).toColor()),
            currentGradient: _config,
            customSwatches: widget.customSwatches,
            onAddSwatch: widget.onAddSwatch,
            onRemoveSwatch: widget.onRemoveSwatch,
            initialPresetType: ConsonaFillType.gradient,
            onSelect: (value) {
              final parsed = parseCustomSwatchItem(value);
              if (parsed.isGradient) {
                final grad = parseCssGradient(parsed.value);
                if (grad != null) {
                  _update(grad);
                  setState(() => _viewingPresets = false);
                }
              } else {
                _updateStopColor(_activeStopId, parsed.value);
                setState(() => _viewingPresets = false);
              }
            },
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCanvas(theme),
        const SizedBox(height: ConsonaSpacing.sm),
        _buildTypeRow(theme),
        const SizedBox(height: ConsonaSpacing.sm),
        _buildTrack(theme),
        const SizedBox(height: ConsonaSpacing.sm),
        _buildStopsHeader(theme),
        const SizedBox(height: ConsonaSpacing.xs + 2),
        ..._config.stops.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildStopRow(theme, s),
            )),
        if (widget.showPresetsRow) ...[
          const SizedBox(height: ConsonaSpacing.xs),
          _buildPresetsRow(theme),
        ],
      ],
    );
  }

  Widget _buildCanvas(ConsonaThemeData theme) {
    final (start, end) = _vector;
    final positions = _stopCanvasPos;
    final sorted = _config.sortedStops;
    final startId = sorted.isNotEmpty ? sorted.first.id : '';
    final endId = sorted.isNotEmpty ? sorted.last.id : '';

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      const h = 136.0;
      Offset toFraction(Offset global) {
        final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return Offset.zero;
        final local = box.globalToLocal(global);
        return Offset(local.dx / box.size.width, local.dy / box.size.height);
      }

      return SizedBox(
        key: _canvasKey,
        height: h,
        child: ClipRRect(
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: _config.toFlutterGradient()),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _VectorLinePainter(start: start, end: end),
                ),
              ),
              for (final p in positions)
                Positioned(
                  left: p.x * w - _kStopThumb / 2,
                  top: p.y * h - _kStopThumb / 2,
                  child: _DragHandle(
                    color: hexToRgba(p.color).toColor(),
                    selected: p.id == _activeStopId,
                    onPanStart: () => _selectStop(p.id),
                    onPanUpdate: (global) {
                      final endpoint = p.id == endId
                          ? 'end'
                          : p.id == startId
                              ? 'start'
                              : null;
                      _dragCanvasStop(
                          p.id, endpoint != null, endpoint, toFraction(global));
                    },
                    onPanEnd: _endDrag,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTypeRow(ConsonaThemeData theme) {
    final colors = theme.colors;
    final isLinearish = _config.type == ConsonaGradientType.linear ||
        _config.type == ConsonaGradientType.angular;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ColorDropdown<ConsonaGradientType>(
          value: _config.type,
          menuWidth: 120,
          items: _kGradientTypes
              .map((t) => (value: t.value, label: t.label))
              .toList(),
          onChanged: (t) => _update(_config.copyWith(type: t)),
          trigger: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _kGradientTypes.firstWhere((t) => t.value == _config.type).label,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLinearish)
              SizedBox(
                width: 44,
                child: _AngleField(
                  angle: _config.angle,
                  onChanged: (a) => _update(_config.copyWith(angle: a % 360)),
                ),
              ),
            const SizedBox(width: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _flip,
              child: Icon(Icons.swap_horiz_rounded,
                  size: 16, color: colors.mutedFg),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrack(ConsonaThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          key: _trackKey,
          height: _kStopHitH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) =>
                _trackPointer(d.localPosition, width, allowCreate: true),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Container(
                    height: _kStopTrackH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_kStopTrackH / 2),
                      gradient:
                          _config.toFlutterGradient(horizontalLinear: true),
                      border: Border.all(
                          color: const Color(0x26000000), width: 1),
                    ),
                  ),
                ),
                for (final s in _config.stops)
                  Positioned(
                    left: (s.position / 100) * width - _kStopThumb / 2,
                    child: _DragHandle(
                      color: hexToRgba(s.color).toColor(),
                      selected: s.id == _activeStopId,
                      onPanStart: () => _selectStop(s.id),
                      onPanUpdate: (global) {
                        final box = _trackKey.currentContext
                            ?.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final local = box.globalToLocal(global);
                        final pos =
                            clampColorValue((local.dx / width) * 100, 0, 100);
                        _updateStopPosition(s.id, pos.roundToDouble(),
                            drag: true);
                      },
                      onPanEnd: _endDrag,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStopsHeader(ConsonaThemeData theme) {
    final colors = theme.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Stops (${_config.stops.length})',
            style: theme.typography.label
                .copyWith(color: colors.foreground, fontWeight: FontWeight.w500)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _addStop,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: colors.foreground),
              const SizedBox(width: 4),
              Text('Add',
                  style: theme.typography.label.copyWith(
                      color: colors.foreground, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStopRow(ConsonaThemeData theme, ConsonaGradientStop stop) {
    final colors = theme.colors;
    final selected = stop.id == _activeStopId;
    final rgba = extractRgba(stop.color);
    final hexValue =
        rgbToHex(rgba.r, rgba.g, rgba.b).replaceFirst('#', '').toUpperCase();
    final alphaPct = (rgba.a * 100).round();
    final borderColor = selected ? colors.primary : colors.border;

    return Row(
      children: [
        // Position box
        SizedBox(
          width: 48,
          child: _MiniTextBox(
            value: '${stop.position.round()}%',
            selected: selected,
            onFocus: () => _selectStop(stop.id),
            onCommit: (v) {
              final n = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
              if (n != null) _updateStopPosition(stop.id, n.toDouble());
            },
          ),
        ),
        const SizedBox(width: 6),
        // Color pill: swatch popover + hex + opacity
        Expanded(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                _StopColorButton(
                  color: stop.color,
                  customSwatches: widget.customSwatches,
                  onAddSwatch: widget.onAddSwatch,
                  onRemoveSwatch: widget.onRemoveSwatch,
                  onChanged: (hex) => _updateStopColor(stop.id, hex),
                  onSelect: () => _selectStop(stop.id),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _InlineText(
                    value: hexValue,
                    onFocus: () => _selectStop(stop.id),
                    onCommit: (v) {
                      final val = v.trim();
                      final clean = val.startsWith('#') ? val : '#$val';
                      if (RegExp(r'^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$')
                          .hasMatch(clean)) {
                        final parsed = hexToRgba(clean);
                        _updateStopColor(
                            stop.id,
                            rgbToHex(parsed.r, parsed.g, parsed.b, rgba.a));
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: _InlineText(
                    value: '$alphaPct%',
                    textAlign: TextAlign.center,
                    onFocus: () => _selectStop(stop.id),
                    onCommit: (v) {
                      final n =
                          int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                      if (n != null) {
                        final c = clampColorValue(n, 0, 100);
                        _updateStopColor(stop.id,
                            rgbToHex(rgba.r, rgba.g, rgba.b, c / 100));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Remove
        SizedBox(
          width: 28,
          child: _config.stops.length > 2
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _deleteStop(stop.id),
                  child: Icon(Icons.remove_rounded,
                      size: 14, color: colors.mutedFg),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPresetsRow(ConsonaThemeData theme) {
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _viewingPresets = true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Presets',
                      style: theme.typography.label.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w500)),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: colors.mutedFg),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _addingPreset = true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 14, color: colors.foreground),
                  const SizedBox(width: 4),
                  Text('New',
                      style: theme.typography.label.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (widget.customSwatches.isEmpty)
          Text('No presets saved. Tap "New" to save this gradient.',
              style: theme.typography.labelSmall
                  .copyWith(color: colors.mutedFg, fontStyle: FontStyle.italic))
        else
          SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.customSwatches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final parsed =
                    parseCustomSwatchItem(widget.customSwatches[idx], idx);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (parsed.isGradient) {
                      final grad = parseCssGradient(parsed.value);
                      if (grad != null) _update(grad);
                    } else {
                      _updateStopColor(_activeStopId, parsed.value);
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: parsed.isGradient
                          ? parseCssGradient(parsed.value)?.toFlutterGradient()
                          : null,
                      color: parsed.isGradient
                          ? null
                          : hexToRgba(parsed.value).toColor(),
                      border: Border.all(color: colors.border, width: 1),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/* ==========================================================================
   Supporting widgets
   ========================================================================== */

class _VectorLinePainter extends CustomPainter {
  _VectorLinePainter({required this.start, required this.end});
  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Offset(start.dx * size.width, start.dy * size.height);
    final p2 = Offset(end.dx * size.width, end.dy * size.height);
    final paint = Paint()
      ..color = const Color(0xBFFFFFFF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Dashed line
    const dash = 4.0, gap = 3.0;
    final total = (p2 - p1).distance;
    final dir = total == 0 ? Offset.zero : (p2 - p1) / total;
    double drawn = 0;
    while (drawn < total) {
      final segEnd = math.min(drawn + dash, total);
      canvas.drawLine(p1 + dir * drawn, p1 + dir * segEnd, paint);
      drawn = segEnd + gap;
    }
  }

  @override
  bool shouldRepaint(_VectorLinePainter old) =>
      old.start != start || old.end != end;
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.color,
    required this.selected,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final Color color;
  final bool selected;
  final VoidCallback onPanStart;
  final ValueChanged<Offset> onPanUpdate; // global position
  final VoidCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (_) => onPanStart(),
      onPanStart: (d) => onPanUpdate(d.globalPosition),
      onPanUpdate: (d) => onPanUpdate(d.globalPosition),
      onPanEnd: (_) => onPanEnd(),
      onPanCancel: onPanEnd,
      child: Container(
        width: _kStopThumb,
        height: _kStopThumb,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
          boxShadow: theme.shadow.resolve(ConsonaShadowLevel.soft),
        ),
        child: selected
            ? Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colors.primary, width: 2),
                ),
              )
            : null,
      ),
    );
  }
}

class _AngleField extends StatefulWidget {
  const _AngleField({required this.angle, required this.onChanged});
  final double angle;
  final ValueChanged<double> onChanged;

  @override
  State<_AngleField> createState() => _AngleFieldState();
}

class _AngleFieldState extends State<_AngleField> {
  late final TextEditingController _c;
  late final FocusNode _f;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: '${widget.angle.round()}°');
    _f = FocusNode();
    _f.addListener(() {
      if (!_f.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(covariant _AngleField old) {
    super.didUpdateWidget(old);
    if (!_f.hasFocus && old.angle != widget.angle) {
      _c.text = '${widget.angle.round()}°';
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _commit() {
    final n = int.tryParse(_c.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n != null) widget.onChanged(n.toDouble());
    _c.text = '${widget.angle.round()}°';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return EditableText(
      controller: _c,
      focusNode: _f,
      textAlign: TextAlign.right,
      maxLines: 1,
      autocorrect: false,
      enableSuggestions: false,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      style: TextStyle(
        fontFamily: 'Menlo',
        fontFamilyFallback: const ['Consolas', 'monospace'],
        fontSize: 11.5,
        color: colors.mutedFg,
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.none,
      ),
      cursorColor: colors.primary,
      backgroundCursorColor: colors.mutedFg,
      onSubmitted: (_) => _commit(),
    );
  }
}

class _MiniTextBox extends StatelessWidget {
  const _MiniTextBox({
    required this.value,
    required this.selected,
    required this.onCommit,
    required this.onFocus,
  });

  final String value;
  final bool selected;
  final ValueChanged<String> onCommit;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
        border: Border.all(
            color: selected ? colors.primary : colors.border, width: 1),
      ),
      alignment: Alignment.center,
      child: _InlineText(
        value: value,
        textAlign: TextAlign.center,
        onCommit: onCommit,
        onFocus: onFocus,
      ),
    );
  }
}

/// Bare monospace inline editable text (no border) for stop pills.
class _InlineText extends StatefulWidget {
  const _InlineText({
    required this.value,
    required this.onCommit,
    this.onFocus,
    this.textAlign = TextAlign.left,
  });

  final String value;
  final ValueChanged<String> onCommit;
  final VoidCallback? onFocus;
  final TextAlign textAlign;

  @override
  State<_InlineText> createState() => _InlineTextState();
}

class _InlineTextState extends State<_InlineText> {
  late final TextEditingController _c;
  late final FocusNode _f;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value);
    _f = FocusNode();
    _f.addListener(() {
      if (_f.hasFocus) {
        widget.onFocus?.call();
      } else {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _InlineText old) {
    super.didUpdateWidget(old);
    if (!_f.hasFocus && widget.value != _c.text) _c.text = widget.value;
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onCommit(_c.text);
    _c.text = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return EditableText(
      controller: _c,
      focusNode: _f,
      textAlign: widget.textAlign,
      maxLines: 1,
      autocorrect: false,
      enableSuggestions: false,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      style: TextStyle(
        fontFamily: 'Menlo',
        fontFamilyFallback: const ['Consolas', 'monospace'],
        fontSize: 11.5,
        color: colors.foreground,
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.none,
      ),
      cursorColor: colors.primary,
      backgroundCursorColor: colors.mutedFg,
      onSubmitted: (_) => _commit(),
    );
  }
}

/// A small circular swatch that opens the solid editor popover for one stop.
class _StopColorButton extends StatelessWidget {
  const _StopColorButton({
    required this.color,
    required this.onChanged,
    required this.onSelect,
    required this.customSwatches,
    this.onAddSwatch,
    this.onRemoveSwatch,
  });

  final String color;
  final ValueChanged<String> onChanged;
  final VoidCallback onSelect;
  final List<String> customSwatches;
  final ValueChanged<String>? onAddSwatch;
  final ValueChanged<String>? onRemoveSwatch;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onSelect();
        final box = context.findRenderObject() as RenderBox?;
        Rect? anchor;
        if (box != null && box.hasSize) {
          anchor = box.localToGlobal(Offset.zero) & box.size;
        }
        ConsonaPopover.show<void>(
          context,
          anchorRect: anchor,
          width: 300,
          builder: (_) => _StopEditorPopover(
            initial: hexToRgba(color),
            customSwatches: customSwatches,
            onAddSwatch: onAddSwatch,
            onRemoveSwatch: onRemoveSwatch,
            onChanged: (rgba) =>
                onChanged(rgbToHex(rgba.r, rgba.g, rgba.b, rgba.a)),
          ),
        );
      },
      child: Container(
        width: _kStopThumb,
        height: _kStopThumb,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hexToRgba(color).toColor(),
          border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
          boxShadow: theme.shadow.resolve(ConsonaShadowLevel.soft),
        ),
      ),
    );
  }
}

/// Editor|Presets popover body used by gradient stop swatches.
class _StopEditorPopover extends StatefulWidget {
  const _StopEditorPopover({
    required this.initial,
    required this.onChanged,
    required this.customSwatches,
    this.onAddSwatch,
    this.onRemoveSwatch,
  });

  final RgbaColor initial;
  final ValueChanged<RgbaColor> onChanged;
  final List<String> customSwatches;
  final ValueChanged<String>? onAddSwatch;
  final ValueChanged<String>? onRemoveSwatch;

  @override
  State<_StopEditorPopover> createState() => _StopEditorPopoverState();
}

class _StopEditorPopoverState extends State<_StopEditorPopover> {
  late RgbaColor _color = widget.initial;
  int _tab = 0; // 0 editor, 1 presets

  void _emit(RgbaColor c) {
    setState(() => _color = c);
    widget.onChanged(c);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConsonaSegmentedControl<int>(
          fullWidth: true,
          selected: _tab,
          segments: const [
            ConsonaSegment(value: 0, label: 'Editor'),
            ConsonaSegment(value: 1, label: 'Presets'),
          ],
          onChanged: (v) => setState(() => _tab = v),
        ),
        const SizedBox(height: ConsonaSpacing.md),
        if (_tab == 0)
          ColorSolidEditor(
            value: _color,
            areaHeight: 128,
            onChanged: _emit,
          )
        else
          ColorPresetsContainer(
            activeColor: _color,
            customSwatches: widget.customSwatches,
            onAddSwatch: widget.onAddSwatch,
            onRemoveSwatch: widget.onRemoveSwatch,
            onSelect: (value) {
              final parsed = parseCustomSwatchItem(value);
              if (!parsed.isGradient) _emit(hexToRgba(parsed.value));
            },
          ),
      ],
    );
  }
}

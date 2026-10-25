/// Consona Color — Color-space math, gradient & image-fill models.
///
/// Feature-for-feature port of the Consona interface `color-utils.ts`:
/// RGBA/HSLA/HSBA conversions, gradient configuration + CSS (de)serialization,
/// image-fill configuration with a filter approximation, and custom-swatch
/// parsing.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Coalesces bursty callbacks (e.g. pointer moves) to one run per frame.
///
/// Use during thumb drags so parent setState / text-field sync does not run
/// dozens of times per gesture — call [flush] on pointer-up for a final emit.
class ConsonaFrameCoalescer {
  VoidCallback? _pending;
  bool _scheduled = false;

  /// Schedule [fn], replacing any previously pending action for this frame.
  void run(VoidCallback fn) {
    _pending = fn;
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _scheduled = false;
      final action = _pending;
      _pending = null;
      action?.call();
    });
  }

  /// Run the pending action immediately (e.g. on drag end).
  void flush() {
    final action = _pending;
    _pending = null;
    _scheduled = false;
    action?.call();
  }

  void cancel() {
    _pending = null;
    _scheduled = false;
  }
}

/// Active color notation for the format inputs row.
enum ConsonaColorFormat { hex, rgb, css, hsl, hsb }

/// Root fill mode of the color picker.
enum ConsonaFillType { solid, gradient, image }

/// Gradient geometry.
enum ConsonaGradientType { linear, radial, angular, diamond }

/// How an image fill is scaled inside its frame.
enum ConsonaImageScaleMode { fill, fit, crop, tile }

/// Clamp [val] between [min] and [max].
double clampColorValue(num val, num min, num max) =>
    math.min(math.max(val.toDouble(), min.toDouble()), max.toDouble());

/* ==========================================================================
   RGBA / HSLA / HSBA value types
   ========================================================================== */

/// Straight-alpha RGBA color. Channels are `0..255`, alpha is `0..1`.
@immutable
class RgbaColor {
  const RgbaColor(this.r, this.g, this.b, [this.a = 1.0]);

  final int r;
  final int g;
  final int b;
  final double a;

  RgbaColor copyWith({int? r, int? g, int? b, double? a}) =>
      RgbaColor(r ?? this.r, g ?? this.g, b ?? this.b, a ?? this.a);

  /// Convert to a Flutter [Color] (premultiplies alpha into the ARGB int).
  Color toColor() =>
      Color.fromARGB((clampColorValue(a, 0, 1) * 255).round(), r, g, b);

  /// Extract straight-alpha RGBA from a Flutter [Color].
  factory RgbaColor.fromColor(Color color) {
    final argb = color.toARGB32();
    return RgbaColor(
      (argb >> 16) & 0xff,
      (argb >> 8) & 0xff,
      argb & 0xff,
      ((argb >> 24) & 0xff) / 255.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RgbaColor &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      (other.a - a).abs() < 0.001;

  @override
  int get hashCode => Object.hash(r, g, b, (a * 100).round());
}

/// HSLA color. `h` is `0..360`, `s`/`l` are `0..100`, `a` is `0..1`.
@immutable
class HslaColor {
  const HslaColor(this.h, this.s, this.l, [this.a = 1.0]);
  final int h;
  final int s;
  final int l;
  final double a;
}

/// HSBA / HSVA color. `h` is `0..360`, `s`/`b` are `0..100`, `a` is `0..1`.
@immutable
class HsbaColor {
  const HsbaColor(this.h, this.s, this.b, [this.a = 1.0]);
  final int h;
  final int s;
  final int b;
  final double a;
}

/// Convert RGB (0-255) to a `#RRGGBB` or `#RRGGBBAA` string.
String rgbToHex(int r, int g, int b, [double a = 1.0]) {
  final cr = clampColorValue(r, 0, 255).round();
  final cg = clampColorValue(g, 0, 255).round();
  final cb = clampColorValue(b, 0, 255).round();
  final ca = clampColorValue(a, 0, 1);

  String two(int n) => n.toRadixString(16).padLeft(2, '0');
  final base = '#${two(cr)}${two(cg)}${two(cb)}';
  if (ca < 1) {
    return '$base${two((ca * 255).round())}';
  }
  return base;
}

/// Parse a hex string (`#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`) to [RgbaColor].
RgbaColor hexToRgba(String hex) {
  var clean = hex.trim().replaceFirst('#', '');
  if (clean.length == 3 || clean.length == 4) {
    clean = clean.split('').map((c) => '$c$c').join();
  }
  int parse(String s) => int.tryParse(s, radix: 16) ?? 0;
  if (clean.length == 6) {
    return RgbaColor(
      parse(clean.substring(0, 2)),
      parse(clean.substring(2, 4)),
      parse(clean.substring(4, 6)),
    );
  } else if (clean.length == 8) {
    final a = (int.tryParse(clean.substring(6, 8), radix: 16) ?? 255) / 255;
    return RgbaColor(
      parse(clean.substring(0, 2)),
      parse(clean.substring(2, 4)),
      parse(clean.substring(4, 6)),
      (a * 100).round() / 100,
    );
  }
  return const RgbaColor(0, 0, 0, 1);
}

/// Convert RGBA to HSLA.
HslaColor rgbaToHsla(int r, int g, int b, [double a = 1.0]) {
  final nr = clampColorValue(r, 0, 255) / 255;
  final ng = clampColorValue(g, 0, 255) / 255;
  final nb = clampColorValue(b, 0, 255) / 255;

  final max = math.max(nr, math.max(ng, nb));
  final min = math.min(nr, math.min(ng, nb));
  double h = 0;
  double s = 0;
  final l = (max + min) / 2;

  if (max != min) {
    final d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    if (max == nr) {
      h = (ng - nb) / d + (ng < nb ? 6 : 0);
    } else if (max == ng) {
      h = (nb - nr) / d + 2;
    } else {
      h = (nr - ng) / d + 4;
    }
    h /= 6;
  }

  return HslaColor(
    (h * 360).round(),
    (s * 100).round(),
    (l * 100).round(),
    clampColorValue(a, 0, 1),
  );
}

/// Convert HSLA to RGBA.
RgbaColor hslaToRgba(int h, int s, int l, [double a = 1.0]) {
  final nh = (h % 360) / 360;
  final ns = clampColorValue(s, 0, 100) / 100;
  final nl = clampColorValue(l, 0, 100) / 100;

  if (ns == 0) {
    final v = (nl * 255).round();
    return RgbaColor(v, v, v, clampColorValue(a, 0, 1));
  }

  double hue2rgb(double p, double q, double t) {
    var nt = t;
    if (nt < 0) nt += 1;
    if (nt > 1) nt -= 1;
    if (nt < 1 / 6) return p + (q - p) * 6 * nt;
    if (nt < 1 / 2) return q;
    if (nt < 2 / 3) return p + (q - p) * (2 / 3 - nt) * 6;
    return p;
  }

  final q = nl < 0.5 ? nl * (1 + ns) : nl + ns - nl * ns;
  final p = 2 * nl - q;
  return RgbaColor(
    (hue2rgb(p, q, nh + 1 / 3) * 255).round(),
    (hue2rgb(p, q, nh) * 255).round(),
    (hue2rgb(p, q, nh - 1 / 3) * 255).round(),
    clampColorValue(a, 0, 1),
  );
}

/// Convert RGBA to HSBA / HSV.
HsbaColor rgbaToHsba(int r, int g, int b, [double a = 1.0]) {
  final nr = clampColorValue(r, 0, 255) / 255;
  final ng = clampColorValue(g, 0, 255) / 255;
  final nb = clampColorValue(b, 0, 255) / 255;

  final max = math.max(nr, math.max(ng, nb));
  final min = math.min(nr, math.min(ng, nb));
  final d = max - min;

  double h = 0;
  final s = max == 0 ? 0.0 : d / max;
  final v = max;

  if (max != min) {
    if (max == nr) {
      h = (ng - nb) / d + (ng < nb ? 6 : 0);
    } else if (max == ng) {
      h = (nb - nr) / d + 2;
    } else {
      h = (nr - ng) / d + 4;
    }
    h /= 6;
  }

  return HsbaColor(
    (h * 360).round(),
    (s * 100).round(),
    (v * 100).round(),
    clampColorValue(a, 0, 1),
  );
}

/// Convert HSBA / HSV to RGBA.
RgbaColor hsbaToRgba(int h, int s, int b, [double a = 1.0]) {
  final nh = ((h % 360) + 360) % 360;
  final ns = clampColorValue(s, 0, 100) / 100;
  final nv = clampColorValue(b, 0, 100) / 100;

  final c = nv * ns;
  final x = c * (1 - (((nh / 60) % 2) - 1).abs());
  final m = nv - c;

  double rp = 0, gp = 0, bp = 0;
  if (nh < 60) {
    rp = c;
    gp = x;
  } else if (nh < 120) {
    rp = x;
    gp = c;
  } else if (nh < 180) {
    gp = c;
    bp = x;
  } else if (nh < 240) {
    gp = x;
    bp = c;
  } else if (nh < 300) {
    rp = x;
    bp = c;
  } else {
    rp = c;
    bp = x;
  }

  return RgbaColor(
    ((rp + m) * 255).round(),
    ((gp + m) * 255).round(),
    ((bp + m) * 255).round(),
    clampColorValue(a, 0, 1),
  );
}

/// Extract RGBA from a hex / rgb / rgba / Flutter color string, with a
/// blue fallback matching the interface.
RgbaColor extractRgba(Object? color) {
  if (color == null) return const RgbaColor(59, 130, 246, 1);
  if (color is Color) return RgbaColor.fromColor(color);
  if (color is RgbaColor) return color;
  final str = color.toString().trim();
  if (str.isEmpty) return const RgbaColor(59, 130, 246, 1);
  if (str.startsWith('#')) return hexToRgba(str);
  final m = RegExp(r'rgba?\(([^)]+)\)').firstMatch(str);
  if (m != null) {
    final parts = m.group(1)!.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      return RgbaColor(
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
        int.tryParse(parts[2]) ?? 0,
        parts.length >= 4 ? (double.tryParse(parts[3]) ?? 1) : 1,
      );
    }
  }
  return const RgbaColor(59, 130, 246, 1);
}

/// Format an [RgbaColor] into the requested [format].
String formatColorString(RgbaColor rgba, ConsonaColorFormat format) {
  final r = rgba.r, g = rgba.g, b = rgba.b, a = rgba.a;
  final alphaClean = (a * 100).round() / 100;
  switch (format) {
    case ConsonaColorFormat.hex:
      return rgbToHex(r, g, b, a);
    case ConsonaColorFormat.rgb:
      return a < 1 ? 'rgba($r, $g, $b, $alphaClean)' : 'rgb($r, $g, $b)';
    case ConsonaColorFormat.css:
      return 'rgba($r, $g, $b, $alphaClean)';
    case ConsonaColorFormat.hsl:
      final h = rgbaToHsla(r, g, b, a);
      return a < 1
          ? 'hsla(${h.h}, ${h.s}%, ${h.l}%, $alphaClean)'
          : 'hsl(${h.h}, ${h.s}%, ${h.l}%)';
    case ConsonaColorFormat.hsb:
      final h = rgbaToHsba(r, g, b, a);
      return a < 1
          ? 'hsba(${h.h}, ${h.s}%, ${h.b}%, $alphaClean)'
          : 'hsb(${h.h}, ${h.s}%, ${h.b}%)';
  }
}

/* ==========================================================================
   Gradient configuration
   ========================================================================== */

/// A single gradient color stop.
@immutable
class ConsonaGradientStop {
  const ConsonaGradientStop({
    required this.id,
    required this.color,
    required this.position,
  });

  /// Stable identity used while editing.
  final String id;

  /// Hex (`#RRGGBB[AA]`) color string.
  final String color;

  /// Position along the gradient, `0..100`.
  final double position;

  ConsonaGradientStop copyWith({String? id, String? color, double? position}) =>
      ConsonaGradientStop(
        id: id ?? this.id,
        color: color ?? this.color,
        position: position ?? this.position,
      );
}

/// Full gradient configuration (type + angle + stops).
@immutable
class ConsonaGradientConfig {
  const ConsonaGradientConfig({
    required this.type,
    required this.angle,
    required this.stops,
  });

  final ConsonaGradientType type;
  final double angle;
  final List<ConsonaGradientStop> stops;

  ConsonaGradientConfig copyWith({
    ConsonaGradientType? type,
    double? angle,
    List<ConsonaGradientStop>? stops,
  }) =>
      ConsonaGradientConfig(
        type: type ?? this.type,
        angle: angle ?? this.angle,
        stops: stops ?? this.stops,
      );

  List<ConsonaGradientStop> get sortedStops =>
      [...stops]..sort((a, b) => a.position.compareTo(b.position));

  /// Build a Flutter [Gradient] for painting. When [horizontalLinear] is true
  /// the gradient is rendered as a horizontal 0→100% bar (used by the track).
  Gradient toFlutterGradient({bool horizontalLinear = false}) {
    final sorted = sortedStops;
    final colors = sorted.isEmpty
        ? [const Color(0xFF3B82F6), const Color(0xFF3B82F6)]
        : sorted.map((s) => hexToRgba(s.color).toColor()).toList();
    var positions = sorted.isEmpty
        ? [0.0, 1.0]
        : sorted.map((s) => clampColorValue(s.position / 100, 0, 1)).toList();
    if (colors.length == 1) {
      colors.add(colors.first);
      positions = [0.0, 1.0];
    }

    if (horizontalLinear || type == ConsonaGradientType.linear) {
      final vec = gradientVector(horizontalLinear ? 90 : angle);
      return LinearGradient(
        begin: Alignment(vec.$1.dx * 2 - 1, vec.$1.dy * 2 - 1),
        end: Alignment(vec.$2.dx * 2 - 1, vec.$2.dy * 2 - 1),
        colors: colors,
        stops: positions,
      );
    }
    if (type == ConsonaGradientType.angular) {
      return SweepGradient(colors: colors, stops: positions);
    }
    // radial + diamond approximation
    return RadialGradient(
      center: Alignment.center,
      radius: 0.75,
      colors: colors,
      stops: positions,
    );
  }
}

/// Compute the normalized (0..1) start & end points of a gradient vector for
/// [angle] degrees (CSS convention: 0° → up, 90° → right). Mirrors the
/// interface geometry so dashed guide + handle positions line up.
(Offset, Offset) gradientVector(double angle) {
  final rad = (angle - 90) * math.pi / 180;
  final cos = math.cos(rad);
  final sin = math.sin(rad);
  final absCos = cos.abs();
  final absSin = sin.abs();
  double scale = 50;
  if (absCos > 0.0001 && absSin > 0.0001) {
    scale = math.min(50 / absCos, 50 / absSin);
  } else if (absCos > 0.0001) {
    scale = 50 / absCos;
  } else if (absSin > 0.0001) {
    scale = 50 / absSin;
  }
  final start = Offset(
    clampColorValue(50 - scale * cos, 0, 100) / 100,
    clampColorValue(50 - scale * sin, 0, 100) / 100,
  );
  final end = Offset(
    clampColorValue(50 + scale * cos, 0, 100) / 100,
    clampColorValue(50 + scale * sin, 0, 100) / 100,
  );
  return (start, end);
}

/// Interpolate between two color strings, returning a hex string.
String interpolateColor(String c1, String c2, double factor) {
  final a = extractRgba(c1);
  final b = extractRgba(c2);
  final t = clampColorValue(factor, 0, 1);
  return rgbToHex(
    (a.r + (b.r - a.r) * t).round(),
    (a.g + (b.g - a.g) * t).round(),
    (a.b + (b.b - a.b) * t).round(),
    ((a.a + (b.a - a.a) * t) * 100).round() / 100,
  );
}

/// Sample the gradient color at [position] (0..100), returning a hex string.
String getColorAtPosition(List<ConsonaGradientStop> stops, double position) {
  if (stops.isEmpty) return '#3b82f6';
  final sorted = [...stops]..sort((a, b) => a.position.compareTo(b.position));
  final first = sorted.first;
  final last = sorted.last;
  if (position <= first.position) return first.color;
  if (position >= last.position) return last.color;
  for (var i = 0; i < sorted.length - 1; i++) {
    final s1 = sorted[i];
    final s2 = sorted[i + 1];
    if (position >= s1.position && position <= s2.position) {
      final range = s2.position - s1.position;
      final factor = range == 0 ? 0.0 : (position - s1.position) / range;
      return interpolateColor(s1.color, s2.color, factor);
    }
  }
  return first.color;
}

/// Serialize a [ConsonaGradientConfig] to a CSS gradient string.
String gradientToCss(ConsonaGradientConfig config) {
  final sorted = config.sortedStops;
  final stopsStr =
      sorted.map((s) => '${s.color} ${s.position.round()}%').join(', ');
  switch (config.type) {
    case ConsonaGradientType.linear:
      return 'linear-gradient(${config.angle.round()}deg, $stopsStr)';
    case ConsonaGradientType.radial:
      return 'radial-gradient(circle at center, $stopsStr)';
    case ConsonaGradientType.angular:
      return 'conic-gradient(from ${config.angle.round()}deg at 50% 50%, $stopsStr)';
    case ConsonaGradientType.diamond:
      return 'radial-gradient(ellipse at center, $stopsStr)';
  }
}

/// Parse a CSS gradient string into a [ConsonaGradientConfig], or null.
ConsonaGradientConfig? parseCssGradient(String css) {
  if (css.isEmpty) return null;
  final trimmed = css.trim();

  ConsonaGradientType type;
  double angle = 135;
  if (trimmed.startsWith('radial-gradient')) {
    type = ConsonaGradientType.radial;
    angle = 0;
  } else if (trimmed.startsWith('conic-gradient')) {
    type = ConsonaGradientType.angular;
    angle = 0;
  } else if (trimmed.startsWith('linear-gradient')) {
    type = ConsonaGradientType.linear;
  } else {
    return null;
  }

  final match = RegExp(r'^[a-z\-]+\((.*)\)$', caseSensitive: false)
      .firstMatch(trimmed);
  if (match == null || match.group(1) == null) return null;
  final inner = match.group(1)!;

  // Split on top-level commas (ignoring nested parens).
  final parts = <String>[];
  var depth = 0;
  var current = '';
  for (var i = 0; i < inner.length; i++) {
    final ch = inner[i];
    if (ch == '(') depth++;
    if (ch == ')') depth--;
    if (ch == ',' && depth == 0) {
      parts.add(current.trim());
      current = '';
    } else {
      current += ch;
    }
  }
  if (current.trim().isNotEmpty) parts.add(current.trim());
  if (parts.isEmpty) return null;

  var stopParts = parts;
  final firstPart = parts.first;
  final angleMatch =
      RegExp(r'^(\d+(?:\.\d+)?)deg$', caseSensitive: false).firstMatch(firstPart);
  if (angleMatch != null) {
    angle = double.parse(angleMatch.group(1)!).roundToDouble();
    stopParts = parts.sublist(1);
  } else if (firstPart.startsWith('to ')) {
    if (firstPart.contains('top') && firstPart.contains('right')) {
      angle = 45;
    } else if (firstPart.contains('bottom') && firstPart.contains('right')) {
      angle = 135;
    } else if (firstPart.contains('bottom') && firstPart.contains('left')) {
      angle = 225;
    } else if (firstPart.contains('top') && firstPart.contains('left')) {
      angle = 315;
    } else if (firstPart.contains('top')) {
      angle = 0;
    } else if (firstPart.contains('right')) {
      angle = 90;
    } else if (firstPart.contains('bottom')) {
      angle = 180;
    } else if (firstPart.contains('left')) {
      angle = 270;
    }
    stopParts = parts.sublist(1);
  } else if (firstPart.startsWith('from ')) {
    final fromMatch =
        RegExp(r'from\s+(\d+)deg', caseSensitive: false).firstMatch(firstPart);
    if (fromMatch != null) angle = double.parse(fromMatch.group(1)!);
    stopParts = parts.sublist(1);
  } else if (firstPart.startsWith('circle') || firstPart.startsWith('ellipse')) {
    stopParts = parts.sublist(1);
  }

  if (stopParts.isEmpty) return null;

  final stops = <ConsonaGradientStop>[];
  for (var idx = 0; idx < stopParts.length; idx++) {
    final sp = stopParts[idx];
    final percentMatch =
        RegExp(r'\s+(\d+(?:\.\d+)?)%\s*$').firstMatch(sp);
    double pos = (idx / math.max(stopParts.length - 1, 1) * 100).roundToDouble();
    var colorStr = sp;
    if (percentMatch != null) {
      pos = clampColorValue(
        double.parse(percentMatch.group(1)!).round(),
        0,
        100,
      );
      colorStr = sp.substring(0, sp.lastIndexOf(percentMatch.group(0)!)).trim();
    }
    stops.add(ConsonaGradientStop(
      id: 'stop_${idx + 1}',
      color: colorStr,
      position: pos,
    ));
  }

  return ConsonaGradientConfig(type: type, angle: angle, stops: stops);
}

/// Curated designer gradient presets (mirrors `DEFAULT_GRADIENT_PRESETS`).
const List<({String name, ConsonaGradientConfig config})> kGradientPresets = [
  (
    name: 'Cosmic Lavender',
    config: ConsonaGradientConfig(
      type: ConsonaGradientType.linear,
      angle: 135,
      stops: [
        ConsonaGradientStop(id: '1', color: '#4f46e5', position: 0),
        ConsonaGradientStop(id: '2', color: '#7c3aed', position: 52),
        ConsonaGradientStop(id: '3', color: '#06b6d4', position: 100),
      ],
    ),
  ),
  (
    name: 'Sunset Velvet',
    config: ConsonaGradientConfig(
      type: ConsonaGradientType.linear,
      angle: 135,
      stops: [
        ConsonaGradientStop(id: '1', color: '#881337', position: 0),
        ConsonaGradientStop(id: '2', color: '#e11d48', position: 48),
        ConsonaGradientStop(id: '3', color: '#f59e0b', position: 100),
      ],
    ),
  ),
  (
    name: 'Aurora Borealis',
    config: ConsonaGradientConfig(
      type: ConsonaGradientType.linear,
      angle: 120,
      stops: [
        ConsonaGradientStop(id: '1', color: '#064e3b', position: 0),
        ConsonaGradientStop(id: '2', color: '#0d9488', position: 54),
        ConsonaGradientStop(id: '3', color: '#5eead4', position: 100),
      ],
    ),
  ),
  (
    name: 'Cyberpunk Rose',
    config: ConsonaGradientConfig(
      type: ConsonaGradientType.linear,
      angle: 90,
      stops: [
        ConsonaGradientStop(id: '1', color: '#f43f5e', position: 0),
        ConsonaGradientStop(id: '2', color: '#8b5cf6', position: 50),
        ConsonaGradientStop(id: '3', color: '#3b82f6', position: 100),
      ],
    ),
  ),
  (
    name: 'Golden Amber',
    config: ConsonaGradientConfig(
      type: ConsonaGradientType.linear,
      angle: 45,
      stops: [
        ConsonaGradientStop(id: '1', color: '#78350f', position: 0),
        ConsonaGradientStop(id: '2', color: '#d97706', position: 50),
        ConsonaGradientStop(id: '3', color: '#fde047', position: 100),
      ],
    ),
  ),
  (
    name: 'Ocean Deep',
    config: ConsonaGradientConfig(
      type: ConsonaGradientType.linear,
      angle: 135,
      stops: [
        ConsonaGradientStop(id: '1', color: '#0f172a', position: 0),
        ConsonaGradientStop(id: '2', color: '#1e3a8a', position: 50),
        ConsonaGradientStop(id: '3', color: '#0284c7', position: 100),
      ],
    ),
  ),
  (
    name: 'Monochrome Slate',
    config: ConsonaGradientConfig(
      type: ConsonaGradientType.linear,
      angle: 180,
      stops: [
        ConsonaGradientStop(id: '1', color: '#09090b', position: 0),
        ConsonaGradientStop(id: '2', color: '#27272a', position: 55),
        ConsonaGradientStop(id: '3', color: '#71717a', position: 100),
      ],
    ),
  ),
  (
    name: 'Ethereal Mist',
    config: ConsonaGradientConfig(
      type: ConsonaGradientType.linear,
      angle: 135,
      stops: [
        ConsonaGradientStop(id: '1', color: '#fce7f3', position: 0),
        ConsonaGradientStop(id: '2', color: '#e0e7ff', position: 50),
        ConsonaGradientStop(id: '3', color: '#ccfbf1', position: 100),
      ],
    ),
  ),
];

/* ==========================================================================
   Image fill configuration
   ========================================================================== */

/// Non-destructive image fill configuration with scale mode + adjustments.
@immutable
class ConsonaImageFillConfig {
  const ConsonaImageFillConfig({
    this.url = '',
    this.mode = ConsonaImageScaleMode.fill,
    this.opacity = 100,
    this.zoom = 130,
    this.exposure = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.temperature = 0,
    this.tint = 0,
    this.highlights = 0,
    this.shadows = 0,
    this.positionX = 50,
    this.positionY = 50,
    this.rotation = 0,
    this.fileName,
  });

  final String url;
  final ConsonaImageScaleMode mode;
  final double opacity; // 0..100
  final double zoom; // 50..500
  final double exposure; // -100..100
  final double contrast; // -100..100
  final double saturation; // -100..100
  final double temperature; // -100..100
  final double tint; // -100..100
  final double highlights; // -100..100
  final double shadows; // -100..100
  final double positionX; // 0..100
  final double positionY; // 0..100
  final double rotation; // 0, 90, 180, 270
  final String? fileName;

  ConsonaImageFillConfig copyWith({
    String? url,
    ConsonaImageScaleMode? mode,
    double? opacity,
    double? zoom,
    double? exposure,
    double? contrast,
    double? saturation,
    double? temperature,
    double? tint,
    double? highlights,
    double? shadows,
    double? positionX,
    double? positionY,
    double? rotation,
    String? fileName,
  }) =>
      ConsonaImageFillConfig(
        url: url ?? this.url,
        mode: mode ?? this.mode,
        opacity: opacity ?? this.opacity,
        zoom: zoom ?? this.zoom,
        exposure: exposure ?? this.exposure,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        temperature: temperature ?? this.temperature,
        tint: tint ?? this.tint,
        highlights: highlights ?? this.highlights,
        shadows: shadows ?? this.shadows,
        positionX: positionX ?? this.positionX,
        positionY: positionY ?? this.positionY,
        rotation: rotation ?? this.rotation,
        fileName: fileName ?? this.fileName,
      );
}

const ConsonaImageFillConfig kDefaultImageFillConfig = ConsonaImageFillConfig();

/// Build a 4x5 color matrix approximating the interface CSS filter chain
/// (`getImageFillFilter`): exposure/highlights → brightness, contrast/shadows →
/// contrast, saturation → saturate, temperature/tint → warm shift + hue rotate.
List<double> imageFillColorMatrix(ConsonaImageFillConfig c) {
  var matrix = _identityMatrix();

  // Brightness (exposure + highlights).
  final brightness = (1 + c.exposure / 100) * (1 + c.highlights * 0.25 / 100);
  if (brightness != 1) {
    matrix = _multiplyMatrix(_scaleMatrix(brightness), matrix);
  }

  // Contrast (contrast + shadows).
  final contrast = (1 + c.contrast / 100) * (1 - c.shadows * 0.2 / 100);
  if (contrast != 1) {
    matrix = _multiplyMatrix(_contrastMatrix(contrast), matrix);
  }

  // Saturation.
  if (c.saturation != 0) {
    matrix = _multiplyMatrix(_saturationMatrix(1 + c.saturation / 100), matrix);
  }

  // Temperature: warm (positive) adds red / removes blue; cool handled by hue.
  if (c.temperature > 0) {
    final warm = c.temperature / 100 * 0.3;
    matrix = _multiplyMatrix(_channelShiftMatrix(1 + warm, 1, 1 - warm), matrix);
  }

  // Hue rotation from tint (+ cool temperature).
  var hue = c.tint * 1.8;
  if (c.temperature < 0) hue += c.temperature * 0.3;
  if (hue != 0) {
    matrix = _multiplyMatrix(_hueRotateMatrix(hue), matrix);
  }

  return matrix;
}

/// Paints an image fill with the same geometry as the web editor:
/// center at `(positionX%, positionY%)`, crop zoom as box size, tile zoom as
/// scale. Do **not** use [Image.alignment] for pan — cover vs contain invert
/// optical drag direction.
class ConsonaImageFillLayer extends StatelessWidget {
  const ConsonaImageFillLayer({
    super.key,
    required this.config,
    this.colorFilter,
    this.opacity = 1,
  });

  final ConsonaImageFillConfig config;
  final ColorFilter? colorFilter;
  final double opacity;

  ImageProvider get _provider {
    final url = config.url;
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma != -1) {
        try {
          return MemoryImage(base64Decode(url.substring(comma + 1)));
        } catch (_) {
          // fall through
        }
      }
    }
    return NetworkImage(url);
  }

  BoxFit get _fit => switch (config.mode) {
        ConsonaImageScaleMode.fill => BoxFit.cover,
        ConsonaImageScaleMode.fit => BoxFit.contain,
        ConsonaImageScaleMode.crop => BoxFit.cover,
        ConsonaImageScaleMode.tile => BoxFit.none,
      };

  @override
  Widget build(BuildContext context) {
    if (config.url.isEmpty) return const SizedBox.expand();

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      if (w <= 0 || h <= 0) return const SizedBox.expand();

      final zoom = clampColorValue(config.zoom, 50, 400) / 100;
      // Crop: box grows with zoom (web `width/height: zoom%`). Fill/fit: 100%.
      final boxW = config.mode == ConsonaImageScaleMode.crop ? w * zoom : w;
      final boxH = config.mode == ConsonaImageScaleMode.crop ? h * zoom : h;
      final left = w * (config.positionX / 100) - boxW / 2;
      final top = h * (config.positionY / 100) - boxH / 2;

      Widget image = config.mode == ConsonaImageScaleMode.tile
          ? Image(
              image: _provider,
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              width: boxW,
              height: boxH,
              alignment: Alignment.topLeft,
              errorBuilder: _errorBuilder,
            )
          : Image(
              image: _provider,
              fit: _fit,
              width: boxW,
              height: boxH,
              // Position is via [Positioned] left/top — not Image.alignment.
              alignment: Alignment.center,
              errorBuilder: _errorBuilder,
            );

      // Crop already sizes the box by zoom%. Tile / fill / fit scale the layer.
      if (config.mode != ConsonaImageScaleMode.crop && zoom != 1) {
        image = Transform.scale(
          scale: zoom,
          filterQuality: FilterQuality.medium,
          child: image,
        );
      }

      if (config.rotation != 0) {
        image = Transform.rotate(
          angle: config.rotation * math.pi / 180,
          child: image,
        );
      }

      final filter = colorFilter ?? imageFillColorFilter(config);
      if (filter != null) {
        image = ColorFiltered(colorFilter: filter, child: image);
      }

      return Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: left,
              top: top,
              width: boxW,
              height: boxH,
              child: image,
            ),
          ],
        ),
      );
    });
  }

  static Widget _errorBuilder(
      BuildContext context, Object error, StackTrace? stack) {
    return const ColoredBox(color: Color(0x11000000));
  }
}

/// Convenience: a [ColorFilter] for the config, or null when it is a no-op.
ColorFilter? imageFillColorFilter(ConsonaImageFillConfig c) {
  final m = imageFillColorMatrix(c);
  final identity = _identityMatrix();
  var same = true;
  for (var i = 0; i < 20; i++) {
    if ((m[i] - identity[i]).abs() > 0.0001) {
      same = false;
      break;
    }
  }
  if (same) return null;
  return ColorFilter.matrix(m);
}

List<double> _identityMatrix() => <double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0, //
      0, 0, 1, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

List<double> _scaleMatrix(double s) => <double>[
      s, 0, 0, 0, 0, //
      0, s, 0, 0, 0, //
      0, 0, s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

List<double> _channelShiftMatrix(double r, double g, double b) => <double>[
      r, 0, 0, 0, 0, //
      0, g, 0, 0, 0, //
      0, 0, b, 0, 0, //
      0, 0, 0, 1, 0, //
    ];

List<double> _contrastMatrix(double c) {
  final t = (1 - c) * 0.5 * 255;
  return <double>[
    c, 0, 0, 0, t, //
    0, c, 0, 0, t, //
    0, 0, c, 0, t, //
    0, 0, 0, 1, 0, //
  ];
}

List<double> _saturationMatrix(double s) {
  const lr = 0.3086, lg = 0.6094, lb = 0.0820;
  final sr = (1 - s) * lr;
  final sg = (1 - s) * lg;
  final sb = (1 - s) * lb;
  return <double>[
    sr + s, sg, sb, 0, 0, //
    sr, sg + s, sb, 0, 0, //
    sr, sg, sb + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

List<double> _hueRotateMatrix(double degrees) {
  final rad = degrees * math.pi / 180;
  final c = math.cos(rad);
  final s = math.sin(rad);
  const lr = 0.213, lg = 0.715, lb = 0.072;
  return <double>[
    lr + c * (1 - lr) + s * (-lr),
    lg + c * (-lg) + s * (-lg),
    lb + c * (-lb) + s * (1 - lb),
    0,
    0,
    lr + c * (-lr) + s * 0.143,
    lg + c * (1 - lg) + s * 0.140,
    lb + c * (-lb) + s * (-0.283),
    0,
    0,
    lr + c * (-lr) + s * (-(1 - lr)),
    lg + c * (-lg) + s * lg,
    lb + c * (1 - lb) + s * lb,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _multiplyMatrix(List<double> a, List<double> b) {
  final out = List<double>.filled(20, 0);
  for (var row = 0; row < 4; row++) {
    for (var col = 0; col < 5; col++) {
      var sum = 0.0;
      for (var k = 0; k < 4; k++) {
        sum += a[row * 5 + k] * b[k * 5 + col];
      }
      if (col == 4) sum += a[row * 5 + 4];
      out[row * 5 + col] = sum;
    }
  }
  return out;
}

/* ==========================================================================
   Custom / saved swatches
   ========================================================================== */

/// Parsed representation of a stored custom swatch string.
@immutable
class ParsedCustomSwatch {
  const ParsedCustomSwatch({
    required this.name,
    required this.value,
    required this.isGradient,
    required this.raw,
  });

  final String name;
  final String value;
  final bool isGradient;
  final String raw;
}

bool _isGradientString(String v) =>
    v.startsWith('linear-gradient') ||
    v.startsWith('radial-gradient') ||
    v.startsWith('conic-gradient');

/// Parse a stored swatch item. Supports a JSON object (`{"name","hex"}`),
/// a CSS gradient string, or a plain hex/rgb string.
ParsedCustomSwatch parseCustomSwatchItem(String item, [int idx = 0]) {
  if (item.isEmpty) {
    return ParsedCustomSwatch(
      name: 'Custom ${idx + 1}',
      value: '#000000',
      isGradient: false,
      raw: '',
    );
  }
  final trimmed = item.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    try {
      final parsed = jsonDecode(trimmed);
      if (parsed is Map) {
        final val =
            (parsed['hex'] ?? parsed['value'] ?? '#000000').toString();
        final isGradient = _isGradientString(val);
        return ParsedCustomSwatch(
          name: (parsed['name'] ??
                  (isGradient ? 'Gradient' : 'Custom ${idx + 1}'))
              .toString(),
          value: val,
          isGradient: isGradient,
          raw: item,
        );
      }
    } catch (_) {
      // fall through
    }
  }
  final isGradient = _isGradientString(trimmed);
  return ParsedCustomSwatch(
    name: isGradient ? 'Gradient' : 'Custom ${idx + 1}',
    value: trimmed,
    isGradient: isGradient,
    raw: item,
  );
}

/// Encode a named solid/gradient swatch into the stored JSON string form.
String encodeCustomSwatch(String name, String hexOrCss) =>
    jsonEncode({'name': name, 'hex': hexOrCss});

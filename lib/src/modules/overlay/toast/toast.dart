/// Consona Toast — Top stack with clean slide-in and horizontal dismiss.
///
/// Features:
/// - Left **poster** slot (icon / image / custom widget)
/// - Built-in + **downstream-registerable** styles via [ConsonaToastController]
/// - [inverted] flips the ambient theme for that toast card
library;

import 'dart:async';

import 'package:flutter/material.dart' show Icons, Material;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../core/animation.dart';
import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../common/overlay_host.dart';

/// Built-in toast kinds — map to [ConsonaToastStyle] presets.
enum ConsonaToastVariant {
  info,
  success,
  warning,
  error,
}

/// Resolves colors + default poster for a toast card.
///
/// Downstream apps create custom styles with [ConsonaToastStyle.custom] and
/// register them on [ConsonaToastController.register], then call
/// `controller.show(styleId: '…')` or `controller.showAs('…')`.
class ConsonaToastStyle {
  const ConsonaToastStyle({
    required this.id,
    this.background,
    this.foreground,
    this.mutedForeground,
    this.borderColor,
    this.accent,
    this.posterBuilder,
  });

  final String id;

  /// Card fill. Defaults to [ConsonaColors.surface].
  final Color Function(ConsonaThemeData theme)? background;

  /// Title / message color. Defaults to [ConsonaColors.foreground].
  final Color Function(ConsonaThemeData theme)? foreground;

  /// Secondary text. Defaults to [ConsonaColors.mutedFg].
  final Color Function(ConsonaThemeData theme)? mutedForeground;

  /// Outline. Defaults to [ConsonaColors.borderLight].
  final Color Function(ConsonaThemeData theme)? borderColor;

  /// Poster well + action tint. Defaults to [ConsonaColors.primary].
  final Color Function(ConsonaThemeData theme)? accent;

  /// Default left poster when the entry does not supply one.
  final Widget? Function(BuildContext context, ConsonaThemeData theme)?
      posterBuilder;

  static Widget _iconPoster(IconData icon, Color color) {
    return Icon(
      icon,
      size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.sm),
      color: color,
    );
  }

  static final ConsonaToastStyle info = ConsonaToastStyle(
    id: 'info',
    accent: (t) => t.colors.primary,
    posterBuilder: (context, theme) =>
        _iconPoster(Icons.info_outline_rounded, theme.colors.primary),
  );

  static final ConsonaToastStyle success = ConsonaToastStyle(
    id: 'success',
    accent: (t) => t.colors.success,
    posterBuilder: (context, theme) => _iconPoster(
      Icons.check_circle_outline_rounded,
      theme.colors.success,
    ),
  );

  static final ConsonaToastStyle warning = ConsonaToastStyle(
    id: 'warning',
    accent: (t) => t.colors.warning,
    posterBuilder: (context, theme) =>
        _iconPoster(Icons.warning_amber_rounded, theme.colors.warning),
  );

  static final ConsonaToastStyle error = ConsonaToastStyle(
    id: 'error',
    accent: (t) => t.colors.danger,
    posterBuilder: (context, theme) =>
        _iconPoster(Icons.error_outline_rounded, theme.colors.danger),
  );

  static List<ConsonaToastStyle> get builtins =>
      [info, success, warning, error];

  /// Built-in style for a [ConsonaToastVariant].
  static ConsonaToastStyle ofVariant(ConsonaToastVariant variant) =>
      switch (variant) {
        ConsonaToastVariant.info => info,
        ConsonaToastVariant.success => success,
        ConsonaToastVariant.warning => warning,
        ConsonaToastVariant.error => error,
      };

  /// Downstream custom style.
  factory ConsonaToastStyle.custom({
    required String id,
    Color Function(ConsonaThemeData theme)? background,
    Color Function(ConsonaThemeData theme)? foreground,
    Color Function(ConsonaThemeData theme)? mutedForeground,
    Color Function(ConsonaThemeData theme)? borderColor,
    Color Function(ConsonaThemeData theme)? accent,
    Widget? Function(BuildContext context, ConsonaThemeData theme)?
        posterBuilder,
    IconData? icon,
  }) {
    final accentOf = accent ?? (t) => t.colors.primary;
    return ConsonaToastStyle(
      id: id,
      background: background,
      foreground: foreground,
      mutedForeground: mutedForeground,
      borderColor: borderColor,
      accent: accentOf,
      posterBuilder: posterBuilder ??
          (icon != null
              ? (context, theme) => _iconPoster(icon, accentOf(theme))
              : null),
    );
  }

  ConsonaToastStyle copyWith({
    String? id,
    Color Function(ConsonaThemeData theme)? background,
    Color Function(ConsonaThemeData theme)? foreground,
    Color Function(ConsonaThemeData theme)? mutedForeground,
    Color Function(ConsonaThemeData theme)? borderColor,
    Color Function(ConsonaThemeData theme)? accent,
    Widget? Function(BuildContext context, ConsonaThemeData theme)?
        posterBuilder,
  }) {
    return ConsonaToastStyle(
      id: id ?? this.id,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      borderColor: borderColor ?? this.borderColor,
      accent: accent ?? this.accent,
      posterBuilder: posterBuilder ?? this.posterBuilder,
    );
  }

  Color resolveBackground(ConsonaThemeData theme) =>
      background?.call(theme) ?? theme.colors.surface;

  Color resolveForeground(ConsonaThemeData theme) =>
      foreground?.call(theme) ?? theme.colors.foreground;

  Color resolveMuted(ConsonaThemeData theme) =>
      mutedForeground?.call(theme) ?? theme.colors.mutedFg;

  Color resolveBorder(ConsonaThemeData theme) =>
      borderColor?.call(theme) ?? theme.colors.borderLight;

  Color resolveAccent(ConsonaThemeData theme) =>
      accent?.call(theme) ?? theme.colors.primary;
}

class ConsonaToastEntry {
  ConsonaToastEntry({
    required this.id,
    required this.message,
    this.title,
    ConsonaToastStyle? style,
    this.poster,
    this.inverted = false,
    this.duration = const Duration(milliseconds: 3500),
    this.actionLabel,
    this.onAction,
  }) : style = style ?? ConsonaToastStyle.info;

  final String id;
  final String message;
  final String? title;
  final ConsonaToastStyle style;

  /// Optional left poster (icon, image, avatar…). Overrides [style]'s default.
  final Widget? poster;

  /// When true, the toast card uses [ConsonaThemeData.invert].
  final bool inverted;

  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Built-in style id → [ConsonaToastVariant], or null for custom styles.
  ConsonaToastVariant? get variant {
    return switch (style.id) {
      'info' => ConsonaToastVariant.info,
      'success' => ConsonaToastVariant.success,
      'warning' => ConsonaToastVariant.warning,
      'error' => ConsonaToastVariant.error,
      _ => null,
    };
  }
}

/// Controller managing toast queues, styles, and auto-dismiss timers.
class ConsonaToastController extends ChangeNotifier {
  static const int maxVisible = 3;

  ConsonaToastController() {
    for (final style in ConsonaToastStyle.builtins) {
      _styles[style.id] = style;
    }
  }

  /// Ambient controller from the nearest [ConsonaToastScope].
  static ConsonaToastController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ConsonaToastScope>();
    if (scope == null) {
      throw StateError(
        'No ConsonaToastScope found. Wrap the app with ConsonaToastLayer '
        '(e.g. in MaterialApp.builder).',
      );
    }
    return scope.controller;
  }

  /// Ambient controller, or null when no toast scope is present.
  static ConsonaToastController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConsonaToastScope>()?.controller;
  }

  final List<ConsonaToastEntry> _entries = [];
  final Map<String, Timer> _timers = {};
  final Map<String, ConsonaToastStyle> _styles = {};
  int _counter = 0;

  List<ConsonaToastEntry> get entries => List.unmodifiable(_entries);

  /// Registered style ids (built-ins + downstream).
  Set<String> get styleIds => Set.unmodifiable(_styles.keys);

  ConsonaToastStyle? styleOf(String id) => _styles[id];

  /// Register or replace a downstream toast style.
  void register(ConsonaToastStyle style) {
    _styles[style.id] = style;
  }

  /// Remove a previously registered custom style (built-ins stay).
  void unregister(String id) {
    if (ConsonaToastStyle.builtins.any((s) => s.id == id)) return;
    _styles.remove(id);
  }

  void show({
    required String message,
    String? title,
    ConsonaToastVariant variant = ConsonaToastVariant.info,
    ConsonaToastStyle? style,
    String? styleId,
    Widget? poster,
    IconData? icon,
    ImageProvider? posterImage,
    bool inverted = false,
    Duration duration = const Duration(milliseconds: 3500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final resolvedStyle = style ??
        (styleId != null ? _styles[styleId] : null) ??
        ConsonaToastStyle.ofVariant(variant);

    final resolvedPoster = poster ??
        (posterImage != null
            ? _ToastPosterImage(image: posterImage)
            : null) ??
        (icon != null
            ? Icon(
                icon,
                size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.sm),
              )
            : null);

    _counter++;
    final id = 'toast_$_counter';
    final entry = ConsonaToastEntry(
      id: id,
      message: message,
      title: title,
      style: resolvedStyle,
      poster: resolvedPoster,
      inverted: inverted,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    var next = [entry, ..._entries];
    while (next.length > maxVisible) {
      final removed = next.removeLast();
      _timers.remove(removed.id)?.cancel();
    }
    _entries
      ..clear()
      ..addAll(next);

    _timers[id]?.cancel();
    _timers[id] = Timer(duration, () => dismiss(id));
    notifyListeners();
  }

  /// Show a registered style by id.
  void showAs(
    String styleId, {
    required String message,
    String? title,
    Widget? poster,
    IconData? icon,
    ImageProvider? posterImage,
    bool inverted = false,
    Duration duration = const Duration(milliseconds: 3500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      message: message,
      title: title,
      styleId: styleId,
      poster: poster,
      icon: icon,
      posterImage: posterImage,
      inverted: inverted,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    final before = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length != before) notifyListeners();
  }

  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _entries.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}

class _ToastPosterImage extends StatelessWidget {
  const _ToastPosterImage({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      fit: BoxFit.cover,
      width: 36,
      height: 36,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Provides an ambient [ConsonaToastController] to descendants.
class ConsonaToastScope extends InheritedWidget {
  const ConsonaToastScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ConsonaToastController controller;

  @override
  bool updateShouldNotify(ConsonaToastScope oldWidget) =>
      controller != oldWidget.controller;
}

/// App-level toast host for [MaterialApp.builder].
///
/// Owns a [ConsonaToastController], exposes it via [ConsonaToastScope] to
/// [child], and paints [ConsonaToastStack] above the route tree.
class ConsonaToastLayer extends StatefulWidget {
  const ConsonaToastLayer({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final ConsonaToastController? controller;

  @override
  State<ConsonaToastLayer> createState() => _ConsonaToastLayerState();
}

class _ConsonaToastLayerState extends State<ConsonaToastLayer> {
  ConsonaToastController? _owned;

  ConsonaToastController get _controller =>
      widget.controller ?? (_owned ??= ConsonaToastController());

  @override
  void dispose() {
    _owned?.dispose();
    _owned = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConsonaToastScope(
      controller: _controller,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          ConsonaToastStack(controller: _controller),
        ],
      ),
    );
  }
}

/// Floating toast host — one shared layout clock for enter + stack shift.
///
/// Requires an explicit [controller] (typically from [ConsonaToastLayer]).
class ConsonaToastStack extends StatefulWidget {
  const ConsonaToastStack({
    super.key,
    required this.controller,
  });

  final ConsonaToastController controller;

  @override
  State<ConsonaToastStack> createState() => _ConsonaToastStackState();
}

class _ConsonaToastStackState extends State<ConsonaToastStack>
    with SingleTickerProviderStateMixin {
  static const _gap = ConsonaSpacing.xs;
  static const _fallbackHeight = 64.0;
  static const _animDuration = Duration(milliseconds: 320);

  late final AnimationController _layout;
  final _heights = <String, double>{};
  final _fromTop = <String, double>{};
  final _toTop = <String, double>{};
  var _items = <ConsonaToastEntry>[];

  ConsonaToastController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _layout = AnimationController(vsync: this, duration: _animDuration)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _controller.addListener(_onController);
    _sync(_controller.entries, animate: false);
  }

  @override
  void didUpdateWidget(covariant ConsonaToastStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      _controller.addListener(_onController);
      _sync(_controller.entries, animate: false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _layout.dispose();
    super.dispose();
  }

  void _onController() => _sync(_controller.entries);

  double _heightOf(String id) => _heights[id] ?? _fallbackHeight;

  /// Visual top at the current layout clock (used as the next animation's from).
  double _visualTop(String id) {
    final to = _toTop[id];
    if (to == null) return 0;
    final from = _fromTop[id] ?? to;
    final t = ConsonaCurves.subtleEase.transform(_layout.value);
    return from + (to - from) * t;
  }

  double _stackHeight() {
    if (_items.isEmpty) return 0;
    var y = 0.0;
    for (var i = 0; i < _items.length; i++) {
      y += _heightOf(_items[i].id);
      if (i < _items.length - 1) y += _gap;
    }
    // Extra headroom so the incoming toast can sit above 0 while entering.
    return y + _fallbackHeight;
  }

  void _writeTargets({required Set<String> entering}) {
    var y = 0.0;
    for (final entry in _items) {
      final id = entry.id;
      final h = _heightOf(id);
      final target = y;
      if (entering.contains(id)) {
        // Slide in from directly above its resting slot — same delta siblings shift.
        _fromTop[id] = target - h - _gap;
      } else {
        _fromTop[id] = _toTop.containsKey(id) ? _visualTop(id) : target;
      }
      _toTop[id] = target;
      y += h + _gap;
    }
  }

  void _sync(List<ConsonaToastEntry> next, {bool animate = true}) {
    final prevIds = _items.map((e) => e.id).toSet();
    final nextIds = next.map((e) => e.id).toSet();
    final entering = nextIds.difference(prevIds);
    final leaving = prevIds.difference(nextIds);

    for (final id in leaving) {
      _heights.remove(id);
      _fromTop.remove(id);
      _toTop.remove(id);
    }
    for (final id in entering) {
      _heights.putIfAbsent(id, () => _fallbackHeight);
    }

    _items = List<ConsonaToastEntry>.from(next);
    _writeTargets(entering: entering);

    if (!mounted) return;

    final shouldAnimate = animate &&
        (entering.isNotEmpty || leaving.isNotEmpty || _items.isNotEmpty);
    if (shouldAnimate && (entering.isNotEmpty || leaving.isNotEmpty)) {
      _layout
        ..duration = _animDuration
        ..forward(from: 0);
    } else if (!animate) {
      _layout.value = 1;
      for (final id in _toTop.keys) {
        _fromTop[id] = _toTop[id]!;
      }
    }
    setState(() {});
  }

  void _onMeasuredHeight(String id, double height) {
    final prev = _heights[id] ?? _fallbackHeight;
    if ((prev - height).abs() < 0.5) return;
    _heights[id] = height;
    // Re-target from the live visual tops so height correction stays in sync.
    _writeTargets(entering: const {});
    _layout.forward(from: 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final theme = ConsonaTheme.of(context);
    final top = MediaQuery.paddingOf(context).top + ConsonaSpacing.sm;
    final t = ConsonaCurves.subtleEase.transform(_layout.value);
    final maxToastWidth = theme.components.overlay.maxToastWidth;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: _stackHeight(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxToastWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.md),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final entry in _items)
                  Positioned(
                    key: ValueKey(entry.id),
                    top: () {
                      final to = _toTop[entry.id] ?? 0;
                      final from = _fromTop[entry.id] ?? to;
                      return from + (to - from) * t;
                    }(),
                    left: 0,
                    right: 0,
                    child: _MeasureHeight(
                      onHeight: (h) => _onMeasuredHeight(entry.id, h),
                      child: _ConsonaToastTile(
                        entry: entry,
                        onDismiss: () => _controller.dismiss(entry.id),
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

class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({
    required this.onHeight,
    required Widget child,
  }) : super(child: child);

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureHeight(onHeight: onHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureHeight renderObject,
  ) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight({required this.onHeight});

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final next = size.height;
    if (_last == next) return;
    _last = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onHeight(next);
    });
  }
}

/// Horizontal-drag dismissible toast card.
class _ConsonaToastTile extends StatefulWidget {
  const _ConsonaToastTile({
    required this.entry,
    required this.onDismiss,
  });

  final ConsonaToastEntry entry;
  final VoidCallback onDismiss;

  @override
  State<_ConsonaToastTile> createState() => _ConsonaToastTileState();
}

class _ConsonaToastTileState extends State<_ConsonaToastTile>
    with SingleTickerProviderStateMixin {
  static const _threshold = 72.0;
  static const _fling = 520.0;

  late final AnimationController _exit;
  double _dragX = 0;
  var _exiting = false;
  double _exitDir = 1;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _exiting) {
          widget.onDismiss();
        }
      });
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  void _beginExit(double direction) {
    if (_exiting) return;
    _exiting = true;
    _exitDir = direction >= 0 ? 1.0 : -1.0;
    ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
    _exit.forward(from: 0);
    setState(() {});
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_exiting) return;
    setState(() => _dragX += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_exiting) return;
    final v = d.primaryVelocity ?? 0;
    final dir = _dragX.abs() < 1
        ? (v >= 0 ? 1.0 : -1.0)
        : (_dragX >= 0 ? 1.0 : -1.0);
    if (_dragX.abs() > _threshold || v.abs() > _fling) {
      _beginExit(dir);
      return;
    }
    setState(() => _dragX = 0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        final t = ConsonaCurves.subtleEase.transform(_exit.value);
        final x = _exiting
            ? _dragX + (_exitDir * (width + 32) - _dragX) * t
            : _dragX;
        return Transform.translate(
          offset: Offset(x, 0),
          child: child,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: () {
          if (!_exiting) setState(() => _dragX = 0);
        },
        child: _ConsonaToastCard(
          entry: widget.entry,
          onDismiss: () => _beginExit(1.0),
        ),
      ),
    );
  }
}

class _ConsonaToastCard extends StatelessWidget {
  const _ConsonaToastCard({
    required this.entry,
    required this.onDismiss,
  });

  final ConsonaToastEntry entry;
  final VoidCallback onDismiss;

  static const _posterSize = 36.0;

  @override
  Widget build(BuildContext context) {
    final ambient = ConsonaTheme.of(context);
    final theme = entry.inverted ? ambient.invert() : ambient;
    final style = entry.style;
    final accent = style.resolveAccent(theme);
    final fg = style.resolveForeground(theme);
    final bg = style.resolveBackground(theme);
    final border = style.resolveBorder(theme);

    final poster = entry.poster ?? style.posterBuilder?.call(context, theme);

    final side = theme.border
        .resolveSide(ConsonaBorderRole.subtle, context: context)
        .copyWith(color: border);

    final card = Semantics(
      liveRegion: true,
      label: entry.title != null
          ? '${entry.title}: ${entry.message}'
          : entry.message,
      child: Material(
        color: bg,
        elevation: 0,
        shape: theme.radius.resolveShape(ConsonaRadiusRole.base, side: side),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(ConsonaSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (poster != null) ...[
                _ToastPosterWell(
                  size: _posterSize,
                  accent: accent,
                  // Tinted well only for stock icon posters — never behind
                  // custom avatars / images supplied by the caller.
                  tinted: entry.poster == null,
                  child: poster,
                ),
                const SizedBox(width: ConsonaSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.title != null) ...[
                      ConsonaOverlayText(
                        entry.title!,
                        maxLines: 1,
                        style: theme.typography.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: ConsonaSpacing.xxs),
                    ],
                    ConsonaOverlayText(
                      entry.message,
                      maxLines: 3,
                      style: theme.typography.body.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
              if (entry.actionLabel != null && entry.onAction != null) ...[
                const SizedBox(width: ConsonaSpacing.sm),
                GestureDetector(
                  onTap: () {
                    entry.onAction!();
                    onDismiss();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: ConsonaOverlayText(
                    entry.actionLabel!,
                    maxLines: 1,
                    style: theme.typography.label.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!entry.inverted) return card;

    return ConsonaThemeScope(theme: theme, child: card);
  }
}

class _ToastPosterWell extends StatelessWidget {
  const _ToastPosterWell({
    required this.size,
    required this.accent,
    required this.tinted,
    required this.child,
  });

  final double size;
  final Color accent;
  final bool tinted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final isBitmap = child is Image || child is _ToastPosterImage;

    if (!tinted) {
      // Custom poster (avatar, photo, …) — no chrome, just a fixed slot.
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: isBitmap ? SizedBox.expand(child: child) : child,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accent.withAlpha((255 * 0.12).round()),
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
      ),
      child: IconTheme.merge(
        data: IconThemeData(
          color: accent,
          size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.sm),
        ),
        child: child,
      ),
    );
  }
}

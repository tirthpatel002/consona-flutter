/// Consona CommandPalette — Responsive Spotlight (⌘K) search & action launcher.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/input/search_field.dart';
import '../../core/typography/kbd.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../common/overlay_host.dart';

/// A single actionable command entry in [ConsonaCommandPalette].
@immutable
class ConsonaCommandItem {
  const ConsonaCommandItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.category,
    this.shortcut,
    this.icon,
    this.onSelected,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? category;
  final String? shortcut;
  final Widget? icon;
  final VoidCallback? onSelected;
}

/// Spotlight (`⌘K` / `Ctrl+K`) command launcher supporting instant query
/// filtering, grouped categories, keyboard Up/Down/Enter navigation, and
/// [ConsonaKbd] shortcut pills.
///
/// Opens as a centered spotlight card on every viewport.
class ConsonaCommandPalette extends StatefulWidget {
  const ConsonaCommandPalette({
    super.key,
    required this.items,
    this.placeholder = 'Type a command or search…',
    this.onSelected,
    this.maxHeight = 360.0,
  });

  final List<ConsonaCommandItem> items;
  final String placeholder;
  final ValueChanged<ConsonaCommandItem>? onSelected;
  final double maxHeight;

  /// Presents a centered [ConsonaCommandPalette]. The route supplies Material
  /// and a text style so debug builds do not paint the fallback yellow
  /// double underline under the command text.
  static Future<ConsonaCommandItem?> show(
    BuildContext context, {
    required List<ConsonaCommandItem> items,
    String placeholder = 'Type a command or search…',
  }) {
    final theme = ConsonaTheme.of(context);
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap),
    );

    return showConsonaOverlay<ConsonaCommandItem>(
      context: context,
      barrierDismissible: true,
      transitionDuration: consonaOverlayMotionDuration(motion.duration),
      builder: (routeContext, animation) {
        final screen = MediaQuery.sizeOf(routeContext);
        final insets = MediaQuery.viewInsetsOf(routeContext);
        final colors = ConsonaTheme.of(routeContext).colors;
        final cardWidth = math.min(540.0, math.max(0.0, screen.width - 48.0));
        final availableHeight = math.max(
          0.0,
          screen.height - insets.vertical - (ConsonaSpacing.lg * 2),
        );
        // Search row plus padding sits above the scrolling list.
        final listHeight = math.min(360.0, math.max(0.0, availableHeight - 88.0));

        return Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: animation,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(routeContext).maybePop(),
                child: ColoredBox(color: colors.foreground.withAlpha(90)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ConsonaSpacing.lg,
                ConsonaSpacing.lg,
                ConsonaSpacing.lg,
                ConsonaSpacing.lg + insets.bottom,
              ),
              child: Center(
                child: ConsonaSurfaceReveal(
                  animation: animation,
                  alignment: Alignment.center,
                  beginScale: 0.94,
                  beginOffset: const Offset(0, 0.08),
                  child: SizedBox(
                    width: cardWidth,
                    child: ConsonaCommandPalette(
                      items: items,
                      placeholder: placeholder,
                      maxHeight: listHeight,
                      onSelected: (item) {
                        Navigator.of(routeContext).maybePop(item);
                        item.onSelected?.call();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  State<ConsonaCommandPalette> createState() => _ConsonaCommandPaletteState();
}

class _ConsonaCommandPaletteState extends State<ConsonaCommandPalette> {
  String _query = '';
  int _activeIndex = 0;

  List<ConsonaCommandItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) {
      return item.title.toLowerCase().contains(q) ||
          (item.subtitle?.toLowerCase().contains(q) ?? false) ||
          (item.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _triggerItem(ConsonaCommandItem item) {
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    if (widget.onSelected != null) {
      widget.onSelected!(item);
    } else {
      item.onSelected?.call();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final list = _filtered;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && list.isNotEmpty) {
      setState(() => _activeIndex = (_activeIndex + 1) % list.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && list.isNotEmpty) {
      setState(
        () => _activeIndex = (_activeIndex - 1 + list.length) % list.length,
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter && list.isNotEmpty) {
      final idx = _activeIndex.clamp(0, list.length - 1);
      _triggerItem(list[idx]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final list = _filtered;
    final safeIdx = list.isEmpty ? 0 : _activeIndex.clamp(0, list.length - 1);

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
          border: theme.border.resolve(
            ConsonaBorderRole.surfaceEdge,
            context: context,
          ),
          boxShadow: theme.shadow.resolve(ConsonaShadowLevel.strong),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(ConsonaSpacing.sm * scale),
              child: ConsonaSearchField(
                placeholder: widget.placeholder,
                onChanged: (q) => setState(() {
                  _query = q;
                  _activeIndex = 0;
                }),
              ),
            ),
            Container(
              height: theme.stroke.resolveWidth(context),
              color: colors.borderLight,
            ),
            if (list.isEmpty)
              Padding(
                padding: EdgeInsets.all(ConsonaSpacing.xl * scale),
                child: Text(
                  'No matching commands found.',
                  textAlign: TextAlign.center,
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxHeight * scale),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(ConsonaSpacing.xs * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < list.length; i++) ...[
                        if (list[i].category != null &&
                            (i == 0 ||
                                list[i - 1].category != list[i].category))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              ConsonaSpacing.sm,
                              ConsonaSpacing.xs,
                              ConsonaSpacing.sm,
                              ConsonaSpacing.xxs,
                            ),
                            child: Text(
                              list[i].category!,
                              style: theme.typography.caption.copyWith(
                                color: colors.mutedFg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        _buildCommandRow(
                          context,
                          list[i],
                          i,
                          i == safeIdx,
                          scale,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandRow(
    BuildContext context,
    ConsonaCommandItem item,
    int index,
    bool isActive,
    double scale,
  ) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    return Semantics(
      button: true,
      selected: isActive,
      label: item.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _activeIndex = index),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _triggerItem(item),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ConsonaSpacing.sm * scale,
              vertical: ConsonaSpacing.sm * scale,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? colors.primary.withAlpha(24)
                  : colors.surface.withAlpha(0),
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
            ),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      size: 16 * scale,
                      color: isActive ? colors.primary : colors.mutedFg,
                    ),
                    child: item.icon!,
                  ),
                  const SizedBox(width: ConsonaSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: theme.typography.label.copyWith(
                          color: colors.foreground,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          style: theme.typography.caption.copyWith(
                            color: colors.mutedFg,
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.shortcut != null) ...[
                  const SizedBox(width: ConsonaSpacing.sm),
                  ConsonaKbd(item.shortcut!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

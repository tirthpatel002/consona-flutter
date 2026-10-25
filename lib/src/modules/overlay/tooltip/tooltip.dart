/// Consona Tooltip — Long-press callout with slide reveal (no fade).
library;

import 'dart:async';
import 'package:flutter/widgets.dart';

import '../../../core/animation.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../common/overlay_host.dart';

/// Tactile callout balloon tooltip supporting both desktop mouse hover and
/// mobile long-press.
class ConsonaTooltip extends StatefulWidget {
  const ConsonaTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration = const Duration(milliseconds: 500),
  });

  final String message;
  final Widget child;
  final Duration waitDuration;

  @override
  State<ConsonaTooltip> createState() => _ConsonaTooltipState();
}

class _ConsonaTooltipState extends State<ConsonaTooltip>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  Timer? _hoverTimer;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _hide(immediate: true);
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    if (!mounted) return;
    if (_entry != null) {
      _controller.forward();
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final screen = MediaQuery.sizeOf(context);

    _entry = OverlayEntry(
      builder: (context) {
        final left = (offset.dx + (size.width / 2) - 72.0)
            .clamp(12.0, screen.width - 156.0);
        return Stack(
          children: [
            Positioned(
              left: left,
              top: (offset.dy - 40.0).clamp(8.0, screen.height - 48.0),
              child: IgnorePointer(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.35),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: ConsonaCurves.subtleEase,
                      reverseCurve: ConsonaCurves.easeOut,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ConsonaSpacing.sm,
                        vertical: ConsonaSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.foreground,
                        borderRadius:
                            theme.radius.resolve(ConsonaRadiusRole.atom),
                        boxShadow:
                            theme.shadow.resolve(ConsonaShadowLevel.subtle),
                      ),
                      child: ConsonaOverlayText(
                        widget.message,
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        style: theme.typography.caption.copyWith(
                          color: colors.background,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_entry!);
    _controller.forward(from: 0);
  }

  void _hide({bool immediate = false}) {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    if (_entry == null) return;
    if (immediate) {
      _entry?.remove();
      _entry = null;
      return;
    }
    _controller.reverse().then((_) {
      if (_controller.status == AnimationStatus.dismissed) {
        _entry?.remove();
        _entry = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: widget.message,
      child: MouseRegion(
        onEnter: (_) {
          _hoverTimer?.cancel();
          _hoverTimer = Timer(widget.waitDuration, _show);
        },
        onExit: (_) => _hide(),
        child: GestureDetector(
          onLongPress: _show,
          onLongPressEnd: (_) => _hide(),
          onTapDown: (_) => _hide(),
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
      ),
    );
  }
}

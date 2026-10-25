/// Consona Link — Inline text action with underline intents and spring press.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';

/// Underline decoration ramp for [ConsonaLink].
enum ConsonaLinkUnderline { none, hover, always }

/// Inline navigational / action text — lighter than [ConsonaButton.plain],
/// with underline and external-affordance support.
class ConsonaLink extends StatefulWidget {
  const ConsonaLink({
    super.key,
    required this.label,
    this.onTap,
    this.intent = ConsonaIntent.primary,
    this.underline = ConsonaLinkUnderline.hover,
    this.size = ConsonaOpticalSize.sm,
    this.leading,
    this.trailing,
    this.external = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final ConsonaIntent intent;
  final ConsonaLinkUnderline underline;
  final ConsonaOpticalSize size;
  final Widget? leading;
  final Widget? trailing;
  final bool external;
  final bool enabled;

  @override
  State<ConsonaLink> createState() => _ConsonaLinkState();
}

class _ConsonaLinkState extends State<ConsonaLink> {
  bool _hovered = false;
  bool _focused = false;

  Color _resolveColor(BuildContext context) {
    final colors = ConsonaTheme.of(context).colors;
    return switch (widget.intent) {
      ConsonaIntent.primary => colors.primary,
      ConsonaIntent.danger => colors.danger,
      ConsonaIntent.success => colors.success,
      ConsonaIntent.warning => colors.warning,
      ConsonaIntent.subtle || ConsonaIntent.secondary => colors.mutedFg,
      ConsonaIntent.plain || ConsonaIntent.ghost => colors.foreground,
      _ => colors.foreground,
    };
  }

  bool get _showUnderline {
    switch (widget.underline) {
      case ConsonaLinkUnderline.always:
        return true;
      case ConsonaLinkUnderline.hover:
        return _hovered || _focused;
      case ConsonaLinkUnderline.none:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final optical = widget.size.standardEquivalent;
    final scale = theme.density.factor;
    final color = _resolveColor(context);
    final interactive = widget.enabled && widget.onTap != null;
    final fontSize = ConsonaGeometries.fontSizeFor(optical) * scale;
    final iconSize = ConsonaGeometries.iconSizeFor(
          optical == ConsonaOpticalSize.lg
              ? ConsonaOpticalSize.sm
              : ConsonaOpticalSize.xs,
        ) *
        scale;

    final text = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.body.copyWith(
        color: color.withAlpha(interactive ? 255 : (255 * ConsonaOpacities.disabled).round()),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.25,
        decoration: _showUnderline ? TextDecoration.underline : TextDecoration.none,
        decorationColor: color,
        decorationThickness: 1.15,
      ),
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leading != null) ...[
          IconTheme(
            data: IconThemeData(size: iconSize, color: color),
            child: widget.leading!,
          ),
          SizedBox(width: ConsonaSpacing.xxs * scale),
        ],
        Flexible(child: text),
        if (widget.trailing != null || widget.external) ...[
          SizedBox(width: ConsonaSpacing.xxs * scale),
          IconTheme(
            data: IconThemeData(size: iconSize, color: color),
            child: widget.trailing ??
                Icon(Icons.open_in_new_rounded, size: iconSize, color: color),
          ),
        ],
      ],
    );

    return Semantics(
      link: true,
      button: true,
      enabled: interactive,
      label: widget.label,
      child: ConsonaHitTarget(
        inflateLayout: false,
        child: ConsonaSpringPress(
          enabled: interactive,
          feedbackEvent: FeedbackEvent.tap,
          pressedScale: 0.97,
          onHoverChanged: (v) => setState(() => _hovered = v),
          onFocusChanged: (v) => setState(() => _focused = v),
          onTap: interactive ? widget.onTap : null,
          mouseCursor:
              interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: child,
        ),
      ),
    );
  }
}

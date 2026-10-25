/// Consona Hit Target — Enforced 44pt/48dp touch accessibility boundary
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Wraps interactive elements to enforce platform-minimum touch targets
/// (44×44pt on iOS/macOS, 48×48dp on Android/others).
///
/// By default the layout box grows to [minSize]. Set [inflateLayout] to
/// `false` when the visual chrome must stay tight (e.g. nav pills) — the
/// hit-test area still expands to [minSize], centered on the child.
class ConsonaHitTarget extends SingleChildRenderObjectWidget {
  const ConsonaHitTarget({
    super.key,
    required Widget child,
    this.minSize,
    this.inflateLayout = true,
  }) : super(child: child);

  /// Optional override for the target box size.
  final Size? minSize;

  /// When `true` (default), the layout box is at least [minSize].
  /// When `false`, layout hugs the child; only hit-testing expands.
  final bool inflateLayout;

  static Size defaultMinSize(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => const Size(44, 44),
      _ => const Size(48, 48),
    };
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderConsonaHitTarget(
      minSize: minSize ?? defaultMinSize(defaultTargetPlatform),
      inflateLayout: inflateLayout,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final target = renderObject as _RenderConsonaHitTarget;
    target
      ..minSize = minSize ?? defaultMinSize(defaultTargetPlatform)
      ..inflateLayout = inflateLayout;
  }
}

class _RenderConsonaHitTarget extends RenderProxyBox {
  _RenderConsonaHitTarget({
    required Size minSize,
    required bool inflateLayout,
  })  : _minSize = minSize,
        _inflateLayout = inflateLayout;

  Size _minSize;
  Size get minSize => _minSize;
  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  bool _inflateLayout;
  bool get inflateLayout => _inflateLayout;
  set inflateLayout(bool value) {
    if (_inflateLayout == value) return;
    _inflateLayout = value;
    markNeedsLayout();
  }

  Offset get _childOffset {
    final child = this.child;
    if (child == null || !_inflateLayout) return Offset.zero;
    return Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final childMin = super.computeMinIntrinsicWidth(height);
    return _inflateLayout ? math.max(childMin, _minSize.width) : childMin;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final childMin = super.computeMinIntrinsicHeight(width);
    return _inflateLayout ? math.max(childMin, _minSize.height) : childMin;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    if (_inflateLayout) {
      final enforced = constraints.enforce(
        BoxConstraints(minWidth: _minSize.width, minHeight: _minSize.height),
      );
      child.layout(enforced.loosen(), parentUsesSize: true);
      size = constraints.constrain(
        Size(
          math.max(child.size.width, _minSize.width),
          math.max(child.size.height, _minSize.height),
        ),
      );
    } else {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    context.paintChild(child, offset + _childOffset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final hitW = math.max(size.width, _minSize.width);
    final hitH = math.max(size.height, _minSize.height);
    final origin = Offset((size.width - hitW) / 2, (size.height - hitH) / 2);
    final hitRect = origin & Size(hitW, hitH);
    if (!hitRect.contains(position)) return false;

    final child = this.child;
    if (child != null) {
      final childOffset = _childOffset;
      final local = position - childOffset;
      final clamped = Offset(
        local.dx.clamp(0.0, child.size.width),
        local.dy.clamp(0.0, child.size.height),
      );
      child.hitTest(result, position: clamped);
    }

    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final childOffset = _childOffset;
    return result.addWithPaintOffset(
      offset: childOffset,
      position: position,
      hitTest: (BoxHitTestResult res, Offset transformed) {
        return child.hitTest(res, position: transformed);
      },
    );
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    transform.translateByDouble(_childOffset.dx, _childOffset.dy, 0, 1);
  }
}

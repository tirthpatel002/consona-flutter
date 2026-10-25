/// Consona InfiniteScroll — Threshold-driven load-more list with footer states.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../loader/loader.dart';
import '../typography/text.dart';

/// Scrollable list that requests the next page when the user nears the end.
class ConsonaInfiniteScroll<T> extends StatefulWidget {
  const ConsonaInfiniteScroll({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    this.hasMore = true,
    this.loading = false,
    this.threshold = 240,
    this.padding,
    this.separatorBuilder,
    this.emptyBuilder,
    this.endBuilder,
    this.errorBuilder,
    this.error = false,
    this.onRetry,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final FutureOr<void> Function() onLoadMore;
  final bool hasMore;
  final bool loading;
  final double threshold;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? endBuilder;
  final WidgetBuilder? errorBuilder;
  final bool error;
  final VoidCallback? onRetry;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  State<ConsonaInfiniteScroll<T>> createState() =>
      _ConsonaInfiniteScrollState<T>();
}

class _ConsonaInfiniteScrollState<T> extends State<ConsonaInfiniteScroll<T>> {
  ScrollController? _owned;
  bool _requestInFlight = false;

  ScrollController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = ScrollController();
    }
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ConsonaInfiniteScroll<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      _owned?.removeListener(_onScroll);
      if (widget.controller == null) {
        _owned ??= ScrollController();
      } else {
        _owned?.dispose();
        _owned = null;
      }
      _controller.addListener(_onScroll);
    }
    if (!widget.loading) _requestInFlight = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _owned?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (!widget.hasMore || widget.loading || widget.error || _requestInFlight) {
      return;
    }
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - widget.threshold) {
      _requestInFlight = true;
      final result = widget.onLoadMore();
      if (result is Future) {
        unawaited(result.whenComplete(() {
          _requestInFlight = false;
        }));
      } else {
        _requestInFlight = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);

    if (widget.items.isEmpty && !widget.loading) {
      return widget.emptyBuilder?.call(context) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.xl),
              child: ConsonaText.caption(
                'Nothing here yet',
                color: theme.colors.mutedFg,
              ),
            ),
          );
    }

    final showFooter = widget.loading ||
        widget.error ||
        (!widget.hasMore && widget.items.isNotEmpty);

    return ListView.separated(
      controller: _controller,
      physics: widget.physics ?? const BouncingScrollPhysics(),
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding ??
          EdgeInsets.all(ConsonaSpacing.md * theme.density.factor),
      itemCount: widget.items.length + (showFooter ? 1 : 0),
      separatorBuilder: (context, index) {
        if (index >= widget.items.length - 1 && showFooter) {
          return const SizedBox.shrink();
        }
        return widget.separatorBuilder?.call(context, index) ??
            SizedBox(height: ConsonaSpacing.sm * theme.density.factor);
      },
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return _buildFooter(context);
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    if (widget.error) {
      return widget.errorBuilder?.call(context) ??
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ConsonaSpacing.md),
            child: Center(
              child: GestureDetector(
                onTap: widget.onRetry,
                child: Text(
                  'Couldn’t load more · Tap to retry',
                  style: theme.typography.caption.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
    }

    if (widget.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: ConsonaSpacing.md),
        child: Center(child: ConsonaLoader()),
      );
    }

    return widget.endBuilder?.call(context) ??
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ConsonaSpacing.md),
          child: Center(
            child: Text(
              'You’re all caught up',
              style: theme.typography.caption.copyWith(color: colors.mutedFg),
            ),
          ),
        );
  }
}

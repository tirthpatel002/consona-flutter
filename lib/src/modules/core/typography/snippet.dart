/// Consona Snippet — Monospace code/token block with copy, collapse, and multi-tab shells.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/motion.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../button/icon_button.dart';

/// Display mode for [ConsonaSnippet].
enum ConsonaSnippetVariant { inline, block }

/// One language / file pane inside a multi-tab [ConsonaSnippet].
class ConsonaSnippetTab {
  const ConsonaSnippetTab({
    required this.id,
    required this.label,
    required this.code,
    this.language,
  });

  /// Stable key used for selection.
  final String id;

  /// Tab chrome label (e.g. `Dart`, `Swift`, `package.json`).
  final String label;

  /// Source shown and copied when this tab is active.
  final String code;

  /// Optional language hint for single-pane headers.
  final String? language;
}

/// Copyable monospace snippet for tokens, commands, and short code.
///
/// Pass [code] for a single pane, or [tabs] for a multi-language / multi-file
/// shell with a sliding underline indicator.
class ConsonaSnippet extends StatefulWidget {
  const ConsonaSnippet({
    super.key,
    this.code,
    this.language,
    this.tabs,
    this.selectedTabId,
    this.onTabChanged,
    this.variant = ConsonaSnippetVariant.block,
    this.maxLines = 8,
    this.maxHeight = 280,
    this.showCopy = true,
    this.collapsed,
    this.onCollapsedChanged,
  }) : assert(
          code != null || tabs != null,
          'Provide code or a tabs list',
        );

  /// Single-pane source. Ignored when [tabs] is non-empty.
  final String? code;

  /// Language hint for single-pane mode.
  final String? language;

  /// Multi-pane definitions. When length > 1, renders a tab bar.
  final List<ConsonaSnippetTab>? tabs;

  /// Controlled active tab id. Defaults to the first tab.
  final String? selectedTabId;

  /// Called when the user selects another tab.
  final ValueChanged<String>? onTabChanged;

  final ConsonaSnippetVariant variant;

  /// Visible line budget while collapsed.
  final int maxLines;

  /// Viewport height for the expanded (or always-tall) code pane — enables
  /// vertical scrolling when content exceeds this.
  final double maxHeight;

  final bool showCopy;
  final bool? collapsed;
  final ValueChanged<bool>? onCollapsedChanged;

  @override
  State<ConsonaSnippet> createState() => _ConsonaSnippetState();
}

class _ConsonaSnippetState extends State<ConsonaSnippet> {
  bool _copied = false;
  bool _localCollapsed = true;
  late String _localTabId;
  Timer? _timer;

  final Map<String, GlobalKey> _tabKeys = {};
  final GlobalKey _tabStackKey = GlobalKey();
  final ScrollController _tabScroll = ScrollController();
  final ScrollController _codeVertical = ScrollController();
  final ScrollController _codeHorizontal = ScrollController();

  final Map<String, Rect> _tabRects = {};
  Rect? _underlineRect;
  bool _underlineReady = false;

  List<ConsonaSnippetTab> get _resolvedTabs {
    final tabs = widget.tabs;
    if (tabs != null && tabs.isNotEmpty) return tabs;
    return [
      ConsonaSnippetTab(
        id: '_single',
        label: widget.language ?? 'Code',
        code: widget.code ?? '',
        language: widget.language,
      ),
    ];
  }

  bool get _isMulti => (widget.tabs?.length ?? 0) > 1;

  String get _activeTabId {
    final tabs = _resolvedTabs;
    final preferred = widget.selectedTabId ?? _localTabId;
    if (tabs.any((t) => t.id == preferred)) return preferred;
    return tabs.first.id;
  }

  ConsonaSnippetTab get _activeTab =>
      _resolvedTabs.firstWhere((t) => t.id == _activeTabId);

  bool get _collapsed => widget.collapsed ?? _localCollapsed;

  @override
  void initState() {
    super.initState();
    _localTabId = widget.selectedTabId ?? _resolvedTabs.first.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureUnderline());
  }

  @override
  void didUpdateWidget(covariant ConsonaSnippet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTabId != null &&
        widget.selectedTabId != oldWidget.selectedTabId) {
      _localTabId = widget.selectedTabId!;
    }
    final ids = _resolvedTabs.map((t) => t.id).toSet();
    if (!ids.contains(_localTabId)) {
      _localTabId = _resolvedTabs.first.id;
    }
    if (oldWidget.selectedTabId != widget.selectedTabId ||
        oldWidget.tabs != widget.tabs) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureUnderline());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabScroll.dispose();
    _codeVertical.dispose();
    _codeHorizontal.dispose();
    super.dispose();
  }

  void _selectTab(String id) {
    if (id == _activeTabId) return;
    setState(() {
      if (widget.selectedTabId == null) _localTabId = id;
      if (widget.collapsed == null) _localCollapsed = true;
      _copied = false;
    });
    widget.onTabChanged?.call(id);
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollTabIntoView(id);
      _measureUnderline();
      if (_codeVertical.hasClients) _codeVertical.jumpTo(0);
      if (_codeHorizontal.hasClients) _codeHorizontal.jumpTo(0);
    });
  }

  void _scrollTabIntoView(String id) {
    final key = _tabKeys[id];
    final ctx = key?.currentContext;
    if (ctx == null || !_tabScroll.hasClients) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _measureUnderline() {
    if (!mounted || !_isMulti) return;
    final stackContext = _tabStackKey.currentContext;
    if (stackContext == null) return;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;

    for (final tab in _resolvedTabs) {
      final ctx = _tabKeys[tab.id]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final offset = box.localToGlobal(Offset.zero, ancestor: stackBox);
      _tabRects[tab.id] = offset & box.size;
    }

    final target = _tabRects[_activeTabId];
    if (target == null) return;
    // Underline hugs the label width, pinned to the bottom of the tab hit area.
    const underlineHeight = 2.0;
    final next = Rect.fromLTWH(
      target.left,
      target.bottom - underlineHeight,
      target.width,
      underlineHeight,
    );
    if (_underlineRect != next || !_underlineReady) {
      setState(() {
        _underlineRect = next;
        _underlineReady = true;
      });
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _activeTab.code));
    if (!mounted) return;
    await ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.success);
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _toggleCollapse() {
    final next = !_collapsed;
    if (widget.collapsed == null) setState(() => _localCollapsed = next);
    widget.onCollapsedChanged?.call(next);
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
  }

  TextStyle _monoStyle(ConsonaThemeData theme, double scale) {
    return theme.typography.caption.copyWith(
      fontFamily: 'Menlo',
      fontFamilyFallback: const ['Consolas', 'monospace'],
      color: theme.colors.foreground,
      height: 1.45,
      fontSize: 12.5 * scale,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  Widget _copyButton() {
    return ConsonaIconButton.plain(
      icon: Icon(
        _copied ? Icons.check_rounded : Icons.copy_rounded,
        size: 16,
      ),
      size: ConsonaOpticalSize.sqSm,
      semanticLabel: _copied ? 'Copied' : 'Copy',
      onTap: _copy,
    );
  }

  Widget _buildCodePane({
    required ConsonaThemeData theme,
    required double scale,
    required String visibleCode,
    required TextStyle mono,
    required bool scrollable,
    required ConsonaMotionSpec motion,
  }) {
    final codeText = Text(
      visibleCode,
      softWrap: false,
      style: mono,
    );

    final horizontal = SingleChildScrollView(
      controller: _codeHorizontal,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: codeText,
    );

    if (!scrollable) {
      return AnimatedSwitcher(
        duration: motion.duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Align(
          key: ValueKey<String>('$_activeTabId-$_collapsed'),
          alignment: Alignment.topLeft,
          child: horizontal,
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: AnimatedSwitcher(
        duration: motion.duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: SingleChildScrollView(
          key: ValueKey<String>('$_activeTabId-scroll'),
          controller: _codeVertical,
          physics: const BouncingScrollPhysics(),
          child: horizontal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final active = _activeTab;
    final lines = active.code.split('\n');
    final needsCollapse = widget.variant == ConsonaSnippetVariant.block &&
        lines.length > widget.maxLines;
    final visibleCode = needsCollapse && _collapsed
        ? lines.take(widget.maxLines).join('\n')
        : active.code;
    final mono = _monoStyle(theme, scale);
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);
    // Scroll when expanded (or when there is no collapse) so tall / wide code
    // can be explored without blowing the layout.
    final scrollable = !needsCollapse || !_collapsed;

    if (widget.variant == ConsonaSnippetVariant.inline) {
      return Semantics(
        label: active.language ?? active.label,
        child: GestureDetector(
          onTap: widget.showCopy ? _copy : null,
          child: AnimatedContainer(
            duration:
                theme.motion.resolve(ConsonaMotionRole.focus, context).duration,
            padding: EdgeInsets.symmetric(
              horizontal: ConsonaSpacing.sm * scale,
              vertical: ConsonaSpacing.xxs * scale,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
              border: theme.border.resolve(
                ConsonaBorderRole.subtle,
                context: context,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    active.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mono,
                  ),
                ),
                if (widget.showCopy) ...[
                  SizedBox(width: ConsonaSpacing.xs * scale),
                  Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 12 * scale,
                    color: _copied ? colors.success : colors.mutedFg,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: active.language ?? active.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
          border: theme.border.resolve(
            ConsonaBorderRole.subtle,
            context: context,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isMulti)
              _buildTabBar(theme, colors, scale)
            else
              _buildSingleHeader(theme, colors, scale, active),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ConsonaSpacing.md * scale,
                ConsonaSpacing.sm * scale,
                ConsonaSpacing.md * scale,
                needsCollapse
                    ? ConsonaSpacing.xs * scale
                    : ConsonaSpacing.md * scale,
              ),
              child: AnimatedSize(
                duration: motion.duration,
                curve: motion.curve,
                alignment: Alignment.topCenter,
                child: _buildCodePane(
                  theme: theme,
                  scale: scale,
                  visibleCode: visibleCode,
                  mono: mono,
                  scrollable: scrollable,
                  motion: motion,
                ),
              ),
            ),
            if (needsCollapse)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleCollapse,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: ConsonaSpacing.md * scale,
                    vertical: ConsonaSpacing.sm * scale,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary.withAlpha(160),
                    border: theme.border.resolve(
                      ConsonaBorderRole.divider,
                      context: context,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedRotation(
                        turns: _collapsed ? 0 : 0.5,
                        duration: motion.duration,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 16 * scale,
                          color: colors.mutedFg,
                        ),
                      ),
                      SizedBox(width: ConsonaSpacing.xxs * scale),
                      Text(
                        _collapsed
                            ? 'Show ${lines.length - widget.maxLines} more lines'
                            : 'Show less',
                        style: theme.typography.caption.copyWith(
                          color: colors.mutedFg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleHeader(
    ConsonaThemeData theme,
    ConsonaColors colors,
    double scale,
    ConsonaSnippetTab active,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ConsonaSpacing.md * scale,
        ConsonaSpacing.sm * scale,
        ConsonaSpacing.xs * scale,
        0,
      ),
      child: Row(
        children: [
          if ((active.language ?? active.label).isNotEmpty)
            Text(
              active.language ?? active.label,
              style: theme.typography.labelSmall.copyWith(
                color: colors.mutedFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          const Spacer(),
          if (widget.showCopy) _copyButton(),
        ],
      ),
    );
  }

  Widget _buildTabBar(
    ConsonaThemeData theme,
    ConsonaColors colors,
    double scale,
  ) {
    final motion = theme.motion.resolve(ConsonaMotionRole.page, context);
    final tabs = _resolvedTabs;
    final underline = _underlineRect;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        border: theme.border.resolve(
          ConsonaBorderRole.divider,
          context: context,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification ||
                    notification is ScrollEndNotification) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _measureUnderline());
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _tabScroll,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: ConsonaSpacing.sm * scale,
                ),
                child: Stack(
                  key: _tabStackKey,
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        for (final tab in tabs)
                          Builder(
                            builder: (context) {
                              _tabKeys.putIfAbsent(tab.id, GlobalKey.new);
                              final selected = tab.id == _activeTabId;
                              return KeyedSubtree(
                                key: _tabKeys[tab.id],
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _selectTab(tab.id),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      ConsonaSpacing.sm * scale,
                                      ConsonaSpacing.sm * scale,
                                      ConsonaSpacing.sm * scale,
                                      ConsonaSpacing.sm * scale + 2,
                                    ),
                                    child: AnimatedDefaultTextStyle(
                                      duration: motion.duration,
                                      curve: motion.curve,
                                      style:
                                          theme.typography.labelSmall.copyWith(
                                        color: selected
                                            ? colors.foreground
                                            : colors.mutedFg,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                      child: Text(tab.label),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    if (underline != null)
                      AnimatedPositioned(
                        duration: _underlineReady
                            ? (motion.duration == Duration.zero
                                ? const Duration(milliseconds: 240)
                                : motion.duration)
                            : Duration.zero,
                        curve: Curves.easeOutCubic,
                        left: underline.left,
                        top: underline.top,
                        width: math.max(underline.width, 12 * scale),
                        height: underline.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius:
                                theme.radius.resolve(ConsonaRadiusRole.full),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.showCopy) ...[
            SizedBox(width: ConsonaSpacing.xxs * scale),
            _copyButton(),
            SizedBox(width: ConsonaSpacing.xs * scale),
          ],
        ],
      ),
    );
  }
}

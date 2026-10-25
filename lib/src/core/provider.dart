/// Consona Provider — Root application plugin and theme host widget
library;

import 'package:flutter/material.dart';

import '../modules/assets/assets_plugin.dart';
import '../modules/feedback/context/feedback_scope.dart';
import '../modules/feedback/engine/feedback_engine.dart';
import '../modules/feedback/feedback_plugin.dart';
import '../modules/overlay/context/overlay_scope.dart';
import '../modules/overlay/engine/overlay_engine.dart';
import '../modules/overlay/overlay_plugin.dart';
import '../theme/presets.dart';
import '../theme/theme_controller.dart';
import '../theme/theme_data.dart';
import '../theme/theme_provider.dart';
import 'plugin.dart';
import 'registry.dart';
import 'types.dart';

class ConsonaProvider extends StatefulWidget {
  const ConsonaProvider({
    super.key,
    this.plugins,
    this.theme,
    this.darkTheme,
    this.themeMode = ConsonaThemeMode.system,
    this.controller,
    this.placeholder,
    required this.child,
  });

  /// Plugins to attach. Defaults to assets, feedback, and overlay.
  final List<ConsonaPlugin>? plugins;

  final ConsonaThemeData? theme;
  final ConsonaThemeData? darkTheme;
  final ConsonaThemeMode themeMode;
  final ConsonaThemeController? controller;

  /// Shown until plugins finish attaching. Defaults to an empty [SizedBox.shrink].
  final Widget? placeholder;

  final Widget child;

  /// Retrieves the ambient [ConsonaRegistry] from context.
  static ConsonaRegistry registryOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ConsonaRegistryScope>();
    if (scope == null) {
      throw StateError('No ConsonaProvider found in context.');
    }
    return scope.registry;
  }

  /// Retrieves the ambient [ConsonaRegistry] or null.
  static ConsonaRegistry? maybeRegistryOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ConsonaRegistryScope>()?.registry;
  }

  /// Whether plugins have finished attaching under the nearest provider.
  static bool isReadyOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ConsonaRegistryScope>();
    return scope?.registry.isReady ?? false;
  }

  /// Material [ThemeData.extensions] list: active [ConsonaThemeData] plus
  /// any plugin-contributed [ThemeExtension]s from the registry.
  ///
  /// Use inside [MaterialApp.theme] / [darkTheme]:
  /// ```dart
  /// ThemeData(
  ///   extensions: ConsonaProvider.materialExtensionsOf(context),
  /// )
  /// ```
  /// Prefer calling from a builder under [ConsonaProvider], or pass the
  /// registry explicitly via [materialExtensions].
  static List<ThemeExtension<dynamic>> materialExtensionsOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ConsonaRegistryScope>();
    final themeScope = context.dependOnInheritedWidgetOfExactType<ConsonaThemeScope>();
    final consonaTheme = themeScope?.theme ?? ConsonaPresets.minimal();
    final pluginExts = scope?.registry.themeExtensions ?? const [];
    return [
      consonaTheme,
      ...pluginExts,
    ];
  }

  /// Builds Material theme extensions from an explicit theme + registry.
  static List<ThemeExtension<dynamic>> materialExtensions({
    required ConsonaThemeData theme,
    ConsonaRegistry? registry,
  }) {
    final pluginExts = registry?.themeExtensions ?? const [];
    return [
      theme,
      ...pluginExts,
    ];
  }

  @override
  State<ConsonaProvider> createState() => _ConsonaProviderState();
}

class _ConsonaProviderState extends State<ConsonaProvider> {
  late final ConsonaPluginRegistry _registry;
  late ConsonaThemeController _themeController;
  bool _ownsController = false;
  bool _attachFailed = false;
  Object? _attachError;

  @override
  void initState() {
    super.initState();
    _registry = ConsonaPluginRegistry();

    if (widget.controller != null) {
      _themeController = widget.controller!;
    } else {
      _ownsController = true;
      _themeController = ConsonaThemeController(
        theme: widget.theme,
        darkTheme: widget.darkTheme,
        themeMode: widget.themeMode,
      );
    }

    _attachPlugins();
  }

  @override
  void didUpdateWidget(ConsonaProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) {
        _themeController.dispose();
      }
      if (widget.controller != null) {
        _ownsController = false;
        _themeController = widget.controller!;
      } else {
        _ownsController = true;
        _themeController = ConsonaThemeController(
          theme: widget.theme,
          darkTheme: widget.darkTheme,
          themeMode: widget.themeMode,
        );
      }
    } else if (_ownsController) {
      if (widget.theme != oldWidget.theme ||
          widget.darkTheme != oldWidget.darkTheme) {
        _themeController.setTheme(
          widget.theme ?? _themeController.theme,
          darkTheme: widget.darkTheme,
        );
      }
      if (widget.themeMode != oldWidget.themeMode) {
        _themeController.setThemeMode(widget.themeMode);
      }
    }
  }

  void _attachPlugins() {
    final pluginsToAttach = widget.plugins ??
        [
          ConsonaAssetsPlugin(),
          ConsonaFeedbackPlugin(),
          ConsonaOverlayPlugin(),
        ];
    // Kick attach immediately. Sync plugins finish before the first build
    // when [attachAll] has no async onAttach (see ConsonaPluginRegistry).
    final future = _registry.attachAll(pluginsToAttach);
    future.then((_) {
      if (mounted) setState(() {});
    }).catchError((Object e) {
      _attachFailed = true;
      _attachError = e;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    if (_ownsController) {
      _themeController.dispose();
    }
    _registry.detachAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        final brightness = MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
        final isDark = switch (_themeController.themeMode) {
          ConsonaThemeMode.dark => true,
          ConsonaThemeMode.light => false,
          ConsonaThemeMode.system => brightness == Brightness.dark,
        };

        final activeTheme = isDark ? _themeController.darkTheme : _themeController.theme;

        if (_attachFailed) {
          return _ConsonaRegistryScope(
            registry: _registry,
            ready: false,
            child: ConsonaThemeScope(
              theme: activeTheme,
              child: ErrorWidget.withDetails(
                message: 'ConsonaProvider plugin attach failed: $_attachError',
              ),
            ),
          );
        }

        // Gate the tree until plugins attach so we never invent a throwaway
        // FeedbackEngine that is discarded when the real one registers.
        if (!_registry.isReady) {
          return _ConsonaRegistryScope(
            registry: _registry,
            ready: false,
            child: ConsonaThemeScope(
              theme: activeTheme,
              child: widget.placeholder ?? const SizedBox.shrink(),
            ),
          );
        }

        final feedbackEngine = _registry.engine<FeedbackEngine>();
        final overlayEngine = _registry.engine<OverlayEngine>();
        Widget child = widget.child;
        if (overlayEngine != null) {
          child = OverlayScope(engine: overlayEngine, child: child);
        }
        if (feedbackEngine != null) {
          child = FeedbackScope(engine: feedbackEngine, child: child);
        }

        return _ConsonaRegistryScope(
          registry: _registry,
          ready: true,
          child: ConsonaThemeScope(
            theme: activeTheme,
            child: child,
          ),
        );
      },
    );
  }
}

class _ConsonaRegistryScope extends InheritedWidget {
  const _ConsonaRegistryScope({
    required this.registry,
    required this.ready,
    required super.child,
  });

  final ConsonaRegistry registry;
  final bool ready;

  @override
  bool updateShouldNotify(_ConsonaRegistryScope oldWidget) =>
      registry != oldWidget.registry || ready != oldWidget.ready;
}

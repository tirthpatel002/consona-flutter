/// Consona Theme Controller — Runtime theme switcher and persistent state controller
library;

import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../core/storage.dart';
import '../core/types.dart';
import 'border.dart';
import 'color_scheme.dart';
import 'density.dart';
import 'motion.dart';
import 'presets.dart';
import 'radius.dart';
import 'shadow.dart';
import 'stroke.dart';
import 'theme_config.dart';
import 'theme_data.dart';
import 'tokens.dart';
import 'typography.dart';

class ConsonaThemeController extends ChangeNotifier {
  ConsonaThemeController({
    ConsonaThemeData? theme,
    ConsonaThemeData? darkTheme,
    this.themeMode = ConsonaThemeMode.system,
    this.storage,
  })  : _theme = theme ?? ConsonaPresets.minimal(),
        _darkTheme = darkTheme ?? (theme ?? ConsonaPresets.minimal()).dark();

  ConsonaThemeData _theme;
  ConsonaThemeData _darkTheme;
  ConsonaThemeMode themeMode;
  final ConsonaStorageAdapter? storage;
  String activePreset = 'minimal';
  Color? _seedColor;

  /// The brand seed currently applied, or null when the palette comes from a preset.
  Color? get seedColor => _seedColor;

  ConsonaThemeData get theme => _theme;
  ConsonaThemeData get darkTheme => _darkTheme;

  static const String _storageKeyMode = 'consona.theme.mode';
  static const String _storageKeyConfig = 'consona.theme.config';

  /// Loads persisted theme configuration from storage if available.
  Future<void> loadPersisted() async {
    if (storage == null) return;

    final savedMode = await storage!.read(_storageKeyMode);
    if (savedMode != null) {
      themeMode = switch (savedMode) {
        'light' => ConsonaThemeMode.light,
        'dark' => ConsonaThemeMode.dark,
        _ => ConsonaThemeMode.system,
      };
    }

    final savedConfig = await storage!.read(_storageKeyConfig);
    if (savedConfig != null) {
      try {
        final decoded = jsonDecode(savedConfig) as Map<String, dynamic>;
        final config = ConsonaThemeConfig.fromJson(decoded);
        _theme = config.toThemeData();
        _darkTheme = _theme.dark();
        activePreset = config.preset;
        if (config.seedColorHex != null) {
          _seedColor = Color(config.seedColorHex!);
          _darkTheme = _darkTheme.copyWith(
            colors: ConsonaColorScheme.fromSeed(_seedColor!).dark,
          );
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  /// Sets the active theme mode (system, light, dark).
  void setThemeMode(ConsonaThemeMode mode) {
    if (themeMode == mode) return;
    themeMode = mode;
    storage?.write(_storageKeyMode, mode.name);
    notifyListeners();
  }

  /// Sets the active light theme (colors included) and optional dark theme. Clears any seed color.
  void setTheme(ConsonaThemeData newTheme, {ConsonaThemeData? darkTheme}) {
    activePreset = '';
    _seedColor = null;
    _theme = newTheme;
    _darkTheme = darkTheme ?? newTheme.dark();
    _persistConfig();
    notifyListeners();
  }

  /// Applies a *knob* transformation (radius, density, shadow, stroke, border
  /// strategy, typography, motion) to BOTH the light and dark themes while
  /// preserving each side's own color palette (including any brand seed).
  ///
  /// Prefer this over [setTheme] for single-knob edits: `setTheme(theme.copyWith
  /// (...))` copies the *currently displayed* palette (which is the dark one in
  /// dark mode) into the light theme and resets the dark palette.
  void updateTheme(
      ConsonaThemeData Function(ConsonaThemeData current) transform) {
    activePreset = '';
    _theme = transform(_theme);
    _darkTheme = transform(_darkTheme);
    _persistConfig();
    notifyListeners();
  }

  void setRadius(ConsonaRadius radius) =>
      updateTheme((t) => t.copyWith(radius: radius));

  void setDensity(ConsonaDensity density) =>
      updateTheme((t) => t.copyWith(density: density));

  /// Sets the elevation preset ([ConsonaShadowLevel.none] flattens everything).
  void setShadowLevel(ConsonaShadowLevel level) => updateTheme(
        (t) => t.copyWith(
          shadow: ConsonaShadow(preset: level, strategy: t.shadow.strategy),
        ),
      );

  void setStroke(ConsonaStroke stroke) =>
      updateTheme((t) => t.copyWith(stroke: stroke));

  /// Switches how edges are drawn (hairline border, shadow edge, both, none).
  void setBorderStrategy(ConsonaBorderStrategy strategy) => updateTheme(
        (t) => t.copyWith(
          shadow: ConsonaShadow(preset: t.shadow.preset, strategy: strategy),
          border: ConsonaBorder(
            stroke: t.stroke,
            colors: t.colors,
            strategy: strategy,
            darkStrategy: t.border.darkStrategy,
            roles: t.border.roles,
          ),
        ),
      );

  void setMotion(ConsonaMotion motion) =>
      updateTheme((t) => t.copyWith(motion: motion));

  void setTypography(ConsonaTypography typography) =>
      updateTheme((t) => t.copyWith(typography: typography));

  /// Switches to one of the named whole-theme presets.
  void setPreset(String presetName) {
    activePreset = presetName;
    _seedColor = null;
    final newTheme = switch (presetName) {
      'linear' => ConsonaPresets.linear(),
      'ios' => ConsonaPresets.ios(),
      'mechanical' => ConsonaPresets.mechanical(),
      'soft' => ConsonaPresets.soft(),
      _ => ConsonaPresets.minimal(),
    };
    _theme = newTheme;
    _darkTheme = newTheme.dark();
    _persistConfig();
    notifyListeners();
  }

  /// Sets a new brand seed color for dynamic tonal palette generation.
  /// The currently selected seed is exposed as [seedColor].
  void setSeedColor(Color seed) {
    final scheme = ConsonaColorScheme.fromSeed(seed);
    _seedColor = seed;
    _theme = _theme.copyWith(colors: scheme.light);
    _darkTheme = _darkTheme.copyWith(colors: scheme.dark);
    _persistConfig();
    notifyListeners();
  }

  static String _radiusName(ConsonaRadius r) {
    if (r.isSquircle) return 'squircle';
    if (r.base <= 0.0) return 'none';
    if (r.base >= ConsonaRadii.full) return 'full';
    if (r.base <= ConsonaRadii.micro) return 'sm';
    if (r.base <= ConsonaRadii.base) return 'md';
    if (r.base <= ConsonaRadii.macro) return 'lg';
    return 'xl';
  }

  void _persistConfig() {
    if (storage == null) return;
    final config = ConsonaThemeConfig(
      preset: activePreset.isEmpty ? 'minimal' : activePreset,
      radius: _radiusName(_theme.radius),
      density: _theme.density.preset.name,
      shadow: _theme.shadow.preset.name,
      stroke: _theme.stroke.preset.name,
      borderStrategy: _theme.border.strategy.name,
      motion: _theme.motion.softness.name,
      seedColorHex: _seedColor?.toARGB32(),
      tabularFigures: _theme.typography.tabularFigures,
    );
    storage?.write(_storageKeyConfig, jsonEncode(config.toJson()));
  }
}

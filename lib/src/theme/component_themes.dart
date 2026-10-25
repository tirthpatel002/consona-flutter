/// Consona Component Themes — Per-component visual token overrides
library;

import 'dart:ui' show lerpDouble;
import 'package:flutter/widgets.dart';
import '../core/types.dart';

class ConsonaButtonThemeData {
  const ConsonaButtonThemeData({
    this.radius,
    this.shape,
    this.defaultSize,
    this.pressedScale,
  });

  final ConsonaRadiusPreset? radius;
  final ConsonaShapeVariant? shape;
  final ConsonaOpticalSize? defaultSize;
  final double? pressedScale;

  ConsonaButtonThemeData copyWith({
    ConsonaRadiusPreset? radius,
    ConsonaShapeVariant? shape,
    ConsonaOpticalSize? defaultSize,
    double? pressedScale,
  }) {
    return ConsonaButtonThemeData(
      radius: radius ?? this.radius,
      shape: shape ?? this.shape,
      defaultSize: defaultSize ?? this.defaultSize,
      pressedScale: pressedScale ?? this.pressedScale,
    );
  }

  Map<String, dynamic> toJson() => {
        if (radius != null) 'radius': radius!.name,
        if (shape != null) 'shape': shape!.name,
        if (defaultSize != null) 'defaultSize': defaultSize!.name,
        if (pressedScale != null) 'pressedScale': pressedScale,
      };

  factory ConsonaButtonThemeData.fromJson(Map<String, dynamic> json) {
    return ConsonaButtonThemeData(
      radius: _parseEnum(ConsonaRadiusPreset.values, json['radius']),
      shape: _parseEnum(ConsonaShapeVariant.values, json['shape']),
      defaultSize: _parseEnum(ConsonaOpticalSize.values, json['defaultSize']),
      pressedScale: (json['pressedScale'] as num?)?.toDouble(),
    );
  }

  static ConsonaButtonThemeData lerp(
    ConsonaButtonThemeData a,
    ConsonaButtonThemeData b,
    double t,
  ) {
    return ConsonaButtonThemeData(
      radius: t < 0.5 ? a.radius : b.radius,
      shape: t < 0.5 ? a.shape : b.shape,
      defaultSize: t < 0.5 ? a.defaultSize : b.defaultSize,
      pressedScale: lerpDouble(a.pressedScale, b.pressedScale, t),
    );
  }
}

class ConsonaCardThemeData {
  const ConsonaCardThemeData({
    this.radius,
    this.shadowLevel,
    this.borderRole,
    this.padding,
  });

  final ConsonaRadiusPreset? radius;
  final ConsonaShadowLevel? shadowLevel;
  final ConsonaBorderRole? borderRole;
  final EdgeInsetsGeometry? padding;

  ConsonaCardThemeData copyWith({
    ConsonaRadiusPreset? radius,
    ConsonaShadowLevel? shadowLevel,
    ConsonaBorderRole? borderRole,
    EdgeInsetsGeometry? padding,
  }) {
    return ConsonaCardThemeData(
      radius: radius ?? this.radius,
      shadowLevel: shadowLevel ?? this.shadowLevel,
      borderRole: borderRole ?? this.borderRole,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toJson() => {
        if (radius != null) 'radius': radius!.name,
        if (shadowLevel != null) 'shadowLevel': shadowLevel!.name,
        if (borderRole != null) 'borderRole': borderRole!.name,
      };

  factory ConsonaCardThemeData.fromJson(Map<String, dynamic> json) {
    return ConsonaCardThemeData(
      radius: _parseEnum(ConsonaRadiusPreset.values, json['radius']),
      shadowLevel: _parseEnum(ConsonaShadowLevel.values, json['shadowLevel']),
      borderRole: _parseEnum(ConsonaBorderRole.values, json['borderRole']),
    );
  }

  static ConsonaCardThemeData lerp(
    ConsonaCardThemeData a,
    ConsonaCardThemeData b,
    double t,
  ) {
    return ConsonaCardThemeData(
      radius: t < 0.5 ? a.radius : b.radius,
      shadowLevel: t < 0.5 ? a.shadowLevel : b.shadowLevel,
      borderRole: t < 0.5 ? a.borderRole : b.borderRole,
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
    );
  }
}

class ConsonaInputThemeData {
  const ConsonaInputThemeData({
    this.radius,
    this.borderRole,
    this.defaultSize,
  });

  final ConsonaRadiusPreset? radius;
  final ConsonaBorderRole? borderRole;
  final ConsonaOpticalSize? defaultSize;

  ConsonaInputThemeData copyWith({
    ConsonaRadiusPreset? radius,
    ConsonaBorderRole? borderRole,
    ConsonaOpticalSize? defaultSize,
  }) {
    return ConsonaInputThemeData(
      radius: radius ?? this.radius,
      borderRole: borderRole ?? this.borderRole,
      defaultSize: defaultSize ?? this.defaultSize,
    );
  }

  Map<String, dynamic> toJson() => {
        if (radius != null) 'radius': radius!.name,
        if (borderRole != null) 'borderRole': borderRole!.name,
        if (defaultSize != null) 'defaultSize': defaultSize!.name,
      };

  factory ConsonaInputThemeData.fromJson(Map<String, dynamic> json) {
    return ConsonaInputThemeData(
      radius: _parseEnum(ConsonaRadiusPreset.values, json['radius']),
      borderRole: _parseEnum(ConsonaBorderRole.values, json['borderRole']),
      defaultSize: _parseEnum(ConsonaOpticalSize.values, json['defaultSize']),
    );
  }

  static ConsonaInputThemeData lerp(
    ConsonaInputThemeData a,
    ConsonaInputThemeData b,
    double t,
  ) {
    return ConsonaInputThemeData(
      radius: t < 0.5 ? a.radius : b.radius,
      borderRole: t < 0.5 ? a.borderRole : b.borderRole,
      defaultSize: t < 0.5 ? a.defaultSize : b.defaultSize,
    );
  }
}

class ConsonaOverlayThemeData {
  const ConsonaOverlayThemeData({
    this.radius,
    this.shadowLevel,
    this.maxToastWidth = 420.0,
    this.maxModalWidth = 440.0,
    this.maxDrawerWidth = 560.0,
    this.maxSideSheetWidth = 400.0,
  });

  final ConsonaRadiusPreset? radius;
  final ConsonaShadowLevel? shadowLevel;
  final double maxToastWidth;
  final double maxModalWidth;
  final double maxDrawerWidth;
  final double maxSideSheetWidth;

  ConsonaOverlayThemeData copyWith({
    ConsonaRadiusPreset? radius,
    ConsonaShadowLevel? shadowLevel,
    double? maxToastWidth,
    double? maxModalWidth,
    double? maxDrawerWidth,
    double? maxSideSheetWidth,
  }) {
    return ConsonaOverlayThemeData(
      radius: radius ?? this.radius,
      shadowLevel: shadowLevel ?? this.shadowLevel,
      maxToastWidth: maxToastWidth ?? this.maxToastWidth,
      maxModalWidth: maxModalWidth ?? this.maxModalWidth,
      maxDrawerWidth: maxDrawerWidth ?? this.maxDrawerWidth,
      maxSideSheetWidth: maxSideSheetWidth ?? this.maxSideSheetWidth,
    );
  }

  Map<String, dynamic> toJson() => {
        if (radius != null) 'radius': radius!.name,
        if (shadowLevel != null) 'shadowLevel': shadowLevel!.name,
        'maxToastWidth': maxToastWidth,
        'maxModalWidth': maxModalWidth,
        'maxDrawerWidth': maxDrawerWidth,
        'maxSideSheetWidth': maxSideSheetWidth,
      };

  factory ConsonaOverlayThemeData.fromJson(Map<String, dynamic> json) {
    return ConsonaOverlayThemeData(
      radius: _parseEnum(ConsonaRadiusPreset.values, json['radius']),
      shadowLevel: _parseEnum(ConsonaShadowLevel.values, json['shadowLevel']),
      maxToastWidth: (json['maxToastWidth'] as num?)?.toDouble() ?? 420.0,
      maxModalWidth: (json['maxModalWidth'] as num?)?.toDouble() ?? 440.0,
      maxDrawerWidth: (json['maxDrawerWidth'] as num?)?.toDouble() ?? 560.0,
      maxSideSheetWidth: (json['maxSideSheetWidth'] as num?)?.toDouble() ?? 400.0,
    );
  }

  static ConsonaOverlayThemeData lerp(
    ConsonaOverlayThemeData a,
    ConsonaOverlayThemeData b,
    double t,
  ) {
    return ConsonaOverlayThemeData(
      radius: t < 0.5 ? a.radius : b.radius,
      shadowLevel: t < 0.5 ? a.shadowLevel : b.shadowLevel,
      maxToastWidth: lerpDouble(a.maxToastWidth, b.maxToastWidth, t) ?? b.maxToastWidth,
      maxModalWidth: lerpDouble(a.maxModalWidth, b.maxModalWidth, t) ?? b.maxModalWidth,
      maxDrawerWidth: lerpDouble(a.maxDrawerWidth, b.maxDrawerWidth, t) ?? b.maxDrawerWidth,
      maxSideSheetWidth:
          lerpDouble(a.maxSideSheetWidth, b.maxSideSheetWidth, t) ?? b.maxSideSheetWidth,
    );
  }
}

class ConsonaComponentThemes {
  const ConsonaComponentThemes({
    this.button = const ConsonaButtonThemeData(),
    this.card = const ConsonaCardThemeData(),
    this.input = const ConsonaInputThemeData(),
    this.overlay = const ConsonaOverlayThemeData(),
  });

  final ConsonaButtonThemeData button;
  final ConsonaCardThemeData card;
  final ConsonaInputThemeData input;
  final ConsonaOverlayThemeData overlay;

  ConsonaComponentThemes copyWith({
    ConsonaButtonThemeData? button,
    ConsonaCardThemeData? card,
    ConsonaInputThemeData? input,
    ConsonaOverlayThemeData? overlay,
  }) {
    return ConsonaComponentThemes(
      button: button ?? this.button,
      card: card ?? this.card,
      input: input ?? this.input,
      overlay: overlay ?? this.overlay,
    );
  }

  Map<String, dynamic> toJson() {
    final buttonJson = button.toJson();
    final cardJson = card.toJson();
    final inputJson = input.toJson();
    final overlayJson = overlay.toJson();
    return {
      if (buttonJson.isNotEmpty) 'button': buttonJson,
      if (cardJson.isNotEmpty) 'card': cardJson,
      if (inputJson.isNotEmpty) 'input': inputJson,
      if (overlayJson.isNotEmpty) 'overlay': overlayJson,
    };
  }

  factory ConsonaComponentThemes.fromJson(Map<String, dynamic> json) {
    return ConsonaComponentThemes(
      button: json['button'] is Map<String, dynamic>
          ? ConsonaButtonThemeData.fromJson(json['button'] as Map<String, dynamic>)
          : const ConsonaButtonThemeData(),
      card: json['card'] is Map<String, dynamic>
          ? ConsonaCardThemeData.fromJson(json['card'] as Map<String, dynamic>)
          : const ConsonaCardThemeData(),
      input: json['input'] is Map<String, dynamic>
          ? ConsonaInputThemeData.fromJson(json['input'] as Map<String, dynamic>)
          : const ConsonaInputThemeData(),
      overlay: json['overlay'] is Map<String, dynamic>
          ? ConsonaOverlayThemeData.fromJson(json['overlay'] as Map<String, dynamic>)
          : const ConsonaOverlayThemeData(),
    );
  }

  static ConsonaComponentThemes lerp(
    ConsonaComponentThemes a,
    ConsonaComponentThemes b,
    double t,
  ) {
    return ConsonaComponentThemes(
      button: ConsonaButtonThemeData.lerp(a.button, b.button, t),
      card: ConsonaCardThemeData.lerp(a.card, b.card, t),
      input: ConsonaInputThemeData.lerp(a.input, b.input, t),
      overlay: ConsonaOverlayThemeData.lerp(a.overlay, b.overlay, t),
    );
  }
}

T? _parseEnum<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! String) return null;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

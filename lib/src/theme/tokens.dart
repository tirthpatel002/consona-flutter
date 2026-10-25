/// Consona Theme Design Tokens
library;

import 'package:flutter/widgets.dart';
import '../core/types.dart';

abstract final class ConsonaSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

abstract final class ConsonaRadii {
  static const double none = 0.0;
  static const double atom = 4.0;
  static const double micro = 6.0;
  static const double base = 10.0;
  static const double macro = 16.0;
  static const double xl = 22.0;
  static const double full = 9999.0;
}

abstract final class ConsonaOpacities {
  static const double transparent = 0.0;
  static const double faint = 0.04;
  static const double subtle = 0.08;
  static const double pressed = 0.12;
  static const double focus = 0.16;
  static const double disabled = 0.38;
  static const double half = 0.50;
  static const double muted = 0.70;
  static const double opaque = 1.0;
}

/// Shared optical geometry — one tone for buttons, inputs, nav, pickers, OTP.
///
/// Prefer [ConsonaSizeScope] (default [ConsonaOpticalSize.sm]) or per-widget
/// `size:` so downstream apps can scale an entire subtree consistently.
abstract final class ConsonaGeometries {
  /// Control / input / chip height for [size].
  static double heightFor(ConsonaOpticalSize size) => switch (size) {
        ConsonaOpticalSize.xs || ConsonaOpticalSize.sqXs => 28.0,
        ConsonaOpticalSize.sm || ConsonaOpticalSize.sqSm => 34.0,
        ConsonaOpticalSize.md || ConsonaOpticalSize.sqMd => 40.0,
        ConsonaOpticalSize.lg || ConsonaOpticalSize.sqLg => 48.0,
      };

  static EdgeInsets horizontalPaddingFor(ConsonaOpticalSize size) =>
      switch (size) {
        ConsonaOpticalSize.xs => const EdgeInsets.symmetric(horizontal: 10.0),
        ConsonaOpticalSize.sm => const EdgeInsets.symmetric(horizontal: 12.0),
        ConsonaOpticalSize.md => const EdgeInsets.symmetric(horizontal: 14.0),
        ConsonaOpticalSize.lg => const EdgeInsets.symmetric(horizontal: 18.0),
        ConsonaOpticalSize.sqXs ||
        ConsonaOpticalSize.sqSm ||
        ConsonaOpticalSize.sqMd ||
        ConsonaOpticalSize.sqLg =>
          EdgeInsets.zero,
      };

  static double iconSizeFor(ConsonaOpticalSize size) => switch (size) {
        ConsonaOpticalSize.xs || ConsonaOpticalSize.sqXs => 14.0,
        ConsonaOpticalSize.sm || ConsonaOpticalSize.sqSm => 16.0,
        ConsonaOpticalSize.md || ConsonaOpticalSize.sqMd => 20.0,
        ConsonaOpticalSize.lg || ConsonaOpticalSize.sqLg => 22.0,
      };

  /// Rating stars sit a step above chrome icons without dominating the row.
  static double ratingIconSizeFor(ConsonaOpticalSize size) => switch (size) {
        ConsonaOpticalSize.xs || ConsonaOpticalSize.sqXs => 18.0,
        ConsonaOpticalSize.sm || ConsonaOpticalSize.sqSm => 22.0,
        ConsonaOpticalSize.md || ConsonaOpticalSize.sqMd => 28.0,
        ConsonaOpticalSize.lg || ConsonaOpticalSize.sqLg => 34.0,
      };

  static double fontSizeFor(ConsonaOpticalSize size) => switch (size) {
        ConsonaOpticalSize.xs || ConsonaOpticalSize.sqXs => 12.0,
        ConsonaOpticalSize.sm || ConsonaOpticalSize.sqSm => 13.5,
        ConsonaOpticalSize.md || ConsonaOpticalSize.sqMd => 15.0,
        ConsonaOpticalSize.lg || ConsonaOpticalSize.sqLg => 16.5,
      };

  /// Cap for calendar day cells so wide layouts stay compact.
  static double maxDayCellFor(ConsonaOpticalSize size) => switch (size) {
        ConsonaOpticalSize.xs || ConsonaOpticalSize.sqXs => 30.0,
        ConsonaOpticalSize.sm || ConsonaOpticalSize.sqSm => 34.0,
        ConsonaOpticalSize.md || ConsonaOpticalSize.sqMd => 38.0,
        ConsonaOpticalSize.lg || ConsonaOpticalSize.sqLg => 42.0,
      };

  /// Wheel / list row extent aligned with control height.
  static double itemExtentFor(ConsonaOpticalSize size) => heightFor(size);
}

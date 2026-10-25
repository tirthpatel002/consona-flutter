/// Consona Animation & Physics Curves
library;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Reusable soft curves and physics simulations.
class ConsonaCurves {
  ConsonaCurves._();

  /// Standard soft deceleration curve for presses, fades, and slides.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Expressive curve with gentle overshoot for pop-ins and checkmarks.
  static const Curve easeOutBack = Curves.easeOutBack;

  /// Subtle ease curve for gentle organic motion.
  static const Curve subtleEase = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Bouncy spring curve with gentle overshoot.
  static const Curve bouncySpring = Curves.easeOutBack;

  /// Spring simulation preset for tactile mobile bounces.
  static SpringSimulation standardSpring({
    double start = 0.0,
    double end = 1.0,
    double velocity = 0.0,
    double damping = 0.82,
    double stiffness = 300.0,
  }) {
    return SpringSimulation(
      SpringDescription(
        mass: 1.0,
        stiffness: stiffness,
        damping: damping * 2 * 17.32, // Critical damping approximation
      ),
      start,
      end,
      velocity,
    );
  }

  /// Linear interpolation helper for discrete amplitudes or values.
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

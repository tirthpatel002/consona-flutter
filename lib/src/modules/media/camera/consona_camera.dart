/// Public API for in-app camera capture (photo + video).
library;

import 'package:flutter/widgets.dart';

import '../../../core/animation.dart';
import '../../overlay/common/overlay_host.dart';
import '../../../theme/tokens.dart';
import 'capture_result.dart';
import 'capture_sheet.dart';

/// Bottom-card camera capture flow (capture → review → confirm).
abstract final class ConsonaCamera {
  /// Opens a rounded bottom card (~80% height). Returns null if dismissed.
  static Future<ConsonaCameraCaptureResult?> show(
    BuildContext context, {
    ConsonaCameraEditCallback? onEdit,
  }) {
    return showConsonaOverlay<ConsonaCameraCaptureResult>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 380),
      builder: (overlayContext, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: ConsonaCurves.subtleEase,
          reverseCurve: ConsonaCurves.easeOut,
        );

        final size = MediaQuery.sizeOf(overlayContext);
        final bottomInset = MediaQuery.paddingOf(overlayContext).bottom;

        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                return ConsonaOverlayBackdrop(
                  progress: curved.value,
                  blurSigma: 18.0,
                  tintOpacity: 0.38,
                  onTap: () => Navigator.of(overlayContext).maybePop(),
                );
              },
            ),
            consonaSlideTransition(
              animation: animation,
              edge: ConsonaOverlayEdge.bottom,
              curve: ConsonaCurves.subtleEase,
              reverseCurve: ConsonaCurves.easeOut,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  size.width * 0.025,
                  0,
                  size.width * 0.025,
                  bottomInset + ConsonaSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: size.width * 0.95,
                    height: size.height * 0.80,
                    child: ConsonaCameraCaptureSheet(onEdit: onEdit),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

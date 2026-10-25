/// Consona Copyable — Tap-to-copy text container with transient confirmation cue
library;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../feedback/engine/feedback_engine.dart';
import '../../feedback/models/feedback_event.dart';
import 'text.dart';

class ConsonaCopyable extends StatefulWidget {
  const ConsonaCopyable({
    super.key,
    required this.textToCopy,
    this.displayWidget,
    this.onCopied,
  });

  final String textToCopy;
  final Widget? displayWidget;
  final VoidCallback? onCopied;

  @override
  State<ConsonaCopyable> createState() => _ConsonaCopyableState();
}

class _ConsonaCopyableState extends State<ConsonaCopyable> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    final feedback = FeedbackEngine.of(context);
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    if (!mounted) return;
    await feedback.trigger(FeedbackEvent.success);

    setState(() => _copied = true);
    widget.onCopied?.call();

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleCopy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? const Row(
                key: ValueKey('copied'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconData(0xe156, fontFamily: 'MaterialIcons'),
                    size: 14.0,
                  ),
                  SizedBox(width: 4.0),
                  ConsonaText.label('Copied!'),
                ],
              )
            : widget.displayWidget ?? ConsonaText.body(widget.textToCopy),
      ),
    );
  }
}

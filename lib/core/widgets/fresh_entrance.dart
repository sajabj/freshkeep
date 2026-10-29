import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A restrained entrance used only for prominent, newly presented content.
/// It renders its final state immediately when Android requests less motion.
class FreshEntrance extends StatelessWidget {
  const FreshEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
        .slideY(
          begin: .035,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

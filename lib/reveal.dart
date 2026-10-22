import 'package:flutter/material.dart';

/// Animasi reveal: fade + slide ke atas dengan penundaan [delayMs].
///
/// Penundaan dibuat dengan kurva [Interval] di atas [TweenAnimationBuilder],
/// sehingga tidak memerlukan state tambahan maupun timer.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.slideDistance = 28,
  });

  final Widget child;
  final int delayMs;
  final double slideDistance;

  @override
  Widget build(BuildContext context) {
    const Duration total = Duration(milliseconds: 1000);
    final double start = (delayMs / total.inMilliseconds).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, slideDistance * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

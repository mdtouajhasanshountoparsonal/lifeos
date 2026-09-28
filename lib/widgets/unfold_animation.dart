import 'package:flutter/material.dart';

/// UnfoldItem — P3: ট্রি-কার্ডের একটি লাইন "উপর থেকে নিচে ভাঁজ খুলে আসে"।
///
/// একটা shared 0..1 [animation] দিয়ে প্রতিটি row staggered slide+fade:
/// - count বড় হলেও step ভাগা (row-গুলো ক্রমে নেমে আসে — কাগজ উল্টানোর অনুভূতি)
/// - easeOutCubic মানে দ্রুত শুরু → মসৃণ থামা
class UnfoldItem extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final int count;
  final Widget child;
  final double step;

  const UnfoldItem({
    super.key,
    required this.animation,
    required this.index,
    required this.count,
    required this.child,
    this.step = 0.26,
  });

  @override
  Widget build(BuildContext context) {
    final total = count < 1 ? 1 : count;
    final start = (index / total).clamp(0.0, 1.0 - step / 2);
    final end = (start + step).clamp(0.0, 1.0);
    final interval = Interval(start, end, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = interval.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -16 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
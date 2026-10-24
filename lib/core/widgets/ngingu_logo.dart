import 'package:flutter/material.dart';

/// Hand-drawn Ngingu badge logo (fish + bubbles in a sky circle).
class NginguLogo extends StatelessWidget {
  const NginguLogo({super.key, this.size = 220, this.animate = true});

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget logo = SizedBox(
      width: size,
      height: size,
      child: Image.asset('assets/images/logo.png', width: size, height: size),
    );
    if (!animate) return logo;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: 0.6 + 0.4 * value, child: child),
      child: logo,
    );
  }
}

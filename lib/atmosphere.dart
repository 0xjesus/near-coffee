import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// Warm paper canvas: a faint grain, a couple of coffee-ring stains, and a
/// slow breathing warmth so the page feels alive without ever distracting
/// from the receipt at its centre.
class CoffeeBackground extends StatefulWidget {
  const CoffeeBackground({super.key, required this.child});
  final Widget child;

  @override
  State<CoffeeBackground> createState() => _CoffeeBackgroundState();
}

class _CoffeeBackgroundState extends State<CoffeeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Coffee.paper),
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _PaperPainter(_c.value),
            isComplex: true,
            willChange: true,
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Breathing warm glow, top-centre — like light over a counter.
    final glow = _lerp(0.10, 0.18, t);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -1.05),
          radius: 1.25,
          colors: [
            Coffee.amber.withValues(alpha: glow),
            Coffee.paper.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );

    // Coffee-ring stains — concentric espresso rings, very faint.
    _coffeeRing(canvas, Offset(size.width * 0.86, size.height * 0.16), 64);
    _coffeeRing(canvas, Offset(size.width * 0.12, size.height * 0.78), 96);
    _coffeeRing(canvas, Offset(size.width * 0.78, size.height * 0.9), 54);

    // Paper grain — a sparse deterministic speckle.
    final rnd = math.Random(7);
    final grain = Paint()..color = Coffee.espresso.withValues(alpha: 0.022);
    final count = (size.width * size.height / 2600).clamp(0, 1400).toInt();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 0.8 + 0.2, grain);
    }

    // Soft warm vignette at the bottom for grounding.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: [
            Coffee.paper.withValues(alpha: 0),
            Coffee.espresso.withValues(alpha: 0.04),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  void _coffeeRing(Canvas canvas, Offset center, double r) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Coffee.espresso.withValues(alpha: 0.05);
    canvas.drawCircle(center, r, ring);
    canvas.drawCircle(center, r - 5, ring..strokeWidth = 1.2);
    canvas.drawCircle(
      center,
      r - 1.6,
      Paint()..color = Coffee.espresso.withValues(alpha: 0.015),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _PaperPainter old) => old.t != t;
}

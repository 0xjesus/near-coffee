import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// Staggered fade + rise on mount. `delay` orchestrates the page-load cascade.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.dy = 14,
  });
  final Widget child;
  final Duration delay;
  final double dy;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.dy),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// A piece of warm paper: soft, slightly lifted, faint border.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color = Coffee.receipt,
    this.radius = Coffee.rLg,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Coffee.line, width: 1),
        boxShadow: [
          BoxShadow(
            color: Coffee.espresso.withValues(alpha: 0.10),
            blurRadius: 30,
            spreadRadius: -6,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Receipt-style horizontal dashed rule.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.color = Coffee.line, this.dash = 5, this.gap = 4});
  final Color color;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 1,
        width: double.infinity,
        child: CustomPaint(painter: _DashPainter(color, dash, gap)),
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.dash, this.gap);
  final Color color;
  final double dash, gap;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, size.width), 0), p);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => false;
}

/// Clips its child with a torn/perforated bottom (and optionally top) edge —
/// the tear-off look of a paper receipt.
class TornEdge extends StatelessWidget {
  const TornEdge({super.key, required this.child, this.top = false, this.bottom = true});
  final Widget child;
  final bool top, bottom;

  @override
  Widget build(BuildContext context) =>
      ClipPath(clipper: _TornClipper(top: top, bottom: bottom), child: child);
}

class _TornClipper extends CustomClipper<Path> {
  _TornClipper({required this.top, required this.bottom});
  final bool top, bottom;
  static const _tooth = 9.0;

  @override
  Path getClip(Size size) {
    final path = Path();
    final n = (size.width / _tooth).floor();
    final w = size.width / n;
    path.moveTo(0, top ? _tooth : 0);
    if (top) {
      for (var i = 0; i < n; i++) {
        path.lineTo(w * i + w / 2, 0);
        path.lineTo(w * (i + 1), _tooth);
      }
    } else {
      path.lineTo(size.width, 0);
    }
    path.lineTo(size.width, bottom ? size.height - _tooth : size.height);
    if (bottom) {
      for (var i = n; i > 0; i--) {
        path.lineTo(w * i - w / 2, size.height);
        path.lineTo(w * (i - 1), size.height - _tooth);
      }
    } else {
      path.lineTo(0, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TornClipper old) => false;
}

/// Small caps "stamped" eyebrow label.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = Coffee.inkSoft});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: Coffee.stamp(11, color: color));
}

/// Primary terracotta call-to-action with a tactile press + loading state.
class CoffeeButton extends StatefulWidget {
  const CoffeeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.filled = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final bool filled;

  @override
  State<CoffeeButton> createState() => _CoffeeButtonState();
}

class _CoffeeButtonState extends State<CoffeeButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled && !widget.loading && widget.onPressed != null;
    final fg = widget.filled ? Colors.white : Coffee.terracotta;
    return AnimatedScale(
      scale: _down && on ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: on ? (_) => setState(() => _down = true) : null,
        onTapUp: on ? (_) => setState(() => _down = false) : null,
        onTapCancel: on ? () => setState(() => _down = false) : null,
        onTap: on ? widget.onPressed : null,
        child: AnimatedOpacity(
          opacity: on ? 1 : 0.45,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.filled ? Coffee.terracotta : Colors.transparent,
              borderRadius: BorderRadius.circular(Coffee.rMd),
              border: widget.filled
                  ? null
                  : Border.all(color: Coffee.terracotta, width: 1.6),
              boxShadow: widget.filled && on
                  ? [
                      BoxShadow(
                        color: Coffee.terracotta.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: widget.loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label,
                          style: Coffee.body(16.5,
                              weight: FontWeight.w700, color: fg)),
                      if (widget.icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(widget.icon, size: 19, color: fg),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The rotated "PAID" stamp that thumps onto the receipt once a tip settles.
class PaidStamp extends StatefulWidget {
  const PaidStamp({super.key, this.label = 'PAID'});
  final String label;
  @override
  State<PaidStamp> createState() => _PaidStampState();
}

class _PaidStampState extends State<PaidStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0, 0.4));
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: fade.value,
        child: Transform.rotate(
          angle: -0.16,
          child: Transform.scale(scale: 1.6 - 0.6 * pop.value, child: child),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Coffee.mintInk, width: 2.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(widget.label,
            style: Coffee.stamp(20, color: Coffee.mintInk)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF070B19), // Deep background
        ),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              painter: FloatingShapesPainter(_ctrl.value),
              size: Size.infinite,
            );
          },
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class FloatingShapesPainter extends CustomPainter {
  final double time;
  FloatingShapesPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
      
    final paint2 = Paint()
      ..color = const Color(0xFFB000FF).withAlpha(15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Shape 1
    final cx1 = size.width * 0.2 + math.sin(time * math.pi * 2) * size.width * 0.2;
    final cy1 = size.height * 0.3 + math.cos(time * math.pi * 2) * size.height * 0.2;
    canvas.drawCircle(Offset(cx1, cy1), size.width * 0.4, paint1);

    // Shape 2
    final cx2 = size.width * 0.8 + math.cos(time * math.pi * 2) * size.width * 0.15;
    final cy2 = size.height * 0.7 + math.sin(time * math.pi * 2) * size.height * 0.25;
    canvas.drawCircle(Offset(cx2, cy2), size.width * 0.5, paint2);
  }

  @override
  bool shouldRepaint(covariant FloatingShapesPainter old) => old.time != time;
}

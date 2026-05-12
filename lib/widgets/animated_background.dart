import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/constants.dart';

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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.background, AppColors.backgroundEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return RepaintBoundary(
              child: CustomPaint(
                painter: FloatingShapesPainter(_ctrl.value),
                size: Size.infinite,
              ),
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
    final colors = [
      AppColors.accentCyan.withAlpha(90),
      AppColors.accentPink.withAlpha(90),
      AppColors.accentPurple.withAlpha(90),
      AppColors.accentAmber.withAlpha(90),
    ];
    
    final radius = size.width * 0.7;

    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.15);

      final double angle = (time * math.pi * 2) + (i * math.pi / 2);
      final double cx = size.width / 2 + math.sin(angle) * (size.width * 0.3);
      final double cy = size.height / 2 + math.cos(angle * 0.8) * (size.height * 0.2);
      
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FloatingShapesPainter old) => old.time != time;
}

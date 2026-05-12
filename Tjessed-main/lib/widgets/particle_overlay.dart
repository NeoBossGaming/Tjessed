import 'package:flutter/material.dart';

class Particle {
  final double dx;
  final double dy;
  final double speed;
  final double size;
  final Color color;

  Particle(this.dx, this.dy, this.speed, this.size, this.color);
}

class TransientEffect {
  final String id;
  final String type; // 'capture', 'powerup'
  final String? square;
  final Color? color;
  final DateTime startTime;
  final int lifespanMs;
  final List<Particle> particles;

  TransientEffect({
    required this.id,
    required this.type,
    this.square,
    this.color,
    this.lifespanMs = 600,
    List<Particle>? particles,
  })  : startTime = DateTime.now(),
        particles = particles ?? [];
}

class ParticleOverlay extends StatefulWidget {
  final List<TransientEffect> effects;
  final double boardSize;
  final bool isWhiteOrientation;

  const ParticleOverlay({
    super.key,
    required this.effects,
    required this.boardSize,
    required this.isWhiteOrientation,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final now = DateTime.now();
          final activeEffects = widget.effects.where((e) {
            final age = now.difference(e.startTime).inMilliseconds;
            return age < e.lifespanMs;
          }).toList();

          if (activeEffects.isEmpty) return const SizedBox.shrink();

          return CustomPaint(
            size: Size(widget.boardSize, widget.boardSize),
            painter: ParticlePainter(
              effects: activeEffects,
              now: now,
              boardSize: widget.boardSize,
              isWhiteOrientation: widget.isWhiteOrientation,
            ),
          );
        },
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<TransientEffect> effects;
  final DateTime now;
  final double boardSize;
  final bool isWhiteOrientation;

  ParticlePainter({
    required this.effects,
    required this.now,
    required this.boardSize,
    required this.isWhiteOrientation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sqSize = size.width / 8;

    for (var e in effects) {
      final ageMs = now.difference(e.startTime).inMilliseconds;
      final progress = (ageMs / e.lifespanMs).clamp(0.0, 1.0);

      if (e.type == 'capture' && e.square != null) {
        final (row, col) = _visualPos(e.square!, isWhiteOrientation);
        final cx = col * sqSize + sqSize / 2;
        final cy = row * sqSize + sqSize / 2;

        for (var p in e.particles) {
          final px = cx + p.dx * p.speed * progress * sqSize;
          final py = cy + p.dy * p.speed * progress * sqSize;
          final opacity = (1.0 - progress).clamp(0.0, 1.0);
          final paint = Paint()
            ..color = p.color.withAlpha((opacity * 255).toInt())
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(px, py), p.size * (1.0 - progress * 0.5), paint);
        }
      } else if (e.type == 'powerup' && e.color != null) {
        // Shockwave + small particles
        final double cx, cy;
        if (e.square != null) {
          final (row, col) = _visualPos(e.square!, isWhiteOrientation);
          cx = col * sqSize + sqSize / 2;
          cy = row * sqSize + sqSize / 2;
        } else {
          cx = size.width / 2;
          cy = size.height / 2;
        }

        final radius = progress * size.width * 0.5;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);

        // Shockwave
        final wavePaint = Paint()
          ..color = e.color!.withAlpha((opacity * 180).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * (1.0 - progress);
        canvas.drawCircle(Offset(cx, cy), radius, wavePaint);

        // Burst particles
        for (var p in e.particles) {
          final px = cx + p.dx * p.speed * progress * sqSize;
          final py = cy + p.dy * p.speed * progress * sqSize;
          final pPaint = Paint()
            ..color = p.color.withAlpha((opacity * 255).toInt())
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(px, py), p.size * (1.0 - progress), pPaint);
        }
      }
    }
  }

  (int, int) _visualPos(String square, bool isWhiteOrientation) {
    int col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int row = 8 - int.parse(square[1]);
    if (!isWhiteOrientation) {
      row = 7 - row;
      col = 7 - col;
    }
    return (row, col);
  }

  @override
  bool shouldRepaint(covariant ParticlePainter old) => true;
}

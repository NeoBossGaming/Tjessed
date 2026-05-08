import 'package:flutter/material.dart';
import '../models/powerup.dart';
import '../utils/constants.dart';
import 'dart:math' as math;

class VfxOverlay extends StatefulWidget {
  final List<ActiveEffect> activeEffects;
  final double boardSize;
  final bool isWhiteOrientation;

  const VfxOverlay({
    super.key,
    required this.activeEffects,
    required this.boardSize,
    required this.isWhiteOrientation,
  });

  @override
  State<VfxOverlay> createState() => _VfxOverlayState();
}

class _VfxOverlayState extends State<VfxOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeEffects.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: VfxPainter(
            effects: widget.activeEffects,
            isWhiteOrientation: widget.isWhiteOrientation,
            time: _ctrl.value,
          ),
        ),
      ),
    );
  }
}

class VfxPainter extends CustomPainter {
  final List<ActiveEffect> effects;
  final bool isWhiteOrientation;
  final double time;

  const VfxPainter({
    required this.effects,
    required this.isWhiteOrientation,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sq = size.width / 8;
    for (var e in effects) {
      switch (e.type) {
        case PowerupType.holyShield:
          if (e.targetSquare != null) _paintShield(canvas, e.targetSquare!, sq);
          break;
        case PowerupType.fortress:
          if (e.affectedSquares != null) _paintFortress(canvas, e.affectedSquares!, sq);
          break;
        case PowerupType.freeze:
          _paintFreeze(canvas, size);
          break;
        default:
          break;
      }
    }
  }

  void _paintShield(Canvas canvas, String square, double sq) {
    final (row, col) = _visualPos(square);
    final cx = col * sq + sq / 2;
    final cy = row * sq + sq / 2;
    final radius = sq * 0.45 + math.sin(time * math.pi * 2) * 2;

    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = AppColors.accentAmber.withAlpha(76)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = AppColors.accentAmber.withAlpha(204)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintFortress(Canvas canvas, List<String> squares, double sq) {
    final fillPaint = Paint()
      ..color = AppColors.tierRare.withAlpha(76)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppColors.tierRare.withAlpha(51)
      ..strokeWidth = 1;

    for (var s in squares) {
      final (row, col) = _visualPos(s);
      final rect = Rect.fromLTWH(col * sq, row * sq, sq, sq);
      canvas.drawRect(rect, fillPaint);
      // Hatch lines
      for (double i = 0; i < sq; i += sq / 4) {
        canvas.drawLine(
          Offset(rect.left + i, rect.top),
          Offset(rect.left, rect.top + i),
          linePaint,
        );
      }
    }
  }

  void _paintFreeze(Canvas canvas, Size size) {
    final opacity = (0.1 + math.sin(time * math.pi * 2) * 0.05).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            AppColors.accentCyan.withAlpha((opacity * 255).toInt()),
            AppColors.accentCyan.withAlpha((opacity * 2 * 255).clamp(0, 255).toInt()),
          ],
          stops: const [0.5, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  (int, int) _visualPos(String square) {
    int col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int row = 8 - int.parse(square[1]);
    if (!isWhiteOrientation) {
      row = 7 - row;
      col = 7 - col;
    }
    return (row, col);
  }

  @override
  bool shouldRepaint(covariant VfxPainter old) =>
      old.time != time || old.effects != effects;
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import 'glass_container.dart';

class TimerWidget extends StatelessWidget {
  final int timeInSeconds;
  final bool isRunning;

  const TimerWidget({
    super.key,
    required this.timeInSeconds,
    this.isRunning = false,
  });

  String get formattedTime {
    final m = timeInSeconds ~/ 60;
    final s = timeInSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeInSeconds <= 30;
    final color = isLowTime ? AppColors.accentRed : (isRunning ? AppColors.accentCyan : AppColors.textSecondary);

    Widget timerText = Text(
      formattedTime,
      style: AppTextStyles.heading2.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        shadows: isRunning ? [Shadow(color: color.withAlpha(150), blurRadius: 10)] : null,
      ),
    );

    if (isRunning && isLowTime) {
      timerText = timerText.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.05, duration: 500.ms);
    }

    return GlassContainer(
      opacity: 0.15,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: AppDimensions.borderRadiusSmall,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: color, size: 24),
          const SizedBox(width: 8),
          timerText,
        ],
      ),
    );
  }
}

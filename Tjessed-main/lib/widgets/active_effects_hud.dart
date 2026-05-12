import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/powerup.dart';
import '../utils/constants.dart';

/// Compact HUD showing all active powerup effects with turns remaining.
class ActiveEffectsHud extends StatelessWidget {
  final List<ActiveEffect> activeEffects;

  const ActiveEffectsHud({super.key, required this.activeEffects});

  @override
  Widget build(BuildContext context) {
    if (activeEffects.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: activeEffects.map((effect) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _EffectChip(effect: effect),
        );
      }).toList(),
    );
  }
}

class _EffectChip extends StatelessWidget {
  final ActiveEffect effect;

  const _EffectChip({required this.effect});

  @override
  Widget build(BuildContext context) {
    final color = effect.type.tier.color;
    final isUrgent = effect.turnsRemaining <= 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha(isUrgent ? 200 : 100),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(40),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(effect.type.icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            effect.type.name,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withAlpha(220),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isUrgent 
                  ? AppColors.accentRed.withAlpha(150) 
                  : color.withAlpha(100),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${effect.turnsRemaining}T',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }
}

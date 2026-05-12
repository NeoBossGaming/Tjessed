import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/powerup.dart';
import '../utils/constants.dart';

class CardRevealOverlay extends StatelessWidget {
  final PowerupType powerup;
  final VoidCallback onDismiss;

  const CardRevealOverlay({
    super.key,
    required this.powerup,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final tier = powerup.tier;
    final color = tier.color;

    return Material(
      color: Colors.black.withAlpha(220),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Stack(
          children: [
            // Background particles/shimmer based on rarity
            if (tier.level >= 4)
              _buildBackgroundEffects(tier),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${tier.label.toUpperCase()} POWER-UP!',
                    style: AppTextStyles.heading3.copyWith(color: color, letterSpacing: 4),
                  ).animate().fade(duration: 250.ms).slideY(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  // The Card
                  Container(
                    width: 200,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [color.withAlpha(100), color.withAlpha(40), Colors.black54],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: color, width: 3),
                      boxShadow: [
                        BoxShadow(color: color.withAlpha(150), blurRadius: 40, spreadRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(powerup.icon, color: color, size: 80),
                        const SizedBox(height: 20),
                        Text(powerup.name, style: AppTextStyles.heading2, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            powerup.description,
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutBack)
                  .shimmer(delay: 350.ms, duration: 1200.ms, color: Colors.white24),

                  const SizedBox(height: 60),
                  
                  Text('TAP TO CONTINUE', style: AppTextStyles.caption.copyWith(color: Colors.white54))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(duration: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundEffects(PowerupTier tier) {
    // Add epic/legendary specific backgrounds like sparkles or flashes
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [tier.color.withAlpha(40), Colors.transparent],
              radius: 1.2,
            ),
          ),
        ).animate(onPlay: (c) => c.repeat()).tint(color: tier.color, duration: 2.seconds),
      ),
    );
  }
}

/// Helper to show the reveal overlay
void showCardReveal(BuildContext context, PowerupType powerup) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'CardReveal',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) {
      return CardRevealOverlay(
        powerup: powerup,
        onDismiss: () => Navigator.pop(context),
      );
    },
  );
}

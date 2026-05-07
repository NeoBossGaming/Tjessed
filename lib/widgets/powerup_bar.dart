import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/powerup.dart';
import '../utils/constants.dart';
import 'glass_container.dart';

class PowerupBar extends StatelessWidget {
  final List<PowerupType> heldPowerups;
  final bool isMyTurn;

  const PowerupBar({
    super.key,
    required this.heldPowerups,
    required this.isMyTurn,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.all(12),
      borderRadius: AppDimensions.borderRadius,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(GameConstants.maxPowerupsHeld, (index) {
          if (index < heldPowerups.length) {
            final p = heldPowerups[index];
            return _PowerupCard(
              p: p,
              isMyTurn: isMyTurn,
            );
          }
          return _buildEmptySlot();
        }),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: 64,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        color: AppColors.surfaceLight.withAlpha(30),
        border: Border.all(
          color: AppColors.textMuted.withAlpha(50),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          color: AppColors.textMuted.withAlpha(80),
        ),
      ),
    );
  }
}

class _PowerupCard extends StatefulWidget {
  final PowerupType p;
  final bool isMyTurn;

  const _PowerupCard({
    required this.p,
    required this.isMyTurn,
  });

  @override
  State<_PowerupCard> createState() => _PowerupCardState();
}

class _PowerupCardState extends State<_PowerupCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final card = _buildCardContent(isDragging: false);

    return Tooltip(
      message: "${widget.p.name}\n${widget.p.description}",
      textStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.background, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: widget.p.tier.color.withAlpha(240),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.isMyTurn ? SystemMouseCursors.grab : SystemMouseCursors.basic,
        child: Draggable<PowerupType>(
          data: widget.p,
          maxSimultaneousDrags: widget.isMyTurn ? 1 : 0,
          feedback: Material(
            color: Colors.transparent,
            child: _buildCardContent(isDragging: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: card,
          ),
          child: AnimatedScale(
            scale: _isHovered ? 1.15 : 1.0,
            duration: 200.ms,
            curve: Curves.easeOutBack,
            child: card,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent({required bool isDragging}) {
    return Container(
      width: 64,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.p.tier.color.withAlpha(isDragging ? 100 : 60),
            widget.p.tier.color.withAlpha(isDragging ? 60 : 30),
          ],
        ),
        border: Border.all(
          color: widget.p.tier.color.withAlpha(isDragging || _isHovered ? 255 : 150),
          width: (isDragging || _isHovered) ? 2.5 : 1.5,
        ),
        boxShadow: (widget.isMyTurn || _isHovered || isDragging) ? [
          BoxShadow(
            color: widget.p.tier.color.withAlpha(isDragging ? 200 : (_isHovered ? 150 : 80)),
            blurRadius: isDragging ? 30 : (_isHovered ? 20 : 10),
            spreadRadius: isDragging ? 5 : 2,
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.p.icon,
            color: widget.p.tier.color,
            size: isDragging ? 38 : 32,
          ),
          const SizedBox(height: 4),
          Text(
            widget.p.tier.label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: widget.p.tier.color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ).animate(target: widget.isMyTurn && !isDragging ? 1 : 0)
     .shimmer(duration: 2.seconds, color: Colors.white.withAlpha(100));
  }
}

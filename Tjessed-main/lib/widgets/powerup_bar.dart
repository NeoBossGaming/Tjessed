import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/powerup.dart';
import '../utils/constants.dart';
import 'card_widget.dart';

class PowerupBar extends StatelessWidget {
  final List<PowerupType> heldPowerups;
  final bool isMyTurn;
  final Function(PowerupType)? onPowerupTap;

  const PowerupBar({
    super.key,
    required this.heldPowerups,
    required this.isMyTurn,
    this.onPowerupTap,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 80;
    const double cardHeight = 110;
    
    return Container(
      height: cardHeight + 40,
      width: double.infinity,
      alignment: Alignment.bottomCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Background slots (optional, could just show nothing if empty)
              if (heldPowerups.isEmpty)
                 Text(
                   'CAPTURE PIECES TO EARN POWER-UPS',
                   style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                 ),
              
              // Fanned cards
              ...List.generate(heldPowerups.length, (index) {
                final p = heldPowerups[index];
                return _FannedCard(
                  index: index,
                  total: heldPowerups.length,
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  barWidth: barWidth,
                  onTap: () {
                    if (isMyTurn && onPowerupTap != null) {
                      onPowerupTap!(p);
                    }
                  },
                  child: CardWidget(
                    powerup: p,
                    isMyTurn: isMyTurn,
                    width: cardWidth,
                    height: cardHeight,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _FannedCard extends StatefulWidget {
  final int index;
  final int total;
  final double cardWidth;
  final double cardHeight;
  final double barWidth;
  final VoidCallback onTap;
  final Widget child;

  const _FannedCard({
    required this.index,
    required this.total,
    required this.cardWidth,
    required this.cardHeight,
    required this.barWidth,
    required this.onTap,
    required this.child,
  });

  @override
  State<_FannedCard> createState() => _FannedCardState();
}

class _FannedCardState extends State<_FannedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Calculate rotation and offset for the fan effect
    final double spreadAngle = 12.0; // Total degrees to spread
    final double angleStep = widget.total > 1 ? spreadAngle / (widget.total - 1) : 0;
    final double startAngle = -(spreadAngle / 2);
    final double currentAngle = startAngle + (widget.index * angleStep);
    
    // Convert degrees to radians for Transform
    final double radians = currentAngle * (math.pi / 180);
    
    // Horizontal offset to space them out even while fanned — use barWidth for centering
    final double xOffset = (widget.index - (widget.total - 1) / 2) * (widget.cardWidth * 0.6);
    
    // Vertical offset to create the "arc" effect
    final double yArc = math.pow((widget.index - (widget.total - 1) / 2), 2) * 5.0;

    return Positioned(
      bottom: _isHovered ? 25 : 10,
      left: (widget.barWidth / 2) - (widget.cardWidth / 2) + xOffset,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Transform.rotate(
            angle: radians,
            child: Transform.translate(
              offset: Offset(0, yArc),
              child: Draggable<PowerupType>(
                data: (widget.child as CardWidget).powerup,
                feedback: Material(
                  color: Colors.transparent,
                  child: CardWidget(
                    powerup: (widget.child as CardWidget).powerup,
                    isMyTurn: true,
                    width: widget.cardWidth * 1.2,
                    height: widget.cardHeight * 1.2,
                    isDragging: true,
                  ),
                ),
                childWhenDragging: const SizedBox.shrink(),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/powerup.dart';
import '../utils/constants.dart';

/// A single power-up card with rarity-colored gradient, glow, and category badge.
class CardWidget extends StatefulWidget {
  final PowerupType powerup;
  final bool isMyTurn;
  final double width;
  final double height;
  final bool isDragging;

  const CardWidget({
    super.key,
    required this.powerup,
    this.isMyTurn = false,
    this.width = 72,
    this.height = 100,
    this.isDragging = false,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.powerup;
    final tierColor = p.tier.color;
    final isHighTier = p.tier.level >= 4;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor:
          widget.isMyTurn ? SystemMouseCursors.grab : SystemMouseCursors.basic,
      child: Tooltip(
        message:
            '${p.name}\n${p.description}\n${p.category.label} • ${p.tier.label}',
        textStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.background,
          fontWeight: FontWeight.bold,
        ),
        decoration: BoxDecoration(
          color: tierColor.withAlpha(240),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        ),
        child: AnimatedScale(
          scale: widget.isDragging ? 1.1 : (_isHovered ? 1.15 : 1.0),
          duration: 200.ms,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
                duration: 200.ms,
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tierColor,
                      Color.lerp(tierColor, Colors.black, 0.15)!,
                    ],
                  ),
                  border: Border.all(
                    color: tierColor.withAlpha(
                      widget.isDragging || _isHovered ? 255 : 150,
                    ),
                    width: (widget.isDragging || _isHovered) ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    if (widget.isMyTurn || _isHovered || widget.isDragging)
                      BoxShadow(
                        color: tierColor.withAlpha(
                          widget.isDragging ? 200 : (_isHovered ? 150 : 60),
                        ),
                        blurRadius:
                            widget.isDragging ? 30 : (_isHovered ? 20 : 8),
                        spreadRadius: widget.isDragging ? 5 : 2,
                      ),
                    if (isHighTier && (widget.isMyTurn || _isHovered))
                      BoxShadow(
                        color: tierColor.withAlpha(80),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Category badge (top-left corner)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: p.category.color.withAlpha(60),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: p.category.color.withAlpha(120),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          p.category.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    // Main content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),
                          Icon(
                            p.icon,
                            color: Colors.white,
                            size: widget.isDragging ? 34 : 28,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              p.name,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(150),
                                    blurRadius: 2,
                                  )
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.tier.label.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(150),
                                  blurRadius: 2,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate(target: widget.isMyTurn && !widget.isDragging ? 1 : 0)
              .shimmer(duration: 2.seconds, color: Colors.white.withAlpha(60)),
        ),
      ).animate(target: widget.isMyTurn ? 0 : 1).custom(
        builder: (context, value, child) => ColorFiltered(
          colorFilter: ColorFilter.matrix([
            0.2126 + 0.7874 * (1 - value), 0.7152 - 0.7152 * (1 - value), 0.0722 - 0.0722 * (1 - value), 0, 0,
            0.2126 - 0.2126 * (1 - value), 0.7152 + 0.2848 * (1 - value), 0.0722 - 0.0722 * (1 - value), 0, 0,
            0.2126 - 0.2126 * (1 - value), 0.7152 - 0.7152 * (1 - value), 0.0722 + 0.9278 * (1 - value), 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        ),
      ),
    );
  }
}

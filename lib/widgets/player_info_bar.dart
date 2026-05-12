import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'glass_container.dart';

class PlayerInfoBar extends StatelessWidget {
  final String fallbackName;
  final List<String> capturedPieces;
  final bool isTop;

  const PlayerInfoBar({
    super.key,
    required this.fallbackName,
    required this.capturedPieces,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: AppDimensions.borderRadius,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceLight,
                  child: Text(
                    fallbackName[0].toUpperCase(),
                    style: AppTextStyles.heading2.copyWith(color: AppColors.accentCyan, fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fallbackName, style: AppTextStyles.heading3),
                ],
              ),
            ],
          ),
          Row(
            children: capturedPieces.map((p) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                ChessPieceUnicode.white[p.toLowerCase()] ?? p,
                style: TextStyle(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                  shadows: [
                    Shadow(color: Colors.black.withAlpha(50), blurRadius: 2),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

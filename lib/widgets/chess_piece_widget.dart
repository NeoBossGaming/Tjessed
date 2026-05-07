import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ChessPieceWidget extends StatelessWidget {
  final String pieceType;
  final String color;
  final double size;

  const ChessPieceWidget({
    super.key,
    required this.pieceType,
    required this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // For now, we use unicode characters as placeholders.
    // Later this can be swapped with Image.asset()
    String unicode = color == 'white'
        ? ChessPieceUnicode.white[pieceType] ?? ''
        : ChessPieceUnicode.black[pieceType] ?? '';

    // To make black pieces visible on dark boards, we can add a subtle text shadow
    return Center(
      child: Text(
        unicode,
        style: TextStyle(
          fontSize: size * 0.8,
          fontWeight: color == 'white' ? FontWeight.w900 : FontWeight.normal,
          color: color == 'white' ? Colors.white : Colors.black87,
          shadows: [
            Shadow(
              color: color == 'white' ? Colors.black.withAlpha(200) : Colors.white.withAlpha(120),
              blurRadius: 6.0,
              offset: const Offset(0, 3),
            ),
            Shadow(
              color: color == 'white' ? AppColors.accentCyan.withAlpha(150) : AppColors.accentRed.withAlpha(150),
              blurRadius: 12.0,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';


import '../services/settings_service.dart';

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
    final bool isWhite = color == 'white';
    final double actualSize = size * 0.9; // Slight padding
    final bool isOutlined = SettingsService().pieceStyle == 'Outlined';

    Widget pieceWidget;
    
    // For outlined style on black pieces, we use the White SVG (which has an outline) 
    // but tint it dark gray so it's distinguishable from white pieces.
    final bool useWhiteSvg = isWhite || isOutlined;
    
    switch (pieceType.toLowerCase()) {
      case 'p':
        pieceWidget = useWhiteSvg ? WhitePawn(size: actualSize) : BlackPawn(size: actualSize);
        break;
      case 'n':
        pieceWidget = useWhiteSvg ? WhiteKnight(size: actualSize) : BlackKnight(size: actualSize);
        break;
      case 'b':
        pieceWidget = useWhiteSvg ? WhiteBishop(size: actualSize) : BlackBishop(size: actualSize);
        break;
      case 'r':
        pieceWidget = useWhiteSvg ? WhiteRook(size: actualSize) : BlackRook(size: actualSize);
        break;
      case 'q':
        pieceWidget = useWhiteSvg ? WhiteQueen(size: actualSize) : BlackQueen(size: actualSize);
        break;
      case 'k':
        pieceWidget = useWhiteSvg ? WhiteKing(size: actualSize) : BlackKing(size: actualSize);
        break;
      default:
        pieceWidget = const SizedBox.shrink();
    }

    if (!isWhite && isOutlined) {
      pieceWidget = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFF555555), // Dark gray tint for outlined black pieces
          BlendMode.modulate,
        ),
        child: pieceWidget,
      );
    }

    return Center(
      child: pieceWidget,
    );
  }
}

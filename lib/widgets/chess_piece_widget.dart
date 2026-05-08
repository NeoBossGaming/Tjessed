import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';


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

    Widget pieceWidget;
    switch (pieceType.toLowerCase()) {
      case 'p':
        pieceWidget = isWhite ? WhitePawn(size: actualSize) : BlackPawn(size: actualSize);
        break;
      case 'n':
        pieceWidget = isWhite ? WhiteKnight(size: actualSize) : BlackKnight(size: actualSize);
        break;
      case 'b':
        pieceWidget = isWhite ? WhiteBishop(size: actualSize) : BlackBishop(size: actualSize);
        break;
      case 'r':
        pieceWidget = isWhite ? WhiteRook(size: actualSize) : BlackRook(size: actualSize);
        break;
      case 'q':
        pieceWidget = isWhite ? WhiteQueen(size: actualSize) : BlackQueen(size: actualSize);
        break;
      case 'k':
        pieceWidget = isWhite ? WhiteKing(size: actualSize) : BlackKing(size: actualSize);
        break;
      default:
        pieceWidget = const SizedBox.shrink();
    }

    return Center(
      child: pieceWidget,
    );
  }
}

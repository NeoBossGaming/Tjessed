import 'package:flutter/material.dart';
import '../engine/chess_engine.dart';
import '../utils/constants.dart';
import 'chess_piece_widget.dart';
import '../models/powerup.dart';

class ChessBoardWidget extends StatefulWidget {
  final ChessEngine engine;
  final double size;
  final bool isWhiteOrientation;
  final Function(String from, String to, String? promotion) onMove;
  final Function(String square)? onSquareTap;
  final List<ActiveEffect> activeEffects;
  final String? selectedSquare;
  final List<String> highlightedSquares;
  final List<String> lastMoveSquares;

  const ChessBoardWidget({
    super.key,
    required this.engine,
    required this.size,
    required this.isWhiteOrientation,
    required this.onMove,
    this.onSquareTap,
    this.activeEffects = const [],
    this.selectedSquare,
    this.highlightedSquares = const [],
    this.lastMoveSquares = const [],
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  @override
  Widget build(BuildContext context) {
    double squareSize = widget.size / 8;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // 1. Board Squares
          _buildBoard(squareSize),
          
          // 2. Highlights & Effects
          _buildHighlights(squareSize),
          
          // 3. Pieces
          _buildPieces(squareSize),
        ],
      ),
    );
  }

  Widget _buildBoard(double squareSize) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        int row = index ~/ 8;
        int col = index % 8;

        // Adjust for orientation
        if (!widget.isWhiteOrientation) {
          row = 7 - row;
          col = 7 - col;
        }

        bool isLight = (row + col) % 2 == 0;
        return Container(
          color: isLight ? AppColors.boardLight : AppColors.boardDark,
        );
      },
    );
  }

  Widget _buildHighlights(double squareSize) {
    List<Widget> highlights = [];

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        int visualRow = widget.isWhiteOrientation ? r : 7 - r;
        int visualCol = widget.isWhiteOrientation ? c : 7 - c;
        
        String square = gridToSquare(r, c);

        // Last move highlight
        if (widget.lastMoveSquares.contains(square)) {
          highlights.add(_buildHighlight(visualRow, visualCol, squareSize, AppColors.lastMoveHighlight));
        }

        // Selected square highlight
        if (widget.selectedSquare == square) {
          highlights.add(_buildHighlight(visualRow, visualCol, squareSize, AppColors.selectedHighlight));
        }

        // Legal move highlight
        if (widget.highlightedSquares.contains(square)) {
          bool hasPiece = widget.engine.getPiece(square) != null;
          highlights.add(
            Positioned(
              left: visualCol * squareSize,
              top: visualRow * squareSize,
              width: squareSize,
              height: squareSize,
              child: Center(
                child: Container(
                  width: hasPiece ? squareSize * 0.8 : squareSize * 0.3,
                  height: hasPiece ? squareSize * 0.8 : squareSize * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasPiece ? Colors.transparent : AppColors.moveHighlight,
                    border: hasPiece ? Border.all(color: AppColors.moveHighlight, width: 4) : null,
                  ),
                ),
              ),
            ),
          );
        }

        // Check highlight
        if (widget.engine.inCheck) {
          var piece = widget.engine.getPiece(square);
          if (piece != null && piece.type.toString() == 'k' && 
              (piece.color.toString() == 'w') == widget.engine.isWhiteTurn) {
            highlights.add(_buildHighlight(visualRow, visualCol, squareSize, AppColors.checkHighlight));
          }
        }
      }
    }

    return Stack(children: highlights);
  }

  Widget _buildHighlight(int visualRow, int visualCol, double size, Color color) {
    return Positioned(
      left: visualCol * size,
      top: visualRow * size,
      width: size,
      height: size,
      child: Container(color: color),
    );
  }

  Widget _buildPieces(double squareSize) {
    List<Widget> pieces = [];
    var boardPieces = widget.engine.getBoardPieces();

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        String square = gridToSquare(r, c);
        PieceInfo? piece = boardPieces[square];

        if (piece != null) {
          int visualRow = widget.isWhiteOrientation ? r : 7 - r;
          int visualCol = widget.isWhiteOrientation ? c : 7 - c;

          pieces.add(
            Positioned(
              left: visualCol * squareSize,
              top: visualRow * squareSize,
              width: squareSize,
              height: squareSize,
              child: GestureDetector(
                onTap: () {
                  if (widget.onSquareTap != null) {
                    widget.onSquareTap!(square);
                  }
                },
                child: ChessPieceWidget(
                  pieceType: piece.type,
                  color: piece.color,
                  size: squareSize,
                ),
              ),
            ),
          );
        } else {
          // Empty square tap target
          int visualRow = widget.isWhiteOrientation ? r : 7 - r;
          int visualCol = widget.isWhiteOrientation ? c : 7 - c;
          pieces.add(
            Positioned(
              left: visualCol * squareSize,
              top: visualRow * squareSize,
              width: squareSize,
              height: squareSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (widget.onSquareTap != null) {
                    widget.onSquareTap!(square);
                  }
                },
                child: Container(),
              ),
            ),
          );
        }
      }
    }

    return Stack(children: pieces);
  }
}

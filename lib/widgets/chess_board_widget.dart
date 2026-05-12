import 'package:flutter/material.dart';
import '../engine/chess_engine.dart';
import '../utils/constants.dart';
import 'chess_piece_widget.dart';
import '../models/powerup.dart';
import '../services/settings_service.dart';

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
  final String? hoveredSquare;

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
    this.hoveredSquare,
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
        clipBehavior: Clip.hardEdge,
        children: [
          // 1. Board Squares (now using Positioned, matching pieces/highlights)
          _buildBoard(squareSize),
          
          // 2. Active effect overlays on squares
          _buildEffectOverlays(squareSize),

          // 3. Highlights & Effects
          _buildHighlights(squareSize),
          
          // 4. Pieces
          _buildPieces(squareSize),
        ],
      ),
    );
  }

  Widget _buildBoard(double squareSize) {
    return AnimatedBuilder(
      animation: SettingsService(),
      builder: (context, _) {
        final theme = SettingsService().boardTheme;
        List<Widget> squares = [];
        for (int r = 0; r < 8; r++) {
          for (int c = 0; c < 8; c++) {
            int logicalRow = r;
            int logicalCol = c;
            if (!widget.isWhiteOrientation) {
              logicalRow = 7 - r;
              logicalCol = 7 - c;
            }
            bool isLight = (logicalRow + logicalCol) % 2 == 0;
            squares.add(
              Positioned(
                left: c * squareSize,
                top: r * squareSize,
                width: squareSize,
                height: squareSize,
                child: Container(
                  color: isLight
                      ? AppColors.getBoardLight(theme)
                      : AppColors.getBoardDark(theme),
                ),
              ),
            );
          }
        }
        return Stack(children: squares);
      },
    );
  }

  Widget _buildEffectOverlays(double squareSize) {
    List<Widget> overlays = [];

    for (var effect in widget.activeEffects) {
      switch (effect.type) {
        case PowerupType.wall:
          if (effect.affectedSquares != null) {
            for (var sq in effect.affectedSquares!) {
              final (vr, vc) = _visualPos(sq);
              overlays.add(
                Positioned(
                  left: vc * squareSize,
                  top: vr * squareSize,
                  width: squareSize,
                  height: squareSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(60),
                      border: Border.all(
                        color: Colors.blue.withAlpha(180),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.view_column, 
                        color: Colors.blue.withAlpha(150), 
                        size: squareSize * 0.6),
                    ),
                  ),
                ),
              );
            }
          }
          break;
        case PowerupType.fortress:
          if (effect.affectedSquares != null) {
            for (var sq in effect.affectedSquares!) {
              final (vr, vc) = _visualPos(sq);
              overlays.add(
                Positioned(
                  left: vc * squareSize,
                  top: vr * squareSize,
                  width: squareSize,
                  height: squareSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withAlpha(50),
                      border: Border.all(
                        color: AppColors.accentAmber.withAlpha(150),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.castle, 
                        color: AppColors.accentAmber.withAlpha(120), 
                        size: squareSize * 0.5),
                    ),
                  ),
                ),
              );
            }
          }
          break;
        case PowerupType.holyShield:
          if (effect.targetSquare != null) {
            final (vr, vc) = _visualPos(effect.targetSquare!);
            overlays.add(
              Positioned(
                left: vc * squareSize,
                top: vr * squareSize,
                width: squareSize,
                height: squareSize,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.accentAmber.withAlpha(200),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(squareSize * 0.1),
                  ),
                  child: Center(
                    child: Icon(Icons.shield, 
                      color: AppColors.accentAmber.withAlpha(150), 
                      size: squareSize * 0.4),
                  ),
                ),
              ),
            );
          }
          break;
        case PowerupType.enrage:
          if (effect.targetSquare != null) {
            final (vr, vc) = _visualPos(effect.targetSquare!);
            overlays.add(
              Positioned(
                left: vc * squareSize,
                top: vr * squareSize,
                width: squareSize,
                height: squareSize,
                child: Container(
                  color: AppColors.accentRed.withAlpha(60),
                  child: Center(
                    child: Icon(Icons.local_fire_department, 
                      color: AppColors.accentRed.withAlpha(150), 
                      size: squareSize * 0.5),
                  ),
                ),
              ),
            );
          }
          break;
        case PowerupType.quickStep:
          if (effect.targetSquare != null) {
            final (vr, vc) = _visualPos(effect.targetSquare!);
            overlays.add(
              Positioned(
                left: vc * squareSize,
                top: vr * squareSize,
                width: squareSize,
                height: squareSize,
                child: Container(
                  color: AppColors.accentGreen.withAlpha(50),
                  child: Center(
                    child: Icon(Icons.keyboard_double_arrow_up, 
                      color: AppColors.accentGreen.withAlpha(180), 
                      size: squareSize * 0.5),
                  ),
                ),
              ),
            );
          }
          break;
        case PowerupType.crownThief:
          if (effect.targetSquare != null) {
            final (vr, vc) = _visualPos(effect.targetSquare!);
            overlays.add(
              Positioned(
                left: vc * squareSize,
                top: vr * squareSize,
                width: squareSize,
                height: squareSize,
                child: Container(
                  color: AppColors.accentPink.withAlpha(50),
                  child: Center(
                    child: Icon(Icons.remove_circle, 
                      color: AppColors.accentPink.withAlpha(150), 
                      size: squareSize * 0.4),
                  ),
                ),
              ),
            );
          }
          break;
        case PowerupType.sabotage:
          // Red border overlay around entire board
          overlays.add(
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.accentRed.withAlpha(120),
                      width: 4,
                    ),
                  ),
                ),
              ),
            ),
          );
          break;
        case PowerupType.freeze:
          // Blue frost overlay + pulsing edges
          overlays.add(
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.accentCyan.withAlpha(100),
                      width: 3,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accentCyan.withAlpha(30),
                        AppColors.accentCyan.withAlpha(60),
                      ],
                      stops: const [0.5, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          );
          break;
        default:
          break;
      }
    }

    return Stack(children: overlays);
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

        // Hover highlight
        if (widget.hoveredSquare == square) {
          highlights.add(
            Positioned(
              left: visualCol * squareSize,
              top: visualRow * squareSize,
              width: squareSize,
              height: squareSize,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withAlpha(150), width: 3),
                  color: Colors.white.withAlpha(40),
                ),
              ),
            ),
          );
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
              child: piece != null
                  ? ChessPieceWidget(
                      pieceType: piece.type,
                      color: piece.color,
                      size: squareSize,
                    )
                  : const SizedBox.expand(),
            ),
          ),
        );
      }
    }

    return Stack(children: pieces);
  }

  (int, int) _visualPos(String square) {
    int col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int row = 8 - int.parse(square[1]);
    if (!widget.isWhiteOrientation) {
      row = 7 - row;
      col = 7 - col;
    }
    return (row, col);
  }
}

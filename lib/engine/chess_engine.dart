import 'package:chess/chess.dart' as ch;
import '../models/powerup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHESS ENGINE - Wraps chess 0.7.0 with powerup-aware logic
// ─────────────────────────────────────────────────────────────────────────────

class EngineMove {
  final String from;
  final String to;
  final dynamic captured;
  
  EngineMove({required this.from, required this.to, this.captured});
}


class ChessEngine {
  ch.Chess _game;

  ChessEngine() : _game = ch.Chess();

  // ── Getters ─────────────────────────────────────────────────────────────────
  ch.Chess get game => _game;
  String get fen => _game.fen;
  bool get isWhiteTurn => _game.turn == ch.Color.WHITE;
  String get turnColor => isWhiteTurn ? 'white' : 'black';
  bool get inCheck => _game.in_check;
  bool get inCheckmate => _game.in_checkmate;
  bool get inStalemate => _game.in_stalemate;
  bool get inDraw => _game.in_draw;
  bool get gameOver => _game.game_over;

  // ── Board Setup ──────────────────────────────────────────────────────────────
  void loadFen(String fen) => _game = ch.Chess.fromFEN(fen);
  void reset() => _game = ch.Chess();

  // ── Piece Access ─────────────────────────────────────────────────────────────
  ch.Piece? getPiece(String square) => _game.get(square);

  // ── Move Generation ──────────────────────────────────────────────────────────
  /// Returns legal moves as a list of Move objects, optionally from a square, with powerup filters.
  List<ch.Move> getLegalMoves({
    String? fromSquare,
    List<ActiveEffect>? activeEffects,
  }) {
    Map<String, dynamic> opts = {'legal': true};
    if (fromSquare != null) opts['square'] = fromSquare;

    List<ch.Move> moves = _game.generate_moves(opts);

    if (activeEffects != null) {
      moves = _filterMovesForEffects(moves, activeEffects);
    }
    return moves;
  }

  /// Returns only the destination squares for a piece at [fromSquare].
  List<String> getLegalDestinations(String fromSquare, {List<ActiveEffect>? activeEffects}) {
    List<String> dests = getLegalMoves(fromSquare: fromSquare, activeEffects: activeEffects)
        .map((m) => m.toAlgebraic)
        .toList();
        
    if (activeEffects != null) {
      for (var effect in activeEffects) {
        if (effect.type == PowerupType.quickStep && effect.targetSquare == fromSquare) {
          // Pawn moves 2 squares forward
          ch.Piece? p = getPiece(fromSquare);
          if (p != null && p.type == ch.PieceType.PAWN) {
            int dir = p.color == ch.Color.WHITE ? 1 : -1;
            int rank = int.parse(fromSquare[1]);
            String file = fromSquare[0];
            int newRank = rank + 2 * dir;
            if (newRank >= 1 && newRank <= 8) {
              String sq2 = '$file$newRank';
              if (getPiece(sq2) == null) { // Quick Step allows leaping over pieces
                if (!dests.contains(sq2)) dests.add(sq2);
              }
            }
          }
        } else if (effect.type == PowerupType.enrage && effect.targetSquare == fromSquare) {
          // Pawn captures forward
          ch.Piece? p = getPiece(fromSquare);
          if (p != null && p.type == ch.PieceType.PAWN) {
            int dir = p.color == ch.Color.WHITE ? 1 : -1;
            int rank = int.parse(fromSquare[1]);
            String file = fromSquare[0];
            int newRank = rank + dir;
            if (newRank >= 1 && newRank <= 8) {
              String target = '$file$newRank';
              ch.Piece? targetP = getPiece(target);
              if (targetP != null && targetP.color != p.color) {
                if (!dests.contains(target)) dests.add(target);
              }
            }
          }
        }
      }
    }
    return dests;
  }

  // ── Make Move ────────────────────────────────────────────────────────────────
  /// Plays a move. Returns the Move object on success, null if illegal.
  EngineMove? makeMove(String from, String to, {String? promotion, List<ActiveEffect>? activeEffects}) {
    // Peek at move list before to find the matching Move object (captures etc.)
    ch.Move? matchingMove;
    for (var m in _game.generate_moves({'legal': true})) {
      if (m.fromAlgebraic == from && m.toAlgebraic == to) {
        if (promotion != null) {
          if (m.promotion != null && m.promotion.toString() == promotion) {
            matchingMove = m;
            break;
          }
        } else {
          matchingMove = m;
          break;
        }
      }
    }

    if (matchingMove != null) {
      Map<String, dynamic> moveMap = {'from': from, 'to': to};
      if (promotion != null) moveMap['promotion'] = promotion;
      _game.move(moveMap);
      return EngineMove(from: from, to: to, captured: matchingMove.captured);
    }
    
    // Check custom powerup moves
    if (activeEffects != null) {
      final dests = getLegalDestinations(from, activeEffects: activeEffects);
      if (dests.contains(to)) {
        ch.Piece? p = removePiece(from);
        ch.Piece? capturedPiece = getPiece(to);
        if (capturedPiece != null) removePiece(to);
        if (p != null) {
          putPiece(p.type.name, p.color == ch.Color.WHITE ? 'white' : 'black', to);
          swapTurn();
          return EngineMove(
            from: from,
            to: to,
            captured: capturedPiece?.type.name,
          );
        }
      }
    }

    return null;
  }

  /// Undo the last move.
  ch.Move? undo() => _game.undo_move();

  // ── History ──────────────────────────────────────────────────────────────────
  List<String> getHistory() {
    return _game.history
        .map((s) => '${s.move.fromAlgebraic}${s.move.toAlgebraic}')
        .toList();
  }

  /// Rebuild history as "e2e4" pairs for Firebase serialisation.
  String getHistoryString() => getHistory().where((s) => s.isNotEmpty).join(', ');

  // ── Board Snapshot ───────────────────────────────────────────────────────────
  Map<String, PieceInfo> getBoardPieces() {
    Map<String, PieceInfo> pieces = {};
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        String sq = gridToSquare(row, col);
        ch.Piece? piece = _game.get(sq);
        if (piece != null) {
          pieces[sq] = PieceInfo(
            type: piece.type.name,   // 'p','n','b','r','q','k'
            color: piece.color == ch.Color.WHITE ? 'white' : 'black',
            square: sq,
          );
        }
      }
    }
    return pieces;
  }

  // ── Board Manipulation (Powerups) ────────────────────────────────────────────
  /// Place a piece. Piece(type, color) order is PieceType first.
  bool putPiece(String typeStr, String colorStr, String square) {
    ch.PieceType? pt = _parsePieceType(typeStr);
    if (pt == null) return false;
    ch.Color c = colorStr == 'white' ? ch.Color.WHITE : ch.Color.BLACK;
    return _game.put(ch.Piece(pt, c), square);
  }

  /// Remove a piece from [square], returns it or null.
  ch.Piece? removePiece(String square) => _game.remove(square);

  /// Flip the active turn in FEN (used for Freeze / Double-Move powerups).
  void swapTurn() {
    List<String> parts = _game.fen.split(' ');
    if (parts.length >= 2) {
      parts[1] = parts[1] == 'w' ? 'b' : 'w';
      _game = ch.Chess.fromFEN(parts.join(' '));
    }
  }

  // ── Attacked Squares ─────────────────────────────────────────────────────────
  List<String> getAttackedSquares(String color) {
    List<String> fenParts = _game.fen.split(' ');
    fenParts[1] = color == 'white' ? 'w' : 'b';
    ch.Chess tmp = ch.Chess.fromFEN(fenParts.join(' '));
    return tmp
        .generate_moves({'legal': true})
        .map((m) => m.toAlgebraic)
        .toSet()
        .toList();
  }

  // ── Private Helpers ──────────────────────────────────────────────────────────
  List<ch.Move> _filterMovesForEffects(
    List<ch.Move> moves,
    List<ActiveEffect> effects,
  ) {
    List<ch.Move> filtered = List.from(moves);
    for (var effect in effects) {
      switch (effect.type) {
        case PowerupType.fortress:
        case PowerupType.wall:
          if (effect.affectedSquares != null) {
            filtered.removeWhere(
              (m) => effect.affectedSquares!.contains(m.toAlgebraic),
            );
          }
          break;
        case PowerupType.holyShield:
          if (effect.targetSquare != null) {
            filtered.removeWhere(
              (m) => m.toAlgebraic == effect.targetSquare &&
                  m.captured != null,
            );
          }
          break;
        default:
          break;
      }
    }
    return filtered;
  }

  ch.PieceType? _parsePieceType(String t) {
    switch (t.toLowerCase()) {
      case 'p': return ch.PieceType.PAWN;
      case 'n': return ch.PieceType.KNIGHT;
      case 'b': return ch.PieceType.BISHOP;
      case 'r': return ch.PieceType.ROOK;
      case 'q': return ch.PieceType.QUEEN;
      case 'k': return ch.PieceType.KING;
      default: return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIECE INFO
// ─────────────────────────────────────────────────────────────────────────────

class PieceInfo {
  final String type;   // 'p','n','b','r','q','k'
  final String color;  // 'white' | 'black'
  final String square; // 'a1'..'h8'

  const PieceInfo({
    required this.type,
    required this.color,
    required this.square,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILITY FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────

String gridToSquare(int row, int col) {
  String file = String.fromCharCode('a'.codeUnitAt(0) + col);
  return '$file${8 - row}';
}

(int, int) squareToGrid(String square) {
  int col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
  int row = 8 - int.parse(square[1]);
  return (row, col);
}

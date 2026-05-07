import 'dart:math';
import '../utils/constants.dart';
import 'chess_engine.dart';
import '../models/powerup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI ENGINE - Minimax with Alpha-Beta pruning + Basic Powerup Heuristics
// ─────────────────────────────────────────────────────────────────────────────

class AIEngine {
  final Random _random = Random();
  final int _maxDepth;

  AIEngine({int depth = GameConstants.aiMediumDepth}) : _maxDepth = depth;

  /// Get the best move for the current position
  ChessMoveResult? getBestMove(ChessEngine engine) {
    List<_ScoredMove> candidates = [];

    for (var move in engine.getLegalMoves()) {
      engine.makeMove(move.fromAlgebraic, move.toAlgebraic);

      int score = _minimax(
        engine,
        _maxDepth - 1,
        -100000,
        100000,
        !engine.isWhiteTurn,
      );

      engine.undo();
      candidates.add(_ScoredMove(move.fromAlgebraic, move.toAlgebraic, score));
    }

    if (candidates.isEmpty) return null;

    // Sort: white maximises, black minimises
    candidates.sort((a, b) =>
        engine.isWhiteTurn ? b.score - a.score : a.score - b.score);

    // Add small random noise among top moves to vary play
    int topScore = candidates.first.score;
    List<_ScoredMove> topMoves =
        candidates.where((c) => (c.score - topScore).abs() < 30).toList();
    topMoves.shuffle(_random);

    return ChessMoveResult(from: topMoves.first.from, to: topMoves.first.to);
  }

  /// AI decides whether to use a powerup — basic heuristic
  PowerupType? decidePowerupUsage(List<PowerupType> held, ChessEngine engine) {
    if (held.isEmpty) return null;
    if (_random.nextDouble() < 0.20) {
      held.sort((a, b) => b.tier.level.compareTo(a.tier.level));
      var usable = held.where((p) => !p.isTargeted).toList();
      if (usable.isNotEmpty) return usable.first;
    }
    return null;
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  int _minimax(ChessEngine engine, int depth, int alpha, int beta, bool isMax) {
    if (depth == 0 || engine.gameOver) return _evaluate(engine);

    List moves = engine.getLegalMoves();
    if (moves.isEmpty) {
      return engine.inCheck ? (isMax ? -99999 : 99999) : 0;
    }

    if (isMax) {
      int best = -100000;
      for (var m in moves) {
        engine.makeMove(m.fromAlgebraic, m.toAlgebraic);
        int eval = _minimax(engine, depth - 1, alpha, beta, false);
        engine.undo();
        if (eval > best) best = eval;
        if (eval > alpha) alpha = eval;
        if (beta <= alpha) break;
      }
      return best;
    } else {
      int best = 100000;
      for (var m in moves) {
        engine.makeMove(m.fromAlgebraic, m.toAlgebraic);
        int eval = _minimax(engine, depth - 1, alpha, beta, true);
        engine.undo();
        if (eval < best) best = eval;
        if (eval < beta) beta = eval;
        if (beta <= alpha) break;
      }
      return best;
    }
  }

  int _evaluate(ChessEngine engine) {
    int score = 0;
    for (var piece in engine.getBoardPieces().values) {
      int val = GameConstants.pieceValues[piece.type] ?? 0;
      int pos = _positionBonus(piece.square);
      score += piece.color == 'white' ? val + pos : -(val + pos);
    }
    return score;
  }

  int _positionBonus(String square) {
    int file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rank = 8 - int.parse(square[1]);
    double dist = (rank - 3.5).abs() + (file - 3.5).abs();
    return ((7.0 - dist) * 2).toInt();
  }
}

class ChessMoveResult {
  final String from;
  final String to;
  const ChessMoveResult({required this.from, required this.to});
}

class _ScoredMove {
  final String from;
  final String to;
  final int score;
  const _ScoredMove(this.from, this.to, this.score);
}

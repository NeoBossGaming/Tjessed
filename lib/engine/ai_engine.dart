import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'chess_engine.dart';
import '../models/powerup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI ENGINE - Stockfish API Integration
// ─────────────────────────────────────────────────────────────────────────────

class AIEngine {
  final int _maxDepth;
  static const String _apiBase = 'https://stockfish.online/api/s/v2.php';

  AIEngine({int depth = GameConstants.aiMediumDepth}) : _maxDepth = depth;

  /// Get the best move for the current position from Stockfish API
  Future<ChessMoveResult?> getBestMove(ChessEngine engine) async {
    try {
      final fen = Uri.encodeComponent(engine.fen);
      // Map GameConstants depth to Stockfish depth (roughly)
      int stockfishDepth = _maxDepth * 3; // Easy(2)->6, Medium(3)->9, Hard(4)->12
      
      final url = '$_apiBase?fen=$fen&depth=$stockfishDepth';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final String bestMove = data['bestmove'] ?? '';
          if (bestMove.isNotEmpty && bestMove.contains('bestmove ')) {
            // Format is "bestmove e2e4 ponder ..."
            final parts = bestMove.split(' ');
            if (parts.length >= 2) {
              final moveStr = parts[1];
              return ChessMoveResult(
                from: moveStr.substring(0, 2),
                to: moveStr.substring(2, 4),
              );
            }
          } else if (data['data'] != null) {
             // Some versions return "bestmove e2e4" in 'data'
             final String d = data['data'];
             final parts = d.split(' ');
             final moveStr = parts.last;
             return ChessMoveResult(
                from: moveStr.substring(0, 2),
                to: moveStr.substring(2, 4),
              );
          }
        }
      }
    } catch (e) {
      debugPrint('AI Error: $e');
    }

    // Fallback: If API fails, use a random legal move
    final moves = engine.getLegalMoves();
    if (moves.isEmpty) return null;
    final m = moves[DateTime.now().millisecond % moves.length];
    return ChessMoveResult(from: m.fromAlgebraic, to: m.toAlgebraic);
  }

  /// AI decides whether to use a powerup — basic heuristic
  PowerupType? decidePowerupUsage(List<PowerupType> held, ChessEngine engine) {
    if (held.isEmpty) return null;
    // Lowered random chance to make it feel more "intelligent" and less spammy
    if (DateTime.now().millisecond % 100 < 15) {
      held.sort((a, b) => b.tier.level.compareTo(a.tier.level));
      var usable = held.where((p) => !p.isTargeted).toList();
      if (usable.isNotEmpty) return usable.first;
    }
    return null;
  }
}

class ChessMoveResult {
  final String from;
  final String to;
  const ChessMoveResult({required this.from, required this.to});
}

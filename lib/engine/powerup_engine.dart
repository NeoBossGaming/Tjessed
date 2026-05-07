import 'dart:math';
import 'package:chess/chess.dart' as ch;
import '../models/powerup.dart';
import 'chess_engine.dart';

class PowerupEngine {
  final Random _random = Random();

  PowerupType? rollPowerup(String capturedPieceType) {
    if (capturedPieceType == 'k') return null;
    final tier = PowerupType.tierForPiece(capturedPieceType);
    final pool = PowerupType.forTier(tier);
    if (pool.isEmpty) return null;
    return pool[_random.nextInt(pool.length)];
  }

  PowerupResult applyPowerup({
    required PowerupType type,
    required ChessEngine engine,
    required String playerColor,
    String? targetSquare,
    List<String>? capturedPieces,
    int currentTimeLeft = 0,
  }) {
    switch (type) {
      case PowerupType.timeWarp:
        return PowerupResult(success: true, message: '+30 seconds added!', timeBonus: 30);

      case PowerupType.scout:
        final opp = playerColor == 'white' ? 'black' : 'white';
        return PowerupResult(
          success: true,
          message: 'Enemy attack zones revealed!',
          highlightSquares: engine.getAttackedSquares(opp),
          effectDuration: 1,
        );

      case PowerupType.freeze:
        return PowerupResult(
          success: true,
          message: 'Opponent frozen for 1 turn!',
          activeEffect: ActiveEffect(type: PowerupType.freeze, turnsRemaining: 1),
        );

      case PowerupType.phantomStep:
        return PowerupResult(
          success: true,
          message: 'Make a bonus non-capture move!',
          activeEffect: ActiveEffect(type: PowerupType.phantomStep, turnsRemaining: 1),
        );

      case PowerupType.holyShield:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select a piece to shield!', requiresTarget: true);
        }
        return PowerupResult(
          success: true,
          message: 'Piece shielded for 2 turns!',
          activeEffect: ActiveEffect(type: PowerupType.holyShield, targetSquare: targetSquare, turnsRemaining: 2),
        );

      case PowerupType.purify:
        return PowerupResult(success: true, message: 'Enemy powerup removed!', removesEnemyPowerup: true);

      case PowerupType.fortress:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select fortress corner!', requiresTarget: true);
        }
        return PowerupResult(
          success: true,
          message: 'Fortress erected for 3 turns!',
          activeEffect: ActiveEffect(
            type: PowerupType.fortress,
            targetSquare: targetSquare,
            affectedSquares: _getFortressZone(targetSquare),
            turnsRemaining: 3,
          ),
        );

      case PowerupType.doubleMove:
        return PowerupResult(
          success: true,
          message: 'You can make two moves!',
          activeEffect: ActiveEffect(type: PowerupType.doubleMove, turnsRemaining: 1),
        );

      case PowerupType.resurrection:
        if (capturedPieces == null || capturedPieces.isEmpty) {
          return PowerupResult(success: false, message: 'No captured pieces!');
        }
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select empty square!', requiresTarget: true);
        }
        final piece = capturedPieces.first;
        final placed = engine.putPiece(piece, playerColor, targetSquare);
        if (placed) {
          return PowerupResult(
            success: true,
            message: 'Piece resurrected at $targetSquare!',
            resurrectedPiece: piece,
            resurrectSquare: targetSquare,
          );
        }
        return PowerupResult(success: false, message: 'Cannot place piece there!');

      case PowerupType.chaosStorm:
        return _applyChaosStorm(engine);
    }
  }

  PowerupResult _applyChaosStorm(ChessEngine engine) {
    final boardPieces = engine.getBoardPieces();
    final nonKing = boardPieces.entries
        .where((e) => e.value.type != 'k')
        .map((e) => e.key)
        .toList();

    if (nonKing.length < 4) {
      return PowerupResult(success: false, message: 'Not enough pieces for Chaos Storm!');
    }

    nonKing.shuffle(_random);
    final swapped = <String>[];

    for (int i = 0; i < 4; i += 2) {
      final sq1 = nonKing[i];
      final sq2 = nonKing[i + 1];
      final p1 = engine.removePiece(sq1);
      final p2 = engine.removePiece(sq2);
      if (p1 != null) {
        engine.putPiece(
          p1.type.name,
          p1.color == ch.Color.WHITE ? 'white' : 'black',
          sq2,
        );
      }
      if (p2 != null) {
        engine.putPiece(
          p2.type.name,
          p2.color == ch.Color.WHITE ? 'white' : 'black',
          sq1,
        );
      }
      swapped.addAll([sq1, sq2]);
    }

    return PowerupResult(success: true, message: 'Chaos Storm! Pieces swapped!', swappedSquares: swapped);
  }

  List<String> _getFortressZone(String topLeft) {
    final (row, col) = squareToGrid(topLeft);
    final zone = <String>[];
    for (int dr = 0; dr < 2; dr++) {
      for (int dc = 0; dc < 2; dc++) {
        final r = row + dr;
        final c = col + dc;
        if (r >= 0 && r < 8 && c >= 0 && c < 8) zone.add(gridToSquare(r, c));
      }
    }
    return zone;
  }

  static List<ActiveEffect> tickEffects(List<ActiveEffect> effects) {
    for (var e in effects) {
      e.turnsRemaining--;
    }
    effects.removeWhere((e) => e.turnsRemaining <= 0);
    return effects;
  }
}

class PowerupResult {
  final bool success;
  final String message;
  final int timeBonus;
  final List<String>? highlightSquares;
  final List<String>? swappedSquares;
  final ActiveEffect? activeEffect;
  final int effectDuration;
  final bool requiresTarget;
  final bool removesEnemyPowerup;
  final String? resurrectedPiece;
  final String? resurrectSquare;

  const PowerupResult({
    required this.success,
    required this.message,
    this.timeBonus = 0,
    this.highlightSquares,
    this.swappedSquares,
    this.activeEffect,
    this.effectDuration = 0,
    this.requiresTarget = false,
    this.removesEnemyPowerup = false,
    this.resurrectedPiece,
    this.resurrectSquare,
  });
}

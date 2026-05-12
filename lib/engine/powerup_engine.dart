import 'dart:math';
import 'package:chess/chess.dart' as ch;
import '../models/powerup.dart';
import 'chess_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POWERUP ENGINE — RNG Rarity Roll + Apply Logic for 22 Power-Ups
// ─────────────────────────────────────────────────────────────────────────────

class PowerupEngine {
  final Random _random = Random();

  // ── RARITY DISTRIBUTION TABLES ──────────────────────────────────────────────
  // Each table is indexed by tier: [Common, Uncommon, Rare, Epic, Legendary]
  // Values are cumulative probabilities (0.0 to 1.0).

  static const Map<PowerupTier, List<double>> _rarityTable = {
    // Killing a pawn: 70% Common, 20% Uncommon, 7% Rare, 2.5% Epic, 0.5% Legendary
    PowerupTier.common:    [0.70, 0.90, 0.97, 0.995, 1.0],
    // Killing a knight/bishop: 10% Common, 50% Uncommon, 25% Rare, 12% Epic, 3% Legendary
    PowerupTier.uncommon:  [0.10, 0.60, 0.85, 0.97, 1.0],
    // Killing a rook: 5% Common, 15% Uncommon, 45% Rare, 28% Epic, 7% Legendary
    PowerupTier.rare:      [0.05, 0.20, 0.65, 0.93, 1.0],
    // Killing a queen: 2% Common, 8% Uncommon, 20% Rare, 50% Epic, 20% Legendary
    PowerupTier.epic:      [0.02, 0.10, 0.30, 0.80, 1.0],
    // (Legendary base is not normally reachable via captures, but included for completeness)
    PowerupTier.legendary: [0.0, 0.0, 0.10, 0.40, 1.0],
  };

  static const List<PowerupTier> _tierOrder = [
    PowerupTier.common,
    PowerupTier.uncommon,
    PowerupTier.rare,
    PowerupTier.epic,
    PowerupTier.legendary,
  ];

  /// Roll a powerup with weighted RNG based on the captured piece.
  PowerupType? rollPowerup(String capturedPieceType) {
    if (capturedPieceType == 'k') return null;

    final baseTier = PowerupType.baseTierForPiece(capturedPieceType);
    final distribution = _rarityTable[baseTier]!;
    final roll = _random.nextDouble();

    // Find which tier the roll lands in
    PowerupTier resultTier = PowerupTier.legendary; // fallback
    for (int i = 0; i < distribution.length; i++) {
      if (roll < distribution[i]) {
        resultTier = _tierOrder[i];
        break;
      }
    }

    final pool = PowerupType.forTier(resultTier);
    if (pool.isEmpty) return null;
    return pool[_random.nextInt(pool.length)];
  }

  // ── APPLY POWERUP ─────────────────────────────────────────────────────────

  PowerupResult applyPowerup({
    required PowerupType type,
    required ChessEngine engine,
    required String playerColor,
    String? targetSquare,
    String? targetSquare2,
    List<String>? capturedPieces,
    int currentTimeLeft = 0,
  }) {
    switch (type) {
      // ── COMMON ────────────────────────────────────────────────────────────
      case PowerupType.timeWarp:
        return PowerupResult(success: true, message: '+30 seconds added!', timeBonus: 30);

      case PowerupType.sniper:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select an enemy piece to snipe!', requiresTarget: true);
        }
        final piece = engine.getPiece(targetSquare);
        if (piece == null || piece.type == ch.PieceType.KING) {
          return PowerupResult(success: false, message: 'Cannot snipe empty squares or the King!');
        }
        final pColor = piece.color == ch.Color.WHITE ? 'white' : 'black';
        if (pColor == playerColor) {
          return PowerupResult(success: false, message: 'Must target an ENEMY piece!');
        }
        
        // Simple check: is there a rook or queen on the same file/rank?
        bool hasLos = false;
        final targetFile = targetSquare[0];
        final targetRank = targetSquare[1];
        final allPieces = engine.getBoardPieces();
        for (final entry in allPieces.entries) {
          final sq = entry.key;
          final p = entry.value;
          if (p.color == playerColor && (p.type == 'r' || p.type == 'q')) {
            if (sq[0] == targetFile || sq[1] == targetRank) {
              hasLos = true;
              break;
            }
          }
        }

        if (!hasLos) {
          return PowerupResult(success: false, message: 'No Queen/Rook has line of sight (same rank/file)!');
        }

        engine.removePiece(targetSquare);
        return PowerupResult(success: true, message: 'BOOM! Target neutralized.', swappedSquares: [targetSquare]);

      case PowerupType.wall:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select wall location!', requiresTarget: true);
        }
        return PowerupResult(
          success: true,
          message: 'Wall constructed for 3 turns!',
          activeEffect: ActiveEffect(
            type: PowerupType.wall,
            targetSquare: targetSquare,
            affectedSquares: getWallZone(targetSquare),
            turnsRemaining: 6,
          ),
        );

      case PowerupType.quickStep:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select a pawn!', requiresTarget: true);
        }
        final piece = engine.getPiece(targetSquare);
        if (piece == null || piece.type != ch.PieceType.PAWN) {
          return PowerupResult(success: false, message: 'Must target a pawn!');
        }
        final pColor = piece.color == ch.Color.WHITE ? 'white' : 'black';
        if (pColor != playerColor) {
          return PowerupResult(success: false, message: 'Must target YOUR pawn!');
        }
        // Mark this pawn for quick step (handled as active effect)
        return PowerupResult(
          success: true,
          message: 'Pawn can leap 2 squares!',
          activeEffect: ActiveEffect(
            type: PowerupType.quickStep,
            targetSquare: targetSquare,
            turnsRemaining: 1,
          ),
        );

      case PowerupType.minorHeal:
        final undone = engine.undo();
        if (undone == null) {
          return PowerupResult(success: false, message: 'No move to undo!');
        }
        return PowerupResult(success: true, message: 'Last move undone — replay!');

      // ── UNCOMMON ──────────────────────────────────────────────────────────
      case PowerupType.enrage:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select a pawn to enrage!', requiresTarget: true);
        }
        final piece = engine.getPiece(targetSquare);
        if (piece == null || piece.type != ch.PieceType.PAWN) {
          return PowerupResult(success: false, message: 'Must target a pawn!');
        }
        return PowerupResult(
          success: true,
          message: 'Pawn enraged — can capture forward!',
          activeEffect: ActiveEffect(
            type: PowerupType.enrage,
            targetSquare: targetSquare,
            turnsRemaining: 1,
          ),
        );

      case PowerupType.freeze:
        return PowerupResult(
          success: true,
          message: 'Opponent frozen for 1 turn!',
          activeEffect: ActiveEffect(type: PowerupType.freeze, turnsRemaining: 1),
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
        return PowerupResult(success: true, message: 'Enemy power-up removed!', removesEnemyPowerup: true);

      case PowerupType.phantomStep:
        return PowerupResult(
          success: true,
          message: 'Make a bonus non-capture move!',
          activeEffect: ActiveEffect(type: PowerupType.phantomStep, turnsRemaining: 1),
        );

      case PowerupType.sabotage:
        return PowerupResult(
          success: true,
          message: 'Enemy power-ups disabled for 2 turns!',
          activeEffect: ActiveEffect(type: PowerupType.sabotage, turnsRemaining: 2),
        );

      // ── RARE ──────────────────────────────────────────────────────────────
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
            affectedSquares: getFortressZone(targetSquare),
            turnsRemaining: 3,
          ),
        );

      case PowerupType.doubleMove:
        return PowerupResult(
          success: true,
          message: 'You can make two moves!',
          activeEffect: ActiveEffect(type: PowerupType.doubleMove, turnsRemaining: 1),
        );

      case PowerupType.swap:
        if (targetSquare == null || targetSquare2 == null) {
          return PowerupResult(success: false, message: 'Select two pieces to swap!', requiresTarget: true);
        }
        final p1 = engine.getPiece(targetSquare);
        final p2 = engine.getPiece(targetSquare2);
        
        if (p1 == null || p2 == null) {
            return PowerupResult(success: false, message: 'Both squares must have pieces!');
        }
        if (p1.type.name == 'k' || p2.type.name == 'k') {
            return PowerupResult(success: false, message: 'Cannot swap a King!');
        }
        
        engine.removePiece(targetSquare);
        engine.removePiece(targetSquare2);
        engine.putPiece(p2.type.name, p2.color == ch.Color.WHITE ? 'white' : 'black', targetSquare);
        engine.putPiece(p1.type.name, p1.color == ch.Color.WHITE ? 'white' : 'black', targetSquare2);
        
        return PowerupResult(
          success: true,
          message: 'Pieces swapped!',
          swappedSquares: [targetSquare, targetSquare2],
        );

      case PowerupType.conscription:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select where to place the pawn!', requiresTarget: true);
        }
        // Validate target is in first 2 ranks and empty
        final rank = int.parse(targetSquare[1]);
        final isValidRank = playerColor == 'white' ? (rank <= 2) : (rank >= 7);
        if (!isValidRank) {
          return PowerupResult(success: false, message: 'Must place in your first 2 ranks!');
        }
        if (engine.getPiece(targetSquare) != null) {
          return PowerupResult(success: false, message: 'Square must be empty!');
        }
        engine.putPiece('p', playerColor, targetSquare);
        return PowerupResult(success: true, message: 'Pawn conscripted at $targetSquare!');

      case PowerupType.exile:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select an enemy piece to exile!', requiresTarget: true);
        }
        return _applyExile(engine, playerColor, targetSquare);

      // ── EPIC ──────────────────────────────────────────────────────────────
      case PowerupType.resurrection:
        if (capturedPieces == null || capturedPieces.isEmpty) {
          return PowerupResult(success: false, message: 'No captured pieces to resurrect!');
        }
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select empty square for resurrection!', requiresTarget: true);
        }
        if (engine.getPiece(targetSquare) != null) {
          return PowerupResult(success: false, message: 'Square must be empty!');
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

      case PowerupType.crownThief:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select an enemy queen!', requiresTarget: true);
        }
        return _applyCrownThief(engine, playerColor, targetSquare);

      case PowerupType.blackHole:
        if (targetSquare == null) {
          return PowerupResult(success: false, message: 'Select the center of the black hole!', requiresTarget: true);
        }
        return _applyBlackHole(engine, targetSquare);

      // ── LEGENDARY ─────────────────────────────────────────────────────────
      case PowerupType.promotionWave:
        return _applyPromotionWave(engine, playerColor);

      case PowerupType.timeFreeze:
        return PowerupResult(
          success: true,
          message: "Opponent's clock frozen for 60 seconds!",
          activeEffect: ActiveEffect(type: PowerupType.timeFreeze, turnsRemaining: 6),
          timePenalty: 60,
        );

      case PowerupType.mirrorDimension:
        return PowerupResult(
          success: true,
          message: 'Your last move will repeat automatically!',
          activeEffect: ActiveEffect(type: PowerupType.mirrorDimension, turnsRemaining: 1),
        );
    }
  }

  // ── COMPLEX POWERUP IMPLEMENTATIONS ─────────────────────────────────────

  PowerupResult _applyExile(ChessEngine engine, String playerColor, String targetSquare) {
    final piece = engine.getPiece(targetSquare);
    if (piece == null) {
      return PowerupResult(success: false, message: 'No piece there!');
    }
    final pColor = piece.color == ch.Color.WHITE ? 'white' : 'black';
    if (pColor == playerColor) {
      return PowerupResult(success: false, message: 'Must target an ENEMY piece!');
    }
    if (piece.type == ch.PieceType.KING) {
      return PowerupResult(success: false, message: 'Cannot exile the king!');
    }

    // Find empty squares to exile to
    final boardPieces = engine.getBoardPieces();
    final allSquares = <String>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        allSquares.add(gridToSquare(r, c));
      }
    }
    final emptySquares = allSquares.where((s) => !boardPieces.containsKey(s)).toList();
    if (emptySquares.isEmpty) {
      return PowerupResult(success: false, message: 'No empty square to exile to!');
    }

    emptySquares.shuffle(_random);
    final destination = emptySquares.first;

    engine.removePiece(targetSquare);
    engine.putPiece(piece.type.name, pColor, destination);

    return PowerupResult(
      success: true,
      message: 'Piece exiled to $destination!',
      swappedSquares: [targetSquare, destination],
    );
  }

  PowerupResult _applyCrownThief(ChessEngine engine, String playerColor, String targetSquare) {
    final piece = engine.getPiece(targetSquare);
    if (piece == null) {
      return PowerupResult(success: false, message: 'No piece there!');
    }
    if (piece.type != ch.PieceType.QUEEN) {
      return PowerupResult(success: false, message: 'Must target a queen!');
    }
    final pColor = piece.color == ch.Color.WHITE ? 'white' : 'black';
    if (pColor == playerColor) {
      return PowerupResult(success: false, message: 'Must target an ENEMY queen!');
    }

    // Demote queen to bishop
    engine.removePiece(targetSquare);
    engine.putPiece('b', pColor, targetSquare);

    return PowerupResult(
      success: true,
      message: 'Crown stolen! Queen demoted to bishop for 3 turns!',
      activeEffect: ActiveEffect(
        type: PowerupType.crownThief,
        targetSquare: targetSquare,
        turnsRemaining: 3,
        extra: {'originalSquare': targetSquare, 'pieceColor': pColor},
      ),
    );
  }

  PowerupResult _applyBlackHole(ChessEngine engine, String targetSquare) {
    final zone = getFortressZone(targetSquare);
    int destroyed = 0;

    for (final sq in zone) {
      final piece = engine.getPiece(sq);
      if (piece != null && piece.type != ch.PieceType.KING) {
        engine.removePiece(sq);
        destroyed++;
      }
    }

    return PowerupResult(
      success: true,
      message: destroyed > 0 
          ? 'Black Hole destroyed $destroyed piece${destroyed > 1 ? "s" : ""}!'
          : 'Black Hole opened on empty space.',
      swappedSquares: zone,
    );
  }

  PowerupResult _applyPromotionWave(ChessEngine engine, String playerColor) {
    final boardPieces = engine.getBoardPieces();
    int promoted = 0;

    // Collect pawn squares first to avoid concurrent modification
    final pawnSquares = boardPieces.entries
        .where((e) => e.value.type == 'p' && e.value.color == playerColor)
        .map((e) => e.key)
        .toList();

    for (final sq in pawnSquares) {
      engine.removePiece(sq);
      engine.putPiece('q', playerColor, sq);
      promoted++;
    }

    if (promoted == 0) {
      return PowerupResult(success: false, message: 'No pawns to promote!');
    }

    return PowerupResult(
      success: true,
      message: 'Promotion Wave! $promoted pawn${promoted > 1 ? "s" : ""} became queens!',
    );
  }

  PowerupResult _applyChaosStorm(ChessEngine engine) {
    // Take a snapshot of the board to avoid concurrent modification
    final boardPieces = Map<String, PieceInfo>.from(engine.getBoardPieces());
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

  // ── HELPERS ─────────────────────────────────────────────────────────────

  static List<String> getWallZone(String topLeft) {
    final (row, col) = squareToGrid(topLeft);
    int r = row;
    int c = col;
    
    // Adjust if on right edge (for 1x2 horizontal wall)
    if (c > 6) c = 6;
    
    final zone = <String>[];
    zone.add(gridToSquare(r, c));
    zone.add(gridToSquare(r, c + 1));
    return zone;
  }

  static List<String> getFortressZone(String topLeft) {
    final (row, col) = squareToGrid(topLeft);
    int r = row;
    int c = col;

    // Adjust if on far edges (for 2x2 zone)
    if (r > 6) r = 6;
    if (c > 6) c = 6;

    final zone = <String>[];
    for (int dr = 0; dr < 2; dr++) {
      for (int dc = 0; dc < 2; dc++) {
        zone.add(gridToSquare(r + dr, c + dc));
      }
    }
    return zone;
  }

  /// Tick down active effect durations. Called each half-turn.
  static List<ActiveEffect> tickEffects(List<ActiveEffect> effects) {
    for (var e in effects) {
      e.turnsRemaining--;
    }
    effects.removeWhere((e) => e.turnsRemaining <= 0);
    return effects;
  }

  /// Handle Crown Thief expiration: restore the queen.
  static void handleExpiredEffects(List<ActiveEffect> expired, ChessEngine engine) {
    for (final e in expired) {
      if (e.type == PowerupType.crownThief && e.extra.containsKey('originalSquare')) {
        final sq = e.extra['originalSquare'] as String;
        final color = e.extra['pieceColor'] as String? ?? 'black';
        final currentPiece = engine.getPiece(sq);
        // Only restore if the bishop is still there (hasn't been captured)
        if (currentPiece != null && currentPiece.type == ch.PieceType.BISHOP) {
          engine.removePiece(sq);
          engine.putPiece('q', color, sq);
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POWERUP RESULT
// ─────────────────────────────────────────────────────────────────────────────

class PowerupResult {
  final bool success;
  final String message;
  final int timeBonus;
  final int timePenalty; // Applied to opponent
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
    this.timePenalty = 0,
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

import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POWERUP TIER
// ─────────────────────────────────────────────────────────────────────────────

enum PowerupTier {
  t1(1, 'Common', AppColors.tier1),
  t2(2, 'Rare', AppColors.tier2),
  t3(3, 'Epic', AppColors.tier3),
  t4(4, 'Legendary', AppColors.tier4);

  final int level;
  final String label;
  final Color color;
  const PowerupTier(this.level, this.label, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// POWERUP TYPE
// ─────────────────────────────────────────────────────────────────────────────

enum PowerupType {
  // Tier 1 (Pawn capture)
  timeWarp(
    tier: PowerupTier.t1,
    name: 'Time Warp',
    description: 'Add 30 seconds to your clock',
    icon: Icons.access_time_filled,
    isTargeted: false,
  ),
  scout(
    tier: PowerupTier.t1,
    name: 'Scout',
    description: 'Reveal all squares your opponent can attack',
    icon: Icons.visibility,
    isTargeted: false,
  ),

  // Tier 2 (Knight/Bishop capture)
  freeze(
    tier: PowerupTier.t2,
    name: 'Freeze',
    description: 'Opponent skips their next turn',
    icon: Icons.ac_unit,
    isTargeted: false,
  ),
  phantomStep(
    tier: PowerupTier.t2,
    name: 'Phantom Step',
    description: 'Make a bonus non-capture move',
    icon: Icons.directions_walk,
    isTargeted: false,
  ),
  holyShield(
    tier: PowerupTier.t2,
    name: 'Holy Shield',
    description: 'Protect one piece from capture for 2 turns',
    icon: Icons.shield,
    isTargeted: true,
  ),
  purify(
    tier: PowerupTier.t2,
    name: 'Purify',
    description: 'Remove one enemy held powerup',
    icon: Icons.cleaning_services,
    isTargeted: false,
  ),

  // Tier 3 (Rook capture)
  fortress(
    tier: PowerupTier.t3,
    name: 'Fortress',
    description: 'Block a 2×2 zone for 3 turns',
    icon: Icons.castle,
    isTargeted: true,
  ),
  doubleMove(
    tier: PowerupTier.t3,
    name: 'Double Move',
    description: 'Take two consecutive moves this turn',
    icon: Icons.fast_forward,
    isTargeted: false,
  ),

  // Tier 4 (Queen capture)
  resurrection(
    tier: PowerupTier.t4,
    name: 'Resurrection',
    description: 'Bring back one of your captured pieces',
    icon: Icons.auto_awesome,
    isTargeted: true,
  ),
  chaosStorm(
    tier: PowerupTier.t4,
    name: 'Chaos Storm',
    description: 'Randomly swap 2 pairs of non-king pieces',
    icon: Icons.thunderstorm,
    isTargeted: false,
  );

  final PowerupTier tier;
  final String name;
  final String description;
  final IconData icon;
  final bool isTargeted; // Requires selecting a target square/piece

  const PowerupType({
    required this.tier,
    required this.name,
    required this.description,
    required this.icon,
    required this.isTargeted,
  });

  /// Get all powerups for a given tier
  static List<PowerupType> forTier(PowerupTier tier) {
    return PowerupType.values.where((p) => p.tier == tier).toList();
  }

  /// Map captured piece type to powerup tier
  static PowerupTier tierForPiece(String pieceType) {
    switch (pieceType) {
      case 'p':
        return PowerupTier.t1;
      case 'n':
      case 'b':
        return PowerupTier.t2;
      case 'r':
        return PowerupTier.t3;
      case 'q':
        return PowerupTier.t4;
      default:
        return PowerupTier.t1;
    }
  }

  Map<String, dynamic> toJson() => {'type': name};

  static PowerupType? fromName(String name) {
    try {
      return PowerupType.values.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE EFFECT (persistent powerup effect on the board)
// ─────────────────────────────────────────────────────────────────────────────

class ActiveEffect {
  final PowerupType type;
  final String? targetSquare; // e.g., "e4" for shield/fortress
  final List<String>? affectedSquares; // For fortress (2x2 zone)
  int turnsRemaining;

  ActiveEffect({
    required this.type,
    this.targetSquare,
    this.affectedSquares,
    required this.turnsRemaining,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'targetSquare': targetSquare ?? '',
        'affectedSquares': affectedSquares ?? [],
        'turnsRemaining': turnsRemaining,
      };

  factory ActiveEffect.fromJson(Map<String, dynamic> json) {
    return ActiveEffect(
      type: PowerupType.fromName(json['type'] as String) ?? PowerupType.timeWarp,
      targetSquare: json['targetSquare'] as String?,
      affectedSquares: (json['affectedSquares'] as List?)?.cast<String>(),
      turnsRemaining: json['turnsRemaining'] as int? ?? 0,
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POWERUP TIER  (5 levels)
// ─────────────────────────────────────────────────────────────────────────────

enum PowerupTier {
  common(1, 'Common', AppColors.tierCommon),
  uncommon(2, 'Uncommon', AppColors.tierUncommon),
  rare(3, 'Rare', AppColors.tierRare),
  epic(4, 'Epic', AppColors.tierEpic),
  legendary(5, 'Legendary', AppColors.tierLegendary);

  final int level;
  final String label;
  final Color color;
  const PowerupTier(this.level, this.label, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// POWERUP CATEGORY
// ─────────────────────────────────────────────────────────────────────────────

enum PowerupCategory {
  offensive('Offensive', '⚔️', Color(0xFFFF4D6D)),
  defensive('Defensive', '🛡️', Color(0xFF4DA6FF)),
  hybrid('Hybrid', '🔄', Color(0xFFB388FF));

  final String label;
  final String emoji;
  final Color color;
  const PowerupCategory(this.label, this.emoji, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// POWERUP TYPE  (22 power-ups)
// ─────────────────────────────────────────────────────────────────────────────

enum PowerupType {
  // ── COMMON (Tier 1) ──────────────────────────────────────────────────────
  timeWarp(
    tier: PowerupTier.common,
    category: PowerupCategory.defensive,
    name: 'Time Warp',
    description: 'Add 30 seconds to your clock',
    icon: Icons.access_time_filled,
    isTargeted: false,
  ),
  sniper(
    tier: PowerupTier.rare,
    category: PowerupCategory.offensive,
    name: 'Sniper',
    description: 'Destroy any enemy piece (except King) in line of sight of your Queen or Rook',
    icon: Icons.gps_fixed,
    isTargeted: true,
  ),
  wall(
    tier: PowerupTier.rare,
    category: PowerupCategory.defensive,
    name: 'Wall',
    description: 'Block a 1×2 zone for 3 turns',
    icon: Icons.view_column,
    isTargeted: true,
  ),
  quickStep(
    tier: PowerupTier.common,
    category: PowerupCategory.offensive,
    name: 'Quick Step',
    description: 'One pawn can move 2 squares regardless of position',
    icon: Icons.keyboard_double_arrow_up,
    isTargeted: true,
  ),
  minorHeal(
    tier: PowerupTier.common,
    category: PowerupCategory.defensive,
    name: 'Minor Heal',
    description: 'Undo your last move and replay',
    icon: Icons.healing,
    isTargeted: false,
  ),

  // ── UNCOMMON (Tier 2) ────────────────────────────────────────────────────
  enrage(
    tier: PowerupTier.uncommon,
    category: PowerupCategory.offensive,
    name: 'Enrage',
    description: 'One pawn can capture forward (not diagonal) this turn',
    icon: Icons.local_fire_department,
    isTargeted: true,
  ),
  freeze(
    tier: PowerupTier.uncommon,
    category: PowerupCategory.offensive,
    name: 'Freeze',
    description: 'Opponent skips their next turn',
    icon: Icons.ac_unit,
    isTargeted: false,
  ),
  holyShield(
    tier: PowerupTier.uncommon,
    category: PowerupCategory.defensive,
    name: 'Holy Shield',
    description: 'Protect one piece from capture for 2 turns',
    icon: Icons.shield,
    isTargeted: true,
  ),
  purify(
    tier: PowerupTier.uncommon,
    category: PowerupCategory.offensive,
    name: 'Purify',
    description: 'Remove one enemy held power-up',
    icon: Icons.cleaning_services,
    isTargeted: false,
  ),
  phantomStep(
    tier: PowerupTier.uncommon,
    category: PowerupCategory.hybrid,
    name: 'Phantom Step',
    description: 'Make a bonus non-capture move',
    icon: Icons.directions_walk,
    isTargeted: false,
  ),
  sabotage(
    tier: PowerupTier.uncommon,
    category: PowerupCategory.offensive,
    name: 'Sabotage',
    description: 'Disable enemy power-up use for 2 turns',
    icon: Icons.block,
    isTargeted: false,
  ),

  // ── RARE (Tier 3) ────────────────────────────────────────────────────────
  fortress(
    tier: PowerupTier.rare,
    category: PowerupCategory.defensive,
    name: 'Fortress',
    description: 'Block a 2×2 zone for 3 turns',
    icon: Icons.castle,
    isTargeted: true,
  ),
  doubleMove(
    tier: PowerupTier.rare,
    category: PowerupCategory.offensive,
    name: 'Double Move',
    description: 'Take two consecutive moves this turn',
    icon: Icons.fast_forward,
    isTargeted: false,
  ),
  swap(
    tier: PowerupTier.rare,
    category: PowerupCategory.hybrid,
    name: 'Swap',
    description: 'Swap the positions of two of your own pieces',
    icon: Icons.swap_horiz,
    isTargeted: true, // needs two targets, first target then second
  ),
  conscription(
    tier: PowerupTier.rare,
    category: PowerupCategory.offensive,
    name: 'Conscription',
    description: 'Place a pawn on any empty square in your first 2 ranks',
    icon: Icons.person_add,
    isTargeted: true,
  ),
  exile(
    tier: PowerupTier.rare,
    category: PowerupCategory.offensive,
    name: 'Exile',
    description: 'Push an enemy piece to a random legal square',
    icon: Icons.logout,
    isTargeted: true,
  ),

  // ── EPIC (Tier 4) ────────────────────────────────────────────────────────
  resurrection(
    tier: PowerupTier.epic,
    category: PowerupCategory.hybrid,
    name: 'Resurrection',
    description: 'Bring back one of your captured pieces',
    icon: Icons.auto_awesome,
    isTargeted: true,
  ),
  chaosStorm(
    tier: PowerupTier.epic,
    category: PowerupCategory.offensive,
    name: 'Chaos Storm',
    description: 'Randomly swap 2 pairs of non-king pieces',
    icon: Icons.thunderstorm,
    isTargeted: false,
  ),
  crownThief(
    tier: PowerupTier.epic,
    category: PowerupCategory.offensive,
    name: 'Crown Thief',
    description: 'Demote an enemy queen to a bishop for 3 turns',
    icon: Icons.remove_circle,
    isTargeted: true,
  ),
  blackHole(
    tier: PowerupTier.epic,
    category: PowerupCategory.hybrid,
    name: 'Black Hole',
    description: 'Destroy all pieces on a chosen 2×2 area',
    icon: Icons.blur_on,
    isTargeted: true,
  ),

  // ── LEGENDARY (Tier 5) ───────────────────────────────────────────────────
  promotionWave(
    tier: PowerupTier.legendary,
    category: PowerupCategory.offensive,
    name: 'Promotion Wave',
    description: 'Promote all your pawns to queens instantly',
    icon: Icons.military_tech,
    isTargeted: false,
  ),
  timeFreeze(
    tier: PowerupTier.legendary,
    category: PowerupCategory.hybrid,
    name: 'Time Freeze',
    description: "Freeze opponent's clock for 60 seconds",
    icon: Icons.timer_off,
    isTargeted: false,
  ),
  mirrorDimension(
    tier: PowerupTier.legendary,
    category: PowerupCategory.hybrid,
    name: 'Mirror Dimension',
    description: 'Clone your last move — it plays again automatically',
    icon: Icons.flip,
    isTargeted: false,
  );

  final PowerupTier tier;
  final PowerupCategory category;
  final String name;
  final String description;
  final IconData icon;
  final bool isTargeted;

  const PowerupType({
    required this.tier,
    required this.category,
    required this.name,
    required this.description,
    required this.icon,
    required this.isTargeted,
  });

  /// Get all powerups for a given tier
  static List<PowerupType> forTier(PowerupTier tier) {
    return PowerupType.values.where((p) => p.tier == tier).toList();
  }

  /// Map captured piece type to a *base* tier (RNG can upgrade it)
  static PowerupTier baseTierForPiece(String pieceType) {
    switch (pieceType) {
      case 'p':
        return PowerupTier.common;
      case 'n':
      case 'b':
        return PowerupTier.uncommon;
      case 'r':
        return PowerupTier.rare;
      case 'q':
        return PowerupTier.epic;
      default:
        return PowerupTier.common;
    }
  }

  // Keep legacy compat
  static PowerupTier tierForPiece(String pieceType) =>
      baseTierForPiece(pieceType);

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
  final String? targetSquare;
  final List<String>? affectedSquares;
  int turnsRemaining;

  /// Extra data for complex effects (e.g., original piece type for Crown Thief)
  final Map<String, dynamic> extra;

  ActiveEffect({
    required this.type,
    this.targetSquare,
    this.affectedSquares,
    required this.turnsRemaining,
    this.extra = const {},
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'targetSquare': targetSquare ?? '',
    'affectedSquares': affectedSquares ?? [],
    'turnsRemaining': turnsRemaining,
    'extra': extra,
  };

  factory ActiveEffect.fromJson(Map<String, dynamic> json) {
    return ActiveEffect(
      type:
          PowerupType.fromName(json['type'] as String) ?? PowerupType.timeWarp,
      targetSquare: json['targetSquare'] as String?,
      affectedSquares: (json['affectedSquares'] as List?)?.cast<String>(),
      turnsRemaining: json['turnsRemaining'] as int? ?? 0,
      extra: (json['extra'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}

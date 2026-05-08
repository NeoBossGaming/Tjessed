import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME & COLORS
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Primary palette - Premium Dark Mode
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color backgroundEnd = Color(0xFF020617); // Slate 950
  static const Color surface = Color(0x33FFFFFF); // Translucent
  static const Color surfaceLight = Color(0x4DFFFFFF); // Translucent light
  static const Color cardBg = Color(0x40000000); // Dark translucent

  // Accent colors (Premium Neon/Pastel)
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan 500
  static const Color accentPink = Color(0xFFEC4899); // Pink 500
  static const Color accentPurple = Color(0xFFA855F7); // Purple 500
  static const Color accentAmber = Color(0xFFF59E0B); // Amber 500
  static const Color accentGreen = Color(0xFF10B981); // Emerald 500
  static const Color accentRed = Color(0xFFEF4444); // Red 500

  // Board colors (Pastel/Chess.com style)
  static Color getBoardLight(String theme) {
    switch(theme) {
      case 'Classic Wood': return const Color(0xFFF0D9B5);
      case 'Dark Neon': return const Color(0xFF2B2B36);
      case 'Ocean Blue': return const Color(0xFFE0EAEF);
      case 'Pastel':
      default:
        return const Color(0xFFEEEED2);
    }
  }

  static Color getBoardDark(String theme) {
    switch(theme) {
      case 'Classic Wood': return const Color(0xFFB58863);
      case 'Dark Neon': return const Color(0xFF5CE1E6).withAlpha(150);
      case 'Ocean Blue': return const Color(0xFF4B7399);
      case 'Pastel':
      default:
        return const Color(0xFF769656); // Chess.com green
    }
  }
  static const Color boardBorder = Color(0xFF4A623A);

  // Highlight colors
  static const Color moveHighlight = Color(0x66000000); // Dark dots for moves
  static const Color lastMoveHighlight = Color(0x66F9DF6E); // Yellow highlight
  static const Color checkHighlight = Color(0x99FF3333); // Red check
  static const Color captureHighlight = Color(0x66000000);
  static const Color selectedHighlight = Color(0x66F9DF6E);

  // Powerup tier colors (5 tiers) - matched to card rarity
  static const Color tierCommon = Color(0xFF9E9E9E); // Silver/Grey
  static const Color tierUncommon = Color(0xFF06D6A0); // Mint Green
  static const Color tierRare = Color(0xFF5CE1E6); // Bright Cyan
  static const Color tierEpic = Color(0xFFCB6CE6); // Purple
  static const Color tierLegendary = Color(0xFFFFD166); // Gold

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC0C0D0);
  static const Color textMuted = Color(0xFF808090);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD166), Color(0xFFFF9F1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────

class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get heading3 => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static TextStyle get button => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIMENSIONS
// ─────────────────────────────────────────────────────────────────────────────

class AppDimensions {
  static const double borderRadius = 16.0;
  static const double borderRadiusSmall = 8.0;
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// CHESS PIECE UNICODE CHARACTERS
// ─────────────────────────────────────────────────────────────────────────────

class ChessPieceUnicode {
  static const Map<String, String> white = {
    'k': '♔',
    'q': '♕',
    'r': '♖',
    'b': '♗',
    'n': '♘',
    'p': '♙',
  };

  static const Map<String, String> black = {
    'k': '♚',
    'q': '♛',
    'r': '♜',
    'b': '♝',
    'n': '♞',
    'p': '♟',
  };

  /// Solid (filled) glyphs used for BOTH white and black pieces.
  /// Color differentiation is handled by paint fill/stroke in ChessPieceWidget.
  static const Map<String, String> solid = {
    'k': '♚',
    'q': '♛',
    'r': '♜',
    'b': '♝',
    'n': '♞',
    'p': '♟',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

class GameConstants {
  static const int defaultTimeSeconds = 600; // 10 minutes
  static const int maxPowerupsHeld = 5;
  static const int eloMatchRange = 200;
  static const int eloMatchExpandedRange = 500;
  static const int matchmakingTimeoutSeconds = 15;

  // AI difficulty depths
  static const int aiEasyDepth = 2;
  static const int aiMediumDepth = 3;
  static const int aiHardDepth = 4;

  // Piece values for AI evaluation
  static const Map<String, int> pieceValues = {
    'p': 100,
    'n': 320,
    'b': 330,
    'r': 500,
    'q': 900,
    'k': 20000,
  };
}

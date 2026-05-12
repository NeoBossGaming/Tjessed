import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME & COLORS
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Primary palette - Bubbly/Quizzer Theme
  static const Color background = Color(0xFFFF6B6B); // Vibrant Coral/Orange
  static const Color backgroundEnd = Color(0xFFFF8E53); // Bright Orange
  static const Color surface = Color(0xFFFFFFFF); // White cards
  static const Color surfaceLight = Color(0xCCFFFFFF); // Translucent White
  static const Color cardBg = Color(0xFFFFFFFF);

  // Accent colors
  static const Color accentCyan = Color(0xFF4ECDC4); // Vibrant Teal
  static const Color accentPink = Color(0xFFFF6B6B); // Coral Pink
  static const Color accentPurple = Color(0xFF845EC2); // Deep Purple
  static const Color accentAmber = Color(0xFFFFD166); // Bright Yellow
  static const Color accentGreen = Color(0xFF06D6A0); // Mint Green
  static const Color accentRed = Color(0xFFEF476F); // Hot Pink/Red

  // Board colors (Joyful Theme variants)
  static Color getBoardLight(String theme) {
    switch (theme) {
      case 'Classic Wood':
        return const Color(0xFFF9F7F3); // Warm White
      case 'Dark Neon':
        return const Color(0xFF1A1A2E); // Deep Navy
      case 'Pastel':
        return const Color(0xFFFFF0F5); // Lavender Blush
      case 'Ocean':
        return const Color(0xFFE0F7FA); // Light Cyan
      default:
        return const Color(0xFFF9F7F3);
    }
  }

  static Color getBoardDark(String theme) {
    switch (theme) {
      case 'Classic Wood':
        return const Color(0xFFFF8E53); // Vibrant Orange
      case 'Dark Neon':
        return const Color(0xFFE94560); // Neon Pink
      case 'Pastel':
        return const Color(0xFFFFB6B9); // Pastel Pink
      case 'Ocean':
        return const Color(0xFF4ECDC4); // Vibrant Teal
      default:
        return const Color(0xFFFF8E53);
    }
  }
  static const Color boardBorder = Color(0xFFFFFFFF); // White Border

  // Highlight colors
  static const Color moveHighlight = Color(0x664ECDC4); 
  static const Color lastMoveHighlight = Color(0x66FFD166); 
  static const Color checkHighlight = Color(0x99EF476F); 
  static const Color captureHighlight = Color(0x66845EC2);
  static const Color selectedHighlight = Color(0x66FF6B6B);

  // Powerup tier colors (5 tiers) - matched to card rarity
  static const Color tierCommon = Color(0xFF95A5A6); // Gray
  static const Color tierUncommon = Color(0xFF06D6A0); // Mint Green
  static const Color tierRare = Color(0xFF4ECDC4); // Teal
  static const Color tierEpic = Color(0xFF845EC2); // Purple
  static const Color tierLegendary = Color(0xFFFFD166); // Gold

  // Text
  static const Color textPrimary = Color(0xFF2B2D42); // Dark Navy/Black
  static const Color textSecondary = Color(0xFF8D99AE); // Cool Gray
  static const Color textMuted = Color(0xFFEDF2F4); // Off White
  static const Color textLight = Color(0xFFFFFFFF); // Pure White

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF476F), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD166), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient coolGradient = LinearGradient(
    colors: [Color(0xFF4ECDC4), Color(0xFF556270)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────

class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle get heading3 => GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle get button => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textLight,
    letterSpacing: 0.5,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIMENSIONS
// ─────────────────────────────────────────────────────────────────────────────

class AppDimensions {
  static const double borderRadius = 24.0;
  static const double borderRadiusSmall = 12.0;
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

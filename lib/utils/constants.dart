import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME & COLORS
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Primary palette - Fun Pastel Theme (Peach & Turquoise)
  static const Color background = Color(0xFFFFF3E0); // Soft Peach
  static const Color backgroundEnd = Color(0xFFFFE0B2); // Warm Pastel Orange
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceLight = Color(0x66FFFFFF); // Translucent White
  static const Color cardBg = Color(0xFFFFFFFF);

  // Accent colors
  static const Color accentCyan = Color(0xFF00ACC1); // Bright Turquoise
  static const Color accentPink = Color(0xFFF06292); // Fun Pink
  static const Color accentPurple = Color(0xFFBA68C8); // Soft Purple
  static const Color accentAmber = Color(0xFFFFB74D); // Soft Amber
  static const Color accentGreen = Color(0xFF81C784); // Soft Green
  static const Color accentRed = Color(0xFFE57373); // Soft Red

  // Board colors (Light & Fun Theme variants)
  static Color getBoardLight(String theme) {
    switch (theme) {
      case 'Classic Wood':
        return const Color(0xFFFFF9C4); // Light Yellow
      case 'Dark Neon':
        return const Color(0xFFB2EBF2); // Soft Cyan
      case 'Pastel':
        return const Color(0xFFF8BBD0); // Soft Pink
      case 'Ocean':
        return const Color(0xFFE1F5FE); // Light Blue
      default:
        return const Color(0xFFFFF9C4);
    }
  }

  static Color getBoardDark(String theme) {
    switch (theme) {
      case 'Classic Wood':
        return const Color(0xFFFFCC80); // Soft Orange
      case 'Dark Neon':
        return const Color(0xFF4DD0E1); // Medium Cyan
      case 'Pastel':
        return const Color(0xFFF06292); // Medium Pink
      case 'Ocean':
        return const Color(0xFF4FC3F7); // Medium Blue
      default:
        return const Color(0xFFFFCC80);
    }
  }
  static const Color boardBorder = Color(0xFFFFE0B2); 

  // Highlight colors
  static const Color moveHighlight = Color(0x6600ACC1); 
  static const Color lastMoveHighlight = Color(0x66FFB74D); 
  static const Color checkHighlight = Color(0x99E57373); 
  static const Color captureHighlight = Color(0x66BA68C8);
  static const Color selectedHighlight = Color(0x66F06292);

  // Powerup tier colors
  static const Color tierCommon = Color(0xFFA1887F); // Light Brown
  static const Color tierUncommon = Color(0xFF81C784); // Green
  static const Color tierRare = Color(0xFF64B5F6); // Blue
  static const Color tierEpic = Color(0xFF9575CD); // Purple
  static const Color tierLegendary = Color(0xFFFFD54F); // Gold

  // Text - Dark Brown for High Readability on Pastel
  static const Color textPrimary = Color(0xFF4E342E); 
  static const Color textSecondary = Color(0xFF795548); 
  static const Color textMuted = Color(0xFF8D6E63); 
  static const Color textLight = Color(0xFFFFFFFF); 

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE57373), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient coolGradient = LinearGradient(
    colors: [Color(0xFF00ACC1), Color(0xFF00838F)],
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
    color: AppColors.textPrimary,
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

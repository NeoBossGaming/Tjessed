import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME & COLORS
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Primary palette
  static const Color background = Color(0xFF070B19);
  static const Color surface = Color(0x1AFFFFFF); // Translucent
  static const Color surfaceLight = Color(0x33FFFFFF); // Translucent light
  static const Color cardBg = Color(0x40000000); // Dark translucent

  // Accent colors
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFFB000FF);
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color accentRed = Color(0xFFFF0055);
  static const Color accentPink = Color(0xFFFF00CC);

  // Board colors
  static const Color boardLight = Color(0x22FFFFFF); // Glass light squares
  static const Color boardDark = Color(0x11000000); // Glass dark squares
  static const Color boardBorder = Color(0x6600E5FF);

  // Highlight colors
  static const Color moveHighlight = Color(0x6600E5FF);
  static const Color lastMoveHighlight = Color(0x44FFB300);
  static const Color checkHighlight = Color(0x88FF0055);
  static const Color captureHighlight = Color(0x66FF0055);
  static const Color selectedHighlight = Color(0x6600E5FF);

  // Powerup tier colors
  static const Color tier1 = Color(0xFF8B949E);
  static const Color tier2 = Color(0xFF00E5FF);
  static const Color tier3 = Color(0xFFB000FF);
  static const Color tier4 = Color(0xFFFFB300);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF070B19), Color(0xFF0A0F24), Color(0xFF070B19)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF0055), Color(0xFFFF00CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF6600)],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

class GameConstants {
  static const int defaultTimeSeconds = 600; // 10 minutes
  static const int maxPowerupsHeld = 3;
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

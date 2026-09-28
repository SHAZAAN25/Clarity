import 'package:flutter/material.dart';

/// Semantic color tokens for the Obsidian Sage palette.
/// Avoids neon gradients, saturated health greens, and pure black.
class AppColors {
  // Dark Palette - Deep charcoal, restrained borders, subtle surface separation
  static const Color darkBackground = Color(0xFF0F141C);
  static const Color darkSurface = Color(0xFF161D27);
  static const Color darkSurfaceElevated = Color(0xFF1E2633);
  static const Color darkCardBorder = Color(0xFF253041);
  static const Color darkDivider = Color(0xFF1F2937);

  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // Light Palette - Warm off-white, crisp card surfaces, soft neutral borders
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F3F5);
  static const Color lightCardBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFE5E7EB);

  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // Restrained Accent: Serene Sage / Emerald (Communicates progress without overwhelming)
  static const Color sagePrimary = Color(0xFF10B981);
  static const Color sageLight = Color(0xFF34D399);
  static const Color sageDark = Color(0xFF059669);
  static const Color sageSubtle = Color(0x1F10B981); // 12% opacity tint

  // Restrained Warning / Attention: Warm Amber (used sparingly for cravings & high-risk windows)
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberSubtle = Color(0x1FF59E0B);

  // Restrained Error / Relapse: Muted Rose (used only for genuine errors or exceeded limits)
  static const Color rose = Color(0xFFEF4444);
  static const Color roseLight = Color(0xFFF87171);
  static const Color roseSubtle = Color(0x1FEF4444);

  // Restrained Companion / Coach: Calm Indigo Slate
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoSubtle = Color(0x1F6366F1);

  // Backward compatibility aliases defaulting to dark palette
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceElevated = darkSurfaceElevated;
  static const Color cardBorder = darkCardBorder;
  static const Color divider = darkDivider;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color indicatorBg = darkCardBorder;
}


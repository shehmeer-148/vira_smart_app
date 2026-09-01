import 'package:flutter/material.dart';

class AppColors {
  AppColors._();


  /// Primary brand color.
  /// Used for buttons, app bars, selected items, switches, progress bars.
  static const Color primary = Color(0xFF3D5739);

  /// Light primary variant.
  static const Color primaryLight = Color(0xFF6E9A63);

  /// Dark primary variant.
  static const Color primaryDark = Color(0xFF355132);

  /// Accent color.
  /// Used for "Water Now", FAB and highlighted actions.
  static const Color accent = Color(0xFFD3A25E);

  /// Light accent.
  static const Color accentLight = Color(0xFFE8C38B);

  /// Dark accent.
  static const Color accentDark = Color(0xFFB88643);

  // ===========================================================================
  // BACKGROUND
  // ===========================================================================

  /// Main application background.
  static const Color background = Color(0xFFF7F4EF);

  /// Card background.
  static const Color surface = Color(0xFFF9F6F2);

  /// Slightly tinted surface.
  static const Color surfaceVariant = Color(0xFFF2EEE8);

  // ===========================================================================
  // TEXT
  // ===========================================================================

  static const Color textPrimary = Color(0xFF2F2F2F);

  static const Color textSecondary = Color(0xFF7B746B);

  static const Color textHint = Color(0xFFB6B0A7);

  static const Color textInverse = Colors.white;

  // ===========================================================================
  // STATUS
  // ===========================================================================

  static const Color success = Color(0xFF6E9A63);

  static const Color warning = Color(0xFFD89C2D);

  static const Color error = Color(0xFFD75B57);

  static const Color info = Color(0xFF5D9CEC);

  // ===========================================================================
  // BORDERS & DIVIDERS
  // ===========================================================================

  static const Color border = Color(0xFFE6E1D8);

  static const Color divider = Color(0xFFE9E4DD);

  // ===========================================================================
  // ICONS
  // ===========================================================================

  static const Color iconPrimary = primary;

  static const Color iconSecondary = textSecondary;

  static const Color iconDisabled = textHint;

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  static const Color bottomNavSelected = primary;

  static const Color bottomNavUnselected = Color(0xFFAAA39A);

  // ===========================================================================
  // INPUTS
  // ===========================================================================

  static const Color inputFill = Colors.white;

  static const Color inputBorder = border;

  static const Color inputFocusedBorder = primary;

  static const Color inputErrorBorder = error;

  // ===========================================================================
  // BUTTONS
  // ===========================================================================

  static const Color buttonPrimary = primary;

  static const Color buttonPrimaryText = Colors.white;

  static const Color buttonSecondary = Colors.white;

  static const Color buttonSecondaryText = accent;

  static const Color buttonDisabled = Color(0xFFD7D2CA);

  // ===========================================================================
  // CARDS
  // ===========================================================================

  static const Color cardBackground = Colors.white;

  static const Color cardBorder = Color(0xFFF2EEE8);

  // ===========================================================================
  // PROGRESS
  // ===========================================================================

  static const Color progressBackground = Color(0xFFE5E0D9);

  static const Color batteryHigh = success;

  static const Color batteryMedium = warning;

  static const Color batteryLow = error;

  // ===========================================================================
  // WATER TANK
  // ===========================================================================

  static const Color tankOk = success;

  static const Color tankLow = warning;

  static const Color tankEmpty = error;

  // ===========================================================================
  // CHIP
  // ===========================================================================

  static const Color chipSelected = primary;

  static const Color chipUnselected = Colors.white;

  static const Color chipBorder = border;

  // ===========================================================================
  // SHADOW
  // ===========================================================================

  static const Color shadow = Color(0x14000000);

  // ===========================================================================
  // OVERLAY
  // ===========================================================================

  static const Color overlay = Color(0x55000000);

  // ===========================================================================
  // TRANSPARENT
  // ===========================================================================

  static const Color transparent = Colors.transparent;
}
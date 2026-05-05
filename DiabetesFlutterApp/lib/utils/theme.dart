import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
class AppColors {
  static const bg        = Color(0xFFF0F4F8);
  static const surface   = Colors.white;
  static const surface2  = Color(0xFFF8FAFC);
  static const border    = Color(0xFFE2E8F0);
  static const border2   = Color(0xFFCBD5E1);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF64748B);
  static const textLight     = Color(0xFF94A3B8);
  static const accent    = Color(0xFF0EA5E9);
  static const accentDark= Color(0xFF0284C7);
  static const accentBg  = Color(0xFFE0F2FE);
  static const indigo    = Color(0xFF6366F1);
  static const green     = Color(0xFF10B981);
  static const yellow    = Color(0xFFF59E0B);
  static const red       = Color(0xFFEF4444);

  // Risk level colours
  static Color riskPrimary(String level) => level == 'High'
      ? red : level == 'Medium' ? yellow : green;
  static Color riskLight(String level) => level == 'High'
      ? const Color(0xFFFEE2E2) : level == 'Medium'
      ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5);
  static Color riskText(String level) => level == 'High'
      ? const Color(0xFF7F1D1D) : level == 'Medium'
      ? const Color(0xFF78350F) : const Color(0xFF065F46);
}

// ── Typography ────────────────────────────────────────────────────────────────
class AppText {
  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
    fontSize: 11, fontWeight: FontWeight.w800,
    color: AppColors.textMuted, letterSpacing: 0.9,
  );
  static TextStyle get label => GoogleFonts.plusJakartaSans(
    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary,
  );
  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.55,
  );
  static TextStyle get mono => GoogleFonts.spaceMono(
    fontSize: 13, fontWeight: FontWeight.w700,
  );
  static TextStyle get monoLarge => GoogleFonts.spaceMono(
    fontSize: 46, fontWeight: FontWeight.w700, height: 1.0,
  );
}

// ── Card decoration ───────────────────────────────────────────────────────────
BoxDecoration cardDecoration({Color? borderTopColor, double radius = 20}) =>
    BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: borderTopColor != null
          ? Border(top: BorderSide(color: borderTopColor, width: 5))
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    surface: AppColors.bg,
  ),
  scaffoldBackgroundColor: AppColors.bg,
  textTheme: GoogleFonts.plusJakartaSansTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 1,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black.withOpacity(0.1),
    titleTextStyle: GoogleFonts.plusJakartaSans(
      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    elevation: 12,
    shadowColor: Colors.black.withOpacity(0.1),
    surfaceTintColor: Colors.transparent,
    indicatorColor: AppColors.accentBg,
    labelTextStyle: WidgetStateProperty.all(
      GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 2),
    ),
    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textLight),
  ),
  sliderTheme: SliderThemeData(
    activeTrackColor: AppColors.accent,
    inactiveTrackColor: AppColors.border2,
    thumbColor: AppColors.accent,
    overlayColor: AppColors.accent.withOpacity(0.15),
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
    trackHeight: 4,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 5,
      shadowColor: AppColors.accent.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 17),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.accent,
      side: const BorderSide(color: AppColors.accent, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
    ),
  ),
);

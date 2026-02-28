import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final String _fontFamily = GoogleFonts.heebo().fontFamily!;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: _fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          background: AppColors.bg,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.bg,

        // ── AppBar ──────────────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: const Color(0x1A000000),
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        // ── Cards — shadow-only, no border (Wolt-style) ──
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Input Fields ────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        ),

        // ── Buttons ─────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── Chips ───────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryLight,
          labelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),

        // ── Bottom Navigation ───────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),

        // ── Bottom Sheet (Wolt-style) ───────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          dragHandleColor: AppColors.divider,
          dragHandleSize: Size(40, 4),
          showDragHandle: true,
        ),

        // ── Dialog ──────────────────────────────────
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          surfaceTintColor: Colors.transparent,
        ),

        // ── Divider ─────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),

        // ── SnackBar ────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),

        // ── Page Transitions ────────────────────────
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  static ThemeData get dark => light.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.darkSurface,
          background: AppColors.darkBg,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        appBarTheme: light.appBarTheme.copyWith(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkTextPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary,
          ),
        ),
        cardTheme: light.cardTheme.copyWith(color: AppColors.darkCard),
      );
}

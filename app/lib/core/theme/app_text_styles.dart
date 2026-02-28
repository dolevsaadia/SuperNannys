import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Named text styles for consistent typography across the app
class AppTextStyles {
  AppTextStyles._();

  static String get _fontFamily => GoogleFonts.heebo().fontFamily!;

  // ── Display ───────────────────────────────────────────
  static TextStyle get displayLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  // ── Headings ──────────────────────────────────────────
  static TextStyle get heading1 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get heading2 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get heading3 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  // ── Body ──────────────────────────────────────────────
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get body => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ── Labels ────────────────────────────────────────────
  static TextStyle get label => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  // ── Caption ───────────────────────────────────────────
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      );

  static TextStyle get captionBold => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint,
      );

  // ── Button ────────────────────────────────────────────
  static TextStyle get button => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  // ── Price ─────────────────────────────────────────────
  static TextStyle get price => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      );

  static TextStyle get priceSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );
}

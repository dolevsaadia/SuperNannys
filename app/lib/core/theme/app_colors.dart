import 'package:flutter/material.dart';

/// SuperNanny brand color system
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);       // violet-600
  static const Color primaryLight = Color(0xFFEDE9FE);  // violet-100
  static const Color primaryDark = Color(0xFF5B21B6);   // violet-700
  static const Color accent = Color(0xFF06B6D4);        // cyan-500
  static const Color accentLight = Color(0xFFCFFAFE);   // cyan-100

  // ── Semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF10B981);       // emerald-500
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);       // amber-500
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);         // red-500
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);          // blue-500
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Neutral (light) ────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF9FAFB);            // gray-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB);       // gray-200
  static const Color border = Color(0xFFD1D5DB);        // gray-300

  // ── Text ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);   // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color textHint = Color(0xFF9CA3AF);      // gray-400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Dark theme ────────────────────────────────────────
  static const Color darkBg = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkDivider = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ── Badges ────────────────────────────────────────────
  static const Color badgeVerified = Color(0xFF10B981);
  static const Color badgeFirstAid = Color(0xFFEF4444);
  static const Color badgeTopRated = Color(0xFFF59E0B);
  static const Color badgeFastResponder = Color(0xFF06B6D4);
  static const Color badgeBackground = Color(0xFF6366F1);

  // ── Rating ────────────────────────────────────────────
  static const Color star = Color(0xFFF59E0B);
}

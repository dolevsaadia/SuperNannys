import 'package:flutter/material.dart';

/// Reusable shadow presets for consistent elevation hierarchy
class AppShadows {
  AppShadows._();

  /// Subtle — cards at rest (NannyCard, menu items)
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Medium — cards on hover / interactive elements
  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Large — modals, floating elements
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Extra large — bottom sheets, overlay dialogs
  static List<BoxShadow> get xl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  /// Top shadow — for sticky headers, nav bars
  static List<BoxShadow> get top => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, -4),
        ),
      ];

  /// Colored glow — for primary buttons and featured cards
  static List<BoxShadow> primaryGlow(double opacity) => [
        BoxShadow(
          color: const Color(0xFF7C3AED).withValues(alpha: opacity),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

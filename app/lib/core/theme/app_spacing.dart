import 'package:flutter/material.dart';

/// Centralized spacing, padding, margin, and border-radius tokens.
/// Use these instead of hardcoded EdgeInsets / BorderRadius values.
class AppSpacing {
  AppSpacing._();

  // ── Raw spacing values ─────────────────────────────────
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 14;
  static const double xxxl = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;

  // ── Common EdgeInsets ──────────────────────────────────

  /// Page-level horizontal padding (20px each side)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 20);

  /// Card internal padding (16px all sides)
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  /// Card bottom section padding
  static const EdgeInsets cardBottomPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  /// Section header padding
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.fromLTRB(20, 24, 20, 14);

  /// List item padding (horizontal scroll)
  static const EdgeInsets listHorizontalPadding = EdgeInsets.symmetric(horizontal: 20);

  /// Input field content padding
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  /// Bottom sheet content padding
  static const EdgeInsets sheetPadding = EdgeInsets.all(20);

  /// Dialog content padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(24);

  /// Compact padding for badges/chips
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  /// Compact padding for small badges
  static const EdgeInsets chipPaddingSm = EdgeInsets.symmetric(horizontal: 6, vertical: 3);

  /// Button content padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20);

  /// Search bar inner padding
  static const EdgeInsets searchBarPadding = EdgeInsets.fromLTRB(16, 2, 16, 6);
}

/// Centralized border-radius tokens.
class AppRadius {
  AppRadius._();

  // ── Raw radius values ──────────────────────────────────
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 14;
  static const double card = 16;
  static const double cardLg = 18;
  static const double pill = 20;
  static const double sheet = 24;
  static const double full = 100;

  // ── Pre-built BorderRadius objects ─────────────────────

  /// Extra small (4px) — minimal rounding
  static final BorderRadius borderXs = BorderRadius.circular(xs);

  /// Small (6px) — rating badges, tiny elements
  static final BorderRadius borderSm = BorderRadius.circular(sm);

  /// Medium (8px) — price tags, sort buttons
  static final BorderRadius borderMd = BorderRadius.circular(md);

  /// Large (10px) — navigate buttons, small containers
  static final BorderRadius borderLg = BorderRadius.circular(lg);

  /// XL (12px) — search bar, badge backgrounds, popup menus
  static final BorderRadius borderXl = BorderRadius.circular(xl);

  /// XXL (14px) — input fields, buttons, snack bars
  static final BorderRadius borderXxl = BorderRadius.circular(xxl);

  /// Card (16px) — standard cards, horizontal nanny cards
  static final BorderRadius borderCard = BorderRadius.circular(card);

  /// Card Large (18px) — full-width nanny cards
  static final BorderRadius borderCardLg = BorderRadius.circular(cardLg);

  /// Pill (20px) — pills, chips, bottom sheet corners, status badges
  static final BorderRadius borderPill = BorderRadius.circular(pill);

  /// Sheet (24px) — bottom sheet top corners
  static final BorderRadius borderSheet = BorderRadius.circular(sheet);

  /// Sheet top-only
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(24));

  /// Card bottom-only (18px) — card footer
  static const BorderRadius cardBottom = BorderRadius.vertical(bottom: Radius.circular(18));
}

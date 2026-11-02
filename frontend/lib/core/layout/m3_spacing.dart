import 'package:flutter/material.dart';

/// Official Google Material Design 3 (M3) Baseline Spacing System (8dp Grid).
///
/// In Material Design 3, all component dimensions, paddings, margins, and gutters
/// align to an 8dp baseline grid (with a 4dp micro-half-step for icons and tight labels).
///
/// Scale:
/// - [xxs]: 4.0dp (Micro-alignment for icon offsets and tag badges)
/// - [xs]: 8.0dp (Tight spacing, internal element separation)
/// - [sm]: 16.0dp (Standard card padding, compact gutter)
/// - [md]: 24.0dp (Section padding, standard container spacing, medium/expanded gutter)
/// - [lg]: 32.0dp (Large container padding, card separation)
/// - [xl]: 40.0dp (Prominent section spacing)
/// - [xxl]: 48.0dp (Standard button minimum touch height / large padding)
/// - [xxxl]: 64.0dp (Hero margins, extra-large display margins)
///
/// Reference: https://m3.material.io/foundations/layout/understanding-layout/spacing
abstract class M3Spacing {
  // --- Raw Dimension Tokens ---
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 40.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // --- Directional Padding Tokens (EdgeInsetsDirectional.all) ---
  static const EdgeInsetsDirectional pXxs = EdgeInsetsDirectional.all(xxs);
  static const EdgeInsetsDirectional pXs = EdgeInsetsDirectional.all(xs);
  static const EdgeInsetsDirectional pSm = EdgeInsetsDirectional.all(sm);
  static const EdgeInsetsDirectional pMd = EdgeInsetsDirectional.all(md);
  static const EdgeInsetsDirectional pLg = EdgeInsetsDirectional.all(lg);
  static const EdgeInsetsDirectional pXl = EdgeInsetsDirectional.all(xl);
  static const EdgeInsetsDirectional pXxl = EdgeInsetsDirectional.all(xxl);
  static const EdgeInsetsDirectional pXxxl = EdgeInsetsDirectional.all(xxxl);

  // --- Horizontal Padding Tokens ---
  static const EdgeInsetsDirectional hXxs = EdgeInsetsDirectional.symmetric(horizontal: xxs);
  static const EdgeInsetsDirectional hXs = EdgeInsetsDirectional.symmetric(horizontal: xs);
  static const EdgeInsetsDirectional hSm = EdgeInsetsDirectional.symmetric(horizontal: sm);
  static const EdgeInsetsDirectional hMd = EdgeInsetsDirectional.symmetric(horizontal: md);
  static const EdgeInsetsDirectional hLg = EdgeInsetsDirectional.symmetric(horizontal: lg);
  static const EdgeInsetsDirectional hXl = EdgeInsetsDirectional.symmetric(horizontal: xl);
  static const EdgeInsetsDirectional hXxl = EdgeInsetsDirectional.symmetric(horizontal: xxl);

  // --- Vertical Padding Tokens ---
  static const EdgeInsetsDirectional vXxs = EdgeInsetsDirectional.symmetric(vertical: xxs);
  static const EdgeInsetsDirectional vXs = EdgeInsetsDirectional.symmetric(vertical: xs);
  static const EdgeInsetsDirectional vSm = EdgeInsetsDirectional.symmetric(vertical: sm);
  static const EdgeInsetsDirectional vMd = EdgeInsetsDirectional.symmetric(vertical: md);
  static const EdgeInsetsDirectional vLg = EdgeInsetsDirectional.symmetric(vertical: lg);
  static const EdgeInsetsDirectional vXl = EdgeInsetsDirectional.symmetric(vertical: xl);
  static const EdgeInsetsDirectional vXxl = EdgeInsetsDirectional.symmetric(vertical: xxl);

  // --- SizedBox Spacers (Height) ---
  static const SizedBox h4 = SizedBox(height: xxs);
  static const SizedBox h8 = SizedBox(height: xs);
  static const SizedBox h16 = SizedBox(height: sm);
  static const SizedBox h24 = SizedBox(height: md);
  static const SizedBox h32 = SizedBox(height: lg);
  static const SizedBox h40 = SizedBox(height: xl);
  static const SizedBox h48 = SizedBox(height: xxl);
  static const SizedBox h64 = SizedBox(height: xxxl);

  // --- SizedBox Spacers (Width) ---
  static const SizedBox w4 = SizedBox(width: xxs);
  static const SizedBox w8 = SizedBox(width: xs);
  static const SizedBox w16 = SizedBox(width: sm);
  static const SizedBox w24 = SizedBox(width: md);
  static const SizedBox w32 = SizedBox(width: lg);
  static const SizedBox w40 = SizedBox(width: xl);
  static const SizedBox w48 = SizedBox(width: xxl);
  static const SizedBox w64 = SizedBox(width: xxxl);

  // --- Square Spacers (Width & Height) ---
  static const SizedBox gapXxs = SizedBox(width: xxs, height: xxs);
  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);
  static const SizedBox gapXxxl = SizedBox(width: xxxl, height: xxxl);
}

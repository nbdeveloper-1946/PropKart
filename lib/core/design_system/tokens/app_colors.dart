import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../theme/propkart_theme.dart';

/// Semantic color tokens. Prefer [PropKartColors.of] when a [BuildContext] is available.
/// Static getters remain for backward compatibility and rebuild via [ThemeManager].
class CRMColors {
  static bool get isDark => ThemeManager().isDarkMode;

  // ── Core surfaces ──────────────────────────────────────────
  static Color get background =>
      isDark ? const Color(0xFF0A0E16) : const Color(0xFFF7F6F2);
  static Color get groupedBackground =>
      isDark ? const Color(0xFF080B12) : const Color(0xFFF0EEE8);
  static Color get cardBg =>
      isDark ? const Color(0xFF141A26) : const Color(0xFFFFFFFF);
  static Color get surface => cardBg;
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF1A2232) : const Color(0xFFFFFFFF);
  static Color get sidebarBg =>
      isDark ? const Color(0xFF0E131F) : const Color(0xFFEDEBE4);
  static Color get glassSurface =>
      isDark ? const Color(0xCC141A26) : const Color(0xE6FFFFFF);

  // ── Brand / accent ─────────────────────────────────────────
  static Color get primary =>
      isDark ? const Color(0xFF5CA380) : const Color(0xFF688A75);
  static Color get primaryHover =>
      isDark ? const Color(0xFF4A8465) : const Color(0xFF53705E);
  static Color get secondary =>
      isDark ? const Color(0xFF8BA39A) : const Color(0xFF8A9E94);
  static Color get accent =>
      isDark ? const Color(0xFF7AB896) : const Color(0xFF7A9C87);

  // ── Borders / dividers ─────────────────────────────────────
  static Color get border =>
      isDark ? const Color(0xFF262E3B) : const Color(0xFFE4E2D8);
  static Color get divider =>
      isDark ? const Color(0xFF1E2633) : const Color(0xFFECEAE3);

  // ── Text ──────────────────────────────────────────────────
  static Color get text =>
      isDark ? const Color(0xFFF3F4F6) : const Color(0xFF2E3331);
  static Color get textSecondary =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5A605D);
  static Color get textMuted =>
      isDark ? const Color(0xFF6B7280) : const Color(0xFF8C928F);

  // ── Semantic ───────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF5B8DEF);

  static Color get disabled =>
      isDark ? const Color(0xFF3A4250) : const Color(0xFFC8CBC7);
  static Color get overlay =>
      isDark ? const Color(0x99000000) : const Color(0x66000000);
  static Color get shadow =>
      isDark ? const Color(0x40000000) : const Color(0x14000000);

  // ── Chart / graph ──────────────────────────────────────────
  static List<Color> get chartColors => isDark
      ? const [
          Color(0xFF5CA380),
          Color(0xFF5B8DEF),
          Color(0xFFF59E0B),
          Color(0xFFEF4444),
          Color(0xFFA78BFA),
          Color(0xFF22D3EE),
        ]
      : const [
          Color(0xFF688A75),
          Color(0xFF5B8DEF),
          Color(0xFFF59E0B),
          Color(0xFFEF4444),
          Color(0xFF8B5CF6),
          Color(0xFF06B6D4),
        ];

  static List<Color> get graphColors => chartColors;

  static List<Color> get gradientPrimary => isDark
      ? const [Color(0xFF7AB896), Color(0xFF5CA380)]
      : const [Color(0xFF7A9C87), Color(0xFF688A75)];

  static Color get skeletonBase =>
      isDark ? const Color(0xFF1E2633) : const Color(0xFFE5E7EB);
  static Color get skeletonHighlight =>
      isDark ? const Color(0xFF2A3444) : const Color(0xFFF3F4F6);

  // ── Context-aware (ThemeExtension when available) ──────────
  static Color backgroundOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.background ?? background;
  static Color cardBgOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.surface ?? cardBg;
  static Color sidebarBgOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.sidebarBg ?? sidebarBg;
  static Color primaryOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.primary ?? primary;
  static Color primaryHoverOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.primaryHover ?? primaryHover;
  static Color borderOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.border ?? border;
  static Color textOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.text ?? text;
  static Color textSecondaryOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.textSecondary ?? textSecondary;
  static Color textMutedOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.textMuted ?? textMuted;
  static Color surfaceElevatedOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.surfaceElevated ?? surfaceElevated;
  static Color glassOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.glassSurface ?? glassSurface;
  static Color overlayOf(BuildContext context) =>
      PropKartColors.maybeOf(context)?.overlay ?? overlay;
}

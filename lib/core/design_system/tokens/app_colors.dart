import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';

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

/// ThemeExtension carrying PropKart semantic colors for light/dark.
@immutable
class PropKartColors extends ThemeExtension<PropKartColors> {
  final Color background;
  final Color groupedBackground;
  final Color surface;
  final Color surfaceElevated;
  final Color sidebarBg;
  final Color glassSurface;
  final Color primary;
  final Color primaryHover;
  final Color secondary;
  final Color accent;
  final Color border;
  final Color divider;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color disabled;
  final Color overlay;
  final Color shadow;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final List<Color> chartColors;
  final List<Color> gradientPrimary;

  const PropKartColors({
    required this.background,
    required this.groupedBackground,
    required this.surface,
    required this.surfaceElevated,
    required this.sidebarBg,
    required this.glassSurface,
    required this.primary,
    required this.primaryHover,
    required this.secondary,
    required this.accent,
    required this.border,
    required this.divider,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.disabled,
    required this.overlay,
    required this.shadow,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.chartColors,
    required this.gradientPrimary,
  });

  static PropKartColors light() => PropKartColors(
        background: const Color(0xFFF7F6F2),
        groupedBackground: const Color(0xFFF0EEE8),
        surface: const Color(0xFFFFFFFF),
        surfaceElevated: const Color(0xFFFFFFFF),
        sidebarBg: const Color(0xFFEDEBE4),
        glassSurface: const Color(0xE6FFFFFF),
        primary: const Color(0xFF688A75),
        primaryHover: const Color(0xFF53705E),
        secondary: const Color(0xFF8A9E94),
        accent: const Color(0xFF7A9C87),
        border: const Color(0xFFE4E2D8),
        divider: const Color(0xFFECEAE3),
        text: const Color(0xFF2E3331),
        textSecondary: const Color(0xFF5A605D),
        textMuted: const Color(0xFF8C928F),
        success: CRMColors.success,
        warning: CRMColors.warning,
        danger: CRMColors.danger,
        info: CRMColors.info,
        disabled: const Color(0xFFC8CBC7),
        overlay: const Color(0x66000000),
        shadow: const Color(0x14000000),
        skeletonBase: const Color(0xFFE5E7EB),
        skeletonHighlight: const Color(0xFFF3F4F6),
        chartColors: const [
          Color(0xFF688A75),
          Color(0xFF5B8DEF),
          Color(0xFFF59E0B),
          Color(0xFFEF4444),
          Color(0xFF8B5CF6),
          Color(0xFF06B6D4),
        ],
        gradientPrimary: const [Color(0xFF7A9C87), Color(0xFF688A75)],
      );

  static PropKartColors dark() => PropKartColors(
        background: const Color(0xFF0A0E16),
        groupedBackground: const Color(0xFF080B12),
        surface: const Color(0xFF141A26),
        surfaceElevated: const Color(0xFF1A2232),
        sidebarBg: const Color(0xFF0E131F),
        glassSurface: const Color(0xCC141A26),
        primary: const Color(0xFF5CA380),
        primaryHover: const Color(0xFF4A8465),
        secondary: const Color(0xFF8BA39A),
        accent: const Color(0xFF7AB896),
        border: const Color(0xFF262E3B),
        divider: const Color(0xFF1E2633),
        text: const Color(0xFFF3F4F6),
        textSecondary: const Color(0xFF9CA3AF),
        textMuted: const Color(0xFF6B7280),
        success: CRMColors.success,
        warning: CRMColors.warning,
        danger: CRMColors.danger,
        info: CRMColors.info,
        disabled: const Color(0xFF3A4250),
        overlay: const Color(0x99000000),
        shadow: const Color(0x40000000),
        skeletonBase: const Color(0xFF1E2633),
        skeletonHighlight: const Color(0xFF2A3444),
        chartColors: const [
          Color(0xFF5CA380),
          Color(0xFF5B8DEF),
          Color(0xFFF59E0B),
          Color(0xFFEF4444),
          Color(0xFFA78BFA),
          Color(0xFF22D3EE),
        ],
        gradientPrimary: const [Color(0xFF7AB896), Color(0xFF5CA380)],
      );

  static PropKartColors of(BuildContext context) {
    final ext = Theme.of(context).extension<PropKartColors>();
    assert(ext != null, 'PropKartColors not found in Theme');
    return ext ?? (Theme.of(context).brightness == Brightness.dark ? dark() : light());
  }

  static PropKartColors? maybeOf(BuildContext context) =>
      Theme.of(context).extension<PropKartColors>();

  @override
  PropKartColors copyWith({
    Color? background,
    Color? groupedBackground,
    Color? surface,
    Color? surfaceElevated,
    Color? sidebarBg,
    Color? glassSurface,
    Color? primary,
    Color? primaryHover,
    Color? secondary,
    Color? accent,
    Color? border,
    Color? divider,
    Color? text,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? disabled,
    Color? overlay,
    Color? shadow,
    Color? skeletonBase,
    Color? skeletonHighlight,
    List<Color>? chartColors,
    List<Color>? gradientPrimary,
  }) {
    return PropKartColors(
      background: background ?? this.background,
      groupedBackground: groupedBackground ?? this.groupedBackground,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      glassSurface: glassSurface ?? this.glassSurface,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      disabled: disabled ?? this.disabled,
      overlay: overlay ?? this.overlay,
      shadow: shadow ?? this.shadow,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      chartColors: chartColors ?? this.chartColors,
      gradientPrimary: gradientPrimary ?? this.gradientPrimary,
    );
  }

  @override
  PropKartColors lerp(ThemeExtension<PropKartColors>? other, double t) {
    if (other is! PropKartColors) return this;
    Color lerpC(Color a, Color b) => Color.lerp(a, b, t)!;
    return PropKartColors(
      background: lerpC(background, other.background),
      groupedBackground: lerpC(groupedBackground, other.groupedBackground),
      surface: lerpC(surface, other.surface),
      surfaceElevated: lerpC(surfaceElevated, other.surfaceElevated),
      sidebarBg: lerpC(sidebarBg, other.sidebarBg),
      glassSurface: lerpC(glassSurface, other.glassSurface),
      primary: lerpC(primary, other.primary),
      primaryHover: lerpC(primaryHover, other.primaryHover),
      secondary: lerpC(secondary, other.secondary),
      accent: lerpC(accent, other.accent),
      border: lerpC(border, other.border),
      divider: lerpC(divider, other.divider),
      text: lerpC(text, other.text),
      textSecondary: lerpC(textSecondary, other.textSecondary),
      textMuted: lerpC(textMuted, other.textMuted),
      success: lerpC(success, other.success),
      warning: lerpC(warning, other.warning),
      danger: lerpC(danger, other.danger),
      info: lerpC(info, other.info),
      disabled: lerpC(disabled, other.disabled),
      overlay: lerpC(overlay, other.overlay),
      shadow: lerpC(shadow, other.shadow),
      skeletonBase: lerpC(skeletonBase, other.skeletonBase),
      skeletonHighlight: lerpC(skeletonHighlight, other.skeletonHighlight),
      chartColors: t < 0.5 ? chartColors : other.chartColors,
      gradientPrimary: t < 0.5 ? gradientPrimary : other.gradientPrimary,
    );
  }
}

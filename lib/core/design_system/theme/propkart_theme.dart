import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/app_blur.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

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

/// Builds full light/dark [ThemeData] with PropKart tokens.
class PropKartTheme {
  static String? get _fontFamily {
    if (kIsWeb) return 'Inter';
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return null;
    }
    return 'Inter';
  }

  static TextTheme _textTheme(PropKartColors c) {
    TextStyle style(TextStyle s) => s.copyWith(color: c.text);
    final base = TextTheme(
      displayLarge: style(CRMTypography.largeDisplay),
      displayMedium: style(CRMTypography.largeTitle),
      displaySmall: style(CRMTypography.display),
      headlineLarge: style(CRMTypography.title),
      headlineMedium: style(CRMTypography.pageTitle),
      headlineSmall: style(CRMTypography.headline),
      titleLarge: style(CRMTypography.sectionTitle),
      titleMedium: style(CRMTypography.cardTitle),
      titleSmall: style(CRMTypography.navigationTitle),
      bodyLarge: style(CRMTypography.body),
      bodyMedium: style(CRMTypography.subheadline),
      bodySmall: style(CRMTypography.caption),
      labelLarge: style(CRMTypography.button),
      labelMedium: style(CRMTypography.label),
      labelSmall: style(CRMTypography.footnote),
    );
    if (_fontFamily == 'Inter') {
      return GoogleFonts.interTextTheme(base);
    }
    return base;
  }

  static ThemeData light() => _build(Brightness.light, PropKartColors.light());
  static ThemeData dark() => _build(Brightness.dark, PropKartColors.dark());

  static ThemeData _build(Brightness brightness, PropKartColors colors) {
    // fromSeed fills every Material 3 role (avoids null.withOpacity crashes on web).
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
    ).copyWith(
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.secondary,
      onSecondary: Colors.white,
      error: colors.danger,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.text,
      onSurfaceVariant: colors.textSecondary,
      surfaceContainerHighest: colors.surfaceElevated,
      surfaceContainerHigh: colors.surfaceElevated,
      surfaceContainer: colors.surface,
      surfaceContainerLow: colors.groupedBackground,
      surfaceContainerLowest: colors.background,
      outline: colors.border,
      outlineVariant: colors.divider,
      shadow: colors.shadow,
      scrim: colors.overlay,
    );

    final borderSoft = colors.border.withValues(alpha: 0.6);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.divider,
      extensions: [colors],
      textTheme: _textTheme(colors),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.glassSurface,
        foregroundColor: colors.text,
        titleTextStyle: CRMTypography.navigationTitle.copyWith(color: colors.text),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          side: BorderSide(color: borderSoft, width: 0.5),
        ),
        shadowColor: colors.shadow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        modalBackgroundColor: colors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.sheet)),
        ),
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CRMSpacing.m,
          vertical: CRMSpacing.s,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          borderSide: BorderSide(color: colors.danger),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: CRMTypography.body.copyWith(color: colors.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          boxShadow: CRMShadows.medium,
        ),
        textStyle: CRMTypography.caption.copyWith(color: colors.text),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.xl),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 0.5,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.text,
        contentPadding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
      ),
    );
  }

  // Re-export motion/blur for convenience
  static const blur = CRMBlur;
  static const motion = CRMMotion;
}
